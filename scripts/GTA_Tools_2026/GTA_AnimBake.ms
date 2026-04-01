-- ============================================================================
--  GTA_AnimBake.ms  -  Motion Capture to GTA Character Baker
--  Format-to-format animation converter.
--
--  Workflow:
--    1. "Setup Rig"  : creates BipGTA biped, loads BipGTA.fig, imports animate.dff
--    2. Load an animation onto BipGTA manually (.bip / mocap)
--    3. "Bake"        : samples biped per frame, writes keys to GTA bones
--
--  Bone mapping is hardcoded (canonical 22-pair table).
--
--  Source: scripts/GTA_Tools_2026/GTA_AnimBake.ms
-- ============================================================================

global bakScriptPath = getFilenamePath (getThisScriptFilename())
global bakIniPath = bakScriptPath + "GTA_AnimBake.ini"
global GTA_ACTIVE_RIG_ROOT
global GTA_ANIMBAKE_ALIGN_DUMMY
global bakRescaleToFig -- forward-declared: defined later in file; pre-declare so MaxScript 2017 resolves it as a global in bakPostLoadSetup

-- ---------------------------------------------------------------------------
-- BoneID-authoritative mapping (gtaBoneID -> bipBone).
-- ---------------------------------------------------------------------------
global GTA_BONEID_BIP_MAP = #(
	#(0,  "BipGTA"),
	#(1,  "BipGTA Pelvis"),
	#(2,  "BipGTA Spine1"),
	#(3,  "BipGTA Spine2"),
	#(4,  "BipGTA Neck"),
	#(5,  "BipGTA Head"),
	#(31, "BipGTA L Clavicle"),
	#(32, "BipGTA L UpperArm"),
	#(33, "BipGTA L Forearm"),
	#(34, "BipGTA L Hand"),
	#(21, "BipGTA R Clavicle"),
	#(22, "BipGTA R UpperArm"),
	#(23, "BipGTA R Forearm"),
	#(24, "BipGTA R Hand"),
	#(41, "BipGTA L Thigh"),
	#(42, "BipGTA L Calf"),
	#(43, "BipGTA L Foot"),
	#(44, "BipGTA L Toe0"),
	#(51, "BipGTA R Thigh"),
	#(52, "BipGTA R Calf"),
	#(53, "BipGTA R Foot"),
	#(54, "BipGTA R Toe0")
)

-- Finger bones are held at rest pose for the full animation.
global GTA_HOLD_BONE_IDS = #(25, 26, 35, 36)

-- Critical bones: bake is aborted if ANY of these are missing in scene
global GTA_CRITICAL_BONE_IDS = #(1, 2, 3, 22, 32, 41, 51)

-- Keep authored target root orientation per model (recommended).
global GTA_PRESERVE_TARGET_ROOT_ROT = true

-- Load CharDFFimp once at script-load time so DFFin is always defined.
-- CharDFFimp resets LetsRockandRoll to undefined at line 6, so we set it true
-- immediately after.  If GTA_CHAR_IO has already loaded it, this is a no-op
-- for function definitions but safely re-asserts LetsRockandRoll.
fileIn (bakScriptPath + "CharDFFimp.ms") quiet:true
global LetsRockandRoll = true

-- ---------------------------------------------------------------------------
--  Helpers
-- ---------------------------------------------------------------------------
fn bakGetDefaultFigPath =
(
	bakScriptPath + "tools\\AnimRig\\BipGTA.fig"
)

fn bakGetDefaultDffPath =
(
	local d = bakScriptPath + "tools\\AnimRig\\cj_plyr.dff"
	if not doesFileExist d do d = bakScriptPath + "tools\\AnimRig\\animate.dff"
	d
)

fn bakNormalizePathSlashes pathVal =
(
	if pathVal == undefined then return ""
	(substituteString pathVal "/" "\\")
)

fn bakIsAbsolutePath pathVal =
(
	local p = bakNormalizePathSlashes pathVal
	if p == "" then return false
	if p.count >= 2 and (substring p 2 1) == ":" then return true
	if p.count >= 2 and (substring p 1 2) == "\\\\" then return true
	false
)

fn bakResolveConfigPath pathVal =
(
	local p = bakNormalizePathSlashes pathVal
	if p == "" then return ""
	if bakIsAbsolutePath p then return p

	while p.count > 0 and ((substring p 1 1) == "\\") do p = substring p 2 (p.count - 1)
	bakScriptPath + p
)

fn bakPathToConfig pathVal =
(
	local p = bakNormalizePathSlashes pathVal
	local base = bakNormalizePathSlashes bakScriptPath
	if p == "" then return ""

	if (toLower p) == (toLower base) then return ""
	if matchPattern (toLower p) pattern:((toLower base) + "*") then
	(
		return (substring p (base.count + 1) (p.count - base.count))
	)

	p
)

fn bakLoadFlatPathConfig =
(
	local figVal = ""
	local dffVal = ""

	if doesFileExist bakIniPath then
	(
		local f = openFile bakIniPath mode:"rt"
		if f != undefined then
		(
			while not eof f do
			(
				local ln = trimRight (trimLeft (readLine f))
				local eqPos = findString ln "="
				if eqPos != undefined and eqPos > 1 then
				(
					local keyName = toLower (trimRight (trimLeft (substring ln 1 (eqPos - 1))))
					local val = trimRight (trimLeft (substring ln (eqPos + 1) (ln.count - eqPos)))
					if keyName == "figurefile" then figVal = val
					else if keyName == "characterdff" then dffVal = val
				)
			)
			close f
		)
	)

	#(figVal, dffVal)
)

fn bakWriteFlatPathConfig figVal dffVal =
(
	local f = createFile bakIniPath
	if f != undefined then
	(
		format "FigureFile=%\n" (bakPathToConfig figVal) to:f
		format "CharacterDFF=%\n" (bakPathToConfig dffVal) to:f
		close f
	)
)

fn bakLoadIniPaths =
(
	local figVal = getINISetting bakIniPath "Paths" "FigureFile"
	local dffVal = getINISetting bakIniPath "Paths" "CharacterDFF"
	local flatVals = bakLoadFlatPathConfig()

	if figVal == "" then figVal = flatVals[1]
	if dffVal == "" then dffVal = flatVals[2]

	if figVal == "" then
	(
		figVal = bakGetDefaultFigPath()
	)
	figVal = bakResolveConfigPath figVal

	if dffVal == "" then
	(
		dffVal = bakGetDefaultDffPath()
	)
	dffVal = bakResolveConfigPath dffVal

	bakWriteFlatPathConfig figVal dffVal

	#(figVal, dffVal)
)

fn bakSaveIniPaths figPath dffPath =
(
	local vals = bakLoadIniPaths()
	local figVal = vals[1]
	local dffVal = vals[2]

	if figPath != undefined and figPath != "" then figVal = figPath
	if dffPath != undefined and dffPath != "" then dffVal = dffPath

	bakWriteFlatPathConfig figVal dffVal
)

fn bakFindBipRoot =
(
	local found = undefined
	for obj in selection while found == undefined do
		if classof obj == Biped_Object then found = obj.controller.rootNode
	if found == undefined then
		for obj in objects while found == undefined do
			if classof obj == Biped_Object then found = obj.controller.rootNode
	found
)

fn bakGetBoneID node =
(
	if node == undefined then return undefined
	local id = undefined
	try (id = getUserProp node "BoneID") catch ()
	if id == undefined or id == "" then return undefined
	try (id as integer) catch (undefined)
)

fn bakCollectHierarchy rootObj =
(
	local nodes = #()
	if rootObj == undefined then return nodes
	local queue = #(rootObj)
	while queue.count > 0 do
	(
		local n = queue[1]
		deleteItem queue 1
		append nodes n
		for c in n.children do append queue c
	)
	nodes
)

fn bakFindRigRootFromNode node =
(
	local cur = node
	while cur != undefined do
	(
		if (bakGetBoneID cur) == 0 then return cur
		cur = cur.parent
	)
	undefined
)

fn bakFindRigRootsInScene =
(
	local roots = #()
	for obj in objects do
	(
		if (bakGetBoneID obj) == 0 and obj.parent == undefined then append roots obj
	)
	roots
)

fn bakGetSkinModifier node =
(
	if node == undefined then return undefined
	if not isProperty node #modifiers then return undefined
	for m in node.modifiers do
	(
		if classof m == Skin then return m
	)
	undefined
)

fn bakResolveRigRootFromSkinnedMesh meshNode =
(
	local parentRoot = bakFindRigRootFromNode meshNode
	if parentRoot != undefined then return parentRoot

	local skinMod = bakGetSkinModifier meshNode
	if skinMod == undefined then return undefined

	local roots = bakFindRigRootsInScene()
	if roots.count < 1 then return undefined

	local bestRoot = undefined
	local bestCount = 0
	local tie = false
	for r in roots do
	(
		local c = 0
		for b in (bakCollectHierarchy r) do
		(
			local deps = undefined
			try (deps = refs.dependents b) catch (deps = undefined)
			if deps != undefined and (findItem deps skinMod) > 0 then c += 1
		)
		if c > bestCount then
		(
			bestCount = c
			bestRoot = r
			tie = false
		)
		else if c == bestCount and c > 0 then
		(
			tie = true
		)
	)

	if bestCount > 0 and not tie then return bestRoot
	undefined
)

fn bakResolveActiveRigRoot showMessage:true =
(
	if selection.count > 0 then
	(
		for s in selection do
		(
			local skinRoot = bakResolveRigRootFromSkinnedMesh s
			if skinRoot != undefined then
			(
				GTA_ACTIVE_RIG_ROOT = skinRoot
				return skinRoot
			)
		)

		local selRoot = bakFindRigRootFromNode selection[1]
		if selRoot != undefined then
		(
			GTA_ACTIVE_RIG_ROOT = selRoot
			return selRoot
		)
	)

	if GTA_ACTIVE_RIG_ROOT != undefined and isValidNode GTA_ACTIVE_RIG_ROOT then return GTA_ACTIVE_RIG_ROOT

	local roots = bakFindRigRootsInScene()
	if roots.count == 1 then
	(
		GTA_ACTIVE_RIG_ROOT = roots[1]
		return roots[1]
	)

	if showMessage and roots.count > 1 then
	(
		messageBox "Multiple GTA rigs found. Select a skinned mesh (preferred) or any node from the target GTA rig, then retry." title:"Bake"
	)

	undefined
)

fn bakFindBoneByID rigRoot boneID =
(
	if rigRoot == undefined then return undefined
	for n in (bakCollectHierarchy rigRoot) do
	(
		if (bakGetBoneID n) == boneID then return n
	)
	undefined
)

fn bakEnforceRootOnlyPositionKeys rigRoot =
(
	if rigRoot == undefined then return 0
	local removed = 0
	for n in (bakCollectHierarchy rigRoot) do
	(
		local id = bakGetBoneID n
		if id != undefined and id != 0 then
		(
			try (deletekeys n.pos.controller; removed += 1) catch ()
		)
	)
	removed
)

fn bakPostLoadSetup figPath =
(
	local bipRoot = bakFindBipRoot()
	if bipRoot == undefined then
	(
		messageBox "No biped in scene. Run Setup Rig first." title:"Post-Load Setup"
		return false
	)

	-- If the biped is already parented (old align dummy or anything else),
	-- detach first and preserve world transform so setup can be safely re-run.
	if bipRoot.parent != undefined then
	(
		local worldTM = bipRoot.transform
		bipRoot.parent = undefined
		bipRoot.transform = worldTM
	)

	local rescaleOK = bakRescaleToFig figPath bipRoot
	if not rescaleOK then
	(
		format "[AnimBake] WARNING: Post-load rescale failed; continuing with dummy setup.\n"
	)

	-- Clean up any leftover align dummies by name in addition to tracked global.
	local oldDummies = #()
	for n in objects where matchPattern n.name pattern:"AnimBake_AlignDummy*" do
	(
		append oldDummies n
	)
	for n in oldDummies do if isValidNode n then try (delete n) catch ()

	if GTA_ANIMBAKE_ALIGN_DUMMY != undefined and isValidNode GTA_ANIMBAKE_ALIGN_DUMMY then
	(
		try (delete GTA_ANIMBAKE_ALIGN_DUMMY) catch ()
	)

	-- Dummy only anchors translation; keep identity rotation to avoid forcing heading.
	local dmy = dummy name:"AnimBake_AlignDummy" boxsize:[0.75,0.75,0.75] wirecolor:(color 255 140 0)
	dmy.pos = bipRoot.transform.row4
	dmy.rotation = quat 0 0 0 1

	local rootTM = bipRoot.transform
	bipRoot.parent = dmy
	bipRoot.transform = rootTM

	dmy.position = [0,0,0]
	GTA_ANIMBAKE_ALIGN_DUMMY = dmy
	format "[AnimBake] Post-load setup complete. Dummy: %\n" dmy.name
	true
)

-- Resolves canonical mapping names like "BipGTA Pelvis" against any biped prefix
-- (BipGTA/Bip01/Bip001/etc.) by matching semantic suffixes.
fn bakResolveBipNode canonicalName bipRoot =
(
	if canonicalName == "BipGTA" then return bipRoot

	local n = getNodeByName canonicalName
	if n != undefined then return n

	local suffix = canonicalName
	local firstSpace = findString canonicalName " "
	if firstSpace != undefined and firstSpace < canonicalName.count then
		suffix = substring canonicalName (firstSpace + 1) (canonicalName.count - firstSpace)

	if bipRoot != undefined then
	(
		local prefName = bipRoot.name + " " + suffix
		n = getNodeByName prefName
		if n != undefined then return n
	)

	for obj in objects do
	(
		if classof obj == Biped_Object then
		(
			if matchPattern obj.name pattern:("* " + suffix) ignoreCase:true then return obj
		)
	)

	undefined
)

-- Re-applies .fig to reset biped proportions after a .bip or other animation
-- source has resized the biped.  Call any time after loading animation.
fn bakRescaleToFig figFilePath bipRoot =
(
	if bipRoot == undefined then (
		messageBox "No biped in scene. Run Setup Rig first." title:"Rescale Biped"
		return false
	)
	local f = if figFilePath != undefined then figFilePath \
	          else (bakScriptPath + "tools\\AnimRig\\BipGTA.fig")
	if not doesFileExist f then (
		messageBox ("Fig file not found:\n" + f) title:"Rescale Biped"
		return false
	)
	local ok = false
	try (
		bipRoot.controller.figureMode = true
		try ( biped.loadFigFile bipRoot.transform.controller f; ok = true ) catch()
		if not ok do try ( biped.loadFigFile bipRoot.controller f; ok = true ) catch()
		bipRoot.controller.figureMode = false
		if ok then format "[AnimBake] Biped rescaled to fig: %\n" f
		     else messageBox "loadFigFile failed (no valid overload)." title:"Rescale Biped"
	) catch (
		try ( bipRoot.controller.figureMode = false ) catch()
		messageBox ("Rescale failed: " + (getCurrentException())) title:"Rescale Biped"
	)
	ok
)

-- ---------------------------------------------------------------------------
--  Biped height capability cache (same pattern as GTA_AnimationRig.ms)
-- ---------------------------------------------------------------------------
global g_bipHeightMode = #auto

fn bakSetBipHeight bipRoot h =
(
	local prevFig = bipRoot.controller.figureMode
	local ok = false

	try ( bipRoot.controller.figureMode = true ) catch ()

	if not ok do try ( bipRoot.controller.height = h; ok = true ) catch ()
	if not ok do try ( biped.height bipRoot.transform.controller h; ok = true ) catch ()
	if not ok do try ( bipRoot.height = h; ok = true ) catch ()

	try ( bipRoot.controller.figureMode = prevFig ) catch ()
	ok
)

-- ---------------------------------------------------------------------------
--  Setup Rig
-- ---------------------------------------------------------------------------
fn bakSetupRig figPath dffPath =
(
	local rigDir   = bakScriptPath + "tools\\AnimRig\\"

	-- User-requested hard reset: start from a clean scene every time.
	try (resetMaxFile #noprompt) catch ()
	GTA_ACTIVE_RIG_ROOT = undefined
	GTA_ANIMBAKE_ALIGN_DUMMY = undefined

	-- Clear existing animation sources/targets before creating a new setup.
	-- Collect first; deleting while iterating scene can crash Max.
	local deleteRoots = #()
	for obj in objects do
	(
		if classof obj == Biped_Object then
		(
			local r = obj.controller.rootNode
			if (findItem deleteRoots r) == 0 then append deleteRoots r
		)
	)
	for r in (bakFindRigRootsInScene()) do
	(
		if (findItem deleteRoots r) == 0 then append deleteRoots r
	)
	for r in deleteRoots do try (delete r) catch()
	GTA_ACTIVE_RIG_ROOT = undefined

	-- 1. Create biped
	local bipObj = biped.createNew 0 0 [0,0,0] height:1.8328
	if bipObj == undefined then (
		messageBox "Failed to create biped." title:"Setup Rig"
		return false
	)
	bipObj.name = "BipGTA"
	local bipRoot = bipObj.controller.rootNode

	-- 2. Load figure file
	local figFile = if figPath != undefined then figPath else (rigDir + "BipGTA.fig")
	if doesFileExist figFile then (
		local prevFigureMode = bipRoot.controller.figureMode
		local figOk = false
		try
		(
			bipRoot.controller.figureMode = true
			try ( biped.loadFigFile bipRoot.transform.controller figFile; figOk = true ) catch()
			if not figOk do try ( biped.loadFigFile bipRoot.controller figFile; figOk = true ) catch()
		)
		catch
		(
			format "[AnimBake] fig load error: %\n" (getCurrentException())
		)
		try ( bipRoot.controller.figureMode = prevFigureMode ) catch ()

		if not figOk then
		(
			messageBox "BipGTA.fig could not be applied. Biped may have wrong spine/neck structure." title:"Setup Rig"
			return false
		)
	) else (
		format "[AnimBake] WARNING: BipGTA.fig not found at %\n" figFile
	)

	-- 3. Import character DFF
	local defaultDff = rigDir + "cj_plyr.dff"
	if not doesFileExist defaultDff do defaultDff = rigDir + "animate.dff"
	local dffFile = if dffPath != undefined then dffPath else defaultDff
	if doesFileExist dffFile then (
		-- CharDFFimp was already loaded at script startup; DFFin should always be defined.
		if DFFin == undefined then
		(
			messageBox "DFFin is undefined." title:"Setup Rig"
			return false
		)

		global LetsRockandRoll = true
		local f = fopen dffFile "rb"
		if f != undefined then (
			local impErr = undefined
			try
			(
				   -- Force StandardMaterial import by overriding global mattype
				   global mattype
				   local oldMatType = undefined
				   if isProperty globals #mattype do oldMatType = mattype
				   mattype = 2 -- force StandardMaterial (Character IO style)
				global ANIMBAKE_FORCE_STDMTL
				local oldForceStdMtl = if isProperty globals #ANIMBAKE_FORCE_STDMTL then ANIMBAKE_FORCE_STDMTL else undefined
				ANIMBAKE_FORCE_STDMTL = true
				DFFin f 1.0 2 ".png" 0.1 true false (getFilenameFile dffFile)
				   if oldMatType != undefined then mattype = oldMatType else (execute "global mattype = undefined")
				if oldForceStdMtl != undefined then ANIMBAKE_FORCE_STDMTL = oldForceStdMtl else (execute "global ANIMBAKE_FORCE_STDMTL = undefined")
				   -- Force all imported character geometry to StandardMaterial.
				   for obj in geometry do (
					   if (matchPattern obj.name pattern:"*Normal*") or (matchPattern obj.name pattern:"*Root*") or (matchPattern obj.name pattern:"*Pelvis*") or (matchPattern obj.name pattern:"*Spine*") or (matchPattern obj.name pattern:"*Head*") or (matchPattern obj.name pattern:"*Clavicle*") or (matchPattern obj.name pattern:"*UpperArm*") or (matchPattern obj.name pattern:"*Forearm*") or (matchPattern obj.name pattern:"*Hand*") or (matchPattern obj.name pattern:"*Thigh*") or (matchPattern obj.name pattern:"*Calf*") or (matchPattern obj.name pattern:"*Foot*") or (matchPattern obj.name pattern:"*Toe*") then (
						   obj.material = StandardMaterial()
						   obj.material.diffuse = color 255 255 255
						   obj.material.specular = color 26 26 26
						   obj.material.specular_level = 10
						   obj.material.glossiness = 0
						   obj.material.soften = 0
					   )
				   )
			)
			catch
			(
				impErr = (getCurrentException() as string)
			)
			fclose f
			if impErr != undefined then
			(
				messageBox ("DFF import failed:\n\n" + impErr) title:"Setup Rig"
				return false
			)
			gc()
		) else (
			messageBox ("Cannot open: " + dffFile) title:"Setup Rig"
			return false
		)
	) else (
		format "[AnimBake] WARNING: animate.dff not found at %\n" dffFile
	)

	-- Prefer newly imported rig root (BoneID 0), then fallback to active/single rig resolve.
	local gtaRoot = undefined
	local postImportRoots = bakFindRigRootsInScene()
	if postImportRoots.count == 1 then gtaRoot = postImportRoots[1]
	if gtaRoot == undefined then gtaRoot = bakResolveActiveRigRoot showMessage:false
	if gtaRoot != undefined then
	(
		GTA_ACTIVE_RIG_ROOT = gtaRoot
		try
		(
			at time 0 biped.setTransform bipRoot #pos gtaRoot.transform.position true
			at time 0 biped.setTransform bipRoot #rotation (gtaRoot.transform.rotation as eulerAngles) true
		)
		catch
		(
			format "[AnimBake] biped align warning: %\n" (getCurrentException())
		)
	)

	format "[AnimBake] Rig setup complete.\n"
	true
)

-- ---------------------------------------------------------------------------
--  Bake
-- ---------------------------------------------------------------------------
fn bakBake startF endF saveBipPath =
(
	local bipRoot = bakFindBipRoot()
	if bipRoot == undefined then (
		messageBox "No biped found in scene. Run Setup Rig first." title:"Bake"
		return false
	)

	local rigRoot = bakResolveActiveRigRoot showMessage:true
	if rigRoot == undefined then return false
	GTA_ACTIVE_RIG_ROOT = rigRoot

	-- Policy: GTA characters only keep root translation keys (BoneID 0).
	bakEnforceRootOnlyPositionKeys rigRoot

	-- Validate critical bones by BoneID under active rig only.
	local missing = #()
	for id in GTA_CRITICAL_BONE_IDS do if (bakFindBoneByID rigRoot id) == undefined then append missing id
	if missing.count > 0 then (
		local msg = "Missing critical GTA BoneIDs in active rig:\n"
		for b in missing do msg += "  " + (b as string) + "\n"
		msg += "\nImport animate.dff first."
		messageBox msg title:"Bake"
		return false
	)

	-- Resolve hold bones (fingers): by BoneID under active rig.
	local holdNodes = #()
	local skippedHold = #()
	for holdID in GTA_HOLD_BONE_IDS do
	(
		local n = bakFindBoneByID rigRoot holdID
		if n != undefined then append holdNodes n
		else append skippedHold holdID
	)

	-- Build resolved pair list  #(#(gtaNode, bipNode or undefined), ...)
	local pairs = #()
	local unmappedBip = #()
	local unmappedGta = #()

	for pair in GTA_BONEID_BIP_MAP do (
		local boneID = pair[1]
		local gtaNode = bakFindBoneByID rigRoot boneID
		local bipNode = bakResolveBipNode pair[2] bipRoot
		if gtaNode != undefined and bipNode != undefined then (
			append pairs #(gtaNode, bipNode, boneID)
		) else (
			if gtaNode == undefined then append unmappedGta boneID
			if bipNode == undefined then append unmappedBip pair[2]
		)
	)

	if pairs.count == 0 then (
		messageBox "No bone pairs resolved. Check scene contents." title:"Bake"
		return false
	)

	format "[AnimBake] Baking % pairs, frames % to %\n" pairs.count startF endF

	-- Ensure all GTA bones have Euler_XYZ rotation controllers so x/y/z_rotation
	-- channels exist.  CharDFFimp may leave Bezier or TCB controllers in place.
	for pair in pairs do
	(
		local gn = pair[1]
		if classof gn.rotation.controller != Euler_XYZ then
			gn.rotation.controller = Euler_XYZ()
	)
	for hn in holdNodes do
		if classof hn.rotation.controller != Euler_XYZ then
			hn.rotation.controller = Euler_XYZ()

	-- Capture rest-pose rotations for hold bones at frame 0 (local space).
	local holdRestRots = #()
	for n in holdNodes do
	(
		local r = at time 0 (
			if n.parent != undefined then in coordsys parent n.rotation
			else n.rotation
		)
		append holdRestRots (r as eulerAngles)
	)

	-- Preserve active target root orientation when requested.
	local rootRestRot = undefined
	if GTA_PRESERVE_TARGET_ROOT_ROT then
	(
		if rigRoot != undefined then rootRestRot = at time 0 (rigRoot.rotation as eulerAngles)
	)

	-- READ PASS: cache each biped bone's world transform at every frame BEFORE
	-- any writes.  Interleaving reads/writes in one pass can stale-cache biped
	-- evaluation and produce wrong rotations.
	-- frameCache[frameIndex][pairIndex] = transform_matrix3
	local frameCache = #()
	for f = startF to endF do
	(
		local fc = #()
		at time f (
			for k = 1 to pairs.count do
				append fc pairs[k][2].transform
		)
		append frameCache fc
	)
	-- Also cache root biped position separately (bipRoot = pairs[1][2] = BipGTA COM)
	-- pairs[1] is Normal <-> BipGTA root.

	-- WRITE PASS: apply cached transforms to GTA bones as local rotations +
	-- root translation.  The IFP exporter reads bones in coordsys parent, so we
	-- must write local (parent-relative) rotations here.
	disablesceneredraw()
	local bakeErr = undefined
	try (
		with animate on (
			for f = startF to endF do (
				local fi = f - startF + 1
				at time f (
					for k = 1 to pairs.count do (
						local gtaNode = pairs[k][1]
						local cachedMat = frameCache[fi][k]
						local boneID = pairs[k][3]
						-- Derive local rotation: world bip rot * inverse(gta parent world rot)
						-- For root (no parent) use world rotation directly.
						local localRot = if gtaNode.parent != undefined then \
							(cachedMat.rotation * inverse(gtaNode.parent.transform.rotation)) \
							else cachedMat.rotation
						-- Override BoneID 0 heading with rest rot if requested.
						if GTA_PRESERVE_TARGET_ROOT_ROT and boneID == 0 and rootRestRot != undefined then (
							gtaNode.rotation.controller.x_rotation = rootRestRot.x
							gtaNode.rotation.controller.y_rotation = rootRestRot.y
							gtaNode.rotation.controller.z_rotation = rootRestRot.z
						) else (
							local ea = localRot as eulerAngles
							gtaNode.rotation.controller.x_rotation = ea.x
							gtaNode.rotation.controller.y_rotation = ea.y
							gtaNode.rotation.controller.z_rotation = ea.z
						)
						-- Position: root (BoneID 0) only.
						if boneID == 0 then (
							local srcPos = cachedMat.translation
							gtaNode.position.controller.x_position = srcPos.x
							gtaNode.position.controller.y_position = srcPos.y
							gtaNode.position.controller.z_position = srcPos.z
						)
					)
				)
			)
			-- Hold bones: write rest-pose local rotation at every frame
			for k = 1 to holdNodes.count do (
				local hn = holdNodes[k]
				local hr = holdRestRots[k]
				for f = startF to endF do
					at time f (
						hn.rotation.controller.x_rotation = hr.x
						hn.rotation.controller.y_rotation = hr.y
						hn.rotation.controller.z_rotation = hr.z
					)
			)
			animationRange = interval startF endF
		)
	)
	catch ( bakeErr = getCurrentException() )

	enablesceneredraw()
	redrawviews()

	if bakeErr != undefined then (
		messageBox ("Bake failed:\n\n" + bakeErr) title:"Bake"
		return false
	)

	-- Optional .bip save
	local bipSaveErr = undefined
	if saveBipPath != undefined then (
		try (
			biped.saveBipFile bipRoot.transform.controller saveBipPath
			format "[AnimBake] Saved .bip: %\n" saveBipPath
		)
		catch ( bipSaveErr = getCurrentException() )
	)

	-- Report
	local report = "Bake complete.\n"
	report += "  Pairs baked : " + (pairs.count as string) + "\n"
	report += "  Fingers held: " + (holdNodes.count as string) + " of " + (GTA_HOLD_BONE_IDS.count as string) + "\n"
	report += "  Frames      : " + (startF as string) + " - " + (endF as string) + "\n"
	if saveBipPath != undefined then (
		if bipSaveErr == undefined then
			report += "  BIP saved   : " + saveBipPath + "\n"
		else
			report += "  BIP FAILED  : " + bipSaveErr + "\n"
	)
	if unmappedBip.count > 0 then (
		report += "\nSkipped (biped not found):\n"
		for b in unmappedBip do report += "  " + b + "\n"
	)
	if unmappedGta.count > 0 then (
		report += "\nSkipped (GTA BoneID not found in active rig):\n"
		for b in unmappedGta do report += "  " + (b as string) + "\n"
	)
	if skippedHold.count > 0 then (
		report += "\nFinger BoneIDs not found in active rig (skipped):\n"
		for b in skippedHold do report += "  " + (b as string) + "\n"
	)
	format "%\n" report
	messageBox report title:"Bake Complete"
	true
)

-- ---------------------------------------------------------------------------
--  UI
-- ---------------------------------------------------------------------------
global GTA_AnimBake_Floater

rollout bakRoll "GTA Anim Bake"
(
	-- Setup
	group "1. Rig Setup"
	(
		label lblFig "Biped Figure File (*.fig):" align:#left
		editText txtFig "" fieldwidth:210 readOnly:true
		button btnPickFig "..." width:25 height:17 align:#right offset:[0,-21] tooltip:"Pick BipGTA.fig"

		label lblDff "GTA Target Character (*.dff):" align:#left
		editText txtDff "" fieldwidth:210 readOnly:true
		button btnPickDff "..." width:25 height:17 align:#right offset:[0,-21] tooltip:"Pick GTA character DFF"

		button btnSetup "Setup Rig" width:240 height:28 align:#center tooltip:"Create BipGTA biped and import GTA character"
	)

	group "2. Load Animation"
	(
		label lblLoadHint1 "Load animation onto BipGTA after setup. Then:" align:#left
		button btnPostLoad "Reconfigure Biped and Center" width:240 height:28 align:#center tooltip:"Reapply .fig, create a small translation-only dummy, parent biped root, then move dummy to world origin."
		label lblLoadHint3 "Unparent BipGTA and delete dummy before loading" align:#left
		label lblLoadHint4 "any new animations - or re-run Setup Rig." align:#left
	)

	-- Bake
	group "3. Bake Animation"
	(
		label lblRange "Frame range:" align:#left across:3
		spinner spStart "" type:#integer fieldwidth:52 range:[-100000,100000,0]
		spinner spEnd   "to" type:#integer fieldwidth:52 range:[-100000,100000,100]

		button btnFromScene "Use Scene Range" width:120 height:17 align:#left across:2
		checkbox chkSaveBip "Save .bip" align:#right checked:false

		button btnBake "Bake To Selected Character" width:240 height:36 align:#center tooltip:"Sample BipGTA and write keys to GTA character bones"
	)

	-- State
	local figPath = undefined
	local dffPath = undefined

	on bakRoll open do (
		local iniVals = bakLoadIniPaths()
		figPath = iniVals[1]
		dffPath = iniVals[2]
		txtFig.text = figPath
		txtDff.text = dffPath
		local tpf = 4800 / frameRate
		spStart.value = (animationRange.start as integer) / tpf
		spEnd.value   = (animationRange.end   as integer) / tpf
	)

	on btnPickFig pressed do (
		local p = getOpenFileName caption:"Choose a biped figure file (*.fig)" types:"Biped Figure File (*.fig)|*.fig|"
		if p != undefined then (
			figPath = p
			txtFig.text = p
			bakSaveIniPaths figPath dffPath
		)
	)

	on btnPickDff pressed do (
		local p = getOpenFileName caption:"Choose GTA character DFF (*.dff)" types:"Character DFF (*.dff)|*.dff|"
		if p != undefined then (
			dffPath = p
			txtDff.text = p
			bakSaveIniPaths figPath dffPath
		)
	)

	on btnSetup pressed do (
		bakSetupRig figPath dffPath
	)

	on btnPostLoad pressed do (
		bakPostLoadSetup figPath
	)

	on btnFromScene pressed do (
		local tpf = 4800 / frameRate
		spStart.value = (animationRange.start as integer) / tpf
		spEnd.value   = (animationRange.end   as integer) / tpf
	)

	on btnBake pressed do (
		local savePath = undefined
		if chkSaveBip.checked then (
			savePath = getSaveFileName caption:"Save Source BIP" types:"Biped Animation (*.bip)|*.bip|"
			if savePath == undefined then return()
			if (getFileNameType savePath) != ".bip" then savePath += ".bip"
		)
		bakBake spStart.value spEnd.value savePath
	)
)

-- Open floater
if GTA_AnimBake_Floater != undefined then ( try (closeRolloutFloater GTA_AnimBake_Floater) catch () )
GTA_AnimBake_Floater = newRolloutFloater "GTA Anim Bake" 280 392
addRollout bakRoll GTA_AnimBake_Floater
