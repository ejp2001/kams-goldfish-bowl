-- GTA Skeleton Inspector v2
-- Dumps loaded character skeleton structure using simple string concatenation
-- Use with your GTA character loaded and Root selected

fn GTAAnim_InspectSkeleton rootObj = (
	if rootObj == undefined then (
		messagebox "Please select the Root node of your GTA character skeleton." title:"GTA Skeleton Inspector"
		return undefined
	)

	print "\n================================================================================"
	print "GTA SKELETON INSPECTION"
	print "================================================================================"
	print ("Root: " + rootObj.name)
	print ""

	local queue = #(#(rootObj, 0))  -- #(node, depth)
	
	while queue.count > 0 do (
		local pair = queue[1]
		deleteItem queue 1
		local node = pair[1]
		local depth = pair[2]
		
		local indent = ""
		for i = 1 to depth do indent += "  "
		
		local boneID = getUserProp node "BoneID"
		local boneIDStr = if boneID != undefined then (" [BoneID=" + (boneID as string) + "]") else ""
		
		print (indent + "|- " + node.name + boneIDStr)
		
		try (
			local pos = node.pos
			print (indent + "  pos: [" + (pos.x as string) + ", " + (pos.y as string) + ", " + (pos.z as string) + "]")
		) catch (
			print (indent + "  pos: <error>")
		)
		
		try (
			local parent = node.parent
			local parentStr = if parent != undefined then parent.name else "(world)"
			print (indent + "  parent: " + parentStr)
		) catch (
			print (indent + "  parent: <error>")
		)
		
		try (
			local rot = node.rotation
			print (indent + "  rot (quat): [" + (rot.x as string) + ", " + (rot.y as string) + ", " + (rot.z as string) + ", " + (rot.w as string) + "]")
		) catch (
			print (indent + "  rot (quat): <error>")
		)
		
		try (
			local worldPos = node.transform.pos
			print (indent + "  world pos: [" + (worldPos.x as string) + ", " + (worldPos.y as string) + ", " + (worldPos.z as string) + "]")
		) catch (
			print (indent + "  world pos: <error>")
		)
		
		print (indent + "")
		
		-- Add children to queue
		for child in node.children do (
			append queue #(child, depth + 1)
		)
	)
	
	print "================================================================================"
	print ""
)

-- Run on selected node
if $selection.count > 0 then (
	GTAAnim_InspectSkeleton $selection[1]
) else (
	print "Please select the Root or any node from your GTA character skeleton and run this script again."
)
