-- GTA IFP Animation Import/Export Tools
-- For skeletal animations and bone keyframes
-- 
-- Original by Kam (2005)
-- Modified by E2001 (2024-2026)

-- MUTEX: Close other IFP tools to prevent global variable conflicts
try (closeRolloutFloater Kam_GTAsaIFP) catch ()

-- Get script directory for relative paths
global ifpScriptPath = getFilenamePath(getThisScriptFilename())

-- Animation functions: Character-specific copy (isolated from world object changes)
fileIn (scriptspath+"\\GTA_Tools_2026\\gtaCharIFPio_Fn.ms") quiet:true

AnimInfo = #()
ifpname = undefined
global GTA_ACTIVE_RIG_ROOT

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

fn GTAAnim_GetBoneID node = (
	if node == undefined then return undefined
	local boneID = undefined
	try (boneID = getUserProp node "BoneID") catch ()
	if boneID == undefined or boneID == "" then return undefined
	try (boneID as integer) catch (undefined)
)

fn GTAAnim_FindRigRootFromNode node = (
	local cur = node
	while cur != undefined do (
		if (GTAAnim_GetBoneID cur) == 0 then return cur
		cur = cur.parent
	)
	undefined
)

fn GTAAnim_FindRigRootsInScene = (
	local roots = #()
	for node in (GTAAnim_GetSceneNodes()) do (
		if (GTAAnim_GetBoneID node) == 0 then append roots node
	)
	roots
)

fn GTAAnim_GetSkinModifier node = (
	if node == undefined then return undefined
	if not isProperty node #modifiers then return undefined
	for m in node.modifiers do (
		if classof m == Skin then return m
	)
	undefined
)

fn GTAAnim_ResolveRigRootFromSkinnedMesh meshNode = (
	local parentRoot = GTAAnim_FindRigRootFromNode meshNode
	if parentRoot != undefined then return parentRoot

	local skinMod = GTAAnim_GetSkinModifier meshNode
	if skinMod == undefined then return undefined

	local roots = GTAAnim_FindRigRootsInScene()
	if roots.count < 1 then return undefined

	local bestRoot = undefined
	local bestCount = 0
	local tie = false
	for r in roots do (
		local c = 0
		for b in (GTAAnim_CollectHierarchy r) do (
			local deps = undefined
			try (deps = refs.dependents b) catch (deps = undefined)
			if deps != undefined and (findItem deps skinMod) > 0 then c += 1
		)
		if c > bestCount then (
			bestCount = c
			bestRoot = r
			tie = false
		) else if c == bestCount and c > 0 then tie = true
	)

	if bestCount > 0 and not tie then return bestRoot
	undefined
)

fn GTAAnim_ResolveActiveRigRoot = (
	if selection.count > 0 then (
		for s in selection do (
			local skinRoot = GTAAnim_ResolveRigRootFromSkinnedMesh s
			if skinRoot != undefined then (
				GTA_ACTIVE_RIG_ROOT = skinRoot
				return skinRoot
			)
		)

		local selRoot = GTAAnim_FindRigRootFromNode selection[1]
		if selRoot != undefined then (
			GTA_ACTIVE_RIG_ROOT = selRoot
			return selRoot
		)
	)

	if GTA_ACTIVE_RIG_ROOT != undefined and isValidNode GTA_ACTIVE_RIG_ROOT then return GTA_ACTIVE_RIG_ROOT

	local roots = GTAAnim_FindRigRootsInScene()
	if roots.count == 1 then (
		GTA_ACTIVE_RIG_ROOT = roots[1]
		return roots[1]
	)

	undefined
)

fn GTAAnim_GetActiveRigBoneNodes = (
	local rigRoot = GTAAnim_ResolveActiveRigRoot()
	if rigRoot == undefined then return #()
	local nodes = #()
	for node in (GTAAnim_CollectHierarchy rigRoot) where (GTAAnim_GetBoneID node) != undefined do append nodes node
	nodes
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

fn GTAAnim_ClearSelectionKeys nodes = (
	for node in nodes do (
		if (GTAAnim_GetBoneID node) != undefined then (
			try (deletekeys node.pos.controller) catch ()
			try (deletekeys node.rotation.controller) catch ()
			try (deletekeys node.scale.controller) catch ()
		)
	)
)

fn GTAAnim_EnforceRootOnlyPositionKeys nodes = (
	for node in nodes do (
		local boneID = GTAAnim_GetBoneID node
		if boneID != undefined and boneID != 0 then (
			try (deletekeys node.pos.controller) catch ()
		)
	)
)

fn GTAAnim_GetApplyNodes = (
	GTAAnim_GetActiveRigBoneNodes()
)

fn GTAAnim_NormalizeLoadedIFPInternalName internalName ver fallbackPath:undefined = (
	local resolvedName = internalName
	if (resolvedName == undefined) or (resolvedName == "") then (
		if fallbackPath != undefined then (
			if ver == 0x33504E41 then resolvedName = GTAAnim_GetNameFromPath fallbackPath maxLen:23
			else resolvedName = GTAAnim_GetNameFromPath fallbackPath
		) else resolvedName = "KamMaxScriptExp"
	)
	if (ver == 0x33504E41) and (resolvedName.count > 23) then resolvedName = substring resolvedName 1 23
	resolvedName
)

fn GTAAnim_CopyBytes srcFile dstFile byteCount = (
	for i = 1 to byteCount do writeByte dstFile (readByte srcFile)
)

fn GTAAnim_WriteLoadedIFPHeader f ver internalName animCount = (
	if ver == 0x33504E41 then (
		writeLong f 0x33504E41
		writeLong f 0
		writeString f internalName
		for i = 1 to (23 - internalName.count) do writeByte f 0
		writeLong f animCount
	) else (
		writeLong f 0x4B504E41
		writeLong f 0
		writeLong f 0x4F464E49
		local infoLength = internalName.count + 1 + 4
		local skipbyte = 4 - (mod (internalName.count + 1) 4)
		if skipbyte != 4 then infoLength += skipbyte
		writeLong f infoLength
		writeLong f animCount
		writeString f internalName
		if skipbyte != 4 then (
			for i = 1 to skipbyte do writeByte f 0
		)
	)
)

fn GTAAnim_RenameLoadedIFPHeader ifpPath newInternalName = (
	local src = undefined
	local dst = undefined
	local tempName = undefined
	try (
		src = fopen ifpPath "rb"
		if src == undefined then return #(false, "Could not open the IFP file.", undefined)

		local hInfo = ReadifpHeader src
		if hInfo == undefined then (
			fclose src
			return #(false, "Could not read the IFP header.", undefined)
		)

		local resolvedName = GTAAnim_NormalizeLoadedIFPInternalName newInternalName hInfo[3] fallbackPath:ifpPath
		if resolvedName == hInfo[2] then (
			fclose src
			return #(true, "Internal name unchanged.", #(hInfo[1], resolvedName, hInfo[3]))
		)

		local dataStart = ftell src
		fseek src 0 #seek_end
		local dataLength = (ftell src) - dataStart
		fseek src dataStart #seek_set

		tempName = (getFilenamePath ifpPath) + "ttemp.bin"
		dst = fopen tempName "wb"
		if dst == undefined then (
			fclose src
			return #(false, "Could not create the temporary file.", undefined)
		)

		GTAAnim_WriteLoadedIFPHeader dst hInfo[3] resolvedName hInfo[1]
		GTAAnim_CopyBytes src dst dataLength

		local totalSize = ftell dst
		fseek dst 4 #seek_set
		writeLong dst (totalSize - 8)
		fclose src
		fclose dst
		gc()

		deleteFile ifpPath
		renameFile tempName ifpPath

		#(true, ("Internal name changed to '" + resolvedName + "'."), #(hInfo[1], resolvedName, hInfo[3]))
	) catch (
		try (fclose src) catch ()
		try (fclose dst) catch ()
		if tempName != undefined then try (deleteFile tempName) catch ()
		#(false, (getCurrentException() as string), undefined)
	)
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

fn GTAAnim_ValidateIFP filepath = (
	local f = fopen filepath "rb"
	if f == undefined then return #("error", "Cannot open file")
	local result = undefined
	try (
		local headerID = readLong f
		local storedLength = readLong f
		fseek f 0 #seek_end
		local actualFileSize = ftell f
		fseek f 8 #seek_set

		if headerID == 0x33504E41 then (
			local intname = readString f
			fseek f (23 - intname.count) #seek_cur
			local animCount = readLong f
			local walkOK = true
			local goodCount = 0
			local lastGoodPos = ftell f
			for i = 1 to animCount while walkOK do (
				if (ftell f) >= actualFileSize then (walkOK = false) else (
					local animStart = ftell f
					local aname = readString f
					fseek f (23 - aname.count) #seek_cur
					local boneCount = readLong f
					local frameDataSize = readLong f
					-- Shallow expected end: animStart + 24(name) + 4(boneCount) + 4(frameDataSize) + 4(unkwn) + 36*boneCount + frameDataSize
					local expectedEnd = animStart + 36 + (36 * boneCount) + frameDataSize
					if boneCount < 1 or boneCount > 256 or frameDataSize < 0 or expectedEnd > actualFileSize then (
						walkOK = false
					) else (
						local unkwn = readLong f
						-- Deep walk: validate each bone header within this animation
						local boneWalkOK = true
						local dataConsumed = 0
						for b = 1 to boneCount while boneWalkOK do (
							if (ftell f) + 36 > actualFileSize then (boneWalkOK = false) else (
								local bname = readString f
								fseek f (23 - bname.count) #seek_cur
								local keyType = readLong f
								local frameCount = readLong f
								local boneID = readLong f
								if keyType == 3 then (
									local boneDataBytes = frameCount * 10
									dataConsumed += boneDataBytes
									if (ftell f) + boneDataBytes > actualFileSize then (boneWalkOK = false)
									else (fseek f boneDataBytes #seek_cur)
								) else if keyType == 4 then (
									local boneDataBytes = frameCount * 16
									dataConsumed += boneDataBytes
									if (ftell f) + boneDataBytes > actualFileSize then (boneWalkOK = false)
									else (fseek f boneDataBytes #seek_cur)
								) else (
									-- Unknown keyType: can't calculate bone size, fall back to shallow seek
									boneWalkOK = false
								)
							)
						)
						-- Accept if deep walk succeeded, OR if shallow seek lands within file
						if boneWalkOK and dataConsumed == frameDataSize then (
							goodCount += 1
							lastGoodPos = ftell f
						) else if expectedEnd <= actualFileSize then (
							-- Deep walk failed but shallow seek is valid: accept and seek to expected end
							fseek f expectedEnd #seek_set
							goodCount += 1
							lastGoodPos = ftell f
						) else (
							walkOK = false
						)
					)
				)
			)
			if walkOK then (
				local trueDataEnd = ftell f
				local correctLength = trueDataEnd - 8
				result = #("ok", storedLength, correctLength, actualFileSize, animCount, intname)
			) else if goodCount > 0 then (
				local salvageLength = lastGoodPos - 8
				result = #("truncated", storedLength, salvageLength, actualFileSize, animCount, intname, goodCount, lastGoodPos)
			) else (
				result = #("corrupt", "Failed to walk any animations - file is unreadable")
			)
		) else if headerID == 0x4B504E41 then (
			if (readLong f) != 0x4F464E49 then (
				result = #("corrupt", "Missing INFO chunk")
			) else (
				local infoLength = readLong f
				local infoStart = ftell f
				local animCount = readLong f
				local intname = readString f
				local skipbyte = 4 - (mod (intname.count + 1) 4)
				if skipbyte != 4 then fseek f skipbyte #seek_cur
				local walkOK = true
				local goodCount = 0
				local lastGoodPos = ftell f
				for i = 1 to animCount while walkOK do (
					if (ftell f) >= actualFileSize then (walkOK = false) else (
						if (readLong f) != 0x454D414E then (walkOK = false) else (
							local nameLength = readLong f
							local aname = readString f
							local nSkip = 4 - (mod nameLength 4)
							if (nSkip > 0) and (nSkip < 4) then fseek f nSkip #seek_cur
							if (readLong f) != 0x4E414744 then (walkOK = false) else (
								local animLen = readLong f
								fseek f animLen #seek_cur
								if (ftell f) > actualFileSize then walkOK = false
								else (goodCount += 1; lastGoodPos = ftell f)
							)
						)
					)
				)
				if walkOK then (
					local trueDataEnd = ftell f
					local correctLength = trueDataEnd - 8
					result = #("ok", storedLength, correctLength, actualFileSize, animCount, intname)
				) else if goodCount > 0 then (
					local salvageLength = lastGoodPos - 8
					result = #("truncated", storedLength, salvageLength, actualFileSize, animCount, intname, goodCount, lastGoodPos)
				) else (
					result = #("corrupt", "Failed to walk any animations - file is unreadable")
				)
			)
		) else (
			result = #("error", "Unknown IFP format (header: " + (formattedPrint headerID format:"08X") + ")")
		)
	) catch (
		result = #("error", getCurrentException())
	)
	fclose f
	result
)

fn GTAAnim_RepairIFP filepath = (
	local info = GTAAnim_ValidateIFP filepath
	if info[1] == "error" then return info
	if info[1] == "corrupt" then return info

	local storedLength = info[2]
	local correctLength = info[3]
	local actualFileSize = info[4]
	local validBytes = correctLength + 8
	local isTruncated = (info[1] == "truncated")
	local newAnimCount = if isTruncated then info[7] else info[5]

	if not isTruncated and storedLength == correctLength and actualFileSize == validBytes then
		return #("ok", "File is already valid - no repair needed")

	-- Fix header: fileLength and animCount
	local headerID = undefined
	local f = fopen filepath "r+b"
	if f == undefined then return #("error", "Cannot open file for writing")
	headerID = readLong f
	fseek f 4 #seek_set
	writeLong f correctLength
	if isTruncated then (
		if headerID == 0x33504E41 then (
			fseek f 8 #seek_set
			local intname = readString f
			fseek f (23 - intname.count) #seek_cur
			writeLong f newAnimCount
		) else (
			fseek f 16 #seek_set
			writeLong f newAnimCount
		)
	)
	fclose f

	-- Truncate to valid data
	if actualFileSize > validBytes then (
		local tmpPath = filepath + ".repair_tmp"
		local src = undefined
		local dst = undefined
		try (
			src = fopen filepath "rb"
			dst = fopen tmpPath "wb"
			GTAAnim_CopyBytes src dst validBytes
			fclose src; src = undefined
			fclose dst; dst = undefined
			deleteFile filepath
			renameFile tmpPath filepath
		) catch (
			if src != undefined then try (fclose src) catch ()
			if dst != undefined then try (fclose dst) catch ()
			try (deleteFile tmpPath) catch ()
			return #("error", "Truncation failed: " + getCurrentException())
		)
	)

	local changes = ""
	if storedLength != correctLength then
		changes += "Fixed fileLength: " + (storedLength as string) + " -> " + (correctLength as string)
	if isTruncated then (
		if changes.count > 0 then changes += "\n"
		changes += "Trimmed to " + (newAnimCount as string) + " of " + (info[5] as string) + " animations (removed " + ((info[5] - newAnimCount) as string) + " damaged)"
	)
	if actualFileSize > validBytes then (
		if changes.count > 0 then changes += "\n"
		changes += "Trimmed " + ((actualFileSize - validBytes) as string) + " trailing bytes"
	)
	#("repaired", changes, newAnimCount, info[6])
)

/*
=============================================================================
   SECTION 1: ANIMATION (IFP) MANAGEMENT
   Uses: gtaCharIFPio_Fn.ms (character animation functions)
   Status: Working correctly
   
   All operations save immediately (no pending changes)
=============================================================================
*/

-- ===========================
-- ROLLOUT 1: ANIMATION
-- ===========================
rollout animateRoll "Character Animation" (
	local HInfo = undefined
	
	button loadifp "Load IFP" width:80 align:#center tooltip:"Load skeletal animation file (.ifp) for editing" across:2
	button btnRepairIFP "Repair IFP" width:80 align:#center tooltip:"Validate and repair IFP file offset errors"
	label lbl1 "Anim. File:" align:#left offset:[6,5]
	label lbl2 "Total Animations:" align:#left offset:[6,0]
	label lbl3 "Internal Name:" align:#left offset:[6,5]
	edittext txtInternalName "" fieldwidth:120 across:2
	button btnSetInternalName "Set" width:50 align:#right offset:[0,-2] tooltip:"Update the loaded IFP internal file name (saves immediately)"
	
	label lblSpacer1 "Double-Click For Fast Load" align:#left	offset:[6,5]
	
	listbox AnimList height:10  offset:[0,0]

	
	button btnRename "Rename" width:80 tooltip:"Rename selected animation (saves immediately)" across:2
	button btnDelete "Delete" width:80 tooltip:"Remove selected animation from list (saves immediately)"
	button btnMoveUp "Move UP" width:80 tooltip:"Move animation up in list order (saves immediately)" across:2
	button btnMoveDown "Move DOWN" width:80 tooltip:"Move animation down in list order (saves immediately)"
	button btnSaveNew "Add New Animation" width:120 tooltip:"Add current timeline as new animation to loaded IFP (saves immediately)" align:#center
	button ReplaceAnim "Replace Animation" width:120 align:#center tooltip:"Replace selected animation with current timeline (saves immediately)"
	button saveAnim "Export New IFP" width:120 align:#center tooltip:"Export current timeline as brand new IFP file"
		
	radioButtons formatType "Format:" labels:#("ANP3 (SA)", "ANPK (III/VC)") columns:2 default:1 align:#center offset:[0,0] tooltip:"ANP3 for San Andreas -- ANPK for III/VC and SA cutscenes"
	checkbox useBoneID "Sibling" align:#right checked:false enabled:false offset:[-15,-5]
	
	label lblSpacer2 "Manual Loading (original method)" align:#left
	
	button RecOrg "M" width:17 align:#left tooltip:"Memorize current pose as original (for Reset button)" across:3
	button apyAnim "Apply Animation" width:120 align:#center tooltip:"Apply selected animation to character bones (matches by name)"
	button ResetPose "R" width:17 align:#right tooltip:"Reset character to memorized original pose"
	checkbox skipPos "Skip Position keys" align:#center offset:[0,-4] tooltip:"Ignore position keyframes (rotation only, for in-place animations)"
	
	label lblSpacer3 "" height:1
	
	spinner astart "Start" fieldwidth:30 align:#left type:#integer range:[0,10000,0] across:2 tooltip:"Starting frame for batch export"
	spinner aend "End" fieldwidth:30 type:#integer range:[0,10000,0] tooltip:"Ending frame for batch export"
	button batAnim "Batch Animation" width:122 align:#center tooltip:"Export multiple animations at once (range-based)"
	
	-- ===========================
	-- EVENT HANDLERS - ANIMATION
	-- ===========================
	
	-- Load IFP file and display animation list
	on loadifp pressed do (
		local bkfile = ifpname
		ifpname = getOpenFileName caption:"Open GTA Animation File" types:"IFP animation (*.ifp)|*.ifp|All files (*.*)|*.*|"
		if (ifpname != undefined) then (
			local f = fopen ifpname "rb"
			HInfo = ReadifpHeader f
			if HInfo == undefined then (
				fclose f
				messagebox "Header Data not correct!" Title:"IFP File Error"
			) 
			else (
				lbl1.text = "Anim. File: " + (filenameFromPath ifpname)
				lbl2.text = "Total Animation: " + (HInfo[1] as string)
				lbl3.text = "Internal Name: " + HInfo[2]
				txtInternalName.text = HInfo[2]
		
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

	on btnRepairIFP pressed do (
		local repairPath = getOpenFileName caption:"Select IFP File to Validate/Repair" types:"IFP animation (*.ifp)|*.ifp|All files (*.*)|*.*|"
		if repairPath == undefined then return()
		local info = GTAAnim_ValidateIFP repairPath
		if info[1] == "error" then (
			messagebox ("Error: " + info[2]) title:"IFP Validate"
			return()
		)
		if info[1] == "corrupt" then (
			messagebox ("File is corrupt:\n" + info[2] + "\n\nNo animations could be read - cannot salvage.") title:"IFP Validate"
			return()
		)

		local storedLen = info[2]
		local correctLen = info[3]
		local fileSize = info[4]
		local animCount = info[5]
		local intName = info[6]
		local validBytes = correctLen + 8

		local msg = "File: " + (filenameFromPath repairPath)
		msg += "\nInternal Name: " + intName
		msg += "\nAnimations: " + (animCount as string)

		if info[1] == "truncated" then (
			local goodCount = info[7]
			msg += "\n\nFile is TRUNCATED — data cuts off mid-animation."
			msg += "\nSalvageable animations: " + (goodCount as string) + " of " + (animCount as string)
			msg += "\nDamaged (will be removed): " + ((animCount - goodCount) as string)
			msg += "\n\nRepair will trim to " + (goodCount as string) + " good animations."
			if queryBox (msg + "\n\nSalvage this file?") title:"IFP Salvage" then (
				local result = GTAAnim_RepairIFP repairPath
				if result[1] == "repaired" then
					messagebox ("Salvage successful!\n\n" + result[2]) title:"IFP Salvage"
				else
					messagebox ("Salvage failed: " + result[2]) title:"IFP Salvage"
			)
		) else (
			local needsFix = (storedLen != correctLen) or (fileSize != validBytes)
			msg += "\n\nStored fileLength: " + (storedLen as string)
			msg += "\nCalculated fileLength: " + (correctLen as string)
			msg += "\nActual file size: " + (fileSize as string)
			msg += "\nExpected file size: " + (validBytes as string)

			if not needsFix then (
				msg += "\n\nFile is valid - no repair needed."
				messagebox msg title:"IFP Validate"
			) else (
				local problems = ""
				if storedLen != correctLen then
					problems += "\n- fileLength field is off by " + ((storedLen - correctLen) as string) + " bytes"
				if fileSize > validBytes then
					problems += "\n- " + ((fileSize - validBytes) as string) + " bytes of trailing garbage"
				msg += "\n\nProblems found:" + problems

				if queryBox (msg + "\n\nRepair this file?") title:"IFP Repair" then (
					local result = GTAAnim_RepairIFP repairPath
					if result[1] == "repaired" then
						messagebox ("Repair successful!\n\n" + result[2]) title:"IFP Repair"
					else
						messagebox ("Repair failed: " + result[2]) title:"IFP Repair"
				)
			)
		)
	)--end on btnRepairIFP

	on btnSetInternalName pressed do (
		if (ifpname == undefined) or (HInfo == undefined) then (
			messagebox "Please load an IFP file first!" title:"No IFP Loaded"
		) else (
			local renameResult = GTAAnim_RenameLoadedIFPHeader ifpname txtInternalName.text
			if renameResult[1] == true then (
				HInfo = renameResult[3]
				lbl3.text = "Internal Name: " + HInfo[2]
				txtInternalName.text = HInfo[2]
				messagebox renameResult[2] title:"Internal Name"
			) else (
				txtInternalName.text = HInfo[2]
				messagebox ("Failed to update internal name:\n" + renameResult[2]) title:"Internal Name"
			)
		)
	)
	
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
		local OrginAry = #()
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
		if (AnimList.selection > 0) then (
			local applyNodes = GTAAnim_GetApplyNodes()
			if applyNodes.count == 0 then (
				messagebox "No active GTA rig found. Select any node from the target GTA rig and retry." title:"Apply Animation"
				return()
			)

			local rult = resetPost applyNodes slidertime
			if rult == false then RecOrg.text = "M"
			local f = fopen ifpname "rb"
			try (
				fseek f AnimInfo[2][AnimList.selection] #seek_set
				ApplyAnim f applyNodes skipPos.checked slidertime AnimInfo[3]
				GTAAnim_EnforceRootOnlyPositionKeys applyNodes
			) catch (
				format "*** ApplyAnim error: %\n" (getCurrentException())
			)
			try (fclose f) catch ()
			gc()
		)
	)--end on apyAnim
	
	-- Double-click animation list to apply
	on AnimList doubleclicked idx do (
		if AnimList.selection == 0 then return()

		local applyNodes = GTAAnim_GetApplyNodes()
		if applyNodes.count == 0 then (
			messagebox "No active GTA rig found. Select any node from the target GTA rig and retry." title:"Apply Animation"
			return()
		)

		local rult = resetPost applyNodes slidertime
		if rult == false then RecOrg.text = "M"
		if (getUserProp applyNodes[1] "OrgPos") == undefined then (
			GTAAnim_StoreOriginalPose applyNodes
			RecOrg.text = "**"
		)
		GTAAnim_ClearSelectionKeys applyNodes
		sliderTime = 0
		local f = fopen ifpname "rb"
		try (
			fseek f AnimInfo[2][AnimList.selection] #seek_set
			format "\nAnime: % at [%]\n" AnimList.selected (ftell f)
			ApplyAnim f applyNodes skipPos.checked slidertime AnimInfo[3]
		) catch (
			format "*** ApplyAnim error: %\n" (getCurrentException())
		)
		try (fclose f) catch ()
		-- Policy: only root translation is allowed; all non-root position keys are removed.
		GTAAnim_EnforceRootOnlyPositionKeys applyNodes
		for i = 1 to applyNodes.count do deletekeys applyNodes[i].scale.controller
		gc()
	)--end on AnimList doubleclicked
	
	-- Batch apply multiple animations
	on batAnim pressed do (
		if (AnimList.selection > 0) then (
			local applyNodes = GTAAnim_GetApplyNodes()
			if applyNodes.count == 0 then (
				messagebox "No active GTA rig found. Select any node from the target GTA rig and retry." title:"Batch Animation"
				return()
			)

			local rult = undefined
			sliderTime = 0
			if (getUserProp applyNodes[1] "OrgPos") == undefined then (
				for i = 1 to applyNodes.count do (
					setUserProp applyNodes[i] "OrgPos" applyNodes[i].pos
					setUserProp applyNodes[i] "OrgRot" [applyNodes[i].rotation.x,applyNodes[i].rotation.y,applyNodes[i].rotation.z]
					setUserProp applyNodes[i] "OrgRotW" applyNodes[i].rotation.w
					setUserProp applyNodes[i] "Orgscl" applyNodes[i].scale
				)
			)
			
			local f = fopen ifpname "rb"
			try (
				for tt = astart.value to aend.value do (
					rult = resetPost applyNodes slidertime
					if rult == false then RecOrg.text = "M"
				
					fseek f AnimInfo[2][tt] #seek_set
				
					ApplyAnim f applyNodes skipPos.checked slidertime AnimInfo[3]
					GTAAnim_EnforceRootOnlyPositionKeys applyNodes

					animationRange = interval 0 (animationRange.end + 1)
					slidertime = animationRange.end
			
					gc()
				)--end for tt
			) catch (
				format "*** Batch ApplyAnim error: %\n" (getCurrentException())
			)
			try (fclose f) catch ()
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
						local tempName = (getFilenamePath ifpname) + "ttemp.bin"
						local ff = fopen tempName "wb"
						local f = fopen ifpname "rb"
						
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
							local dataLength = 0
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
							local animData = #()
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
			local animName = AnimList.selected
			local selIndex = AnimList.selection
			local result = queryBox ("Delete animation: " + animName + "?\n\nThis cannot be undone.") title:"Confirm Delete"
			if result then (
				try (
					-- Rebuild IFP without deleted animation
					local tempName = (getFilenamePath ifpname) + "ttemp.bin"
					local ff = fopen tempName "wb"
					local f = fopen ifpname "rb"
					
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
							local dataLength = 0
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
			local idx = AnimList.selection
			local animName = AnimList.selected
			try (
				-- Rebuild IFP with animations reordered
				local tempName = (getFilenamePath ifpname) + "ttemp.bin"
				local ff = fopen tempName "wb"
				local f = fopen ifpname "rb"
				
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
					local dataLength = 0
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
			local idx = AnimList.selection
			local animName = AnimList.selected
			try (
				-- Rebuild IFP with animations reordered
				local tempName = (getFilenamePath ifpname) + "ttemp.bin"
				local ff = fopen tempName "wb"
				local f = fopen ifpname "rb"
				
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
					local dataLength = 0
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
			local exportNodes = GTAAnim_GetActiveRigBoneNodes()
			if exportNodes.count == 0 then (
				messagebox "No active GTA rig found. Select any node from the target GTA rig and retry." title:"No Active Rig"
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
								
								local f = fopen ifpname "rb+"
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
		sliderTime = 0
		local exportNodes = GTAAnim_GetActiveRigBoneNodes()
		if (AnimList.selection != 0)AND(exportNodes.count > 0) then (
			local OK2Append = false
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
		) else if AnimList.selection == 0 then (
			messagebox "Please select an animation to replace." title:"No Selection"
		) else (
			messagebox "No active GTA rig found. Select any node from the target GTA rig and retry." title:"No Active Rig"
		)--end if AnimList.selection
	)--end on ReplaceAnim 
	
	-- Export selection as new IFP file
	on saveAnim pressed do (
		local exportNodes = GTAAnim_GetActiveRigBoneNodes()
		if (exportNodes.count > 0) then (
			local Sname = getSaveFileName caption:"Save GTA Animation file" types:"IFP animation (*.ifp)|*.ifp"
			if Sname != undefined then (
				if exportNodes.count == 0 then (
					messagebox "No active GTA rig found. Select any node from the target GTA rig and retry." title:"No Active Rig"
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
							local f = fopen Sname "wb"

							if formatType.state == 1 then (   					--ANP3 (SA)
								local exportAnimName = GTAAnim_GetNameFromPath Sname maxLen:23
								GTAAnim_WriteSingleIFPHeader f 0x33504E41 Sname
								local thisLength = ExpsaIFP f exportNodes exportAnimName
								
								if thisLength == undefined then (
									fclose f
									deleteFile Sname
									messagebox "Export failed - no animation data!\n\nCheck that bones have rotation keyframes." title:"Export Failed"
								) else (
									local size = ftell f
									fseek f 4 #seek_set
									writeLong f (size - 8)
									fclose f
								)
							) else (   					   									--ANPK (III/VC)
								GTAAnim_WriteSingleIFPHeader f 0x4B504E41 Sname
								local anpkAnimName = if AnimList.selection != 0 then AnimList.selected else (GTAAnim_GetNameFromPath Sname)
								local thisLength = expAnim f exportNodes useBoneID.checked anpkAnimName
								
								if thisLength == undefined then (
									fclose f
									deleteFile Sname
									messagebox "Export failed - no animation data!\n\nCheck that bones have rotation keyframes." title:"Export Failed"
								) else (
									local size = ftell f
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
							local Sname2 = (substring Sname 1 (Sname.count - 4)) + ".txt"
							local ss = "" as stringstream

							clearlistener()
							format "<!-- path=\"%\" -->\n" Sname2
							format"//\n//\n//This is Header Section\n"  

							if formatType.state == 1 then (   					--ANP3 (SA)
								local thisLength = gExpsaIFP ss exportNodes (GTAAnim_GetNameFromPath Sname2 maxLen:23)
								format "c 4\nANP3\ni 1\n%\n" (thisLength + 28)
								format "c 24\n%\n//\n//\n" (GTAAnim_GetNameFromPath Sname2 maxLen:23)
								format "i 1\n1\n"
							) else (																		--ANPK (III/VC)
								local thisLength = gm_expAnim ss exportNodes useBoneID.checked AnimList.selected
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
		)--end if exportNodes.count
	)--end on saveAnim
)--end rollout animateRoll

/*
=============================================================================
   SECTION 2: ABOUT
=============================================================================
*/

rollout aboutRoll "About" (
	label l1 "GTA IFP Animation IO V2.1"
	label l1a "March, 2026"
	label l2 "Code based on Kam's GTA_IFP_IO v1.1"
	label l2a "and 2018 Goldfish Edition."
	label l2b ""
	label l3 "Enhanced by E2001"
)

/*
=============================================================================
   FLOATER CREATION
=============================================================================
*/

if Kam_GTAsaIFP != undefined then ( closeRolloutFloater Kam_GTAsaIFP; gc() )
Kam_GTAsaIFP = newRolloutFloater "IFP IO" 220 628 10 30
addRollout animateRoll Kam_GTAsaIFP
addRollout aboutRoll Kam_GTAsaIFP rolledup:true
