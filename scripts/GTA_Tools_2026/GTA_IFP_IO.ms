-- GTA IFP Animation Import/Export Tools
-- For skeletal animations and bone keyframes
-- 
-- Original by Kam (2005)
-- Modified by E2001 (2024-2026)
--
-- Separated from Character IO for standalone animation management
--
-- CHANGELOG (March 14, 2026):
-- - Restored immediate save behavior (all operations save to disk immediately)
-- - Removed "Save File" button (no longer needed with immediate saves)
-- - All operations now match original workflow: instant file updates

-- MUTEX: Close other IFP tools to prevent global variable conflicts
try (closeRolloutFloater Kam_GTAsaIFP) catch ()

-- Get script directory for relative paths
global ifpScriptPath = getFilenamePath(getThisScriptFilename())

-- Animation functions: Use 2018 Goldfish version (enhanced features)
fileIn (scriptspath+"\\GTA_Tools_2026\\gtaIFPio_Fn.ms") quiet:true

AnimInfo = #()
ifpname = undefined
global GTAAnimNorm_lastAnimName = "NORMALIZED"

fn GTAAnim_AppendUniqueTime timeArray tm = (
	if (findItem timeArray tm) == 0 then append timeArray tm
)

fn GTAAnim_SortTimes timeArray = (
	qsort timeArray (fn _gtaAnimSort a b = (if a < b then -1 else if a > b then 1 else 0))
	timeArray
)

fn GTAAnim_CollectHierarchy rootObj = (
	local nodes = #()
	if rootObj == undefined then return nodes

	local queue = #(rootObj)
	while queue.count > 0 do (
		local current = queue[1]
		deleteItem queue 1
		append nodes current
		for child in current.children do append queue child
	)
	nodes
)

fn GTAAnim_FindSceneRoot obj = (
	local rootObj = obj
	if rootObj == undefined then return undefined
	while rootObj.parent != undefined do rootObj = rootObj.parent
	rootObj
)

fn GTAAnim_FindGTARoot obj = (
	local sceneRoot = GTAAnim_FindSceneRoot obj
	if sceneRoot == undefined then return undefined

	local hierarchy = GTAAnim_CollectHierarchy sceneRoot
	for node in hierarchy do (
		if (getUserProp node "BoneID") == 0 then return node
	)
	sceneRoot
)

fn GTAAnim_GetKeyTimes ctrl startTime endTime = (
	local times = #()
	if ctrl == undefined then return times
	try (
		for i = 1 to ctrl.keys.count do (
			local tm = getKeyTime ctrl i
			if (tm >= startTime) and (tm <= endTime) then GTAAnim_AppendUniqueTime times tm
		)
	) catch ()
	times
)

fn GTAAnim_GetFrameFromTime tm = (
	((tm as integer) / ticksPerFrame) as integer
)

fn GTAAnim_GetTimeFromFrame frameNumber = (
	(frameNumber as integer) * ticksPerFrame
)

fn GTAAnim_GetExportBones rootObj = (
	local exportBones = #()
	for node in (GTAAnim_CollectHierarchy rootObj) where (getUserProp node "BoneID") != undefined do append exportBones node
	exportBones
)

fn GTAAnim_GetSceneNodes = (
	local sceneNodes = #()
	for child in rootNode.children do join sceneNodes (GTAAnim_CollectHierarchy child)
	sceneNodes
)

fn GTAAnim_GetSceneBoneNodes = (
	local boneNodes = #()
	for node in (GTAAnim_GetSceneNodes()) where (getUserProp node "BoneID") != undefined do append boneNodes node
	boneNodes
)

fn GTAAnim_GetNameFromPath fname maxLen:0 = (
	local outName = getFilenameFile fname
	if outName == undefined or outName == "" then outName = "KamMaxScriptExp"
	if (maxLen > 0) and (outName.count > maxLen) then outName = substring outName 1 maxLen
	outName
)

fn GTAAnim_StoreOriginalPose nodes = (
	for node in nodes do (
		setUserProp node "OrgPos" node.pos
		setUserProp node "OrgRot" [node.rotation.x,node.rotation.y,node.rotation.z]
		setUserProp node "OrgRotW" node.rotation.w
		setUserProp node "Orgscl" node.scale
	)
)

fn GTAAnim_EnsureOriginalPoseForHierarchy rootObj = (
	if rootObj == undefined then return false
	local hierarchy = GTAAnim_CollectHierarchy rootObj
	if hierarchy.count == 0 then return false
	if (getUserProp hierarchy[1] "OrgPos") == undefined then GTAAnim_StoreOriginalPose hierarchy
	true
)

fn GTAAnim_ClearSelectionKeys nodes = (
	for node in nodes do (
		try (deletekeys node.pos.controller) catch ()
		try (deletekeys node.rotation.controller) catch ()
		try (deletekeys node.scale.controller) catch ()
	)
)

	fn GTAAnim_ResetSelectionControllers nodes = (
		for node in nodes do (
			local curPos = node.pos
			local curRot = node.rotation
			local curScale = node.scale
			try (node.rotation.controller = tcb_rotation()) catch ()
			try (node.pos.controller = bezier_position()) catch ()
			try (node.scale.controller = bezier_scale()) catch ()
			try (node.rotation = curRot) catch ()
			try (node.scale = curScale) catch ()
			try (node.pos = curPos) catch ()
		)
	)

fn GTAAnim_RestoreOriginalPoseImmediate nodes = (
	for node in nodes do (
		try (
			local rotXYZ = readvalue ((getUserProp node "OrgRot") as stringstream)
			local rotW = getUserProp node "OrgRotW"
			node.rotation = (quat rotXYZ.x rotXYZ.y rotXYZ.z rotW)
			node.scale = readvalue ((getUserProp node "Orgscl") as stringstream)
			node.pos = readvalue ((getUserProp node "OrgPos") as stringstream)
		) catch ()
	)
)

fn GTAAnim_GetApplyNodes = (
	if selection.count > 0 then return (selection as array)
	GTAAnim_GetSceneNodes()
)

fn GTAAnim_WriteSingleIFPHeader f ver outPath = (
	local internalName = undefined
	if ver == 0x33504E41 then (
		internalName = GTAAnim_GetNameFromPath outPath maxLen:23
		writeLong f 0x33504E41
		writeLong f 0
		writeString f internalName
		for i = 1 to (23 - internalName.count) do writeByte f 0
		writeLong f 1
	) else (
		internalName = GTAAnim_GetNameFromPath outPath
		writeLong f 0x4B504E41
		writeLong f 0
		writeLong f 0x4F464E49
		local infoLength = internalName.count + 1 + 4
		local skipbyte = 4 - (mod (internalName.count + 1) 4)
		if skipbyte != 4 then infoLength += skipbyte
		writeLong f infoLength
		writeLong f 1
		writeString f internalName
		if skipbyte != 4 then (
			for i = 1 to skipbyte do writeByte f 0
		)
	)
	internalName
)

fn GTAAnim_NormalizeRootFacing rootObj yawDegrees startFrame endFrame rotatePosition rotateRotation = (
	local gtaRoot = GTAAnim_FindGTARoot rootObj
	if gtaRoot == undefined then return #(false, "Could not find a GTA root node.")
	GTAAnim_EnsureOriginalPoseForHierarchy gtaRoot

	local startTime = GTAAnim_GetTimeFromFrame startFrame
	local endTime = GTAAnim_GetTimeFromFrame endFrame
	local times = #()

	if rotateRotation then (
		for tm in GTAAnim_GetKeyTimes gtaRoot.rotation.controller startTime endTime do GTAAnim_AppendUniqueTime times tm
	)
	if rotatePosition then (
		for tm in GTAAnim_GetKeyTimes gtaRoot.pos.controller startTime endTime do GTAAnim_AppendUniqueTime times tm
	)

	if times.count == 0 then GTAAnim_AppendUniqueTime times startTime
	GTAAnim_AppendUniqueTime times endTime
	GTAAnim_SortTimes times

	local yawQuat = (angleaxis yawDegrees [0,0,1]) as quat
	local yawMatrix = rotateZMatrix yawDegrees
	local rootAnchorPos = undefined
	local rotSamples = #()
	local posSamples = #()
	if rotatePosition then (
		at time startTime (
			try (rootAnchorPos = gtaRoot.pos) catch ()
		)
	)

	for tm in times do at time tm (
		if rotateRotation then (
			local currentRot = undefined
			try (currentRot = gtaRoot.rotation) catch ()
			if currentRot != undefined then append rotSamples #(tm, (yawQuat * currentRot))
		)
		if rotatePosition then (
			local currentPos = undefined
			try (currentPos = gtaRoot.pos) catch ()
			if (currentPos != undefined) and (rootAnchorPos != undefined) then (
				local posOffset = currentPos - rootAnchorPos
				append posSamples #(tm, (rootAnchorPos + (posOffset * yawMatrix)))
			)
		)
	)

	if rotateRotation and (classof gtaRoot.rotation.controller != tcb_rotation) then (
		gtaRoot.rotation.controller = tcb_rotation()
	)
	if rotatePosition and (classof gtaRoot.pos.controller != bezier_position) then (
		gtaRoot.pos.controller = bezier_position()
	)

	with animate on (
		for sample in rotSamples do at time sample[1] (
			gtaRoot.rotation = sample[2]
		)
		for sample in posSamples do at time sample[1] (
			gtaRoot.pos = sample[2]
			local pc = gtaRoot.pos.controller
			local tk = getKeyIndex pc sample[1]
			try (
				pc.keys[tk].InTangentType = #linear
				pc.keys[tk].OutTangentType = #linear
			) catch ()
		)
	)

	#(true, ("Normalized root '" + gtaRoot.name + "' across " + (times.count as string) + " key time(s)."), gtaRoot, times.count)
)

fn GTAAnim_ExportNormalizedIFP rootObj fname animName exportFormat useBoneIDsForANPK = (
	local gtaRoot = GTAAnim_FindGTARoot rootObj
	if gtaRoot == undefined then return #(false, "Could not find a GTA root node.")

	local exportBones = GTAAnim_GetExportBones gtaRoot
	if exportBones.count == 0 then return #(false, "No nodes with BoneID were found under the selected hierarchy.")
	local resolvedAnimName = GTAAnim_GetNameFromPath fname maxLen:23

	local f = undefined
	try (
		f = fopen fname "wb"
		if f == undefined then return #(false, "Could not create the output file.")

		local thisLength = undefined
		if exportFormat == 1 then (
			GTAAnim_WriteSingleIFPHeader f 0x33504E41 fname
			thisLength = ExpsaIFP f exportBones resolvedAnimName
		) else (
			GTAAnim_WriteSingleIFPHeader f 0x4B504E41 fname
			thisLength = expAnim f exportBones useBoneIDsForANPK resolvedAnimName
		)

		if thisLength == undefined then (
			fclose f
			deleteFile fname
			return #(false, "No animation data was exported. Check that the bones have keys.")
		)

		local totalSize = ftell f
		fseek f 4 #seek_set
		writeLong f (totalSize - 8)
		fclose f
		#(true, ("Exported normalized animation '" + resolvedAnimName + "'."), exportBones.count)
	) catch (
		try (fclose f) catch ()
		try (deleteFile fname) catch ()
		#(false, (getCurrentException() as string))
	)
)

/*
=============================================================================
   SECTION 1: ANIMATION (IFP) MANAGEMENT
   Uses: gtaIFPio_Fn.ms (2018 Goldfish Edition)
   Status: Working correctly
   
   All operations save immediately (no pending changes)
=============================================================================
*/

-- ===========================
-- ROLLOUT 1: ANIMATION
-- ===========================
rollout animateRoll "Animation" (
	local HInfo = undefined
	
	button loadifp "Load IFP File" width:120 align:#center tooltip:"Load skeletal animation file (.ifp) for editing"
	label lbl1 "Anim. File:" align:#left offset:[30,5]
	label lbl2 "Total Animation:" align:#left offset:[30,0]
	label lbl3 "Internal Name:" align:#left offset:[30,0]
	listbox AnimList height:10
	
	label lblSpacer1 "" height:8
	
	button btnRename "Rename" width:80 tooltip:"Rename selected animation (saves immediately)" across:2
	button btnDelete "Delete" width:80 tooltip:"Remove selected animation from list (saves immediately)"
	button btnMoveUp "Move UP" width:80 tooltip:"Move animation up in list order (saves immediately)" across:2
	button btnMoveDown "Move DOWN" width:80 tooltip:"Move animation down in list order (saves immediately)"
	button btnSaveNew "Add New Animation" width:120 tooltip:"Add current timeline as new animation to loaded IFP (saves immediately)" align:#center
	button ReplaceAnim "Replace Animation" width:120 align:#center tooltip:"Replace selected animation with current timeline (saves immediately)"
	button saveAnim "Export New IFP" width:120 align:#center tooltip:"Export current timeline as brand new IFP file"
	radioButtons formatType "Format:" labels:#("ANP3 (SA)", "ANPK (III/VC)") columns:2 default:1 align:#center offset:[0,0] tooltip:"SA uses ANP3 format, III/VC use ANPK format"
	checkbox useBoneID "Sibling" align:#left checked:false enabled:false offset:[85,-5]
	
	label lblSpacer2 "" height:8
	
	button RecOrg "M" width:17 align:#left tooltip:"Memorize current pose as original (for Reset button)" across:3
	button apyAnim "Apply Animation" width:86 align:#center tooltip:"Apply selected animation to character bones (matches by name)"
	button ResetPose "R" width:17 align:#right tooltip:"Reset character to memorized original pose"
	checkbox skipPos "Skip Position keys" align:#right offset:[5,-4] tooltip:"Ignore position keyframes (rotation only, for in-place animations)"
	
	label lblSpacer3 "" height:8
	
	spinner astart "Start" fieldwidth:30 type:#integer range:[0,10000,0] across:2 tooltip:"Starting frame for batch export"
	spinner aend "End" fieldwidth:30 type:#integer range:[0,10000,0] tooltip:"Ending frame for batch export"
	button batAnim "Batch Animation" width:122 align:#center tooltip:"Export multiple animations at once (range-based)"
	
	-- ===========================
	-- EVENT HANDLERS - ANIMATION
	-- ===========================
	
	-- Load IFP file and display animation list
	on loadifp pressed do (
		bkfile = ifpname
		ifpname = getOpenFileName caption:"Open GTA Animation File" types:"IFP animation (*.ifp)|*.ifp|All files (*.*)|*.*|"
		if (ifpname != undefined) then (
			f = fopen ifpname "rb"
			HInfo = ReadifpHeader f
			if HInfo == undefined then (
				fclose f
				messagebox "Header Data not correct!" Title:"IFP File Error"
			) 
			else (
				lbl1.text = "Anim. File: " + (filenameFromPath ifpname)
				lbl2.text = "Total Animation: " + (HInfo[1] as string)
				lbl3.text = "Internal Name: " + HInfo[2]
		
				AnimInfo = ifpAnimInfo f HInfo[1] HInfo[3]
				if AnimInfo == undefined then (
					fclose f
					messagebox "Animation Data not correct!!" Title:"IFP File Error"
				) else ( 
					AnimList.items = AnimInfo[1]
					
					-- Auto-detect format and set radio buttons
					if AnimInfo[3] == 0x4B504E41 then (
						formatType.state = 2  -- ANPK (III/VC)
						useBoneID.enabled = true
					) else (
						formatType.state = 1  -- ANP3 (SA)
						useBoneID.enabled = false
					)
				)--end if/else AnimInfo
				fclose f
				astart.value = 1
				aend.value = HInfo[1]
			)--end if/else HInfo
		) else ifpname = bkfile
	)--end on loadifp
	
	-- Spinner range validation handlers
	on astart changed val do (
		if val < 1 then astart.value = 1
		if HInfo != undefined then (
			if astart.value > HInfo[1] then astart.value = HInfo[1]
			if astart.value > aend.value then aend.value = astart.value	
		) else astart.value = 0
	)
	
	on aend changed val do (
		if val < 1 then aend.value = 1
		if HInfo != undefined then (
			if aend.value > HInfo[1] then aend.value = HInfo[1]
			if aend.value < astart.value then astart.value = aend.value
		) else aend.value = 0
	)
	
	-- Record original pose for reset
	on RecOrg pressed do (
		OrginAry = #()
		for i = 1 to $selection.count do (
			setUserProp $selection[i] "OrgPos" $selection[i].pos
			setUserProp $selection[i] "OrgRot" [$selection[i].rotation.x,$selection[i].rotation.y,$selection[i].rotation.z]
			setUserProp $selection[i] "OrgRotW" $selection[i].rotation.w
			setUserProp $selection[i] "Orgscl" $selection[i].scale
		)	
		RecOrg.text = "**"
	)
	
	-- Reset to original pose
	on ResetPose pressed do (
		sliderTime = 0
		for i = 1 to $selection.count do (
			deletekeys $selection[i].pos.controller
			deletekeys $selection[i].rotation.controller
			deletekeys $selection[i].scale.controller
			try (
				tp = readvalue ((getUserProp $selection[i] "OrgRot") as stringstream)
				tpW = getUserProp $selection[i] "OrgRotW"
				$selection[i].rotation = (quat tp.x tp.y tp.z tpW)
				$selection[i].scale = readvalue ((getUserProp $selection[i] "Orgscl") as stringstream)
				$selection[i].pos = readvalue ((getUserProp $selection[i] "OrgPos") as stringstream)
			) catch (RecOrg.text = "M")
		)--end for i	
	)
	
	-- Apply selected animation to timeline
	on apyAnim pressed do (
		if (AnimList.selection > 0)AND($selection.count >0) then (
			rult = resetPost $selection slidertime
			if rult == false then RecOrg.text = "M"
			select $*
			f = fopen ifpname "rb"
			fseek f AnimInfo[2][AnimList.selection] #seek_set
			
			ApplyAnim f ($selection as array) skipPos.checked slidertime AnimInfo[3]
		
			fclose f
			gc()
		)
	)--end on apyAnim
	
	-- Double-click animation list to apply
	on AnimList doubleclicked idx do (
		local applyNodes = GTAAnim_GetApplyNodes()
		if applyNodes.count == 0 then return undefined
		if (getUserProp applyNodes[1] "OrgPos") == undefined then (
			GTAAnim_StoreOriginalPose applyNodes
			RecOrg.text = "**"
		)
		rult = resetPost applyNodes slidertime
		if rult == false then RecOrg.text = "M"
		GTAAnim_ClearSelectionKeys applyNodes
		sliderTime = 0
		f = fopen ifpname "rb"
		fseek f AnimInfo[2][AnimList.selection] #seek_set

		ApplyAnim f applyNodes skipPos.checked slidertime AnimInfo[3]
	
		fclose f
		gc()
	)--end on AnimList doubleclicked
	
	-- Batch apply multiple animations
	on batAnim pressed do (
		if (AnimList.selection > 0)AND($selection.count >0) then (
			sliderTime = 0
			if (getUserProp $selection[1] "OrgPos") == undefined then (
				for i = 1 to $selection.count do (
					setUserProp $selection[i] "OrgPos" $selection[i].pos
					setUserProp $selection[i] "OrgRot" [$selection[i].rotation.x,$selection[i].rotation.y,$selection[i].rotation.z]
					setUserProp $selection[i] "OrgRotW" $selection[i].rotation.w
					setUserProp $selection[i] "Orgscl" $selection[i].scale
				)
			)
			
			f = fopen ifpname "rb"
			for tt = astart.value to aend.value do (
				rult = resetPost $selection slidertime
				if rult == false then RecOrg.text = "M"
			
				fseek f AnimInfo[2][tt] #seek_set
			
				ApplyAnim f ($selection as array) skipPos.checked slidertime AnimInfo[3]

				animationRange = interval 0 (animationRange.end + 1)
				slidertime = animationRange.end
		
				gc()
			)--end for tt
			fclose f
			animationRange = interval 0 (animationRange.end - 1)
		)
	)--end on batAnim
	
	-- Animation management handlers
	on btnRename pressed do (
		if AnimList.selection == 0 then (
			messagebox "Please select an animation to rename!" title:"No Selection"
		) else (
			local oldName = AnimList.selected
			local selIndex = AnimList.selection
			global renameDialogResult = oldName
			
			-- Create a simple rollout for input
			rollout renameDialog "Rename Animation" (
				edittext txtName "New name:" text:renameDialogResult fieldwidth:150
				button btnOK "OK" width:80 align:#center
				button btnCancel "Cancel" width:80 align:#center offset:[0,-26]
				
				on btnOK pressed do (
					renameDialogResult = txtName.text
					destroyDialog renameDialog
				)
				on btnCancel pressed do (
					destroyDialog renameDialog
				)
			)
			
			createDialog renameDialog 200 90 modal:true
			local newNameInput = renameDialogResult
			
			if newNameInput != "" and newNameInput != oldName then (
				-- Check for duplicate names
				if findItem AnimInfo[1] newNameInput != 0 then (
					messagebox ("Animation name '" + newNameInput + "' already exists!") title:"Duplicate Name"
				) else (
					try (
						-- Rebuild IFP with renamed animation
						tempName = (getFilenamePath ifpname) + "ttemp.bin"
						ff = fopen tempName "wb"
						f = fopen ifpname "rb"
						
						-- Write header
						if AnimInfo[3] == 0x33504E41 then (
							-- SA format
							writeLong ff AnimInfo[3] #unsigned
							writeLong ff 0  -- Placeholder
							writeString ff HInfo[2]
							for i = 1 to (23 - HInfo[2].count) do writeByte ff 0
							writeLong ff HInfo[1]
						) else (
							-- VC format (not fully supported for rename yet)
							messagebox "Rename not supported for VC format IFP files yet." title:"Not Supported"
							fclose f
							fclose ff
							deleteFile tempName
							return undefined
						)
						
						-- Copy all animations, modifying the selected one
						for i = 1 to AnimInfo[1].count do (
							fseek f AnimInfo[2][i] #seek_set
							
							-- Determine animation data length
							if i < AnimInfo[1].count then (
								dataLength = AnimInfo[2][i+1] - AnimInfo[2][i]
							) else (
								-- Last animation
								local animName = readString f
								local skipBytes = 23 - animName.count
								fseek f skipBytes #seek_cur
								local boneCount = readLong f
								local frameDataSize = readLong f
								dataLength = 36 + frameDataSize + (36 * boneCount)
								fseek f AnimInfo[2][i] #seek_set
							)
							
							-- Read animation data
							animData = #()
							for b = 1 to dataLength do (
								append animData (readByte f)
							)
							
							-- If this is the renamed animation, update the name in the data
							if i == selIndex then (
								nameBytes = #()
								for c = 1 to newNameInput.count do (
									append nameBytes (bit.charasint newNameInput[c])
								)
								append nameBytes 0
								while nameBytes.count < 24 do append nameBytes 0
								for b = 1 to 24 do (
									animData[b] = nameBytes[b]
								)
							)
							
							-- Write animation data
							for b in animData do (
								writeByte ff b
							)
						)
						
						-- Update file length
						local totalSize = ftell ff
						fseek ff 4 #seek_set
						writeLong ff (totalSize - 8)
						fclose f
						fclose ff
						gc()
						
						-- Replace original
						deleteFile ifpname
						renameFile tempName ifpname
						
						-- Reload
						f = fopen ifpname "rb"
						HInfo = ReadifpHeader f
						AnimInfo = ifpAnimInfo f HInfo[1] HInfo[3]
						fclose f
						
						AnimList.items = AnimInfo[1]
						AnimList.selection = selIndex
					) catch (
						try (fclose f) catch()
						try (fclose ff) catch()
						try (deleteFile tempName) catch()
						messagebox ("Error renaming animation:\n" + (getCurrentException())) title:"Error"
					)
				)
			)
		)
	)
	
	on btnDelete pressed do (
		if AnimList.selection == 0 then (
			messagebox "Please select an animation to delete!" title:"No Selection"
		) else (
			animName = AnimList.selected
			selIndex = AnimList.selection
			result = queryBox ("Delete animation: " + animName + "?\n\nThis cannot be undone.") title:"Confirm Delete"
			if result then (
				try (
					-- Rebuild IFP without deleted animation
					tempName = (getFilenamePath ifpname) + "ttemp.bin"
					ff = fopen tempName "wb"
					f = fopen ifpname "rb"
					
					-- Write header with updated count
					if AnimInfo[3] == 0x33504E41 then (
						-- SA format
						writeLong ff AnimInfo[3] #unsigned
						writeLong ff 0  -- Placeholder
						writeString ff HInfo[2]
						for i = 1 to (23 - HInfo[2].count) do writeByte ff 0
						writeLong ff (HInfo[1] - 1)  -- Decrement count
					) else (
						-- VC format
						messagebox "Delete not supported for VC format IFP files yet." title:"Not Supported"
						fclose f
						fclose ff
						deleteFile tempName
						return undefined
					)
					
					-- Copy all animations except the deleted one
					for i = 1 to AnimInfo[1].count do (
						if i != selIndex then (
							fseek f AnimInfo[2][i] #seek_set
							
							-- Determine animation data length
							if i < AnimInfo[1].count then (
								dataLength = AnimInfo[2][i+1] - AnimInfo[2][i]
							) else (
								-- Last animation
								local animName = readString f
								local skipBytes = 23 - animName.count
								fseek f skipBytes #seek_cur
								local boneCount = readLong f
								local frameDataSize = readLong f
								dataLength = 36 + frameDataSize + (36 * boneCount)
								fseek f AnimInfo[2][i] #seek_set
							)
							
							-- Copy animation data
							for b = 1 to dataLength do (
								writeByte ff (readByte f)
							)
						)
					)
					
					-- Update file length
					local totalSize = ftell ff
					fseek ff 4 #seek_set
					writeLong ff (totalSize - 8)
					fclose f
					fclose ff
					gc()
					
					-- Replace original
					deleteFile ifpname
					renameFile tempName ifpname
					
					-- Reload
					f = fopen ifpname "rb"
					HInfo = ReadifpHeader f
					AnimInfo = ifpAnimInfo f HInfo[1] HInfo[3]
					fclose f
					
					AnimList.items = AnimInfo[1]
					lbl2.text = "Total Animation: " + (HInfo[1] as string)
				) catch (
					try (fclose f) catch()
					try (fclose ff) catch()
					try (deleteFile tempName) catch()
					messagebox ("Error deleting animation:\n" + (getCurrentException())) title:"Error"
				)
			)
		)
	)
	
	on btnMoveUp pressed do (
		if AnimList.selection == 0 then (
			messagebox "Please select an animation to move!" title:"No Selection"
		) else if AnimList.selection == 1 then (
			messagebox "Animation is already at the top!" title:"Can't Move"
		) else (
			idx = AnimList.selection
			animName = AnimList.selected
			try (
				-- Rebuild IFP with animations reordered
				tempName = (getFilenamePath ifpname) + "ttemp.bin"
				ff = fopen tempName "wb"
				f = fopen ifpname "rb"
				
				-- Write header
				if AnimInfo[3] == 0x33504E41 then (
					writeLong ff AnimInfo[3] #unsigned
					writeLong ff 0  -- Placeholder
					writeString ff HInfo[2]
					for i = 1 to (23 - HInfo[2].count) do writeByte ff 0
					writeLong ff HInfo[1]
				) else (
					messagebox "Move not supported for VC format IFP files yet." title:"Not Supported"
					fclose f
					fclose ff
					deleteFile tempName
					return undefined
				)
				
				-- Write animations in new order (swap idx with idx-1)
				for i = 1 to AnimInfo[1].count do (
					-- Determine which animation to write
					local srcIdx = i
					if i == idx - 1 then srcIdx = idx      -- Write selected animation here
					else if i == idx then srcIdx = idx - 1  -- Write previous animation here
					
					fseek f AnimInfo[2][srcIdx] #seek_set
					
					-- Determine animation data length
					if srcIdx < AnimInfo[1].count then (
						dataLength = AnimInfo[2][srcIdx+1] - AnimInfo[2][srcIdx]
					) else (
						local animName = readString f
						local skipBytes = 23 - animName.count
						fseek f skipBytes #seek_cur
						local boneCount = readLong f
						local frameDataSize = readLong f
						dataLength = 36 + frameDataSize + (36 * boneCount)
						fseek f AnimInfo[2][srcIdx] #seek_set
					)
					
					-- Copy animation data
					for b = 1 to dataLength do (
						writeByte ff (readByte f)
					)
				)
				
				-- Update file length
				local totalSize = ftell ff
				fseek ff 4 #seek_set
				writeLong ff (totalSize - 8)
				fclose f
				fclose ff
				gc()
				
				-- Replace original
				deleteFile ifpname
				renameFile tempName ifpname
				
				-- Reload
				f = fopen ifpname "rb"
				HInfo = ReadifpHeader f
				AnimInfo = ifpAnimInfo f HInfo[1] HInfo[3]
				fclose f
				
				AnimList.items = AnimInfo[1]
				AnimList.selection = idx - 1
			) catch (
				try (fclose f) catch()
				try (fclose ff) catch()
				try (deleteFile tempName) catch()
				messagebox ("Error moving animation:\n" + (getCurrentException())) title:"Error"
			)
		)
	)
	
	on btnMoveDown pressed do (
		if AnimList.selection == 0 then (
			messagebox "Please select an animation to move!" title:"No Selection"
		) else if AnimList.selection == AnimInfo[1].count then (
			messagebox "Animation is already at the bottom!" title:"Can't Move"
		) else (
			idx = AnimList.selection
			animName = AnimList.selected
			try (
				-- Rebuild IFP with animations reordered
				tempName = (getFilenamePath ifpname) + "ttemp.bin"
				ff = fopen tempName "wb"
				f = fopen ifpname "rb"
				
				-- Write header
				if AnimInfo[3] == 0x33504E41 then (
					writeLong ff AnimInfo[3] #unsigned
					writeLong ff 0  -- Placeholder
					writeString ff HInfo[2]
					for i = 1 to (23 - HInfo[2].count) do writeByte ff 0
					writeLong ff HInfo[1]
				) else (
					messagebox "Move not supported for VC format IFP files yet." title:"Not Supported"
					fclose f
					fclose ff
					deleteFile tempName
					return undefined
				)
				
				-- Write animations in new order (swap idx with idx+1)
				for i = 1 to AnimInfo[1].count do (
					-- Determine which animation to write
					local srcIdx = i
					if i == idx then srcIdx = idx + 1      -- Write next animation here
					else if i == idx + 1 then srcIdx = idx  -- Write selected animation here
					
					fseek f AnimInfo[2][srcIdx] #seek_set
					
					-- Determine animation data length
					if srcIdx < AnimInfo[1].count then (
						dataLength = AnimInfo[2][srcIdx+1] - AnimInfo[2][srcIdx]
					) else (
						local animName = readString f
						local skipBytes = 23 - animName.count
						fseek f skipBytes #seek_cur
						local boneCount = readLong f
						local frameDataSize = readLong f
						dataLength = 36 + frameDataSize + (36 * boneCount)
						fseek f AnimInfo[2][srcIdx] #seek_set
					)
					
					-- Copy animation data
					for b = 1 to dataLength do (
						writeByte ff (readByte f)
					)
				)
				
				-- Update file length
				local totalSize = ftell ff
				fseek ff 4 #seek_set
				writeLong ff (totalSize - 8)
				fclose f
				fclose ff
				gc()
				
				-- Replace original
				deleteFile ifpname
				renameFile tempName ifpname
				
				-- Reload
				f = fopen ifpname "rb"
				HInfo = ReadifpHeader f
				AnimInfo = ifpAnimInfo f HInfo[1] HInfo[3]
				fclose f
				
				AnimList.items = AnimInfo[1]
				AnimList.selection = idx + 1
			) catch (
				try (fclose f) catch()
				try (fclose ff) catch()
				try (deleteFile tempName) catch()
				messagebox ("Error moving animation:\n" + (getCurrentException())) title:"Error"
			)
		)
	)
	
	on btnSaveNew pressed do (
		if ifpname == undefined then (
			messagebox "Please load an IFP file first!" title:"No IFP Loaded"
		) else if AnimInfo[3] != 0x33504E41 then (
			messagebox "Add New only works with SA format IFP files currently.\n\nVC format support coming soon." title:"Format Not Supported"
		) else (
			local exportNodes = GTAAnim_GetSceneBoneNodes()
			if exportNodes.count == 0 then (
				messagebox "No bones with BoneID found in the scene!\n\nSet BoneID user properties on bones.\n\nExample: setUserProp $myBone \"BoneID\" 0" title:"No Bones"
			) else (
					-- Create input dialog
					rollout newAnimDialog "Add New Animation" (
						local newAnimResult = "NEW_ANIM"
						edittext txtName "Animation name:" text:"NEW_ANIM" fieldwidth:150
						button btnOK "OK" width:80 align:#center
						button btnCancel "Cancel" width:80 align:#center offset:[0,-26]
						
						on btnOK pressed do (
							newAnimResult = txtName.text
							destroyDialog newAnimDialog
						)
						on btnCancel pressed do (
							newAnimResult = ""
							destroyDialog newAnimDialog
						)
						
						fn getResult = (
							return newAnimResult
						)
					)
					
					createDialog newAnimDialog 200 90 modal:true
					local newAnimName = newAnimDialog.getResult()
					
					if newAnimName != "" then (
						-- Check for duplicate names
						if findItem AnimInfo[1] newAnimName != 0 then (
							messagebox ("Animation '" + newAnimName + "' already exists!") title:"Duplicate Name"
						) else (
							try (
								-- Rebuild IFP file with new animation appended
								
								f = fopen ifpname "rb+"
								if f == undefined then (
									messagebox "Failed to open IFP file for appending." title:"I/O Error"
									return undefined
								)
								
								local headerID = readLong f
								if headerID != 0x33504E41 then (
									fclose f
									messagebox "Loaded file is not SA format (ANP3)." title:"Format Error"
									return undefined
								)
								
								local currentFileLength = readLong f
								fseek f 24 #seek_cur
								local currentAnimCount = readLong f
								
								-- Append at the logical end of animation data, not EOF.
								fseek f (currentFileLength + 8) #seek_set
								
								animLength = ExpsaIFP f exportNodes newAnimName
								if animLength == undefined then (
									fclose f
									messagebox "Failed to export animation data!\n\nCheck that the selected bones have animation keys." title:"Export Failed"
									return undefined
								)
								
								local totalSize = ftell f
								fseek f 4 #seek_set
								writeLong f (totalSize - 8)
								fseek f 32 #seek_set
								writeLong f (currentAnimCount + 1)
								fclose f
								gc()
								
								-- Reload file info
								f = fopen ifpname "rb"
								HInfo = ReadifpHeader f
								AnimInfo = ifpAnimInfo f HInfo[1] HInfo[3]
								fclose f
								
								-- Update UI
								AnimList.items = AnimInfo[1]
								AnimList.selection = AnimInfo[1].count
								lbl2.text = "Total Animation: " + (HInfo[1] as string)
								
								messagebox ("Animation '" + newAnimName + "' added successfully!") title:"Success"
								
							) catch (
								try (fclose f) catch()
								messagebox ("Error adding animation:\n" + (getCurrentException())) title:"Error"
							)
					)
				)
			)
		)
	)
	
	-- Animation format changes
	on formatType changed state do (
		-- State 1 = ANP3 (SA), State 2 = ANPK (III/VC)
		if state == 2 then (
			useBoneID.enabled = true
		) else (
			useBoneID.enabled = false
		)
	)
	
	on useBoneID changed state do (
		if useBoneID.checked == true then useBoneID.text = "Bone ID"
		else useBoneID.text = "Sibling"
	)
	
	-- Replace animation in loaded IFP file
	on ReplaceAnim pressed do (
		local exportNodes = GTAAnim_GetSceneBoneNodes()
		sliderTime = 0
		if (AnimList.selection != 0)AND(exportNodes.count > 0) then (
			OK2Append = false
			-- Verify format matches: State 1 = ANP3 (0x33504E41), State 2 = ANPK (0x4B504E41)
			if (formatType.state == 2)AND(AnimInfo[3] == 0x4B504E41) then OK2Append = true
			if (formatType.state == 1)AND(AnimInfo[3] == 0x33504E41) then OK2Append = true
			if OK2Append == false then (
				messagebox "Cannot replace animation:\n\nFile format does not match selected format.\n\nANP3 (SA) and ANPK (III/VC) cannot be mixed." title: "IFP Format Mismatch"
			) else (
				try (
					local tempName = (getFilenamePath ifpname) + "ttemp.bin"
					local selIndex = AnimList.selection
					local ff = fopen tempName "wb"
					local f = fopen ifpname "rb"
					if (ff == undefined) or (f == undefined) then (
						try (fclose ff) catch()
						try (fclose f) catch()
						messagebox "Could not open files for replace operation." title:"Replace Error"
						return undefined
					)

					if AnimInfo[3] == 0x33504E41 then (
						writeLong ff AnimInfo[3] #unsigned
						writeLong ff 0
						writeString ff HInfo[2]
						for i = 1 to (23 - HInfo[2].count) do writeByte ff 0
						writeLong ff HInfo[1]
					) else (
						writeLong ff AnimInfo[3] #unsigned
						writeLong ff 0
						writeLong ff 0x4F464E49 #unsigned
						local infoLength = HInfo[2].count + 1 + 4
						local skipbyte = 4 - (mod (HInfo[2].count + 1) 4)
						if skipbyte != 4 then infoLength += skipbyte
						writeLong ff infoLength
						writeLong ff HInfo[1]
						writeString ff HInfo[2]
						if skipbyte != 4 then for i = 1 to skipbyte do writeByte ff 0
					)

					for i = 1 to AnimInfo[1].count do (
						if i == selIndex then (
							local thisLength = undefined
							if AnimInfo[3] == 0x33504E41 then thisLength = ExpsaIFP ff exportNodes AnimList.selected
							else thisLength = expAnim ff exportNodes useBoneID.checked AnimList.selected
							if thisLength == undefined then (
								fclose f
								fclose ff
								deleteFile tempName
								messagebox "Replacement export failed. Check that the selected bones have animation keys." title:"Replace Error"
								return undefined
							)
						) else (
							fseek f AnimInfo[2][i] #seek_set
							local dataLength = 0
							if i < AnimInfo[1].count then (
								dataLength = AnimInfo[2][i+1] - AnimInfo[2][i]
							) else if AnimInfo[3] == 0x33504E41 then (
								local animName = readString f
								local skipBytes = 23 - animName.count
								fseek f skipBytes #seek_cur
								local boneCount = readLong f
								local frameDataSize = readLong f
								dataLength = 36 + frameDataSize + (36 * boneCount)
								fseek f AnimInfo[2][i] #seek_set
							) else (
								fseek f AnimInfo[2][i] #seek_set
								if (readLong f) != 0x454D414E then (
									fclose f
									fclose ff
									deleteFile tempName
									messagebox "Could not parse ANPK animation during replace." title:"Replace Error"
									return undefined
								)
								local nameLength = readLong f
								local skipBytes = 4 - (mod nameLength 4)
								if (skipBytes > 0) and (skipBytes < 4) then fseek f skipBytes #seek_cur
								if (readLong f) != 0x4E414744 then (
									fclose f
									fclose ff
									deleteFile tempName
									messagebox "Could not parse ANPK DGAN header during replace." title:"Replace Error"
									return undefined
								)
								local animLength = readLong f
								dataLength = animLength + 16 + nameLength
								if (skipBytes > 0) and (skipBytes < 4) then dataLength += skipBytes
								fseek f AnimInfo[2][i] #seek_set
							)

							for b = 1 to dataLength do writeByte ff (readByte f)
						)
					)

					local totalSize = ftell ff
					fseek ff 4 #seek_set
					writeLong ff (totalSize - 8)
					fclose f
					fclose ff
					gc()

					deleteFile ifpname
					renameFile tempName ifpname

					f = fopen ifpname "rb"
					HInfo = ReadifpHeader f
					AnimInfo = ifpAnimInfo f HInfo[1] HInfo[3]
					fclose f
					AnimList.items = AnimInfo[1]
					AnimList.selection = selIndex

					format "DONE!!\n\n"
				) catch (
					try (fclose f) catch()
					try (fclose ff) catch()
					try (deleteFile tempName) catch()
					messagebox ("Error replacing animation:\n" + (getCurrentException())) title:"Replace Error"
				)
				gc()
			)
		)--end if AnimList.selection
	)--end on ReplaceAnim 
	
	-- Export selection as new IFP file
	on saveAnim pressed do (
		local exportNodes = GTAAnim_GetSceneBoneNodes()
		if (AnimList.selection != 0)AND(exportNodes.count >0) then (
			Sname = getSaveFileName caption:"Save GTA Animation file" types:"IFP animation (*.ifp)|*.ifp"
			if Sname != undefined then (
				if exportNodes.count == 0 then (
					messagebox "No bones with BoneID found in the scene!\n\nSet BoneID user properties on bones.\n\nExample: setUserProp $myBone \"BoneID\" 0" title:"No Bones"
				) else (
					-- Check for animation keys
					local hasKeys = false
					local keyInfo = ""
					for obj in exportNodes do (
						local rotKeys = obj.rotation.controller.keys.count
						local posKeys = obj.pos.controller.keys.count
						keyInfo += "  " + obj.name + ": " + (rotKeys as string) + " rot, " + (posKeys as string) + " pos keys\n"
						if rotKeys > 0 then hasKeys = true
					)
					
					if not hasKeys then (
						messagebox ("No rotation keys found on any bones!\n\nBones checked:\n" + keyInfo + "\nYou must set rotation keyframes before exporting.") title:"No Keys"
					) else (
						try (	--undefined*undefined
							f = fopen Sname "wb"

							if formatType.state == 1 then (   					--ANP3 (SA)
								local exportAnimName = GTAAnim_GetNameFromPath Sname maxLen:23
								GTAAnim_WriteSingleIFPHeader f 0x33504E41 Sname
								thisLength = ExpsaIFP f exportNodes exportAnimName
								
								if thisLength == undefined then (
									fclose f
									deleteFile Sname
									messagebox "Export failed - no animation data!\n\nCheck that bones have rotation keyframes." title:"Export Failed"
								) else (
									size = ftell f
									fseek f 4 #seek_set
									writeLong f (size - 8)
									fclose f
								)
							) else (   					   									--ANPK (III/VC)
								writeLong f 0x4B504E41		--ANPK
								writeLong f 0
								writeLong f 0x4F464E49		--INFO
								writeLong f 20
								writeLong f 1
								writeString f "KamMaxScriptExp"
								thisLength = expAnim f exportNodes useBoneID.checked AnimList.selected
								
								if thisLength == undefined then (
									fclose f
									deleteFile Sname
									messagebox "Export failed - no animation data!\n\nCheck that bones have rotation keyframes." title:"Export Failed"
								) else (
									size = ftell f
									fseek f 4 #seek_set
									writeLong f (size - 8)
									fclose f
								)
							)
						) catch (
							try (fclose f) catch()
							messagebox ("Error exporting IFP:\n" + (getCurrentException())) title:"Export Error"
							-----------------------
							--This is GMax output--
							-----------------------
							Sname = (substring Sname 1 (Sname.count - 4)) + ".txt"
							ss = "" as stringstream

							clearlistener()
							format "<!-- path=\"%\" -->\n" Sname
							format"//\n//\n//This is Header Section\n"  

							if formatType.state == 1 then (   					--ANP3 (SA)
								thisLength = gExpsaIFP ss exportNodes (GTAAnim_GetNameFromPath Sname maxLen:23)
								format "c 4\nANP3\ni 1\n%\n" (thisLength + 28)
								format "c 24\n%\n//\n//\n" (GTAAnim_GetNameFromPath Sname maxLen:23)
								format "i 1\n1\n"
							) else (																		--ANPK (III/VC)
								thisLength = gm_expAnim ss exportNodes useBoneID.checked AnimList.selected
								format "c 4\nANPK\ni 1\n%\n" (thisLength + 28)
								format "c 4\nINFO\ni 2\n20 1\n"
								format "c 16\nKamMaxScriptExp\n//\n//\n"
							)	

							format "%\n//" (ss as string)
						)--end try/catch
						gc()
					)
				)
			)--end if Sname
		)--end if AnimList.selection
	)--end on saveAnim
)--end rollout animateRoll

/*
=============================================================================
	SECTION 2: NORMALIZATION
	Targets already GTA-compatible hierarchies and fixes root-space issues.
=============================================================================
*/

rollout normalizeRoll "Normalize" (
	local pickedRoot = undefined

	label lblScope "For already-mapped GTA hierarchies only." align:#center
	label lblScope2 "This fixes root facing/motion, not foreign bone mapping." align:#center
	button btnUseSelection "Use Selected Root" width:140 align:#center tooltip:"Pick a node from the animated GTA hierarchy"
	label lblRoot "Root: <none>" align:#left offset:[8,0]
	checkbox useAnimRange "Use animation range" checked:true align:#center
	spinner startFrame "Start" fieldwidth:40 type:#integer range:[0,100000,0] across:2 enabled:false
	spinner endFrame "End" fieldwidth:40 type:#integer range:[0,100000,100] enabled:false
	spinner yawDegrees "Yaw Degrees" fieldwidth:50 type:#float range:[-360.0,360.0,180.0] align:#left tooltip:"180 fixes the common backwards-facing case"
	checkbox rotateHeading "Rotate root heading" checked:true align:#left tooltip:"Flip the character's facing direction"
	checkbox rotateMotion "Rotate travel path" checked:false align:#left tooltip:"For true locomotion clips only. Leave OFF for in-place dances or hip-compensated animations."
	button btnNormalize "Normalize Root Facing" width:160 align:#center
	label lblSpacerNorm "" height:8
	radioButtons exportFormat "Export Format:" labels:#("ANP3 (SA)", "ANPK (III/VC)") columns:2 default:1 align:#center
	checkbox useBoneIDsForANPK "Use BoneID for ANPK" checked:false align:#center enabled:false
	button btnNormalizeExport "Normalize + Export" width:160 align:#center tooltip:"Applies normalization, then exports a fresh IFP file"

	fn RefreshRangeUI = (
		local startVal = 0
		local endVal = 100
		try (
			startVal = GTAAnim_GetFrameFromTime animationRange.start
			endVal = GTAAnim_GetFrameFromTime animationRange.end
		) catch ()
		startFrame.value = startVal
		endFrame.value = endVal
		startFrame.enabled = not useAnimRange.checked
		endFrame.enabled = not useAnimRange.checked
	)

	fn SetPickedRoot rootObj = (
		pickedRoot = rootObj
		if pickedRoot == undefined then lblRoot.text = "Root: <none>"
		else lblRoot.text = "Root: " + (GTAAnim_FindGTARoot pickedRoot).name
	)

	fn GetRootFromSelection = (
		if selection.count != 1 then return undefined
		selection[1]
	)

	fn GetStartFrameValue = (
		if useAnimRange.checked then GTAAnim_GetFrameFromTime animationRange.start else startFrame.value
	)

	fn GetEndFrameValue = (
		if useAnimRange.checked then GTAAnim_GetFrameFromTime animationRange.end else endFrame.value
	)

	on normalizeRoll open do (
		RefreshRangeUI()
		if selection.count == 1 then SetPickedRoot selection[1]
	)

	on useAnimRange changed state do RefreshRangeUI()

	on exportFormat changed state do (
		useBoneIDsForANPK.enabled = (state == 2)
	)

	on btnUseSelection pressed do (
		local rootObj = GetRootFromSelection()
		if rootObj == undefined then (
			messagebox "Select exactly one node from the GTA hierarchy first." title:"Normalize"
		) else (
			SetPickedRoot rootObj
		)
	)

	on btnNormalize pressed do (
		if pickedRoot == undefined then (
			messagebox "Pick a GTA hierarchy root first." title:"Normalize"
		) else (
			local startVal = GetStartFrameValue()
			local endVal = GetEndFrameValue()
			if endVal < startVal then (
				messagebox "End frame must be greater than or equal to start frame." title:"Normalize"
			) else if (rotateHeading.checked == false) and (rotateMotion.checked == false) then (
				messagebox "Enable at least one normalization option." title:"Normalize"
			) else (
				local result = GTAAnim_NormalizeRootFacing pickedRoot yawDegrees.value startVal endVal rotateMotion.checked rotateHeading.checked
				if result[1] == true then messagebox result[2] title:"Normalize"
				else messagebox result[2] title:"Normalize Error"
			)
		)
	)

	on btnNormalizeExport pressed do (
		if pickedRoot == undefined then (
			messagebox "Pick a GTA hierarchy root first." title:"Normalize + Export"
		) else (
			local startVal = GetStartFrameValue()
			local endVal = GetEndFrameValue()
			if endVal < startVal then (
				messagebox "End frame must be greater than or equal to start frame." title:"Normalize + Export"
			) else (
				local outName = getSaveFileName caption:"Export normalized IFP" types:"IFP animation (*.ifp)|*.ifp|"
				if outName != undefined then (
					local normResult = GTAAnim_NormalizeRootFacing pickedRoot yawDegrees.value startVal endVal rotateMotion.checked rotateHeading.checked
					if normResult[1] != true then (
						messagebox normResult[2] title:"Normalize Error"
					) else (
						local exportResult = GTAAnim_ExportNormalizedIFP pickedRoot outName undefined exportFormat.state useBoneIDsForANPK.checked
						if exportResult[1] == true then messagebox (normResult[2] + "\n\n" + exportResult[2]) title:"Normalize + Export"
						else messagebox exportResult[2] title:"Export Error"
					)
				)
			)
		)
	)
)

/*
=============================================================================
   SECTION 3: ABOUT
=============================================================================
*/

-- ===========================
-- ROLLOUT 2: ABOUT
-- ===========================
rollout aboutRoll "About" (
	label l1 "GTA IFP Animation IO V2.1"
	label l1a "March, 2026"
	label l2 "Code based on Kam's GTA_IFP_IO v1.1"
	label l2a "and 2018 Goldfish Edition."
	label l2b ""
	label l3 "Enhanced by E2001"
	label l3a "Immediate save workflow restored"
)

/*
=============================================================================
   FLOATER CREATION
=============================================================================
*/

if Kam_GTAsaIFP != undefined then ( closeRolloutFloater Kam_GTAsaIFP; gc() )
Kam_GTAsaIFP = newRolloutFloater "Animation IFP IO" 220 820 10 30
addRollout animateRoll Kam_GTAsaIFP
addRollout normalizeRoll Kam_GTAsaIFP rolledup:true
addRollout aboutRoll Kam_GTAsaIFP rolledup:true
