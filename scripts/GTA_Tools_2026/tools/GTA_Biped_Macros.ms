-- Macros for GTA Biped two-step creation
-- Place this file in your scripts folder and fileIn it to register macros under 'GTA Tools'

macroScript GTA_CreateBiped_Step1
category:"GTA Tools"
tooltip:"Create Biped (Step 1)"
buttontext:"Create Biped"
(
    try (g) catch (g = GTAAnimRigSystem_v4())
    -- Default parameters; edit these values if you need different defaults
    local defaultHeight = 1.9
    local defaultZ = -90.0
    local defaultPos = [0,0,0.8]
    g.CreateBiped_Step1 defaultHeight defaultZ defaultPos
)

macroScript GTA_FinalizeBiped_Step2
category:"GTA Tools"
tooltip:"Finalize Biped (Step 2)"
buttontext:"Finalize Biped"
(
    try (g) catch (g = GTAAnimRigSystem_v4())
    local defaultHeight = 1.9
    g.CreateBiped_Step2 defaultHeight
)
