-- Launcher: safe loader for GTA_AnimationRig.ms
-- This runs at top-level and ensures the rig UI launcher is called from a global scope.

try (
    local scriptPath = getFilenamePath (getThisScriptFilename())
    local rigPath = scriptPath + "..\\GTA_AnimationRig.ms"
    rigPath = normalizePath rigPath

    if not (doesFileExist rigPath) then (
        -- try sibling folder (in case tools folder differs)
        rigPath = (getFilenamePath (getThisScriptFilename())) + "GTA_AnimationRig.ms"
        rigPath = normalizePath rigPath
    )

    if not (doesFileExist rigPath) then (
        messageBox ("Cannot find GTA_AnimationRig.ms at: " + rigPath) title:"Launcher Error"
    ) else (
        -- fileIn rig script (executes top-level defs)
        fileIn rigPath

        -- Diagnostics: avoid calling `isdefined` (it may be shadowed in this Max session)
        format "Launcher: fileIn completed.\n"

        -- Safely read the loaded flag using try/catch (won't call any possibly-shadowed function)
        local loadedVal = undefined
        try ( loadedVal = GTA_AnimationRig_loaded ) catch()
        format "Launcher: GTA_AnimationRig_loaded = %\n" loadedVal

        -- Safely test whether ShowGTAAnimationRigUI exists and is callable
        local uiCallable = false
        try (
            if (typeof ShowGTAAnimationRigUI == #function) then uiCallable = true
        ) catch()
        format "Launcher: ShowGTAAnimationRigUI callable: %\n" uiCallable

        -- Prefer explicit loaded flag if present and true
        if (loadedVal == true) then (
            if uiCallable then (
                try ( ShowGTAAnimationRigUI() ) catch ( messageBox ("Error calling ShowGTAAnimationRigUI():\n" + (getCurrentException())) title:"Launcher Error" )
            ) else (
                messageBox "GTA Animation Rig loaded but UI launcher not found or not callable (ShowGTAAnimationRigUI)" title:"Launcher Error"
            )
        ) else (
            -- fallback: try to call the UI function if it exists and is callable
            if uiCallable then (
                try ( ShowGTAAnimationRigUI() ) catch ( messageBox ("Error calling ShowGTAAnimationRigUI():\n" + (getCurrentException())) title:"Launcher Error" )
            ) else (
                messageBox "GTA Animation Rig failed to load or did not define callable UI launcher." title:"Launcher Error"
            )
        )
    )
) catch ( messageBox ("Launcher failed: " + (getCurrentException())) title:"Launcher Exception" )
