-- GTA_Script_Controller.ms
-- Centralized global variable declaration and initialization for all GTA Tools
-- This file is auto-generated and should be updated whenever a new global is added to any tool script.
-- Last updated: March 17, 2026

-- DFF IO Globals
global gDffIOMode = #shared
global DFFexPara = undefined
global pbMax = 0
global pbcount = 0
global bNVC = undefined
global chCol = undefined
global gUVpack = undefined
global gMeshFix = undefined
global gNvcDefolt = undefined
global gVcDefolt = undefined
global gValpha = undefined
global bModelInfo_rol = undefined
global errInfo_mass = undefined
global errInfo_mass_ = undefined
global isIplImport = false
global gTickTime = 0
global Dummysize = 0.1
global SAColBase = undefined
global bonechain = #()
global gfname = undefined

-- CHAR IO Globals
global charScriptPath = undefined
global LetsRockandRoll = undefined
global skn = undefined

-- DFFexp/DFFimp/DFFin/DFFout/CharDFFimp/CharDFFexp
-- (Some of these are re-used in multiple scripts)
global exp_lockDFF = undefined
global objExpName = undefined
global DFF2dfx_light_rol = undefined
global DFF2dfx_prt_rol = undefined
global DFF2dfx_sgn_rol = undefined
global DFF2dfx_stm_rol = undefined
global DFF2dfx_esc_rol = undefined
global DFF2dfx_light = undefined
global gUVAnimEnabled = true
global gUVAnimMaterialList = #()
global lightArr = #()
global dffExportCurMshName = undefined
global newHierarchyArr = #()
global lightArr_ = undefined
global impHas2dfx = undefined
global imp2dfxCount = undefined
global FrameAry = #()
global SkinData = #()
global implightErr = false
global gUVAnimDict = #()
global gUVAnimImportEnabled = true

global ibm = #()
global mtlflag = #()
global cntLDffNow = undefined
global cntLDffMax = undefined

global RFpos = [200,200]
global ideData = undefined
global pbideCount = undefined
global pbideMax = undefined

-- Add new globals here as needed

-- MUTEX: Close all tool floaters at startup to prevent conflicts
try (closeRolloutFloater Kam_GTA) catch ()
try (closeRolloutFloater IFP_IO_GTAsa) catch ()
-- Add more as needed
