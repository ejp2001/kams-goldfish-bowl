-- GTA Skeleton Inspector
-- Dumps loaded character skeleton structure and bone orientations for diagnostics
-- Use this to understand target skeleton pivot/orientation before retargeting

fn GTAAnim_InspectSkeleton rootObj = (
	if rootObj == undefined then (
		messagebox "Please select a bone or root node from the loaded GTA character." title:"Skeleton Inspector"
		return undefined
	)

	format "\n"
	format "================================================================================\n"
	format "GTA SKELETON INSPECTION\n"
	format "================================================================================\n"
	format "Root: %\n" rootObj.name
	format "\n"

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
		
		format "%" indent
		format "|- % %\n" node.name boneIDStr
		
		try (
			local pos = node.pos
			format "%  pos: [%.3f, %.3f, %.3f]\n" indent pos.x pos.y pos.z
		) catch (
			format "%  pos: <error reading position>\n" indent
		)
		
		try (
			local parent = node.parent
			local parentStr = if parent != undefined then parent.name else "(world)"
			format "%  parent: %\n" indent parentStr
		) catch (
			format "%  parent: <error reading parent>\n" indent
		)
		
		try (
			local rot = node.rotation
			format "%  rot (quat): [%.4f, %.4f, %.4f, %.4f]\n" indent rot.x rot.y rot.z rot.w
		) catch (
			format "%  rot (quat): <error reading rotation>\n" indent
		)
		
		try (
			local worldPos = node.transform.pos
			local worldRot = node.transform.rotationpart
			format "%  world pos: [%.3f, %.3f, %.3f]\n" indent worldPos.x worldPos.y worldPos.z
		) catch (
			format "%  world pos: <error reading world transform>\n" indent
		)
		
		format "%\n" indent
		
		-- Add children to queue
		for child in node.children do (
			append queue #(child, depth + 1)
		)
	)
	
	format "================================================================================\n\n"
)

-- Run inspector on selected node or Root
if $selection.count > 0 then (
	GTAAnim_InspectSkeleton $selection[1]
) else (
	local sceneRoot = getNodeByName "Root"
	if sceneRoot != undefined then (
		GTAAnim_InspectSkeleton sceneRoot
	) else (
		messagebox "No selection and no 'Root' node found in scene." title:"Skeleton Inspector"
	)
)
