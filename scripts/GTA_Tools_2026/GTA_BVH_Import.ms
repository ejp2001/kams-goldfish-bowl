-- BVH Importer for GTA San Andreas
-- Loads BioVision Hierarchy (.bvh) motion capture onto Max timeline
-- Then use GTA_CHAR_IO -> IFP Export to save as IFP
--
-- Recovered from VS Code history (March 2026). Bugs fixed:
--   1. channelStart field was missing from BVHBone struct (properties cannot be
--      added to MaxScript struct instances dynamically -- was silently undefined,
--      causing all channel reads to be skipped entirely).
--   2. quat angle [axis] does NOT create an angle-axis quaternion in MaxScript.
--      Fixed: (angleAxis angle axis) as quat.
--   3. No Y-up to Z-up axis remapping (BVH=Y-up, Max=Z-up). Skeleton was built
--      horizontally on the ground.
--   4. Non-root bone rotations were not applied in coordsys parent.
--
-- NOTE: This importer creates a BVH skeleton with BVH joint names (e.g. Hips,
-- LeftUpLeg). To export as GTA SA IFP you must rename bones to match the GTA SA
-- hierarchy and add BoneID user properties before using GTA_CHAR_IO.
-- A separate retargeting/mapping step is still needed for bone name remapping.

-- BVH bone structure
struct BVHBone (
	name,
	parent,
	offset    = [0,0,0],
	channels  = 0,
	channelOrder = #(),
	channelStart = 1,   -- FIX: must be declared here; cannot be set dynamically
	children  = #(),
	dummy     = undefined,
	bindRot   = (quat 0 0 0 1),
	bindPos   = [0,0,0],
	bindWorldRot = (quat 0 0 0 1)
)

global GTAAnim_LastBVHRoot = undefined

fn GTAAnim_DeleteHierarchy rootObj = (
	if rootObj == undefined then return false
	local nodes = #()
	local queue = #(rootObj)
	while queue.count > 0 do (
		local n = queue[1]
		deleteItem queue 1
		append nodes n
		for c in n.children do append queue c
	)
	for i = nodes.count to 1 by -1 do (
		try (if isValidNode nodes[i] then delete nodes[i]) catch ()
	)
	true
)

-- ---------------------------------------------------------------------------
-- Parse BVH file into BVHBone structs + raw motion data
-- ---------------------------------------------------------------------------
fn ParseBVH bvhPath bvhScale:1.0 = (
	local file = openFile bvhPath mode:"r"
	if file == undefined then (
		format "ERROR: Cannot open BVH file: %\n" bvhPath
		return undefined
	)

	local rootBone   = undefined
	local allBones   = #()
	local boneStack  = #()
	local currentBone = undefined

	local frameCount = 0
	local frameTime  = 0.033333
	local motionData = #()
	local inMotion   = false

	format "\n=== Parsing BVH: % ===\n" (getFilenameFile bvhPath)

	while not (eof file) do (
		local line    = readLine file
		local trimmed = trimLeft (trimRight line)
		if trimmed.count == 0 then continue

		if not inMotion then (
			-- ROOT or JOINT
			if (matchPattern trimmed pattern:"ROOT *") or (matchPattern trimmed pattern:"JOINT *") then (
				local parts = filterString trimmed " \t"
				if parts.count >= 2 then (
					local boneName = parts[2]
					local newBone  = BVHBone name:boneName parent:currentBone
					append allBones newBone
					if currentBone != undefined then
						append currentBone.children newBone
					else
						rootBone = newBone
					append boneStack currentBone
					currentBone = newBone
				)
			)
			-- OFFSET  (BVH is Y-up, Max is Z-up: remap [x,y,z]->[x,-z,y]; scale to GTA units)
			else if matchPattern trimmed pattern:"OFFSET *" then (
				local parts = filterString trimmed " \t"
				if parts.count >= 4 and currentBone != undefined then (
					local bxVal = (parts[2] as float) * bvhScale
					local byVal = (parts[3] as float) * bvhScale
					local bzVal = (parts[4] as float) * bvhScale
					currentBone.offset = [bxVal, -bzVal, byVal]
				)
			)
			-- CHANNELS
			else if matchPattern trimmed pattern:"CHANNELS *" then (
				local parts = filterString trimmed " \t"
				if parts.count >= 2 and currentBone != undefined then (
					currentBone.channels = parts[2] as integer
					currentBone.channelOrder = #()
					for i = 3 to parts.count do
						append currentBone.channelOrder parts[i]
				)
			)
			-- End Site  (push nil onto stack so closing "}" pops correctly)
			else if matchPattern trimmed pattern:"End Site" then (
				append boneStack currentBone
				currentBone = undefined
			)
			-- Closing brace
			else if trimmed == "}" then (
				if boneStack.count > 0 then (
					currentBone = boneStack[boneStack.count]
					deleteItem boneStack boneStack.count
				)
			)
			-- MOTION section begins
			else if matchPattern trimmed pattern:"MOTION" then (
				inMotion = true
			)
		) else (
			-- Frames:
			if matchPattern trimmed pattern:"Frames:*" then (
				local parts = filterString trimmed ": \t"
				if parts.count >= 2 then
					frameCount = parts[2] as integer
			)
			-- Frame Time:
			else if matchPattern trimmed pattern:"Frame Time:*" then (
				local parts = filterString trimmed ": \t"
				if parts.count >= 3 then
					frameTime = parts[3] as float
			)
			-- Motion data line
			else (
				local values = filterString trimmed " \t"
				if values.count > 0 then (
					local frameData = #()
					for v in values do append frameData (v as float)
					append motionData frameData
				)
			)
		)
	)
	close file

	-- FIX: assign channelStart INSIDE the struct here (not in ApplyMotionData
	-- where it was being set on an undeclared struct property and silently lost)
	local channelIndex = 1
	for bone in allBones do (
		bone.channelStart = channelIndex
		channelIndex += bone.channels
	)

	local fps = if (frameTime != undefined and frameTime > 0) then (1.0 / frameTime) else 30.0
	format "Parsed: % joints, % frames at %.0f fps\n" allBones.count frameCount fps

	return #(rootBone, allBones, frameCount, fps, motionData)
)

-- ---------------------------------------------------------------------------
-- Create Max dummy hierarchy from parsed BVH bones (rest pose, no animation)
-- ---------------------------------------------------------------------------
fn GTAAnim_GetBVHHelperSize helperScale = (
	local helperSize = abs helperScale * 2.0
	if helperSize < 0.05 then helperSize = 0.05
	helperSize
)

fn GTAAnim_StyleBVHDummy node helperSize = (
	if node == undefined then return undefined
	try (node.boxsize = [helperSize, helperSize, helperSize]) catch ()
	try (node.wirecolor = (color 255 220 0)) catch ()
	try (node.showLinks = true) catch ()
	node
)

fn CreateDummyHierarchy bvhRoot parentDummy helperScale:1.0 = (
	if bvhRoot == undefined then return undefined

	local helperSize = GTAAnim_GetBVHHelperSize helperScale
	local newDummy = dummy name:bvhRoot.name boxsize:[helperSize,helperSize,helperSize]
	if parentDummy != undefined then
		newDummy.parent = parentDummy
	if parentDummy != undefined then try (parentDummy.showLinks = true) catch ()
	GTAAnim_StyleBVHDummy newDummy helperSize

	-- Offset is already remapped to Max Z-up in ParseBVH.
	-- Child offsets in BVH are parent-space, not world-space.
	if parentDummy == undefined then newDummy.pos = bvhRoot.offset
	else in coordsys parent newDummy.pos = bvhRoot.offset
	bvhRoot.dummy = newDummy
	bvhRoot.bindRot = newDummy.rotation
	bvhRoot.bindPos = newDummy.pos
	bvhRoot.bindWorldRot = newDummy.transform.rotationpart

	for child in bvhRoot.children do
		CreateDummyHierarchy child newDummy helperScale:helperScale

	return newDummy
)

-- ---------------------------------------------------------------------------
-- Build a quaternion from a single frame's Euler channel data for one bone.
-- BVH channel order is the application order (e.g. Zrotation Xrotation Yrotation
-- = intrinsic ZXY = apply Z first, X second, Y third in local space).
--
-- FIX: original code used  quat angle [1,0,0]  which sets quat components
-- directly to [angle,1,0,0] (not a unit quaternion, completely wrong).
-- Correct form: (angleAxis angle axis) as quat
--
-- FIX: axis remapping for BVH Y-up -> Max Z-up:
--   BVH Xrotation axis [1,0,0] -> Max [1, 0, 0]  (same)
--   BVH Yrotation axis [0,1,0] -> Max [0, 0, 1]  (BVH Y = Max Z)
--   BVH Zrotation axis [0,0,1] -> Max [0,-1, 0]  (BVH Z = Max -Y)
-- ---------------------------------------------------------------------------
fn BVHEulerToQuat channelOrder frameData channelStart = (
	local q = quat 0 0 0 1

	-- Respect the exact BVH channel order per joint.
	-- For each listed rotation channel, apply that axis-rotation in sequence.
	for i = 1 to channelOrder.count do (
		local ch  = channelOrder[i]
		local idx = channelStart + i - 1
		if idx <= frameData.count then (
			local v = frameData[idx]
			local qStep = undefined
			if ch == "Xrotation" then qStep = (angleAxis v [1, 0, 0]) as quat      -- BVH X -> Max X
			else if ch == "Yrotation" then qStep = (angleAxis v [0, 0, 1]) as quat  -- BVH Y -> Max Z
			else if ch == "Zrotation" then qStep = (angleAxis v [0,-1, 0]) as quat  -- BVH Z -> Max -Y

			-- Accumulate in channel-list order; reversing this can flip child chains.
			if qStep != undefined then q = q * qStep
		)
	)

	q
)

-- ---------------------------------------------------------------------------
-- Apply BVH motion data to the dummy hierarchy
-- ---------------------------------------------------------------------------
fn ApplyMotionData allBones motionData frameCount fps gtaRootOnlyPos:true gtaFacing180:true bvhScale:1.0 = (
	format "\n=== Applying % frames ===\n" frameCount

	-- Match Max frame rate and range to the BVH source
	frameRate = fps
	animationRange = interval 0 (frameCount - 1)

	local facingFix = (angleAxis 180 [0,0,1]) as quat

	with animate on (
		for f = 0 to (frameCount - 1) do (
			at time f (
				if (f + 1) <= motionData.count then (
					local frameData = motionData[f + 1]

					for bone in allBones do (
						if bone.dummy == undefined or bone.channels == 0 then continue

						-- Collect position channels (root usually has these)
						local hasPos = false
						local bxp = 0.0; local byp = 0.0; local bzp = 0.0
						for i = 1 to bone.channelOrder.count do (
							local ch  = bone.channelOrder[i]
							local idx = bone.channelStart + i - 1
							if idx <= frameData.count then (
								local v = frameData[idx]
							-- FIX: remap Y-up to Z-up for positions too; apply scale
							if      ch == "Xposition" then ( bxp = v * bvhScale;     hasPos = true )
							else if ch == "Yposition" then ( bzp = v * bvhScale;     hasPos = true )  -- BVH Y -> Max Z
							else if ch == "Zposition" then ( byp = -(v * bvhScale);  hasPos = true )  -- BVH Z -> Max -Y
							)
						)

						-- Build rotation for this bone this frame
						local rot = BVHEulerToQuat bone.channelOrder frameData bone.channelStart

						-- FIX: root bone gets world transform; children get parent-space rotation
						if bone.parent == undefined then (
							-- Root: channels give absolute world position
							if hasPos then
								bone.dummy.pos = [bxp, byp, bzp]
							if gtaFacing180 then bone.dummy.rotation = (facingFix * rot)
							else bone.dummy.rotation = rot
						) else (
							-- Non-root: rotation is relative to parent
							-- FIX: must use coordsys parent so rotation isn't corrupted by world
							in coordsys parent (
								bone.dummy.rotation = rot
							)
						)
					)
				)
			)
		)
	)

	-- GTA rule: only the root should carry translation animation.
	-- If any child ended up with position keys, strip them and restore rest offsets.
	if gtaRootOnlyPos then (
		for bone in allBones where bone.parent != undefined and bone.dummy != undefined do (
			at time 0 (
				in coordsys parent bone.dummy.pos = bone.offset
			)
			try (deleteKeys bone.dummy.position.controller #allKeys) catch ()
		)
	)

	format "Done.\n"
)

-- ---------------------------------------------------------------------------
-- Main entry: parse + create hierarchy + apply animation
-- ---------------------------------------------------------------------------
fn GTAAnim_ImportBVHCore bvhPath gtaRootOnlyPos:true gtaFacing180:true bvhScale:1.0 = (
	-- Keep only one helper BVH rig in scene to avoid stacked imports.
	try (
		if (GTAAnim_LastBVHRoot != undefined) and (isValidNode GTAAnim_LastBVHRoot) then (
			GTAAnim_DeleteHierarchy GTAAnim_LastBVHRoot
		)
	) catch ()
	GTAAnim_LastBVHRoot = undefined

	local parseResult = ParseBVH bvhPath bvhScale:bvhScale
	if parseResult == undefined then (
		messagebox "Could not read BVH file.\nCheck the Listener for details." title:"BVH Import Error"
		return undefined
	)

	local rootBone  = parseResult[1]
	local allBones  = parseResult[2]
	local frameCount = parseResult[3]
	local fps        = parseResult[4]
	local motionData = parseResult[5]

	if rootBone == undefined then (
		messagebox "No ROOT joint found in BVH file." title:"BVH Import Error"
		return undefined
	)

	format "\n=== Creating skeleton ===\n"
	local rootDummy = CreateDummyHierarchy rootBone undefined helperScale:bvhScale
	GTAAnim_LastBVHRoot = rootDummy

	ApplyMotionData allBones motionData frameCount fps gtaRootOnlyPos:gtaRootOnlyPos gtaFacing180:gtaFacing180 bvhScale:bvhScale

	format "\n=== BVH Import complete ===\n"
	format "  Joints : %\n" allBones.count
	format "  Frames : %\n" frameCount
	format "  FPS    : %\n" fps
	format "  Root   : %\n\n" rootDummy.name
	format "  GTA root-only pos keys : %\n" gtaRootOnlyPos
	format "  GTA 180 facing fix     : %\n\n" gtaFacing180
	format "Joint names are BVH names (Hips, LeftUpLeg, etc).\n"
	format "Next: load GTA character via GTA_CHAR_IO, then click Retarget.\n\n"

	select rootDummy
	return #(rootDummy, allBones, frameCount)
)

fn ImportBVH bvhPath gtaRootOnlyPos:true gtaFacing180:true bvhScale:1.0 = (
	GTAAnim_ImportBVHCore bvhPath gtaRootOnlyPos:gtaRootOnlyPos gtaFacing180:gtaFacing180 bvhScale:bvhScale
)

-- ---------------------------------------------------------------------------
-- CMU BVH -> GTA SA ped mapping
--
-- Format:
--   #( bvhJointName, gtaBoneID, gtaBoneName, copyRootPos )
--
-- Matching is BoneID-first because imported GTA character rigs often use names
-- like "~L~Thigh" or "Bip01~R~Clavicle" rather than the cleaner UI labels.
-- Name lookup remains as a fallback for non-standard rigs.
-- ---------------------------------------------------------------------------
fn GetCMUToGTAMapping = (
	-- gtaBoneID undefined or gtaBoneName "" = skip (intermediate/virtual joint)
	-- Updated March 2026: mapped to actual BVH source (not CMU mocap naming)
	#(
		#("Hips",            0,  "Root",        true),
		#("LHipJoint",       undefined, "",     false),
		#("LeftHip",         41, "L Thigh",     false),
		#("LeftKnee",        42, "L Calf",      false),
		#("LeftAnkle",       43, "L Foot",      false),
		#("LeftToe",         44, "L Toe0",      false),
		#("RHipJoint",       undefined, "",     false),
		#("RightHip",        51, "R Thigh",     false),
		#("RightKnee",       52, "R Calf",      false),
		#("RightAnkle",      53, "R Foot",      false),
		#("RightToe",        54, "R Toe0",      false),
		#("lowerback",       undefined, "",     false),
		#("Chest",           2,  "Spine",       false),
		#("Chest2",          3,  "Spine1",      false),
		#("lowerneck",       undefined, "",     false),
		#("Neck",            4,  "Neck",        false),
		#("Head",            5,  "Head",        false),
		#("LeftCollar",      31, "L Clavicle",  false),
		#("LeftShoulder",    32, "L UpperArm",  false),
		#("LeftElbow",       33, "L ForeArm",   false),
		#("LeftWrist",       34, "L Hand",      false),
		#("lhand",           35, "L Finger",    false),
		#("LFingers",        36, "L Finger01",  false),
		#("LThumb",          undefined, "",     false),
		#("RightCollar",     21, "R Clavicle",  false),
		#("RightShoulder",   22, "R UpperArm",  false),
		#("RightElbow",      23, "R ForeArm",   false),
		#("RightWrist",      24, "R Hand",      false),
		#("rhand",           25, "R Finger",    false),
		#("RFingers",        26, "R Finger01",  false),
		#("RThumb",          undefined, "",     false)
	)
)

fn GTAAnim_FindBoneInHierarchyByName rootObj boneName = (
	if rootObj == undefined then return undefined
	local queue = #(rootObj)
	while queue.count > 0 do (
		local current = queue[1]
		deleteItem queue 1
		if current.name == boneName then return current
		for child in current.children do append queue child
	)
	undefined
)

fn GTAAnim_NormalizeBoneName boneName = (
	if boneName == undefined then return ""
	local normalized = toLower boneName
	normalized = substituteString normalized " " ""
	normalized = substituteString normalized "_" ""
	normalized = substituteString normalized "-" ""
	normalized = substituteString normalized "~" ""
	normalized
)

fn GTAAnim_StripCommonRigPrefixes normalizedName = (
	local outName = normalizedName
	if outName == undefined then outName = ""
	outName = substituteString outName "bip001" ""
	outName = substituteString outName "bip01" ""
	outName = substituteString outName "bone" ""
	outName = substituteString outName "dummy" ""
	outName = substituteString outName "joint" ""
	outName = substituteString outName "node" ""
	outName
)

fn GTAAnim_FindBoneInHierarchyByNormalizedName rootObj boneName = (
	if rootObj == undefined then return undefined
	local targetName = GTAAnim_NormalizeBoneName boneName
	if targetName == "" then return undefined
	local targetStripped = GTAAnim_StripCommonRigPrefixes targetName
	local queue = #(rootObj)
	while queue.count > 0 do (
		local current = queue[1]
		deleteItem queue 1
		local currentNorm = GTAAnim_NormalizeBoneName current.name
		local currentStripped = GTAAnim_StripCommonRigPrefixes currentNorm
		if (currentNorm == targetName) or (currentStripped == targetName) or (currentNorm == targetStripped) or (currentStripped == targetStripped) then return current
		for child in current.children do append queue child
	)
	undefined
)

fn GTAAnim_FindBoneInHierarchyByFuzzyNormalizedName rootObj boneName = (
	if rootObj == undefined then return undefined
	local targetName = GTAAnim_NormalizeBoneName boneName
	if targetName == "" then return undefined
	local targetStripped = GTAAnim_StripCommonRigPrefixes targetName
	local queue = #(rootObj)
	local bestNode = undefined
	local bestScore = -1
	while queue.count > 0 do (
		local current = queue[1]
		deleteItem queue 1
		local currentNorm = GTAAnim_NormalizeBoneName current.name
		local currentStripped = GTAAnim_StripCommonRigPrefixes currentNorm
		local score = 0
		if findString currentNorm targetName != undefined then score += 40
		if findString currentStripped targetName != undefined then score += 60
		if findString currentNorm targetStripped != undefined then score += 50
		if findString currentStripped targetStripped != undefined then score += 80
		if score > bestScore then (
			bestScore = score
			bestNode = current
		)
		for child in current.children do append queue child
	)
	if bestScore >= 80 then bestNode else undefined
)

fn GTAAnim_GetBoneID node = (
	if node == undefined then return undefined
	local boneID = undefined
	try (boneID = (getUserProp node "BoneID") as integer) catch (boneID = undefined)
	boneID
)

fn GTAAnim_FindBoneInHierarchyByBoneID rootObj boneID = (
	if rootObj == undefined then return undefined
	if boneID == undefined then return undefined
	if (GTAAnim_GetBoneID rootObj) == boneID then return rootObj
	local queue = #(rootObj)
	while queue.count > 0 do (
		local current = queue[1]
		deleteItem queue 1
		if (GTAAnim_GetBoneID current) == boneID then return current
		for child in current.children do append queue child
	)
	undefined
)

fn GTAAnim_ResolveTargetBone gtaRoot gtaBoneID gtaName = (
	if gtaRoot == undefined then return undefined
	if gtaBoneID == 0 then return gtaRoot
	local gtaDummy = GTAAnim_FindBoneInHierarchyByBoneID gtaRoot gtaBoneID
	if gtaDummy != undefined then return gtaDummy
	if gtaName == "Root" then return gtaRoot
	local gtaDummy = GTAAnim_FindBoneInHierarchyByName gtaRoot gtaName
	if gtaDummy != undefined then return gtaDummy
	GTAAnim_FindBoneInHierarchyByNormalizedName gtaRoot gtaName
)

fn GTAAnim_ResolveTargetBoneEx gtaRoot gtaBoneID gtaName = (
	if gtaRoot == undefined then return #(undefined, "none")
	if gtaBoneID == 0 then return #(gtaRoot, "root")
	local byID = GTAAnim_FindBoneInHierarchyByBoneID gtaRoot gtaBoneID
	if byID != undefined then return #(byID, "boneid")
	if gtaName == "Root" then return #(gtaRoot, "root")
	local byName = GTAAnim_FindBoneInHierarchyByName gtaRoot gtaName
	if byName != undefined then return #(byName, "name")
	local byNorm = GTAAnim_FindBoneInHierarchyByNormalizedName gtaRoot gtaName
	if byNorm != undefined then return #(byNorm, "normalized")
	local byFuzzy = GTAAnim_FindBoneInHierarchyByFuzzyNormalizedName gtaRoot gtaName
	if byFuzzy != undefined then return #(byFuzzy, "fuzzy")
	#(undefined, "none")
)

fn GTAAnim_GetWorldRotation node = (
	if node == undefined then return (quat 0 0 0 1)
	local worldRot = quat 0 0 0 1
	try (worldRot = node.transform.rotationpart) catch (worldRot = quat 0 0 0 1)
	worldRot
)

fn GTAAnim_GetWorldPosition node = (
	if node == undefined then return [0,0,0]
	local worldPos = [0,0,0]
	try (worldPos = node.transform.pos) catch (worldPos = [0,0,0])
	worldPos
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

fn GTAAnim_FindMappedTargetBySource mappedPairs sourceBone = (
	for p in mappedPairs where p[1] == sourceBone do return p[2]
	undefined
)

fn GTAAnim_FindSourceBasisForTargetParent mappedPairs sourceBone targetParentNode = (
	if sourceBone == undefined then return undefined
	if targetParentNode == undefined then return undefined
	local p = sourceBone.parent
	while p != undefined do (
		local mappedTarget = GTAAnim_FindMappedTargetBySource mappedPairs p
		if mappedTarget == targetParentNode then return p
		p = p.parent
	)
	undefined
)

fn RetargetBVHToGTATarget allBones frameCount gtaRoot = (
	if gtaRoot == undefined then (
		format "Retarget aborted: target GTA root is undefined.\n"
		return 0
	)

	local mapping  = GetCMUToGTAMapping()
	local transferCount = 0
	local skipped  = 0
	local notFound = #()
	local noMapping = #()
	local targetNodes = GTAAnim_CollectHierarchy gtaRoot
	local mappedPairs = #()

	format "\n=== Retargeting BVH -> GTA target: % ===\n" gtaRoot.name
	format "  BVH joints (%): " allBones.count
	for bone in allBones do format "% " bone.name
	format "\n"

	-- Clear old animation first so repeated retarget runs don't keep stale keys.
	for node in targetNodes do (
		try (deleteKeys node.rotation.controller #allKeys) catch ()
		if node != gtaRoot then try (deleteKeys node.pos.controller #allKeys) catch ()
	)

	for bone in allBones do (
		local mappingEntry = undefined
		for m in mapping where m[1] == bone.name do ( mappingEntry = m; exit )

		if mappingEntry == undefined then ( append noMapping bone.name; skipped += 1; continue )

		local gtaBoneID = mappingEntry[2]
		local gtaName = undefined
		if mappingEntry.count >= 3 then gtaName = mappingEntry[3]
		local copyRootPos = false
		if mappingEntry.count >= 4 then copyRootPos = mappingEntry[4]

		if gtaName == undefined then ( skipped += 1; continue )
		if gtaName == "" then ( skipped += 1; continue )
		if bone.dummy == undefined then continue

		local resolveResult = GTAAnim_ResolveTargetBoneEx gtaRoot gtaBoneID gtaName
		local gtaDummy = resolveResult[1]
		local resolveMode = resolveResult[2]

		-- Some GTA rigs have no explicit Pelvis node under Root; use Root for Hips.
		if (gtaDummy == undefined) and (bone.name == "Hips") then (
			gtaDummy = gtaRoot
			resolveMode = "hips-root-fallback"
		)

		if gtaDummy == undefined then (
			append notFound (gtaName + " [BoneID " + (gtaBoneID as string) + "]")
			continue
		)

		append mappedPairs #(bone, gtaDummy, copyRootPos, gtaBoneID, resolveMode)
	)

	-- Pure local-space solve:
	-- Non-root bones use local rotation delta from source bind -> source frame,
	-- applied to target bind local rotation. Root also transfers position delta.
	-- Cached pair format:
	-- #(bone, gtaDummy, copyRootPos, gtaBoneID, resolveMode,
	--   posTarget, sourceRefLocal, targetRefLocal, sourceFrame0Pos, targetRestPos)
	for i = 1 to mappedPairs.count do (
		local pair = mappedPairs[i]
		local bone = pair[1]
		local gtaDummy = pair[2]
		local copyRootPos = pair[3]
		local gtaBoneID = pair[4]
		local resolveMode = pair[5]
		local posTarget = if copyRootPos then gtaRoot else gtaDummy
		format "  map: % -> % [id:% via:% posToRoot:%]\n" bone.name gtaDummy.name gtaBoneID resolveMode copyRootPos

		local sourceRefLocal = quat 0 0 0 1
		local targetRefLocal = quat 0 0 0 1
		local sourceFrame0Pos = [0,0,0]
		local targetRestPos = [0,0,0]

		at time 0 (
			-- Use frame-0 local rotations as the retarget reference pose.
			sourceRefLocal = bone.dummy.rotation
			targetRefLocal = gtaDummy.rotation
			if copyRootPos then (
				sourceFrame0Pos = bone.dummy.pos
				targetRestPos = posTarget.pos
			)
		)

		mappedPairs[i] = #(bone, gtaDummy, copyRootPos, gtaBoneID, resolveMode, posTarget, sourceRefLocal, targetRefLocal, sourceFrame0Pos, targetRestPos)
	)

	with animate on (
		for f = 0 to (frameCount - 1) do (
			at time f (
				for pair in mappedPairs do (
					local bone = pair[1]
					local gtaDummy = pair[2]
					local copyRootPos = pair[3]
					local posTarget = pair[6]
					local sourceRefLocal = pair[7]
					local targetRefLocal = pair[8]
					local sourceFrame0Pos = pair[9]
					local targetRestPos = pair[10]

					local sourceFrameLocal = bone.dummy.rotation
					-- Delta from source frame-0 pose in local space.
					local sourceDeltaLocal = (inverse sourceRefLocal) * sourceFrameLocal
					local outLocal = targetRefLocal * (inverse sourceDeltaLocal)
					in coordsys parent gtaDummy.rotation = outLocal

					if copyRootPos then (
						local sourceFramePos = bone.dummy.pos
						posTarget.pos = targetRestPos + (sourceFramePos - sourceFrame0Pos)
					)
				)
			)
		)
	)

	transferCount = mappedPairs.count

	format "Mapped % bones, skipped %.\n" transferCount skipped
	if noMapping.count > 0 then (
		format "BVH joints not in mapping table (wrong BVH format?):\n"
		for n in noMapping do format "  - %\n" n
	)
	if notFound.count > 0 then (
		format "Missing in target hierarchy (BVH joints mapped but GTA bone not found):\n"
		for n in notFound do format "  - %\n" n
	)

	-- Safety: GTA expects translation keys only on root.
	for node in targetNodes where node != gtaRoot do (
		try (deleteKeys node.pos.controller #allKeys) catch ()
	)

	return transferCount
)

-- ---------------------------------------------------------------------------
-- Retarget BVH dummies -> GTA bones already in scene
--
-- Approach: world-space rotation copy.
--   At each frame, read the BVH dummy's world rotation and write it onto
--   the matching GTA bone (Max converts to local automatically).
--   For Hips->Root: position is also transferred.
--
-- This skips intermediate joints (their motion is already embedded in the
-- world rotation of their descendants when the BVH dummies are animated).
--
-- Prerequisite: load your GTA character with GTA_CHAR_IO first so that
-- bones named "Root", "L Thigh", etc. exist in the scene.
-- ---------------------------------------------------------------------------
fn RetargetBVHToGTA allBones frameCount = (
	local sceneRoot = getNodeByName "Root"
	if sceneRoot == undefined then (
		format "Retarget aborted: could not find a scene node named 'Root'.\n"
		return 0
	)
	local transferCount = RetargetBVHToGTATarget allBones frameCount sceneRoot
	format "\nUse GTA_CHAR_IO -> Export IFP to save as .ifp\n\n"
	return transferCount
)

-- ---------------------------------------------------------------------------
-- UI
-- ---------------------------------------------------------------------------
rollout BVH_Importer_UI "BVH Importer" width:300 (

	local lastImportedBones     = #()
	local lastImportedFrameCount = 0

	group "Source" (
		edittext txtBVH   "" width:280 readOnly:true
		button btnBrowse  "Browse BVH File..." width:280
	)

	group "Import Settings" (
		label lblStatus "No file selected." align:#left
		spinner spnScale "Scale:" type:#float range:[0.0001, 100.0, 0.05] fieldwidth:50 \
			tooltip:"BVH unit to Max unit scale. CMU mocap ~= 0.05 (cm to game units)."
		checkbox chkRootOnlyPos "GTA: root bone only position keys" checked:true \
			tooltip:"Strip translation keys from all non-root bones after import."
		checkbox chkFacing180   "GTA: 180 degree facing fix"        checked:true \
			tooltip:"Rotate root 180 degrees (GTA characters face backward in anim space)."
	)

	button btnImport   "1. Import BVH to Timeline"     width:280 height:35 enabled:false

	group "Retarget" (
		label lblRtg1 "Load GTA character (GTA_CHAR_IO) first," align:#left
		label lblRtg2 "then retarget BVH motion onto it:"        align:#left
		button btnRetarget "2. Retarget to GTA Skeleton in Scene" width:280 height:35 enabled:false \
			tooltip:"Copies BVH world rotations onto GTA bones. Requires GTA character already imported."
	)

	on btnBrowse pressed do (
		local p = getopenfilename caption:"Select BVH File" types:"BVH File (*.bvh)|*.bvh|All Files (*.*)|*.*|"
		if p != undefined then (
			txtBVH.text    = p
			lblStatus.text = "Ready: " + (getFilenameFile p)
			btnImport.enabled = true
		)
	)

	on btnImport pressed do (
		if txtBVH.text == "" then (
			messagebox "Select a BVH file first." title:"No Input"
			return()
		)
		local result = ImportBVH txtBVH.text \
			gtaRootOnlyPos:chkRootOnlyPos.checked \
			gtaFacing180:chkFacing180.checked \
			bvhScale:spnScale.value
		if result != undefined then (
			lastImportedBones      = result[2]
			lastImportedFrameCount = result[3]
			btnRetarget.enabled = true
			messagebox ("BVH imported!\n\nBVH skeleton is now in the scene.\n\nNext:\n1. Import your GTA character via GTA_CHAR_IO.\n2. Click 'Retarget to GTA Skeleton'.") title:"BVH Import"
		) else (
			messagebox "Import failed. Check the Listener for details." title:"BVH Import Error"
		)
	)

	on btnRetarget pressed do (
		if lastImportedBones.count == 0 then (
			messagebox "Import a BVH file first." title:"No BVH Data"
			return()
		)
		local n = RetargetBVHToGTA lastImportedBones lastImportedFrameCount
		if n > 0 then
			messagebox ("Retarget complete! " + n as string + " bones transferred.\n\nUse GTA_CHAR_IO -> Export IFP to save.") title:"Retarget"
		else
			messagebox "No bones were mapped.\n\nLoad the GTA character first via GTA_CHAR_IO so bones like 'Root', 'L Thigh' etc. exist in the scene.\n\nCheck the Listener for details." title:"Retarget Failed"
	)

	on BVH_Importer_UI open do (
		format "\n===== BVH Importer =====\n"
		format "Workflow:\n"
		format "  1. Browse + Import BVH -> creates BVH skeleton with animation\n"
		format "  2. Import GTA character via GTA_CHAR_IO\n"
		format "  3. Retarget -> transfers motion onto GTA bones\n"
		format "  4. GTA_CHAR_IO -> Export IFP\n\n"
	)
)

-- Signal to IFP_IO that this module loaded successfully
global GTAAnim_BVH_MODULE_LOADED = true

global BVH_Importer_Float
if (GTA_BVH_IMPORT_DISABLE_UI == undefined) or (GTA_BVH_IMPORT_DISABLE_UI == false) then (
	try (closeRolloutFloater BVH_Importer_Float) catch ()
	BVH_Importer_Float = newRolloutFloater "BVH Importer" 320 360
	addRollout BVH_Importer_UI BVH_Importer_Float
)
