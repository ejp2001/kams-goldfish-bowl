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
global bakLegacyIniPath = bakScriptPath + "GTA_AnimBake.ini"
global bakIniPath = bakLegacyIniPath
global GTA_ACTIVE_RIG_ROOT
global GTA_ANIMBAKE_ALIGN_DUMMY
global bakRescaleToFig -- forward-declared: defined later in file; pre-declare so MaxScript 2017 resolves it as a global in bakPostLoadSetup

-- ---------------------------------------------------------------------------
-- BoneID-authoritative mapping (gtaBoneID -> bipBone).
-- ---------------------------------------------------------------------------
global GTA_BONEID_BIP_MAP = #(
	#(0,  "BipGTA"),
	#(1,  "BipGTA Pelvis"),
	#(2,  "BipGTA Spine"),
	#(3,  "BipGTA Spine1"),
	#(4,  "BipGTA Neck"),
	#(5,  "BipGTA Head"),
	#(31, "BipGTA L Clavicle"),
	#(32, "BipGTA L UpperArm"),
	#(33, "BipGTA L Forearm"),
	#(34, "BipGTA L Hand"),
	#(35, "BipGTA L Finger0"),
	#(36, "BipGTA L Finger01"),
	#(21, "BipGTA R Clavicle"),
	#(22, "BipGTA R UpperArm"),
	#(23, "BipGTA R Forearm"),
	#(24, "BipGTA R Hand"),
	#(25, "BipGTA R Finger0"),
	#(26, "BipGTA R Finger01"),
	#(41, "BipGTA L Thigh"),
	#(42, "BipGTA L Calf"),
	#(43, "BipGTA L Foot"),
	#(44, "BipGTA L Toe0"),
	#(51, "BipGTA R Thigh"),
	#(52, "BipGTA R Calf"),
	#(53, "BipGTA R Foot"),
	#(54, "BipGTA R Toe0")
)

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

fn bakTryWritableIniInDir baseDir =
(
	local d = bakNormalizePathSlashes baseDir
	if d == "" then return ""

	local settingsDir = d + "\\GTA_Tools_2026"
	try (makeDir settingsDir all:true) catch ()

	local candidate = settingsDir + "\\GTA_AnimBake.ini"
	local testStream = undefined
	try (testStream = openFile candidate mode:"a+") catch (testStream = undefined)
	if testStream != undefined then
	(
		close testStream
		return candidate
	)

	""
)

fn bakGetWritableIniPath =
(
	local candidate = ""

	try (candidate = bakTryWritableIniInDir (getDir #userScripts)) catch (candidate = "")
	if candidate != "" then return candidate

	try (candidate = bakTryWritableIniInDir (getDir #plugcfg)) catch (candidate = "")
	if candidate != "" then return candidate

	try (candidate = bakTryWritableIniInDir (getDir #maxData)) catch (candidate = "")
	if candidate != "" then return candidate

	try (candidate = bakTryWritableIniInDir (getDir #temp)) catch (candidate = "")
	if candidate != "" then return candidate

	local legacyTest = undefined
	try (legacyTest = openFile bakLegacyIniPath mode:"a+") catch (legacyTest = undefined)
	if legacyTest != undefined then
	(
		close legacyTest
		return bakLegacyIniPath
	)

	bakLegacyIniPath
)

fn bakGetIniSettingMerged sectionName keyName =
(
	local val = getINISetting bakIniPath sectionName keyName
	if val == "" and bakIniPath != bakLegacyIniPath then
	(
		val = getINISetting bakLegacyIniPath sectionName keyName
	)
	val
)

fn bakLoadFlatPathConfigFromFile iniPath =
(
	local figVal = ""
	local dffVal = ""

	if doesFileExist iniPath then
	(
		local f = openFile iniPath mode:"rt"
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

fn bakLoadFlatPathConfig =
(
	local vals = bakLoadFlatPathConfigFromFile bakIniPath
	if (vals[1] == "" and vals[2] == "" and bakIniPath != bakLegacyIniPath) then
	(
		vals = bakLoadFlatPathConfigFromFile bakLegacyIniPath
	)
	vals
)

fn bakWriteFlatPathConfig figVal dffVal =
(
	if bakIniPath == "" or bakIniPath == bakLegacyIniPath do
	(
		bakIniPath = bakGetWritableIniPath()
	)

	local f = createFile bakIniPath
	if f == undefined then
	(
		local fallback = ""
		try (fallback = bakTryWritableIniInDir (getDir #temp)) catch (fallback = "")
		if fallback != "" then
		(
			bakIniPath = fallback
			f = createFile bakIniPath
		)
	)

	if f != undefined then
	(
		format "FigureFile=%\n" (bakPathToConfig figVal) to:f
		format "CharacterDFF=%\n" (bakPathToConfig dffVal) to:f
		close f
	)
)

fn bakLoadIniPaths =
(
	bakIniPath = bakGetWritableIniPath()
	format "[AnimBake] INI path: %\n" bakIniPath
	local figVal = bakGetIniSettingMerged "Paths" "FigureFile"
	local dffVal = bakGetIniSettingMerged "Paths" "CharacterDFF"
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

fn bakSetLinearDefaultTangents =
(
	-- Keep new keys linear for this session's bake workflow.
	try (inTangentType = #linear) catch ()
	try (outTangentType = #linear) catch ()
	true
)

fn bakClearRigAnimationKeys rigRoot =
(
	if rigRoot == undefined then return 0
	local cleared = 0
	for n in (bakCollectHierarchy rigRoot) do
	(
		try (deletekeys n.rotation.controller; cleared += 1) catch ()
		try (deletekeys n.pos.controller; cleared += 1) catch ()
		try (deletekeys n.scale.controller; cleared += 1) catch ()
	)
	cleared
)

fn bakControllerKeyRange ctrl =
(
	if ctrl == undefined then return undefined
	local keyCount = 0
	try (keyCount = numKeys ctrl) catch (keyCount = 0)
	if keyCount < 1 then return undefined

	local minT = undefined
	local maxT = undefined
	for k = 1 to keyCount do
	(
		local kt = undefined
		try (kt = getKeyTime ctrl k) catch (kt = undefined)
		if kt != undefined then
		(
			if minT == undefined or kt < minT then minT = kt
			if maxT == undefined or kt > maxT then maxT = kt
		)
	)
	if minT == undefined then undefined else #(minT, maxT)
)

fn bakMergeTimeRange a b =
(
	if a == undefined then return b
	if b == undefined then return a
	#(amin #(a[1], b[1]), amax #(a[2], b[2]))
)

fn bakGetBipedAnimRange pairs bipRoot =
(
	local nodes = #()
	if bipRoot != undefined then append nodes bipRoot
	for p in pairs do
	(
		local bn = p[2]
		if bn != undefined and (findItem nodes bn) == 0 then append nodes bn
	)

	local rng = undefined
	for n in nodes do
	(
		if isProperty n #transform then
			rng = bakMergeTimeRange rng (bakControllerKeyRange n.transform.controller)
		if isProperty n #rotation then
			rng = bakMergeTimeRange rng (bakControllerKeyRange n.rotation.controller)
		if isProperty n #pos then
			rng = bakMergeTimeRange rng (bakControllerKeyRange n.pos.controller)
	)

	if rng == undefined then interval animationRange.start animationRange.end
	else interval rng[1] rng[2]
)

fn bakGetCurrentBipedAnimRange bipRoot =
(
	if bipRoot == undefined then return interval animationRange.start animationRange.end

	local nodes = #(bipRoot)
	for pair in GTA_BONEID_BIP_MAP do
	(
		local bn = bakResolveBipNode pair[2] bipRoot
		if bn != undefined and (findItem nodes bn) == 0 then append nodes bn
	)

	local rng = undefined
	for n in nodes do
	(
		if isProperty n #transform then
			rng = bakMergeTimeRange rng (bakControllerKeyRange n.transform.controller)
		if isProperty n #rotation then
			rng = bakMergeTimeRange rng (bakControllerKeyRange n.rotation.controller)
		if isProperty n #pos then
			rng = bakMergeTimeRange rng (bakControllerKeyRange n.pos.controller)
	)

	if rng == undefined then interval animationRange.start animationRange.end
	else interval rng[1] rng[2]
)

fn bakFormatAnimationLength rng =
(
if rng == undefined then return "0 frames"
local startF = (rng.start as integer) / ticksPerFrame
local endF = (rng.end as integer) / ticksPerFrame
local len = (endF - startF + 1)
if len < 0 then len = 0
(len as string) + " frames"
)

fn bakGetCurrentBipedAnimSignature bipRoot =
(
	if bipRoot == undefined then return ""

	local nodes = #(bipRoot)
	for pair in GTA_BONEID_BIP_MAP do
	(
		local bn = bakResolveBipNode pair[2] bipRoot
		if bn != undefined and (findItem nodes bn) == 0 then append nodes bn
	)

	local totalKeys = 0
	for n in nodes do
	(
		if isProperty n #transform then try (totalKeys += numKeys n.transform.controller) catch ()
		if isProperty n #rotation then try (totalKeys += numKeys n.rotation.controller) catch ()
		if isProperty n #pos then try (totalKeys += numKeys n.pos.controller) catch ()
	)

	local rng = bakGetCurrentBipedAnimRange bipRoot
	((rng.start as integer) as string) + "|" + ((rng.end as integer) as string) + "|" + (totalKeys as string)
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

	-- Dummy anchors translation and provides a 180-degree Z rotation to flip the
	-- animation for GTA's reversed coordinate convention.
	-- Move to frame 0 first so the biped is at its rest position, not wherever
	-- the timeline happened to be when the button was clicked.
	sliderTime = 0
	local dmy = dummy name:"AnimBake_AlignDummy" boxsize:[0.75,0.75,0.75] wirecolor:(color 255 140 0)
	dmy.pos = bipRoot.transform.row4
	dmy.rotation = quat 0 0 0 1

	local rootTM = bipRoot.transform
	bipRoot.parent = dmy
	bipRoot.transform = rootTM

	dmy.position = [0,0,0]
	-- Rotate dummy 180 degrees around Z: GTA animations run reversed.
	dmy.rotation = (eulerAngles 0 0 180) as quat
	GTA_ANIMBAKE_ALIGN_DUMMY = dmy
	animationRange = bakGetCurrentBipedAnimRange bipRoot
	-- Select the dummy so the user can adjust it without accidentally
	-- grabbing the biped root, which sits at the same position.
	select dmy
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
--  Import Character DFF  (non-destructive: does not reset scene or create biped)
-- ---------------------------------------------------------------------------
fn bakImportCharDFF dffPath =
(
	if DFFin == undefined then
	(
		messageBox "DFFin is undefined. CharDFFimp.ms may not have loaded." title:"Import Character"
		return false
	)

	local dffFile = dffPath
	if dffFile == undefined or dffFile == "" or not doesFileExist dffFile then
	(
		messageBox ("DFF not found:\n" + (if dffFile != undefined then dffFile else "(none)")) title:"Import Character"
		return false
	)

	global LetsRockandRoll = true
	local f = fopen dffFile "rb"
	if f == undefined then
	(
		messageBox ("Cannot open: " + dffFile) title:"Import Character"
		return false
	)

	local impErr = undefined
	try
	(
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
	)
	catch
	(
		impErr = (getCurrentException() as string)
	)
	fclose f

	if impErr != undefined then
	(
		messageBox ("DFF import failed:\n\n" + impErr) title:"Import Character"
		return false
	)

	-- Cache whichever rig root was just imported, if unambiguous.
	local roots = bakFindRigRootsInScene()
	if roots.count == 1 then GTA_ACTIVE_RIG_ROOT = roots[1]

	gc()
	format "[AnimBake] Character imported: %\n" dffFile
	true
)

-- ---------------------------------------------------------------------------
--  Bake
-- ---------------------------------------------------------------------------
fn bakBake saveBipPath =
(
	-- Bake uses the detected biped animation range.
	local bipRoot = bakFindBipRoot()
	if bipRoot == undefined then (
	messageBox "No biped found in scene. Create a biped and load an animation first." title:"Bake"
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

	-- Before baking, clear GTA keys and fit timeline to biped animation range.
	bakClearRigAnimationKeys rigRoot
	local bipRange = bakGetBipedAnimRange pairs bipRoot
	animationRange = bipRange
	local startF = (animationRange.start as integer) / ticksPerFrame
	local endF = (animationRange.end as integer) / ticksPerFrame

	format "[AnimBake] Baking % pairs, frames % to %\n" pairs.count startF endF

	-- Ensure all GTA bones have Euler_XYZ rotation controllers so x/y/z_rotation
	-- channels exist.  CharDFFimp may leave Bezier or TCB controllers in place.
	for pair in pairs do
	(
		local gn = pair[1]
		if classof gn.rotation.controller != Euler_XYZ then
			gn.rotation.controller = Euler_XYZ()
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
	format "%\n" report
	messageBox report title:"Bake Complete"
	true
)


-- ---------------------------------------------------------------------------
--  Create or Reset Biped  (works even when no biped exists in scene)
-- ---------------------------------------------------------------------------
fn bakCreateOrResetBiped figPath =
(
	-- Remove all existing Biped_Object nodes
	local bipObjs = for obj in objects where classof obj == Biped_Object collect obj
	for obj in bipObjs do if isValidNode obj then try (delete obj) catch ()

	-- Remove align dummies
	local oldDummies = for n in objects where matchPattern n.name pattern:"AnimBake_AlignDummy*" collect n
	for n in oldDummies do if isValidNode n then try (delete n) catch ()
	if GTA_ANIMBAKE_ALIGN_DUMMY != undefined and isValidNode GTA_ANIMBAKE_ALIGN_DUMMY then
		try (delete GTA_ANIMBAKE_ALIGN_DUMMY) catch ()
	GTA_ANIMBAKE_ALIGN_DUMMY = undefined
	GTA_ACTIVE_RIG_ROOT = undefined

	-- Create new biped at origin
	-- biped.createNew <height> <angle> <pos> is the correct MaxScript API
	local bipCOM = undefined
	try ( bipCOM = biped.createNew 170 0 [0,0,0] ) catch ()
	if bipCOM == undefined then (
		messageBox "Failed to create biped.\n\nbiped.createNew returned undefined.\nCheck the MaxScript Listener for details." title:"Load/Reset Biped"
		return false
	)
	local bipRoot = bipCOM.controller.rootNode

	-- Apply .fig proportions to set correct GTA proportions
	if figPath != undefined and figPath != "" and doesFileExist figPath then (
		local rescaleOK = bakRescaleToFig figPath bipRoot
		if not rescaleOK then format "[AnimBake] WARNING: fig rescale failed; continuing.\n"
	) else if figPath != undefined and figPath != "" then (
		format "[AnimBake] WARNING: fig file not found: %\n" figPath
	)

	-- Explicitly re-centre biped at world origin (fig load can shift position)
	try ( in coordsys world bipCOM.pos = [0,0,0] ) catch ()

	-- Select biped COM so user can load animation directly via Motion panel
	select bipCOM
	format "[AnimBake] Fresh biped created at world origin. Load an animation, then click 'Apply Fig && Center Biped'.\n"
	true
)

-- ---------------------------------------------------------------------------
--  UI
-- ---------------------------------------------------------------------------
global GTA_AnimBake_Floater

rollout bakRoll "GTA Anim Bake"
(
	-- 1. Setup
	group "1. Setup"
	(
		label lblFig "Biped Figure File (*.fig):" align:#left
		editText txtFig "" fieldwidth:210 readOnly:true
		button btnPickFig "..." width:25 height:17 align:#right offset:[0,-21] tooltip:"Pick BipGTA.fig"
		button btnResetBiped "Load / Reset Biped" width:240 height:28 align:#center tooltip:"Delete any existing biped and align dummy; create a fresh biped at world origin and apply the selected .fig."

		label lblDff "Character DFF (*.dff):" align:#left offset:[0,4]
		editText txtDff "" fieldwidth:210 readOnly:true
		button btnPickDff "..." width:25 height:17 align:#right offset:[0,-21] tooltip:"Pick GTA character DFF"
		button btnImportDff "Import GTA Character DFF" width:240 height:22 align:#center tooltip:"Import GTA character DFF into the current scene"
	)

	-- 2. Animation
	group "2. Animation"
	(
		button btnLoadAnim "How to load animation (click for help)" width:240 height:22 align:#center tooltip:"Instructions for loading a BIP or motion capture animation onto the biped"
		button btnApplyFig "Apply Fig && Center Biped" width:240 height:28 align:#center tooltip:"Re-apply .fig proportions and re-centre biped under align dummy."
		editText txtAnimLen "Animation length:" fieldwidth:100 readOnly:true align:#right offset:[0,2]
	)

	-- 3. Bake
	group "3. Bake"
	(
		button btnBake "Bake To Selected Character" width:240 height:36 align:#center tooltip:"Sample biped and write keys to GTA character bones"
		checkbox chkSaveBip "Save .bip" align:#right checked:false
	)

	-- State
	local figPath = undefined
	local dffPath = undefined

	on bakRoll open do
	(
		local iniVals = bakLoadIniPaths()
		figPath = iniVals[1]
		dffPath = iniVals[2]
		txtFig.text = figPath
		txtDff.text = dffPath
		txtAnimLen.text = bakFormatAnimationLength animationRange
	)

	on btnPickFig pressed do
	(
		local p = getOpenFileName caption:"Choose a biped figure file (*.fig)" types:"Biped Figure File (*.fig)|*.fig|"
		if p != undefined then
		(
			figPath = p
			txtFig.text = p
			bakSaveIniPaths figPath dffPath
		)
	)

	on btnPickDff pressed do
	(
		local p = getOpenFileName caption:"Choose GTA character DFF (*.dff)" types:"Character DFF (*.dff)|*.dff|"
		if p != undefined then
		(
			dffPath = p
			txtDff.text = p
			bakSaveIniPaths figPath dffPath
		)
	)

	on btnImportDff pressed do
	(
		bakImportCharDFF dffPath
	)

	on btnResetBiped pressed do
	(
		if bakCreateOrResetBiped figPath then
			txtAnimLen.text = bakFormatAnimationLength animationRange
	)

	on btnApplyFig pressed do
	(
		if bakPostLoadSetup figPath then
			txtAnimLen.text = bakFormatAnimationLength animationRange
	)

	on btnLoadAnim pressed do
	(
		messageBox ("To load an animation onto the biped:\n\n" + \
			"Option A — BIP file:\n" + \
			"  Select the biped COM (BipGTA or Bip01).\n" + \
			"  Motion panel > Biped rollout > Load File (.bip).\n\n" + \
			"Option B — Motion capture (.bvh / .csm / .htr etc):\n" + \
			"  Select the biped COM.\n" + \
			"  Motion panel > Biped rollout > Motion Capture.\n\n" + \
			"After loading, click \"Apply Fig && Center Biped\" to\n" + \
			"restore GTA proportions and re-centre the rig.") \
			title:"How to load animation"
	)

	on btnBake pressed do
	(
		local savePath = undefined
		if chkSaveBip.checked then
		(
			savePath = getSaveFileName caption:"Save Source BIP" types:"Biped Animation (*.bip)|*.bip|"
			if savePath == undefined then return()
			if (getFileNameType savePath) != ".bip" then savePath += ".bip"
		)
		local bakeOK = bakBake savePath
		if bakeOK then
			txtAnimLen.text = bakFormatAnimationLength animationRange
	)
)

-- Open floater
if GTA_AnimBake_Floater != undefined then ( try (closeRolloutFloater GTA_AnimBake_Floater) catch () )
GTA_AnimBake_Floater = newRolloutFloater "GTA Anim Bake" 280 400
addRollout bakRoll GTA_AnimBake_Floater




