-- GTA Animation Rig Tool
-- Simple animation workflow: Create rig → Animate → Export
-- Handles all technical cleanup automatically

try (fileIn (scriptspath+"\\GTA_Tools_2026\\gtaIFPio_Fn.ms") quiet:true) catch (format "Error loading gtaIFPio_Fn.ms: %\n" (getCurrentException()))
try (fileIn (scriptspath+"\\GTA_Tools_2026\\CharDFFimp.ms") quiet:true) catch (format "Error loading CharDFFimp.ms: %\n" (getCurrentException()))
try (fileIn (scriptspath+"\\GTA_Tools_2026\\CharDFFexp.ms") quiet:true) catch (format "Error loading CharDFFexp.ms: %\n" (getCurrentException()))

global GTA_AnimRig_IKHandles = #()  -- Track IK solvers created by this tool

-- Bone structure data: 24-bone gameplay skeleton
fn GetGameplayBoneData = (
	#(
		#("Pelvis", 0, undefined, 2),
		#("Spine1", 1, "Pelvis", 2),
		#("L Thigh", 2, "Pelvis", 2),
		#("R Thigh", 3, "Pelvis", 0),
		#("Spine", 4, "Spine1", 2),
		#("L Calf", 5, "L Thigh", 2),
		#("R Calf", 6, "R Thigh", 2),
		#("Neck", 7, "Spine", 2),
		#("L Foot", 8, "L Calf", 2),
		#("R Foot", 9, "R Calf", 2),
		#("Head", 10, "Neck", 0),
		#("L Toe0", 11, "L Foot", 0),
		#("R Toe0", 12, "R Foot", 0),
		#("L Clavicle", 13, "Spine", 2),
		#("R Clavicle", 14, "Spine", 2),
		#("L UpperArm", 15, "L Clavicle", 2),
		#("R UpperArm", 16, "R Clavicle", 2),
		#("L Forearm", 17, "L UpperArm", 2),
		#("R Forearm", 18, "R UpperArm", 2),
		#("L Hand", 19, "L Forearm", 2),
		#("R Hand", 20, "R Forearm", 2),
		#("L Finger", 21, "L Hand", 0),
		#("R Finger", 22, "R Hand", 0),
		#("Belly", 23, "Spine1", 0)
	)
)

-- Bone structure data: 64-bone cutscene skeleton (extended with facial bones)
fn GetCutsceneBoneData = (
	local bones = GetGameplayBoneData()
	-- Add facial and extra bones (simplified - expand as needed)
	append bones #("Jaw", 24, "Head", 0)
	append bones #("L Brow", 25, "Head", 0)
	append bones #("R Brow", 26, "Head", 0)
	append bones #("L breast", 27, "Spine1", 0)
	append bones #("R breast", 28, "Spine1", 0)
	bones
)

-- Create bone hierarchy with proper GTA properties
fn CreateGTARig boneData rigName = (
	local boneObjs = #()
	
	-- Create all bones first
	for boneInfo in boneData do (
		local boneName = boneInfo[1]
		local boneID = boneInfo[2]
		local boneType = boneInfo[4]
		
		local bonePos = [0, 0, boneID * 5]  -- Simple vertical spacing for now
		local boneObj = point name:boneName pos:bonePos size:2 axistripod:on centermarker:off cross:off box:on
		
		-- Set GTA bone properties
		setUserProp boneObj "BoneID" boneID
		setUserProp boneObj "BoneIndex" boneID
		setUserProp boneObj "BoneType" boneType
		setUserProp boneObj "FrameName" boneName
		
		append boneObjs boneObj
	)
	
	-- Link bones to parents
	for i = 1 to boneData.count do (
		local parentName = boneData[i][3]
		if parentName != undefined then (
			local parentObj = getNodeByName parentName
			if parentObj != undefined then (
				boneObjs[i].parent = parentObj
			)
		)
	)
	
	-- Adjust bone positions based on hierarchy (basic layout)
	local pelvis = boneObjs[1]
	pelvis.pos = [0, 0, 100]
	
	-- Return root bone
	return pelvis
)

-- Create IK controls for easy animation
fn CreateIKControls rootBone = (
	GTA_AnimRig_IKHandles = #()
	
	-- Find limb bones
	local lThigh = getNodeByName "L Thigh"
	local lCalf = getNodeByName "L Calf"
	local lFoot = getNodeByName "L Foot"
	
	local rThigh = getNodeByName "R Thigh"
	local rCalf = getNodeByName "R Calf"
	local rFoot = getNodeByName "R Foot"
	
	local lUpperArm = getNodeByName "L UpperArm"
	local lForearm = getNodeByName "L ForeArm"
	local lHand = getNodeByName "L Hand"
	
	local rUpperArm = getNodeByName "R UpperArm"
	local rForearm = getNodeByName "R ForeArm"
	local rHand = getNodeByName "R Hand"
	
	-- Create IK chain for left leg
	if lThigh != undefined and lCalf != undefined and lFoot != undefined then (
		local lLegIK = IKSys.ikChain lThigh lFoot "IKHISolver"
		if lLegIK != undefined then (
			append GTA_AnimRig_IKHandles lLegIK
			setUserProp lLegIK "GTA_AnimRig_IK" true
		)
	)
	
	-- Create IK chain for right leg
	if rThigh != undefined and rCalf != undefined and rFoot != undefined then (
		local rLegIK = IKSys.ikChain rThigh rFoot "IKHISolver"
		if rLegIK != undefined then (
			append GTA_AnimRig_IKHandles rLegIK
			setUserProp rLegIK "GTA_AnimRig_IK" true
		)
	)
	
	-- Create IK chain for left arm
	if lUpperArm != undefined and lForearm != undefined and lHand != undefined then (
		local lArmIK = IKSys.ikChain lUpperArm lHand "IKHISolver"
		if lArmIK != undefined then (
			append GTA_AnimRig_IKHandles lArmIK
			setUserProp lArmIK "GTA_AnimRig_IK" true
		)
	)
	
	-- Create IK chain for right arm
	if rUpperArm != undefined and rForearm != undefined and rHand != undefined then (
		local rArmIK = IKSys.ikChain rUpperArm rHand "IKHISolver"
		if rArmIK != undefined then (
			append GTA_AnimRig_IKHandles rArmIK
			setUserProp rArmIK "GTA_AnimRig_IK" true
		)
	)
	
	format "Created % IK controls\n" GTA_AnimRig_IKHandles.count
)

-- Bake IK animation to keyframes
fn BakeIKAnimation startFrame endFrame interval:1.0 = (
	if GTA_AnimRig_IKHandles.count == 0 then (
		format "No IK controls to bake\n"
		return false
	)
	
	-- Collect bones affected by IK
	local affectedBones = #()
	for ikChain in GTA_AnimRig_IKHandles do (
		if isValidNode ikChain then (
			-- Get start and end bones from IK chain
			local startBone = ikChain.startJoint
			local endBone = ikChain.endJoint
			
			if startBone != undefined and endBone != undefined then (
				-- Collect all bones in chain
				local bone = endBone
				while bone != undefined and bone != startBone.parent do (
					appendIfUnique affectedBones bone
					bone = bone.parent
				)
			)
		)
	)
	
	-- Bake animation
	if affectedBones.count > 0 then (
		with animate on (
			for frame = startFrame to endFrame by interval do (
				sliderTime = frame
				for bone in affectedBones do (
					-- Force evaluation and add keys
					at time frame (
						bone.rotation.controller.value = bone.rotation.controller.value
						bone.position.controller.value = bone.position.controller.value
					)
				)
			)
		)
		
		-- Delete IK chains
		for ikChain in GTA_AnimRig_IKHandles do (
			if isValidNode ikChain then (
				-- Remove IK chain but keep bones
				delete ikChain
			)
		)
		GTA_AnimRig_IKHandles = #()
		
		format "Baked IK animation: % bones\n" affectedBones.count
		return true
	) else (
		format "No bones found for IK baking\n"
		return false
	)
)

-- Helper: Collect all bones in hierarchy
fn CollectAllBones rootBone = (
	local allBones = #(rootBone)
	local stack = #(rootBone)
	
	while stack.count > 0 do (
		local node = stack[stack.count]
		deleteItem stack stack.count
		
		for child in node.children do (
			append allBones child
			append stack child
		)
	)
	
	return allBones
)

-- Clean animation keys before export
fn CleanAnimationKeys rootBone = (
	local allBones = CollectAllBones rootBone
	
	format "Cleaning keys for % bones...\n" allBones.count
	
	-- Delete position keys for all bones except root
	for i = 2 to allBones.count do (
		local bone = allBones[i]
		if bone.position.controller != undefined then (
			bone.position.controller = Position_XYZ()
		)
	)
	
	-- Delete scale keys for all bones
	for bone in allBones do (
		if bone.scale.controller != undefined then (
			bone.scale.controller = ScaleXYZ()
		)
	)
	
	format "Animation keys cleaned\n"
)

-- Export animation to IFP
fn ExportRigAnimation rootBone animName fname isAppend = (
	-- Bake IK if present
	if GTA_AnimRig_IKHandles.count > 0 then (
		local result = queryBox "Bake IK animation before export?" title:"IK Detected"
		if result then (
			BakeIKAnimation animationRange.start animationRange.end interval:1.0
		)
	)
	
	-- Clean keys
	CleanAnimationKeys rootBone
	
	-- Export using existing IFP export function
	if ExportIFPFromRoot != undefined then (
		ExportIFPFromRoot rootBone fname isAppend
		format "Exported: %\n" fname
		return true
	) else (
		messagebox "IFP export function not loaded" title:"Export Error"
		return false
	)
)


rollout GTA_AnimRig_UI "GTA Animation Rig" width:280 height:500 (
	
	local currentRig = undefined
	local rigType = "none"
	
	group "Rig Setup" (
		label lblInfo "Load a GTA character model:" align:#left
		button btnLoadMale "Load Male Character" width:250 height:30 tooltip:"Import male gameplay character with proper skeleton"
		button btnLoadFemale "Load Female Character" width:250 height:30 tooltip:"Import female gameplay character with proper skeleton"
		button btnLoadCustom "Load Custom DFF..." width:250 height:30 tooltip:"Import any character DFF file"
		label lblRigStatus "No rig loaded" align:#center
	)
	
	group "Animation Tools" (
		checkbox chkUseIK "Use IK Controls (arms/legs)" checked:false enabled:false tooltip:"Create IK solvers for easier animation"
		button btnImportIFP "Import IFP to Rig" width:250 height:30 enabled:false tooltip:"Load GTA IFP animation onto rig"
		button btnRetarget "Retarget Animation (BVH/FBX/Biped)" width:250 height:30 enabled:false tooltip:"Load animation from other sources with bone mapping"
		spinner spnStartFrame "Start:" type:#integer range:[0,10000,0] fieldwidth:60 across:2
		spinner spnEndFrame "End:" type:#integer range:[0,10000,30] fieldwidth:60
		button btnSetRange "Set Animation Range" width:250 enabled:false
	)
	
	group "Export" (
		label lbl1 "Animation Name:" align:#left
		edittext txtAnimName "" width:250 text:"anim_01" enabled:false
		button btnExportIFP "Export IFP (New File)" width:250 height:35 enabled:false
		button btnExportAppend "Export IFP (Append to File)" width:250 height:35 enabled:false
	)
	
	group "Utilities" (
		button btnSelectAll "Select All Bones" width:120 height:25 across:2 enabled:false
		button btnSelectRoot "Select Root Only" width:120 height:25 enabled:false
		button btnCleanKeys "Clean Keys Manually" width:250 height:25 enabled:false tooltip:"Remove position/scale keys (automatic on export)"
	)
	
	-- Load male character
	on btnLoadMale pressed do (
		if currentRig != undefined then (
			local result = queryBox "Delete current rig and load new character?" title:"Rig Exists"
			if not result then return()
		)
		
		-- Look for male character DFF in common locations
		local malePathOptions = #(
			scriptspath+"\\GTA_Tools_2026\\rigs\\male.dff",
			scriptspath+"\\..\\models\\male.dff",
			"C:\\Program Files\\Rockstar Games\\GTA San Andreas\\models\\gta3.img\\male.dff"
		)
		
		local foundPath = undefined
		for p in malePathOptions do (
			if doesFileExist p then (
				foundPath = p
				exit
			)
		)
		
		if foundPath == undefined then (
			foundPath = getopenfilename caption:"Select Male Character DFF" types:"DFF File (*.dff)|*.dff|"
		)
		
		if foundPath != undefined then (
			-- Insert DFF folder at beginning of texture search (highest priority)
			local texPath = getFilenamePath foundPath
			mapPaths.add texPath 1  -- Insert at index 1 (beginning)
			format "Texture path added with priority: %\n" texPath
			
			-- Import using Character IO import function
			if DFFin != undefined then (
				local f = fopen foundPath "rb"
				if f != undefined then (
					DFFin f 1.0 1 ".png" 0.1 true false (getFilenameFile foundPath)
					fclose f
					
					-- Find root bone (Pelvis)
					currentRig = getNodeByName "Pelvis"
					if currentRig == undefined then currentRig = $selection[1]
					
					rigType = "male"
					lblRigStatus.text = "Male Character Loaded"
					chkUseIK.enabled = true
					btnImportIFP.enabled = true
					btnRetarget.enabled = true
					btnSetRange.enabled = true
					txtAnimName.enabled = true
					btnExportIFP.enabled = true
					btnExportAppend.enabled = true
					btnSelectAll.enabled = true
					btnSelectRoot.enabled = true
					btnCleanKeys.enabled = true
					
					select currentRig
					format "Loaded male character: %\n" foundPath
				) else (
					messagebox "Failed to open DFF file" title:"Import Error"
				)
			) else (
				messagebox "DFF import function not loaded" title:"Import Error"
			)
		)
	)
	
	-- Load female character
	on btnLoadFemale pressed do (
		if currentRig != undefined then (
			local result = queryBox "Delete current rig and load new character?" title:"Rig Exists"
			if not result then return()
		)
		
		-- Look for female character DFF in common locations
		local femalePathOptions = #(
			scriptspath+"\\GTA_Tools_2026\\rigs\\female.dff",
			scriptspath+"\\..\\models\\female.dff",
			"C:\\Program Files\\Rockstar Games\\GTA San Andreas\\models\\gta3.img\\female.dff"
		)
		
		local foundPath = undefined
		for p in femalePathOptions do (
			if doesFileExist p then (
				foundPath = p
				exit
			)
		)
		
		if foundPath == undefined then (
			foundPath = getopenfilename caption:"Select Female Character DFF" types:"DFF File (*.dff)|*.dff|"
		)
		
		if foundPath != undefined then (
			-- Insert DFF folder at beginning of texture search (highest priority)
			local texPath = getFilenamePath foundPath
			mapPaths.add texPath 1  -- Insert at index 1 (beginning)
			format "Texture path added with priority: %\n" texPath
			
			-- Import using Character IO import function
			if DFFin != undefined then (
				local f = fopen foundPath "rb"
				if f != undefined then (
					DFFin f 1.0 1 ".png" 0.1 true false (getFilenameFile foundPath)
					fclose f
					
					-- Find root bone (Pelvis)
					currentRig = getNodeByName "Pelvis"
					if currentRig == undefined then currentRig = $selection[1]
					
					rigType = "female"
					lblRigStatus.text = "Female Character Loaded"
					chkUseIK.enabled = true
					btnImportIFP.enabled = true
					btnRetarget.enabled = true
					btnSetRange.enabled = true
					txtAnimName.enabled = true
					btnExportIFP.enabled = true
					btnExportAppend.enabled = true
					btnSelectAll.enabled = true
					btnSelectRoot.enabled = true
					btnCleanKeys.enabled = true
					
					select currentRig
					format "Loaded female character: %\n" foundPath
				) else (
					messagebox "Failed to open DFF file" title:"Import Error"
				)
			) else (
				messagebox "DFF import function not loaded" title:"Import Error"
			)
		)
	)
	
	-- Load custom DFF
	on btnLoadCustom pressed do (
		if currentRig != undefined then (
			local result = queryBox "Delete current rig and load new character?" title:"Rig Exists"
			if not result then return()
		)
		
		local foundPath = getopenfilename caption:"Select Character DFF" types:"DFF File (*.dff)|*.dff|"
		
		if foundPath != undefined then (
			-- Insert DFF folder at beginning of texture search (highest priority)
			local texPath = getFilenamePath foundPath
			mapPaths.add texPath 1  -- Insert at index 1 (beginning)
			format "Texture path added with priority: %\n" texPath
			
			-- Import using Character IO import function
			if DFFin != undefined then (
				local f = fopen foundPath "rb"
				if f != undefined then (
					DFFin f 1.0 1 ".png" 0.1 true false (getFilenameFile foundPath)
					fclose f
					
					-- Find root bone (Pelvis or first selected)
					currentRig = getNodeByName "Pelvis"
					if currentRig == undefined then currentRig = $selection[1]
					
					rigType = "custom"
					lblRigStatus.text = "Custom Character Loaded"
					chkUseIK.enabled = true
					btnImportIFP.enabled = true
					btnRetarget.enabled = true
					btnSetRange.enabled = true
					txtAnimName.enabled = true
					btnExportIFP.enabled = true
					btnExportAppend.enabled = true
					btnSelectAll.enabled = true
					btnSelectRoot.enabled = true
					btnCleanKeys.enabled = true
					
					select currentRig
					format "Loaded custom character: %\n" foundPath
				) else (
					messagebox "Failed to open DFF file" title:"Import Error"
				)
			) else (
				messagebox "DFF import function not loaded" title:"Import Error"
			)
		)
	)
	
	-- Toggle IK controls
	on chkUseIK changed state do (
		if currentRig == undefined then return()
		
		if state then (
			CreateIKControls currentRig
			messagebox "IK controls created for arms and legs.\nAnimate the IK solvers, then export (will auto-bake)." title:"IK Created"
		) else (
			-- Delete IK controls
			for ikHandle in GTA_AnimRig_IKHandles do (
				if isValidNode ikHandle then delete ikHandle
			)
			GTA_AnimRig_IKHandles = #()
			format "Deleted IK controls\n"
		)
	)
	
	-- Import IFP
	on btnImportIFP pressed do (
		if currentRig == undefined then (
			messagebox "Create a rig first" title:"No Rig"
			return()
		)
		
		local fname = getopenfilename caption:"Import IFP Animation" types:"IFP File (*.ifp)|*.ifp|"
		if fname != undefined then (
			-- Use existing IFP import function
			if ApplyAnim != undefined then (
				ApplyAnim fname currentRig true  -- noPOSkey = true (no position keys for children)
				format "Imported: %\n" fname
			) else (
				messagebox "IFP import function not loaded" title:"Import Error"
			)
		)
	)
	
	-- Retarget animation from other sources
	on btnRetarget pressed do (
		if currentRig == undefined then (
			messagebox "Create a rig first" title:"No Rig"
			return()
		)
		
		messagebox "To retarget animation:\n\n1. Load your source animation (BVH/FBX/Biped) into the scene\n2. Use: GTA Tools → Other Tools → GTA Animation XML IO\n3. Export animation from source skeleton\n4. Map bone names to GTA rig bones\n5. Import onto GTA rig\n\nOr manually animate the rig and export to IFP." title:"Animation Retargeting" beep:false
		
		-- Try to launch the retargeting tool if available
		try (
			fileIn (scriptspath+"\\..\\originals\\Other Plugins\\GTA_Animation_XML_IO\\GTA_Anim_XML_IO.ms")
		) catch (
			format "GTA_Animation_XML_IO not found - use manual workflow\n"
		)
	)
	
	-- Set animation range
	on btnSetRange pressed do (
		animationRange = interval spnStartFrame.value spnEndFrame.value
		format "Animation range: % to %\n" spnStartFrame.value spnEndFrame.value
	)
	
	-- Export IFP (new file)
	on btnExportIFP pressed do (
		if currentRig == undefined then (
			messagebox "Create a rig first" title:"No Rig"
			return()
		)
		
		local fname = getsavefilename caption:"Export IFP Animation" types:"IFP File (*.ifp)|*.ifp|"
		if fname != undefined then (
			ExportRigAnimation currentRig txtAnimName.text fname false
		)
	)
	
	-- Export IFP (append)
	on btnExportAppend pressed do (
		if currentRig == undefined then (
			messagebox "Create a rig first" title:"No Rig"
			return()
		)
		
		local fname = getopenfilename caption:"Append to IFP File" types:"IFP File (*.ifp)|*.ifp|"
		if fname != undefined then (
			ExportRigAnimation currentRig txtAnimName.text fname true
		)
	)
	
	-- Select all bones
	on btnSelectAll pressed do (
		if currentRig == undefined then return()
		
		local allBones = CollectAllBones currentRig
		select allBones
		format "Selected % bones\n" allBones.count
	)
	
	-- Select root only
	on btnSelectRoot pressed do (
		if currentRig == undefined then return()
		select currentRig
	)
	
	-- Clean keys manually
	on btnCleanKeys pressed do (
		if currentRig == undefined then return()
		CleanAnimationKeys currentRig
		messagebox "Position keys (except root) and scale keys removed" title:"Keys Cleaned"
	)
	
	-- Initialize
	on GTA_AnimRig_UI open do (
		spnStartFrame.value = animationRange.start
		spnEndFrame.value = animationRange.end
		format "\n----- GTA Animation Rig -----\n"
		format "Load a character model, animate, and export\n"
		format "Place male.dff/female.dff in scripts/GTA_Tools_2026/rigs/ for quick access\n"
		format "IK is optional - bakes automatically\n"
		format "Keys are cleaned automatically on export\n\n"
	)
)

-- Launch UI
global GTA_AnimRig_Float
if GTA_AnimRig_Float != undefined then (
	closeRolloutFloater GTA_AnimRig_Float
	gc()
)
GTA_AnimRig_Float = newRolloutFloater "GTA Animation Rig" 300 600
addRollout GTA_AnimRig_UI GTA_AnimRig_Float
