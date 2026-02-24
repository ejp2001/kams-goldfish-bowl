-- GTA Character Import/Export Tools
-- For SKINNED CHARACTER models and skeletal animations ONLY
-- 
-- For world objects (props, doors, vehicles, etc.), use GTA_DFF_IO.ms
--
-- Original by Kam (2005)
-- Modified by E2001 (2024-2026)
--
-- Uses 2005 original for BOTH import and export (seamless, proven workflow)

-- MUTEX: Close other DFF tools to prevent global variable conflicts
try (closeRolloutFloater Kam_GTA) catch ()

-- Get script directory for relative paths
global charScriptPath = getFilenamePath(getThisScriptFilename())

-- Import: Community-improved CharDFFimp.ms (CharR namespace, better materials)
fileIn (charScriptPath + "CharDFFimp.ms") quiet:true

-- Bypass z-modeler lock and non-standard DFF checks (hidden feature)
-- MUST be set AFTER loading CharDFFimp.ms which resets it to undefined
global LetsRockandRoll = True  -- Capital T to match CharDFFimp.ms comparison

-- Export: Use 2005 original (seamless, no seams) - now in same folder
fileIn (charScriptPath + "CharDFFexp.ms") quiet:true

-- Settings persistence functions
fn SaveImportSettings matTypeVal texTypeVal scaleVal = (
	try (
		local iniFile = scriptsPath + "GTA_Tools_2026\\settings.ini"
		setINISetting iniFile "Import_Shared" "mattype" (matTypeVal as string)
		setINISetting iniFile "Import_Shared" "textype" (texTypeVal as string)
		setINISetting iniFile "Character_Import" "scale" (scaleVal as string)
		format "Character settings saved: mattype=% textype=% scale=%\n" matTypeVal texTypeVal scaleVal
	) catch (
		format "Error saving character import settings: %\n" (getCurrentException())
	)
)

fn LoadImportSettings = (
	try (
		local iniFile = scriptsPath + "GTA_Tools_2026\\settings.ini"
		local matVal = getINISetting iniFile "Import_Shared" "mattype"
		local texVal = getINISetting iniFile "Import_Shared" "textype"
		local scaleVal = getINISetting iniFile "Character_Import" "scale"
		
		local result = #(1, 3, 1.0)  -- Defaults: GTA material, PNG, 1.0 scale
		
		if matVal != "" then result[1] = matVal as integer
		if texVal != "" then result[2] = texVal as integer
		if scaleVal != "" then result[3] = scaleVal as float
		
		format "Character settings loaded: mattype=% textype=% scale=%\n" result[1] result[2] result[3]
		return result
	) catch (
		format "Error loading character import settings, using defaults\n"
		return #(1, 3, 1.0)  -- Defaults
	)
)

/*
=============================================================================
   SECTION 1: CHARACTER DFF IMPORT
   Uses: CharDFFimp.ms (2005 ORIGINAL - proven character workflow)
   Status: Loads from original mse files decrypted folder
=============================================================================
*/

-- ===========================
-- ROLLOUT 1: DFF IMPORT
-- ===========================
rollout importRoll "Import" (
		radioButtons textype "Texture:" labels:#("TGA", "BMP", "PNG") columns:3 default:3 align:#center tooltip:"Texture file extension (.tga, .bmp, or .png)"
		radioButtons materialType "Material:" labels:#("GTA Material", "Standard") columns:2 default:1 align:#center tooltip:"GTA Material (supports 2dfx) or Standard (Max native)"
		spinner impScale "Import Scale:" fieldwidth:42 range:[0,100,1.0] align:#left tooltip:"Scale multiplier (1.0=game size, 10.0=easier to edit)"
		button loaddff "Import Character DFF" width:200 height:28 align:#center tooltip:"Import skinned character with Skin modifier and bone weights"
		checkbox sdtl "Show verbose output in listener." checked:false align:#center

	
	-- ===========================
	-- EVENT HANDLERS - IMPORT
	-- ===========================
	
	-- Load saved settings on rollout open
	on importRoll open do (
		local settings = LoadImportSettings()
		materialType.state = settings[1]
		textype.state = settings[2]
		impScale.value = settings[3]
	)
	
	-- Save settings when changed
	on materialType changed state do (
		SaveImportSettings materialType.state textype.state impScale.value
	)
	
	on textype changed state do (
		SaveImportSettings materialType.state textype.state impScale.value
	)
	
	on impScale changed val do (
		SaveImportSettings materialType.state textype.state impScale.value
	)
	
	-- Load saved settings on rollout open
	on importRoll open do (
		local settings = LoadImportSettings()
		materialType.state = settings[1]
		textype.state = settings[2]
		impScale.value = settings[3]
	)
	
	-- Save settings when changed
	on materialType changed state do (
		SaveImportSettings materialType.state textype.state impScale.value
	)
	
	on textype changed state do (
		SaveImportSettings materialType.state textype.state impScale.value
	)
	
	on impScale changed val do (
		SaveImportSettings materialType.state textype.state impScale.value
	)
	
	-- Import DFF with character-specific options

		-- Import DFF with character-specific options
		on loaddff pressed do (
			fname = getopenfilename caption:"Read Character DFF File" types:"Character DFF (*.dff)|*.dff|"
			if fname != undefined then (
				f = fopen fname "rb"
				if f == undefined then ( 
					Messagebox "Can't open the file!" title:"I/O Error" 
				) else (
					-- Get texture extension from radio button
					local texExt = case textype.state of (
						1: ".tga"
						2: ".bmp"
						3: ".png"
					)
					-- Get material type (1 = GTA Material, 2 = Standard)
					local matType = materialType.state  -- Direct: radio 1 -> GTA, radio 2 -> Standard
					format "Material Type Selected: % (1=GTA, 2=Standard)\n" matType
					-- Call DFFin from CharDFFimp.ms with scale
					DFFin f impScale.value matType texExt 0.1 true importRoll.sdtl.checked (getFilenameFile fname)
				)
				fclose f
				gc()
			)
		)
)--end rollout importRoll

/*
=============================================================================
   SECTION 2: CHARACTER DFF EXPORT
   Uses: CharDFFexp.ms (2005 original)
   Status: Working correctly with 2005 seamless export
=============================================================================
*/

-- ===========================
-- ROLLOUT 2: EXPORT
-- ===========================
rollout exportRoll "Export" (
	radioButtons expVersion "Game Version:" labels:#("GTA3", "VC", "SA") columns:3 default:3 align:#center
	spinner expScale "Export Scale:" fieldwidth:42 range:[0,100,1.0] align:#left
	checkbox MMC "Modulate Material Color" align:#left checked:true
	checkbox TUV "Texture UV" align:#left checked:true
	checkbox NOR "Normals" align:#left checked:true
	checkbox CPV "Vertex Prelighting" align:#left checked:false
	button savedff "Export Character DFF" width:200 height:28 align:#center tooltip:"Export skinned character model"
	
	-- ===========================
	-- EVENT HANDLERS - EXPORT
	-- ===========================
	
	-- Normals and Vertex Prelighting are mutually exclusive
	on NOR changed state do (
		if state == true then CPV.checked = false
	)
	
	on CPV changed state do (
		if state == true then NOR.checked = false
	)
	
	-- Export Character DFF
	on savedff pressed do (
		if $selection.count != 1 then (
			messagebox "Select exactly one skinned character to export!" title:"Selection Error"
		) else if (classof $.modifiers[1] != skin) then (
			messagebox "This object is not skinned correctly!\nSkin modifier must be on the topmost of the stack!!" title:"Skin Error"
		) else (
			fname = getsavefilename caption:"Save Character DFF File" types:"Character DFF (*.dff)|*.dff|"
			if fname != undefined then (
				-- Determine game version
				local ver = case expVersion.state of (
					1: 0x0800FFFF  -- GTA3
					2: 0x0C02FFFF  -- VC
					3: 0x1803FFFF  -- SA
				)
				
				-- Prepare for export
				max modify mode
				local bkup = $.name
				$.name = "CharExpTemp"
				global skn = $.modifiers[1]
				local boneCount = skinOps.getNumberBones skn
				local boneReady = true
				global bonechain = #()
				
				-- Collect bones
				for i = 1 to boneCount do (
					local tmp = skinOps.getBoneName skn i 0
					local tt = "getUserProp $'" + tmp + "' \"BoneType\""
					if (execute tt) == undefined then (
						boneReady = false
						exit
					)	
					tt = "getUserProp $'" + tmp + "' \"BoneID\""
					local BID = execute tt
					if BID == undefined then (
						boneReady = false
						exit
					)
					local tb = "append bonechain $'" + tmp + "'"
					execute tb
				)
				$.name = bkup
				
				-- Sort bones by BoneIndex
				bonechain = BoneArybyIndex bonechain
				
				if (boneReady == false)OR(bonechain == undefined) then (
					messagebox "You didn't set BoneIDs/BoneTypes properly!\nEach bone must have 'BoneID' & 'BoneType' in it's User Properties." title:"BoneID/BoneType Error"
				) else (
					-- Verify all vertices have skin weights
					for i = 1 to $.numverts do (
						if skinOps.GetVertexWeightCount skn i == 0 then (
							boneReady = false
							exit
						)
					)
					
					if boneReady == false then (
						messagebox "You didn't set Skin/Vertices properly!\nEach Vertex must be influenced by at least 1 Bone." title:"Skin Error"
					) else (
						try (
							f = fopen fname "wb"
							if f == undefined then (
								Messagebox "Can't create the file!" title:"I/O Error"
							) else (
								-- Call wCharDFFout from CharDFFexp.ms
								wCharDFFout f $ bonechain MMC.checked TUV.checked CPV.checked NOR.checked expScale.value ver 0 false
								fclose f
								format "Character DFF exported successfully!\n"
							)
						) catch (
							try (fclose f) catch()
							messagebox ("Error exporting DFF:\n" + (getCurrentException())) title:"Export Error"
						)
						gc()
					)
				)
			)
		)
	)
)--end rollout exportRoll


/*
=============================================================================
   SECTION 3: DUMMIES/BONES HELPER
=============================================================================
*/

-- ===========================
-- ROLLOUT 3: DUMMIES/BONES HELPER
-- ===========================
rollout dmyHelper "Dummies/Bones Helper" (
	spinner dmyboxsize "Size: " range:[0.00000001,100000,10.0]
	button dmyasBox "Box" width:40 tooltip:"Show Dummies/bones as box" align:#left across:3
	button dmynLink "Link" width:40 tooltip:"Show Dummies/bones as box with Links" align:#center	
	button dmyasBone "Bone" width:40 tooltip:"Show Dummies/bones as bone" align:#right

	on dmyboxsize changed val do (
		for dmy in $selection where classof dmy == Dummy do (
			dmy.boxsize = [val,val,val]
		)	
	)

	on dmyasBox pressed do (
		for dmy in $selection where classof dmy == Dummy do (
			dmy.showLinksOnly = false
			dmy.showLinks = false
		)
		forceCompleteRedraw()
	)
	on dmynLink pressed do (
		for dmy in $selection where classof dmy == Dummy do (
			dmy.showLinksOnly = false
			dmy.showLinks = true
		)
		forceCompleteRedraw()
	)
	
	on dmyasBone pressed do (
		for dmy in $selection where classof dmy == Dummy do dmy.showLinksOnly = true
		forceCompleteRedraw()
	)
)--end rollout dmyHelper

/*
=============================================================================
   SECTION 4: ABOUT
=============================================================================
*/

-- ===========================
-- ROLLOUT 4: ABOUT
-- ===========================
rollout aboutRoll "About" (
	label l1 "GTA Character IO V3"
	label l1a "February, 2026"
	label l2 "Code based on Kam's original DFF/IFP tools"
	label l2a "and various other sources."
	label l2b ""
	label l3 "as much as I could affect"
	label l3a "without an encryption key"
)

/*
=============================================================================
   FLOATER CREATION
=============================================================================
*/

if Kam_GTA != undefined then ( closeRolloutFloater Kam_GTA; gc() )
Kam_GTA = newRolloutFloater "Character IO" 200 400 10 30
addRollout importRoll Kam_GTA
addRollout exportRoll Kam_GTA
addRollout dmyHelper Kam_GTA rolledup:true
addRollout aboutRoll Kam_GTA rolledup:true