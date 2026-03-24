-- Skeleton Bone Analyzer - Clean Flat Output
-- Shows key bones with rotations and parents for side-by-side comparison

fn GTAAnim_NormalizeName s = (
	local t = s as string
	while (t.count > 0 and (substring t 1 1) == " ") do (
		t = substring t 2 (t.count - 1)
	)
	while (t.count > 0 and (substring t t.count 1) == " ") do (
		t = substring t 1 (t.count - 1)
	)
	(toLower t)
)

fn GTAAnim_AnalyzeCriticalBones rootObj = (
	if rootObj == undefined then (
		messagebox "Select Root or any bone." title:"Bone Analyzer"
		return undefined
	)

	-- Aliases per critical bone (normalized lowercase)
	local criticalBones = #(
		#("Root", #("root", "hips")),
		#("Pelvis", #("pelvis", "hip", "hips")),
		#("Spine", #("spine", "spine0")),
		#("Spine1", #("spine1", "spine2", "chest")),
		#("Neck", #("neck")),
		#("Head", #("head")),
		#("L UpperArm", #("l upperarm", "leftarm", "left upperarm", "bip01 l upperarm")),
		#("R UpperArm", #("r upperarm", "rightarm", "right upperarm", "bip01 r upperarm")),
		#("L Thigh", #("l thigh", "leftupleg", "left thigh")),
		#("R Thigh", #("r thigh", "rightupleg", "right thigh")),
		#("L Foot", #("l foot", "leftfoot", "left foot")),
		#("R Foot", #("r foot", "rightfoot", "right foot"))
	)
	
	print "\n================================================================================"
	print "CRITICAL BONES ANALYSIS"
	print "================================================================================"
	print ""
	
	-- Walk up to find root
	local currentNode = rootObj
	while currentNode.parent != undefined do (
		currentNode = currentNode.parent
	)
	
	-- Build flat dict of all bones
	local allBones = #()
	local queue = #(currentNode)
	
	while queue.count > 0 do (
		local node = queue[1]
		deleteItem queue 1
		append allBones node
		for child in node.children do append queue child
	)
	
	-- Print critical bones only
	for boneSpec in criticalBones do (
		local boneName = boneSpec[1]
		local aliases = boneSpec[2]
		local found = false
		for node in allBones do (
			local nodeNorm = GTAAnim_NormalizeName node.name
			if (findItem aliases nodeNorm) > 0 then (
				found = true
				local rot = node.rotation
				local parent = if node.parent != undefined then (GTAAnim_NormalizeName node.parent.name) else "(world)"
				local pos = node.pos
				
				print ("Bone: " + boneName)
				print ("  Matched Node: " + node.name)
				print ("  Parent: " + parent)
				print ("  Pos: [" + (pos.x as string) + ", " + (pos.y as string) + ", " + (pos.z as string) + "]")
				print ("  Quat X: " + (rot.x as string))
				print ("  Quat Y: " + (rot.y as string))
				print ("  Quat Z: " + (rot.z as string))
				print ("  Quat W: " + (rot.w as string))
				print ""
				exit
			)
		)
		if not found then print ("WARNING: " + boneName + " not found\n")
	)
	
	print "================================================================================"
	print ""
)

-- Run on selected node
if $selection.count > 0 then (
	GTAAnim_AnalyzeCriticalBones $selection[1]
) else (
	print "Please select any bone and run this script."
)
