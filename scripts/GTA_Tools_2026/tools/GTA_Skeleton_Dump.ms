global GTA_Dump_GetBoneID
global GTA_Dump_FindBestRootFromNode
global GTA_Dump_FindSceneRoot
global GTA_Dump_BuildReport
global GTA_Dump_ToListener
global GTA_Dump_ToFile

fn GTA_Dump_GetBoneID node = (
    local boneID = undefined
    try (boneID = getUserProp node "BoneID") catch ()
    if boneID == undefined or boneID == "" then return undefined
    try (boneID as integer) catch (undefined)
)

fn GTA_Dump_NormalizeName rawName = (
    local value = toLower (rawName as string)
    value = substituteString value " " ""
    value = substituteString value "_" ""
    value = substituteString value "-" ""
    value = substituteString value "." ""
    value
)

fn GTA_Dump_IsOptionalBone nodeName = (
    local key = GTA_Dump_NormalizeName nodeName
    local optionalKeys = #(
        "lbreast", "rbreast", "leftbreast", "rightbreast",
        "belly", "jaw", "lbrow", "rbrow", "leftbrow", "rightbrow"
    )
    ((findItem optionalKeys key) > 0)
)

fn GTA_Dump_FormatFloat value = (
    formattedPrint value format:".4f"
)

fn GTA_Dump_FormatPoint pointValue = (
    "[" + (GTA_Dump_FormatFloat pointValue.x) + ", " + (GTA_Dump_FormatFloat pointValue.y) + ", " + (GTA_Dump_FormatFloat pointValue.z) + "]"
)

fn GTA_Dump_FormatEuler eulerValue = (
    "[" + (GTA_Dump_FormatFloat eulerValue.x) + ", " + (GTA_Dump_FormatFloat eulerValue.y) + ", " + (GTA_Dump_FormatFloat eulerValue.z) + "]"
)

fn GTA_Dump_GetLocalTM node = (
    if node.parent != undefined then (node.transform * (inverse node.parent.transform)) else node.transform
)

fn GTA_Dump_CollectHierarchy rootObj = (
    local out = #()
    if rootObj == undefined or (not (isValidNode rootObj)) then return out

    local queue = #(#(rootObj, 0))
    while queue.count > 0 do (
        local item = queue[1]
        deleteItem queue 1
        append out item
        for child in item[1].children do append queue #(child, item[2] + 1)
    )
    out
)

fn GTA_Dump_FindBestRootFromNode node = (
    if node == undefined or (not (isValidNode node)) then return undefined

    local current = node
    local best = undefined
    while current != undefined do (
        if (GTA_Dump_GetBoneID current) == 0 then best = current
        current = current.parent
    )

    if best != undefined then best else node
)

fn GTA_Dump_FindSceneRoot = (
    local roots = #()
    for obj in objects do (
        if (GTA_Dump_GetBoneID obj) == 0 then append roots obj
    )

    if roots.count == 0 then return undefined
    if roots.count == 1 then return roots[1]

    local preferredNames = #("root", "normal", "fat", "ripped")
    for preferred in preferredNames do (
        for rootObj in roots do (
            if (toLower rootObj.name) == preferred then return rootObj
        )
    )

    roots[1]
)

fn GTA_Dump_BuildReport rootObj = (
    if rootObj == undefined or (not (isValidNode rootObj)) then return undefined

    local report = stringStream ""
    local rows = GTA_Dump_CollectHierarchy rootObj
    local optionalCount = 0
    local coreCount = 0

    format "GTA Skeleton Dump\n" to:report
    format "Generated: %\n" (localTime as string) to:report
    format "Current Time: %\n" (currentTime as string) to:report
    format "Root Name: %\n" rootObj.name to:report
    format "Root BoneID: %\n" (GTA_Dump_GetBoneID rootObj) to:report
    format "Node Count: %\n\n" rows.count to:report
    format "Depth\tBoneID\tInclude\tNode\tParent\tLocalPos\tLocalRotEuler\n" to:report

    for row in rows do (
        local node = row[1]
        local depth = row[2]
        local boneID = GTA_Dump_GetBoneID node
        local includeTag = if GTA_Dump_IsOptionalBone node.name then "optional-no" else "core-yes"
        local parentName = if node.parent != undefined then node.parent.name else "(none)"
        local localTM = GTA_Dump_GetLocalTM node
        local localPos = localTM.row4
        local localRot = (localTM.rotationpart as eulerAngles)

        if includeTag == "optional-no" then optionalCount += 1 else coreCount += 1

        format "%\t%\t%\t%\t%\t%\t%\n" depth boneID includeTag node.name parentName (GTA_Dump_FormatPoint localPos) (GTA_Dump_FormatEuler localRot) to:report
    )

    format "\nCore Bones: %\n" coreCount to:report
    format "Optional Bones: %\n" optionalCount to:report
    format "\nNotes:\n" to:report
    format "- optional-no marks default exclusion candidates for shared ped animation use.\n" to:report
    format "- Root selection should be BoneID 0 first; names like Root/Normal/Fat/Ripped are useful aliases only.\n" to:report

    (report as string)
)

fn GTA_Dump_ToListener rootObj:undefined = (
    local resolvedRoot = rootObj
    if resolvedRoot == undefined then (
        if selection.count > 0 then resolvedRoot = GTA_Dump_FindBestRootFromNode selection[1]
        else resolvedRoot = GTA_Dump_FindSceneRoot()
    )

    local reportText = GTA_Dump_BuildReport resolvedRoot
    if reportText == undefined then (
        messageBox "No valid GTA root found. Select a hierarchy node or make sure a BoneID 0 root exists in the scene." title:"GTA Skeleton Dump"
        return false
    )

    clearListener()
    format "%" reportText
    true
)

fn GTA_Dump_ToFile rootObj:undefined outPath:undefined = (
    local resolvedRoot = rootObj
    if resolvedRoot == undefined then (
        if selection.count > 0 then resolvedRoot = GTA_Dump_FindBestRootFromNode selection[1]
        else resolvedRoot = GTA_Dump_FindSceneRoot()
    )

    local reportText = GTA_Dump_BuildReport resolvedRoot
    if reportText == undefined then (
        messageBox "No valid GTA root found. Select a hierarchy node or make sure a BoneID 0 root exists in the scene." title:"GTA Skeleton Dump"
        return false
    )

    local targetPath = outPath
    if targetPath == undefined then (
        targetPath = getSaveFileName caption:"Save GTA Skeleton Dump" filename:"gta_skeleton_dump.txt" types:"Text File (*.txt)|*.txt|All Files (*.*)|*.*|"
    )
    if targetPath == undefined then return false

    local outFile = createFile targetPath
    format "%" reportText to:outFile
    close outFile
    true
)

format "GTA Skeleton Dump loaded.\n"
format "Use GTA_Dump_ToListener() or GTA_Dump_ToFile().\n"
format "If you already selected a node under the GTA hierarchy, no arguments are needed.\n"