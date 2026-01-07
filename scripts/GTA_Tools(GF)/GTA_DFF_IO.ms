global DFF2dfx
global DFFexPara
global pbMax = 0 
global pbcount = 0 
Global bNVC
Global chCol
Global gUVpack
Global gMeshFix
Global gNvcDefolt
Global gVcDefolt
Global gValpha 
Global bModelInfo_rol
global errInfo_mass
global errInfo_mass_
global isIplImport = false

-- Load IFP export/import functions if not already loaded
if IFPioInfo == undefined then fileIn (scriptspath+"\\GTA_Tools(GF)\\gtaIFPio_Fn.ms") quiet:true 
else if IFPioInfo() != 051014 then fileIn (scriptspath+"\\GTA_Tools(GF)\\gtaIFPio_Fn.ms") quiet:true

fn pbUpdate = (
	pbcount += 1
	DFFexPara.pb.value = (((pbcount as float)/pbMax)*100)
)

-- Detect if DFF contains skin data (character model vs world object)
-- Opens its own file handle to avoid interfering with import
fn hasSkinData filePath = (
	local testFile = fopen filePath "rb"
	if testFile == undefined then (
		return false
	)
	
	local hasSkin = false
	
	try (
		-- Get file size
		fseek testFile 0 #seek_end
		local fileSize = ftell testFile
		fseek testFile 0 #seek_set
		
		-- Read and validate root CLUMP chunk
		if (ftell testFile + 12) > fileSize then (
			fclose testFile
			return false
		)
		
		local clumpID = readlong testFile #unsigned
		local clumpSize = readlong testFile #unsigned
		local clumpVersion = readlong testFile #unsigned
		
		if clumpID != 0x10 then (  -- Not a DFF
			fclose testFile
			return false
		)
		
		local clumpEnd = ftell testFile + clumpSize
		if clumpEnd > fileSize then clumpEnd = fileSize
		
		-- Scan top-level chunks in CLUMP
		while (ftell testFile + 12) <= clumpEnd and not hasSkin do (
			local pos = ftell testFile
			local chunkID = readlong testFile #unsigned
			local chunkSize = readlong testFile #unsigned
			local chunkVersion = readlong testFile #unsigned
			local chunkEnd = ftell testFile + chunkSize
			
			if chunkEnd > fileSize then (
				break
			)
			
			-- Check if this is GeometryList (0x1A)
			if chunkID == 0x1A then (
				-- Scan chunks inside GeometryList
				while (ftell testFile + 12) <= chunkEnd and not hasSkin do (
					local geoPos = ftell testFile
					local geoID = readlong testFile #unsigned
					local geoSize = readlong testFile #unsigned
					local geoVer = readlong testFile #unsigned
					local geoEnd = ftell testFile + geoSize
					
					if geoEnd > fileSize then break
					
					-- Only scan extensions if this is actually a Geometry (0x0F)
					if geoID == 0x0F then (
						-- Scan extensions inside Geometry
						while (ftell testFile + 12) <= geoEnd and not hasSkin do (
							local extPos = ftell testFile
							local extID = readlong testFile #unsigned
							local extSize = readlong testFile #unsigned
							local extVer = readlong testFile #unsigned
							local extEnd = ftell testFile + extSize
							
							-- If this is Extension container (0x3), scan inside it for plugins
							if extID == 0x3 then (
								while (ftell testFile + 12) <= extEnd and not hasSkin do (
									local pluginPos = ftell testFile
									local pluginID = readlong testFile #unsigned
									local pluginSize = readlong testFile #unsigned
									local pluginVer = readlong testFile #unsigned
									local pluginEnd = ftell testFile + pluginSize
									
									if pluginID == 0x116 then (  -- Skin PLG found!
										hasSkin = true
										exit
									)
									
									-- Skip plugin data
									if pluginEnd <= fileSize and pluginEnd > ftell testFile then
										fseek testFile pluginEnd #seek_set
									else
										break
								)
							) else if extID == 0x116 then (  -- Skin PLG found directly!
								hasSkin = true
								exit
							)
							
							-- Skip extension data safely
							if extEnd <= fileSize and extEnd > ftell testFile then
								fseek testFile extEnd #seek_set
							else
								break
						)
					)
					
					-- Skip to next geometry chunk safely
					if geoEnd <= fileSize and geoEnd > ftell testFile then
						fseek testFile geoEnd #seek_set
					else
						break
				)
			)
			
			-- Skip to next top-level chunk safely
			if chunkEnd <= fileSize and chunkEnd > ftell testFile then
				fseek testFile chunkEnd #seek_set
			else
				break
		)
		
	) catch (
		-- On any error, assume not a character
		hasSkin = false
	)
	
	-- Close test file handle
	try (fclose testFile) catch ()
	
	return hasSkin
)

-- Export IFP animation from hierarchy root object
-- Wraps the existing ExpsaIFP/expAnim functions to work with UI buttons
fn ExportIFPFromRoot rootObj fname isAppend = (
	if rootObj == undefined then (
		format "ExportIFPFromRoot: No root object specified\n"
		return false
	)
	
	-- Collect hierarchy (root + all children recursively)
	local hierarchy = #(rootObj)
	local queue = #(rootObj)
	while queue.count > 0 do (
		local current = queue[1]
		deleteItem queue 1
		for child in current.children do (
			append hierarchy child
			append queue child
		)
	)
	
	format "Exporting IFP for % objects (root: %)\n" hierarchy.count rootObj.name
	
	-- Animation name should match the DFF/root object name
	local animName = rootObj.name
	if animName == undefined or animName.count == 0 then animName = "anim"
	
	-- Extract internal file name from IFP filename (without path and extension)
	local internalName = getFilenameFile fname
	if internalName == undefined or internalName.count == 0 then internalName = animName
	
	-- Ensure all objects in hierarchy have BoneID user properties
	-- ExpsaIFP requires BoneID >= 0 to process animation keyframes
	-- Only assign BoneIDs to objects that actually have animation keys
	local boneIdSet = 0
	for obj in hierarchy do (
		local existingID = getUserProp obj "BoneID"
		if existingID == undefined then (
			-- Check if object has any keyframes (use try/catch for safety)
			local hasKeys = false
			try (
				if obj.pos.controller.keys.count > 0 then hasKeys = true
			) catch ()
			try (
				if obj.rotation.controller.keys.count > 0 then hasKeys = true
			) catch ()
			
			-- Only assign BoneID if object has keyframes
			if hasKeys then (
				setUserProp obj "BoneID" boneIdSet
				boneIdSet += 1
				format "Assigned BoneID % to %\n" (boneIdSet - 1) obj.name
			)
		)
	)
	
	try (
		local f = undefined
		local currentAnimCount = 1
		local currentFileLength = 0
		
		if isAppend then (
			-- For append mode, open in read/write mode to update header
			f = fopen fname "rb+"
			if f == undefined then (
				format "Failed to open file for appending: %\n" fname
				return false
			)
			
			-- Read existing header
			local headerID = readLong f
			if headerID != 0x33504E41 then (
				format "Not a valid SA IFP file (ANP3)\n"
				fclose f
				return false
			)
			
			currentFileLength = readLong f
			fseek f 24 #seek_cur  -- Skip internal name (24 bytes)
			currentAnimCount = readLong f
			
			-- Seek to end of file to append new animation
			fseek f 0 #seek_end
			
		) else (
			-- Create new file
			f = fopen fname "wb"
			if f == undefined then (
				format "Failed to open file: %\n" fname
				return false
			)
			
			-- Write SA format (ANP3) header
			writeLong f 0x33504E41		-- ANP3
			writeLong f 0				-- length placeholder
			writeString f internalName	-- IFP internal name (e.g., "chiliad_int")
			for i = 1 to (24 - internalName.count - 1) do writeByte f 0
			writeLong f 1				-- 1 animation (will update if appending later)
		)
		
		-- Export using the working ExpsaIFP function from gtaIFPio_Fn.ms
		local thisLength = ExpsaIFP f hierarchy animName
		
		if thisLength == undefined then (
			format "No keyframe animation found on % or its children\n" rootObj.name
			fclose f
			return false
		)
		
		if isAppend then (
			-- Update animation count and file length in header
			fseek f 4 #seek_set
			writeLong f (currentFileLength + thisLength)
			fseek f 24 #seek_cur  -- Skip internal name
			writeLong f (currentAnimCount + 1)
		) else (
			-- Update file length in header for new file
			fseek f 4 #seek_set
			writeLong f (thisLength + 28)
		)
		
		fclose f
		format "IFP export complete: % bytes\n" thisLength
		return true
		
	) catch (
		format "ExportIFPFromRoot error: %\n" (getCurrentException())
		if f != undefined then fclose f
		return false
	)
)

fn SetINI key value_= (
	try (
		if  key == "Exp_NOR" then (
			if value_ == true then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NOR" "1" )
			else if value_ == false then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NOR" "0" )
		)
		if  key == "Exp_VC" then (
			if value_ == true then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VC" "1" )
			else if value_ == false then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VC" "0" )
		)
		if  key == "Exp_NVC" then (
			--messagebox (value_ as string)
			if value_ == true then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NVC" "1" )
			else if value_ == false then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NVC" "0" )
		)
		if  key == "Exp_VCdef" then (
			if value_ >= 0 then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VCdef" ((value_ as integer) as string) )
		)
		if  key == "Exp_NVCdef" then (
			if value_ >= 0 then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NVCdef" ((value_ as integer) as string) )
		)
		if  key == "Exp_chAlpha" then (
			if value_ == true then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_chAlpha" "1" )
			else if value_ == false then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_chAlpha" "0" )
		)
		/*
		if  key == "Exp_chMMC" then (
			if value_ == true then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_chMMC" "1" )
			else if value_ == false then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_chMMC" "0" )
		)
		*/
		if  key == "Exp_VER" then (
			if value_ == "SA" then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VER" "SA" )
			else if value_ == "VC" then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VER" "VC" )
				else if value_ == "GTA3" then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VER" "GTA3" )
		)
		if  key == "Exp_SkipCol" then (
			if value_ == true then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_SkipCol" "1" )
			else if value_ == false then (setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_SkipCol" "0" )
		)

	) catch (format "error autoSet % %\n" key value_)
)

fn OpenFileDialog_ = (
	theDialog = dotNetObject "System.Windows.Forms.OpenFileDialog" --create a OpenFileDialog
	theDialog.title = "PLEASE Select One Or More Files" --set the title
	theDialog.Multiselect = true --allow multiple files to be selected
	theDialog.Filter = "DFF Files (*.dff)|*.dff|All Files (*.*)|*.*" --specify the filter
	theDialog.FilterIndex = 1 --set the filter drop-down list to All Files
	result = theDialog.showDialog() --display the dialog, get result into variable
	result.ToString() --when closed, convert the result to string
	result.Equals result.OK --returns TRUE if OK was pressed, FALSE otherwise
	result.Equals result.Cancel --returns TRUE if Cancel was pressed, FALSE otherwise
	theFilenames = theDialog.fileNames --the selected filenames will be returned as an array
	return theFilenames
)

-----------------  UI Update ------------------
global gTickTime = 0
fn interfaceUpdate_ gTickTime = (
	--print gTickTime
	if gTickTime > 25 then (
		app=dotNetclass "System.Windows.Forms.Application"
		app.doEvents()
		--windows.processPostedMessages()
		gTickTime = 0
	) else (
		gTickTime += 1
	)
	return gTickTime
)

fn interfaceUpdate = (
	app=dotNetclass "System.Windows.Forms.Application"
	app.doEvents()
)
-------------------------------------------------



fn getNum str = (
	str2 = copy str
	str1 = filterString str2 " "
	str = (str1[1] as string)
)

try (fileIn (scriptspath+"\\GTA_Tools(GF)\\DFFimp.ms")) catch (format "Error loading DFFimp.ms: %\n" (getCurrentException()))
try (fileIn (scriptspath+"\\GTA_Tools(GF)\\CharDFFimp.ms")) catch (format "Error loading CharDFFimp.ms: %\n" (getCurrentException()))
try (fileIn (scriptspath+"\\GTA_Tools(GF)\\DFFexp.ms") quiet:true) catch (format "Error loading DFFexp.ms: %\n" (getCurrentException()))
try (fileIn (scriptspath+"\\GTA_Tools(GF)\\ui_2dfx.ms") quiet:true) catch (format "Error loading ui_2dfx.ms: %\n" (getCurrentException()))

Global Dummysize = 0.1		--control the dummy size, change it before pressing the Import Button 
Global SAColBase = undefined
Global bonechain = #()
global gfname

fn getRootObj objArr = (
	nodeObj = objArr[1]
	local nodeObjFirst
	while (nodeObj != undefined) do (
		nodeObjFirst = nodeObj
		nodeObj = nodeObj.parent
	)
	return nodeObjFirst
)

rollout aboutRoll "About" (
	group "" (
		checkbox sdtl "Show detail info." checked:false
	)
	
	label l1 "- GTA DFF IO -" align:#center offset:[-12,8]
	label l21_ " v0.4.0" align:#left
	label l1_ " last upd: 09.12.25" align:#left
	label l3 "The script can work with" align:#left offset:[0,8]
	label s1 "  - Bones/Skin" align:#left
	label s2 "  - Collision" align:#left
	label s4 "  - Materials" align:#left
	label s42 "  - Static models" align:#left
	label s43 "  - Animation models" align:#left
	label s44 "  - Vehicle models" align:#left
	
	label l21 " "
	label s41 "Other script features" align:#left
	label s5 "  - ZM Lock DFF" align:#left
	label s6 "  - New noBack Lock DFF (by GF)" align:#left
	label s62 "  - UV / Mesh Fix (optional)" align:#left
	
	label s7 "  Import / Export:" align:#left offset:[0,8]
	label s8 "    - Prelit Day / Night" align:#left
	label s9 "    - Vertex Alpha" align:#left
	label s10 "    - UV1 / UV2" align:#left
	label s11 "    - 2dfx (light)" align:#left
	label s12 "    - Normals" align:#left
	label s13 "    - Bump map" align:#left
	label s14 "    - Dual map" align:#left
	label s16 "    - Normal map (DK plugin)" align:#left
	label s17 "    - Reflection map (DK plugin)" align:#left
	
	label s15 "(c) Goldfish, Kam 2020" align:#right offset:[0,0]
	label s18 "Enhanced by E2001 2025" align:#right offset:[0,0]
)

rollout DFFinPara "Import DFF" (

local fname = undefined
local no_clump = #()

	Group "Multi. Clump" (
        spinner whichone "" type:#integer range:[1,1,1] align:#left fieldwidth:35 offset:[-3,3] across:2 enabled:false
        button useclump "Import" width:70 offset:[-3,0] enabled:false
	)
	group "" (
		radiobuttons textype "Image Type:" labels:#("tga", "bmp","png") columns:3 default:3
		radiobuttons mattype "MATERIAL AS:" align:#left labels:#("GTAmaterial", "Standart") columns:1 offset:[15,5]
		--spinner ISc "Import Scale: " fieldwidth:42 range:[0,100,SPscale] align:#right
		button imp "Import DFF" width:120 height:30 align:#center
		label lmasimp "Mass import is supported !"
	)
	group "" (
		checkbutton autoskin "A" width:17 tooltip:"Auto Skin after import dff character" highlightcolor:yellow align:#left across:2 offset:[0,-3] checked:true
		button skinchr "Skin the Character" width:103 tooltip:"Selected model must be Skin/bones ready" align:#right offset:[-2,-3]
		progressBar skinstate color:red height:8 offset:[0,-3]
		button RenameSel "Re-Name" width:61 tooltip:"Add BoneIndex to the name of objects for easy skinnig" align:#left across:2
		button RtnameSel "Restore" width:61 tooltip:"Restore Original names to selected objects" align:#right
	)
	
	-- START: IFP Import UI (added after Restore button group)
	group "Animation Import" (
		button IFPimp "Import IFP Animation" width:120 tooltip:"Import hierarchy animation from .ifp file to selected root object" align:#center
	)
	
	-- IFP Import handler
	on IFPimp pressed do (
		if selection.count != 1 then (
			messagebox "Select a single root object for hierarchy animation import." title:"Import IFP"
		) else (
			if ImportIFPToHierarchy == undefined then (
				messagebox "ImportIFPToHierarchy function is not defined!\nMake sure DFFimp.ms loaded correctly." title:"Import IFP Error"
			) else (
				try (
					-- Pass root object name as animation name to match
					-- Always import position keys for world objects (skipPosKeys is false)
					ok = ImportIFPToHierarchy selection[1] undefined false selection[1].name
					if ok then messagebox "IFP animation imported successfully!" title:"Import IFP"
				) catch (
					local errMsg = getCurrentException()
					if errMsg == undefined then errMsg = "Unknown error"
					messagebox ("Error importing IFP: " + errMsg) title:"Import IFP"
				)
			)
		)
	)
	-- END: IFP Import UI
	
	on RenameSel pressed do (
		for obj in $selection do (
			onm = getUserProp obj "BoneIndex"
			if onm != undefined then (
				if onm <10 then obj.name = "0" + onm as string + "_" + (RestoreSpace obj.name)
				else obj.name = onm as string + "_" + (RestoreSpace obj.name)
			)
		)--end for	
	)

	on RtnameSel pressed do (
		for obj in $selection do (
			onm = getUserProp obj "FrameName"
			if onm != undefined then obj.name = RestoreSpace onm
		)--end for
	)--end on RenameSel

	on skinchr pressed do (
		if (SkinData != undefined)AND($selection.count == 1) then (
			global skn = $.modifiers[1]
			if (skn != undefined)AND(classof $ == Editable_mesh) then (
				if $.numVerts != SkinData[1].count then \
					messagebox "Skin Data Not correct!" title:"Skin Error"
				else (
					max modify mode
					modPanel.SetCurrentObject skn
					if (skinOps.GetNumberBones skn) != SkinData[3].count then (
						messagebox "Bones count in skin Modifier Not correct!" title:"Skin Error"
					)	
 					else (
						--skn
						for i = 1 to $.numVerts do (
							skinOps.SetVertexWeights skn i SkinData[1][i] SkinData[2][i]
							if (mod i 50) == 0 then skinstate.value = 100 * i/$.numVerts
						)
						skinstate.value = 0
						gc()
					)
				)
			) else messagebox "Skin modifier not found" title:"Skin Error"
		) else messagebox "Make sure you have selected the right character\nwith Skin modifier applied" title:""
	)--end on skinchr


	on useclump pressed do (
		f = fopen gfname "rb"
		if f != undefined then  (
			if whichone.value != 1 then fseek f no_clump[(whichone.value)] #seek_set
			texEx = case textype.state of (
				1: ".tga"
				2: ".bmp"
				3: ".png"
			)
			clearlistener()
			cntLDffNow = 0
			cntLDffMax = 0
			
			-- Detect character model vs world object
			local isCharacter = hasSkinData gfname
			
			if isCharacter then (
				format "Detected character model (has Skin PLG), using CharDFFin...\n"
				CharDFFin f 1.0 mattype.state texEx dummysize autoskin.checked aboutRoll.sdtl.checked (getFilenameFile gfname)
			) else (
				format "Detected world object, using DFFin...\n"
				DFFin f 1.0 mattype.state texEx dummysize autoskin.checked aboutRoll.sdtl.checked (getFilenameFile gfname)
			)
			
			fclose f
			gc()
		) else (
			format "ERROR\n"
		)
	)--end on useclump
    
	on imp pressed do (
		gfname = ""
		local masImp = true
		try ( 
			fname = OpenFileDialog_() 
		) catch (
			masImp = false
			fname = getopenfilename caption:"Read DFF File" types:"dff File (*.dff)|*.dff|"
		)
		if fname != undefined then (
			texEx = case textype.state of (
				1: ".tga"
				2: ".bmp"
				3: ".png"
			)--end case
			if  masImp == true then (
				cntLDffNow = 0
				cntLDffMax = fname.count
				for i = 1 to fname.count do (
					cntLDffNow += 1
					f = fopen fname[i] "rb"
					if f == undefined then ( Messagebox "Can't open the file!" title:"I/O Error" )
					else (
						--no_clump = checkClump f
						no_clump = #(1)
						if no_clump == undefined then
							messagebox "This DFF is locked !\nThe author of this model do not allow you to modify it.\n\nPlease contact the author for the permission." title:"Import Failed"
						else if no_clump.count == 0 then messagebox "Not a Void DFF file!" title:"File Format Error"
						else (
							if no_clump.count == 1 then (
								clearlistener()
								
								-- Detect character model (has skin data) vs world object
							local isCharacter = hasSkinData fname[i]
							
							if isCharacter then (
								-- Character model: use CharDFFin
								format "Detected character model (has Skin PLG), using CharDFFin...\n"
								CharDFFin f 1.0 mattype.state texEx dummysize autoskin.checked aboutRoll.sdtl.checked (getFilenameFile fname[i])
							) else (
								-- World object: use DFFin
								format "Detected world object, using DFFin...\n"
								DFFin f 1.0 mattype.state texEx dummysize autoskin.checked aboutRoll.sdtl.checked (getFilenameFile fname[i])
							)
							
							useclump.enabled = false
							whichone.enabled = false
						) else (
								fclose f
								gfname = fname[i]
								whichone.range = [1,no_clump.count,1]
								whichone.enabled = true
								useclump.enabled = true
								txt = "This DFF has " + no_clump.count as string + " Clumps.\nPlease choose one to Import!"
								Messagebox  txt title: ""
							)
						)--end if/else no_clump
					)--end if/else f
				)
				cntLDffNow = 0
				cntLDffMax = 0
			) else (
				f = fopen fname "rb"
				if f == undefined then ( Messagebox "Can't open the file!" title:"I/O Error" )
				else (
					no_clump = checkClump f
					if no_clump == undefined then
						messagebox "This DFF is locked !\nThe author of this model do not allow you to modify it.\n\nPlease contact the author for the permission." title:"Import Failed"
					else if no_clump.count == 0 then messagebox "Not a Void DFF file!" title:"File Format Error"
					else (
						if no_clump.count == 1 then (
							texEx = case textype.state of (
								1: ".tga"
								2: ".bmp"
								3: ".png"
							)--end case
							clearlistener()
							cntLDffNow = 0
							cntLDffMax = 0
							
							-- Detect character model vs world object
							local isCharacter = hasSkinData fname
							
							if isCharacter then (
								format "Detected character model (has Skin PLG), using CharDFFin...\n"
								CharDFFin f 1.0 mattype.state texEx dummysize autoskin.checked aboutRoll.sdtl.checked (getFilenameFile fname)
							) else (
								format "Detected world object, using DFFin...\n"
								DFFin f 1.0 mattype.state texEx dummysize autoskin.checked aboutRoll.sdtl.checked (getFilenameFile fname)
							)
							useclump.enabled = false
							whichone.enabled = false
						) else (
							fclose f
							whichone.range = [1,no_clump.count,1]
							whichone.enabled = true
							useclump.enabled = true
							txt = "This DFF has " + no_clump.count as string + " Clumps.\nPlease choose one to Import!"
							Messagebox  txt title: ""
						)
					)--end if/else no_clump
				)--end if/else f

			)
		)
		fclose f
		gc()
	)--end on imp
    
)--end rollout DFFinPara



	
		fn ModelInfoRead obj = (
			bModelInfo_rol.statUV2.highlightcolor = (color 255 255 255)
			bModelInfo_rol.statUV2.checked = false
			bModelInfo_rol.statUV2.checked = true
			if (classof obj) == Editable_mesh then (
				if (meshop.getMapSupport obj -2) != false then (
					bModelInfo_rol.numVA.text = (meshop.getNumMapVerts obj -2) as string
				) else bModelInfo_rol.numVA.text = "none"
				if (meshop.getMapSupport obj 0) != false then (
					bModelInfo_rol.numVC.text = (meshop.getNumMapVerts obj 0) as string
				) else bModelInfo_rol.numVC.text = "none"
				if (meshop.getMapSupport obj -1) != false then (
					bModelInfo_rol.numnVC.text = (meshop.getNumMapVerts obj -1) as string
				) else bModelInfo_rol.numnVC.text = "none"
				if (meshop.getMapSupport obj 1) != false then (
					bModelInfo_rol.numUV1.text = (meshop.getNumMapVerts obj 1) as string
				) else bModelInfo_rol.numUV1.text = "none"
				if (meshop.getMapSupport obj 2) != false then (
					bModelInfo_rol.numUV2.text = (meshop.getNumMapVerts obj 2) as string
				) else bModelInfo_rol.numUV2.text = "none"
				
				local nUV1,nUV2,nV,nall
				nV =  obj.numverts
				if (meshop.getMapSupport obj 1) == true then  nUV1 = (meshop.getNumMapVerts obj 1) else nUV1 = 0
				if (meshop.getMapSupport obj 2) == true then  nUV2 = (meshop.getNumMapVerts obj 2) else nUV2 = 0
				erStat = false
				if nUV2 > nUV1 and nUV1 > nV then erStat = true
					else if nUV2 > nV and nV >= nUV1 then erStat = true
				if erStat == true then (
					bModelInfo_rol.statUV2.highlightcolor = (color 250 90 0)
					bModelInfo_rol.statUV2.checked = false
					bModelInfo_rol.statUV2.checked = true
				)
			)
			if (classof obj) == Editable_Poly then (
				if (polyop.getMapSupport obj -2) != false then (
					bModelInfo_rol.numVA.text = (polyop.getNumMapVerts obj -2) as string
				) else bModelInfo_rol.numVA.text = "none"
				if (polyop.getMapSupport obj 0) != false then (
					bModelInfo_rol.numVC.text = (polyop.getNumMapVerts obj 0) as string
				) else bModelInfo_rol.numVC.text = "none"
				if (polyop.getMapSupport obj -1) != false then (
					bModelInfo_rol.numnVC.text = (polyop.getNumMapVerts obj -1) as string
				) else bModelInfo_rol.numnVC.text = "none"
				if (polyop.getMapSupport obj 1) != false then (
					bModelInfo_rol.numUV1.text = (polyop.getNumMapVerts obj 1) as string
				) else bModelInfo_rol.numUV1.text = "none"
				if (polyop.getMapSupport obj 2) != false then (
					bModelInfo_rol.numUV2.text = (polyop.getNumMapVerts obj 2) as string
				) else bModelInfo_rol.numUV2.text = "none"
				if (polyop.getMapSupport obj 2) == true then  (
					if (polyop.getMapSupport obj 1) == true then  (
						if (polyop.getNumMapVerts obj 2) > (polyop.getNumMapVerts obj 1) then (
							bModelInfo_rol.statUV2.highlightcolor = (color 250 90 0)
							bModelInfo_rol.statUV2.checked = false
							bModelInfo_rol.statUV2.checked = true
						)
					) else (

						if (obj.numverts) < (polyop.getNumMapVerts obj 2) then (
							bModelInfo_rol.statUV2.highlightcolor = (color 250 90 0)
							bModelInfo_rol.statUV2.checked = false
							bModelInfo_rol.statUV2.checked = true
						)
					)
				)
			)
		)
		
rollout DFFexPara "Export DFF" (
	group "General parameters" (
		checkbutton eGTA3 "GTA3" width:54 highlightcolor:(color 0 189 0) offset:[-4,0] across:3
		checkbutton eVC   "VC"   width:54 highlightcolor:(color 0 189 0) offset:[0,0]
		checkbutton eSA   "SA"   width:54 highlightcolor:(color 0 189 0) offset:[4,0] checked:true
		--checkbox MMC "MMC"  align:#left  tooltip:"use Modulate Material Color" checked:true 
		checkbox AppendFile "Apnd" tooltip:"Append export to DFF"  across:2
		checkbox lockdff "lock DFF"  tooltip:"ZM Lock" offset:[-7,0]
		checkbox vAlpha "use Vertex Alpha"  tooltip:"Export Vertex Alpha" checked:false
		groupBox group1 "Vertex Color:"  width: 106 height:15 align:#right 
		checkbutton NOR "Normals"  width:48  highlightcolor:(color 0 189 0) tooltip:"export Normals"  across:3 offset:[-4,0]		
		checkbutton CPV "DAY" width:54  highlightcolor:(color 0 189 0) tooltip:"export Vertex Color" offset:[-4,0] checked:true
		checkbutton _bNVC "NIGHT" width:54  highlightcolor:(color 0 189 0) tooltip:"export Vertex illum" offset:[2,0] checked:true	
		label textPrelit "Default:" align:#left  across:3 
		spinner VCdef "VC" type:#integer range:[0,255,80]  fieldwidth:30  offset:[-8,0]
		spinner NVCdef "NVC" type:#integer range:[0,255,10] align:#right fieldwidth:30 offset:[5,0]
		)

		group "SA Collision" (
			checkbox Vparts "Vehicle Parts" align:#left across:2
			button colbase "Sel COL" width:65 offset:[0,-4] tooltip:"Select collision file"
		) 
		group "Export" (
			
			checkbox UVpack "UV Fix"  checked:false tooltip:"FIX UV (optional, longer time of export)" across:2 
			checkbox MeshFix "Mesh Fix"  checked:false align:#left  tooltip:"Fix polygons (optional, longer time of export)" 
			checkbox noCOL "SKIP COL" checked:true align:#left   tooltip:"Select COL3/COLL" offset:[0,5]
			button exp "EXPORT TO DFF" width:120 height:40 tooltip:"Only selected objects will export" align:#center
			label lmasexp "Mass export is supported !"
		)
		
		-- START: IFP UI & handler (moved directly after Export group)
		group "Animation Export" (
			button IFPexpNew "Export New IFP File" width:150 tooltip:"Export hierarchy/world-object animation as a new .ifp file" align:#center
			button IFPexpAppend "Append To Existing IFP File" width:150 tooltip:"Append exported animation to an existing .ifp file" align:#center
		)

		-- Manual IFP export handlers (inside the same rollout)
		on IFPexpNew pressed do (
			if selection.count != 1 then (
				messagebox "Select a single root object for hierarchy animation export." title:"Export IFP"
			) else (
				try (
					fname = getSaveFileName caption:"Export animation (.ifp)" types:"GTA animation (*.ifp)|*.ifp|"
					if fname != undefined then (
						ok = ExportIFPFromRoot selection[1] fname false
						if ok then messagebox ("IFP exported: " + fname) title:"Export IFP"
					)
				) catch (messagebox "Error exporting IFP" title:"Export IFP")
			)
		)
		
		on IFPexpAppend pressed do (
			if selection.count != 1 then (
				messagebox "Select a single root object for hierarchy animation export." title:"Export IFP"
			) else (
				try (
					fname = getOpenFileName caption:"Select existing IFP file to append to" types:"GTA animation (*.ifp)|*.ifp|"
					if fname != undefined then (
						ok = ExportIFPFromRoot selection[1] fname true
						if ok then messagebox ("IFP appended to: " + fname) title:"Export IFP"
					)
				) catch (messagebox "Error appending IFP" title:"Export IFP")
			)
		)
		-- END: IFP UI & handler
		
		progressbar pb color:blue width:178 height:6 offset:[-8,0]
		group "SA Char. Options" (
			checkbox SAbodypart "as SA Body Part" align:#left
			checkbox forceRBN "Rename Root Bone as" align:#left
			checkbutton rbR "Ripped" width:40 highlightcolor:yellow checked:true align:#left offset:[0,-5] enabled:false across:3
			checkbutton rbF   "Fat"   width:40 highlightcolor:yellow align:#left offset:[0,-5] enabled:false
			checkbutton rbN   "Normal"   width:40 highlightcolor:yellow align:#left offset:[0,-5] enabled:false
		)
		button BSexp "Bones/Skin Export" width:120 height:30 tooltip:"Select the skinned Character only" align:#center --offset:[0,-3]
		group "Other Tools" (
			button bModelInfo "Model chanell Info >"  tooltip:"Channel information of the selected model"
		)		
		
		on noCOL changed state do (
			if state == true then SetINI "Exp_SkipCol" true
			else SetINI "Exp_SkipCol" false
		)
		
		/*
		on MMC changed state do (
			if state == true then SetINI "Exp_chMMC" true
			else SetINI "Exp_chMMC" false
		)
		*/
		
		on vAlpha changed state do (
			if state == true then SetINI "Exp_chAlpha" true
			else SetINI "Exp_chAlpha" false
		)
		
		on VCdef changed state do (
			SetINI "Exp_VCdef" state
		)
		on NVCdef changed state do (
			SetINI "Exp_NVCdef" state
		)
		
		on CPV changed state do (
			if state == true then SetINI "Exp_VC" true
			else SetINI "Exp_VC" false
		)
		on NOR changed state do (
			if state == true then (
				if _bNVC.checked == true then (
					_bNVC.checked = false
					SetINI "Exp_NOR" true
					SetINI "Exp_NVC" false
				) else SetINI "Exp_NOR" true
			) else SetINI "Exp_NOR" false
		)
		on _bNVC changed state do (
			if state == true then (
				if eSA.checked == true then (
					if NOR.checked == true then NOR.checked = false
					SetINI "Exp_NVC" true
					SetINI "Exp_NOR" false
				) else (
					_bNVC.checked = false
					SetINI "Exp_NVC" false
				)
			) else SetINI "Exp_NVC" false
		)
		
		on DFFexPara open do (
			chFile = openFile (scriptsPath + "GTA_Tools(GF)\settings.ini")
			clearListener()
			try (
				if chFile == undefined then (
					(setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NOR" "0" )
					(setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VC" "1" )
					(setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NVC" "1" )
					(setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VCdef" "80" )
					(setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NVCdef" "10" )
					(setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_chAlpha" "0" )
					--(setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_chMMC" "1" )
					(setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VER" "SA" )
					(setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_SkipCol" "1" )
					--(setINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_UVpack" "0" )
				) else (
					close chFile
					/*
					res = (getINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_UVpack")
					if (res as integer) != undefined then (
						if (res as integer) == 0 then UVpack.checked = false
						else if (res as integer) == 1 then UVpack.checked = true
					)
					*/
					res = (getINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_SkipCol")
					if (res as integer) != undefined then (
						if (res as integer) == 0 then noCOL.checked = false
						else if (res as integer) == 1 then noCOL.checked = true
					)
					res = (getINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VER")
					if (res as string) != undefined then (
						if (res as string) == "SA" then (
							eSA.checked = true
							eVC.checked = false
							eGTA3.checked = false
						) else (
							if (res as string) == "VC" then (
								
								eSA.checked = false
								eVC.checked = true
								eGTA3.checked = false
							) else (
								if (res as string) == "GTA3" then (
									eSA.checked = false
									eVC.checked = false
									eGTA3.checked = true
								)
							)
						)
					)
					/*
					res = (getINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_chMMC")
					if (res as integer) != undefined then (
						if (res as integer) == 0 then MMC.checked = false
						else if (res as integer) == 1 then MMC.checked = true
					)
					*/
					res = (getINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_chAlpha")
					if (res as integer) != undefined then (
						if (res as integer) == 0 then vAlpha.checked = false
						else if (res as integer) == 1 then vAlpha.checked = true
					)
					res = (getINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NVCdef")
					if (res as integer) != undefined then (
						if (res as integer) >= 0  then NVCdef.value = (res as integer)
					)
					res = (getINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VCdef")
					if (res as integer) != undefined then (
						if (res as integer) >= 0  then VCdef.value = (res as integer)
					)
					res = (getINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NVC")
					if (res as integer) != undefined then (
						if (res as integer) == 0 then _bNVC.checked = false
						else if (res as integer) == 1 then (
							_bNVC.checked = true
							NOR.checked = false
						)
					)
					res = (getINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_NOR")
					if (res as integer) != undefined then (
						if (res as integer) == 0 then NOR.checked = false
						else if (res as integer) == 1 then (
							NOR.checked = true
							_bNVC.checked = false
						)
					)			
					res = (getINISetting (scriptsPath + "GTA_Tools(GF)\settings.ini") "UI_AutoSet" "Exp_VC")
					if (res as integer) != undefined then (
						if (res as integer) == 0 then CPV.checked = false
						else if (res as integer) == 1 then CPV.checked = true
					)
				)
			) catch (format "error autoSet(open)\n")
			exp_lockDFF = false
			format " ------ DFF IO -------\n last upd: 09.12.25\n         --- \n GTA Tools ver 0.4.0 \n based on Goldfish/Kam's scripts\n modified by E2001\n\n"
		) 
		
		on bModelInfo pressed do (
			try (DestroyDialog bModelInfo_rol) catch()
				
			rollout bModelInfo_rol "Model info" width:250   (
				label mName "-" align:#left
				label tab "----------------------------------------------" align:#left
				-------
				label Vtext "Vertex:" align:#left across:2
				label numV "-" align:#left  
				-------
				label VAtext "Vertex Alpha:" align:#left across:4
				checkbutton statVA "" highlightcolor:(color 255 255 255) align:#right checked:true height:15
				label numVA "-" align:#left  offset:[8,0]
				button VAclear "clear" align:#right offset:[0,-3]
				-------
				label VCtext "Vertex Color:" align:#left across:4
				checkbutton statVC "" highlightcolor:(color 255 255 255) align:#right checked:true height:15
				label numVC "-" align:#left  offset:[8,0]
				button VCclear "clear" align:#right offset:[0,-3]
				-------
				label nVCtext "Night Vertex Color:" align:#left across:4
				checkbutton statnVC "" highlightcolor:(color 255 255 255) align:#right checked:true height:15
				label numnVC "-" align:#left  offset:[8,0]
				button nVCclear "clear" align:#right offset:[0,-3]
				-------
				label UV1text "UV1 coord:" align:#left across:4
				checkbutton statUV1 "" highlightcolor:(color 255 255 255) align:#right checked:true height:15
				label numUV1 "-" align:#left  offset:[8,0]
				button UV1clear "clear" align:#right offset:[0,-3]
				-------
				label UV2text "UV2 coord:" align:#left across:4
				checkbutton statUV2 "" highlightcolor:(color 255 255 255) align:#right checked:true height:15
				label numUV2 "-" align:#left  offset:[8,0]
				button UV2clear "clear" align:#right offset:[0,-3]

				button btn_Reread "re-read" align:#left width:69 height:22 across:2
				button btn_close "close" align:#right width:69 height:22
				
				on statVA changed state do if state == false then statVA.checked = true
					
				on statVA changed state do if state == false then statVA.checked = true
				on statVC changed state do if state == false then statVC.checked = true
				on statnVC changed state do if state == false then statnVC.checked = true
				on statUV1 changed state do if state == false then statUV1.checked = true
				on statUV2 changed state do if state == false then statUV2.checked = true
			
				on btn_Reread pressed do (
					if $selection.count >= 1 then (
						mName.text = (selection[1].name as string) + ":"
						if ((classof selection[1]) == Editable_mesh) or ((classof selection[1]) == Editable_Poly) then (
							ModelInfoRead selection[1]
							numV.text = (selection[1].numverts as string) 
						) else (
							numVA.text = "-"
							numVC.text = "-"
							numnVC.text = "-"
							numUV1.text = "-"
							numUV2.text = "-"
						)
					) else mName.text = "-"
				)
				on VAclear pressed do (
					if (classof selection[1]) == Editable_mesh then (
						meshop.setMapSupport selection[1] -2 false
						numVA.text = "none"
					)
					if (classof selection[1]) == Editable_Poly then (
						polyop.setMapSupport selection[1] -2 false
						numVA.text = "none"
					)
					
				)
				on VCclear pressed do (
					if (classof selection[1]) == Editable_mesh then (
						meshop.setMapSupport selection[1] 0 false
						numVC.text = "none"
					)
					if (classof selection[1]) == Editable_Poly then (
						polyop.setMapSupport selection[1] 0 false
						numVC.text = "none"
					)
				)
				on nVCclear pressed do (
					if (classof selection[1]) == Editable_mesh then (
						meshop.setMapSupport selection[1] -1 false
						numnVC.text = "none"
					)
					if (classof selection[1]) == Editable_Poly then (
						polyop.setMapSupport selection[1] -1 false
						numnVC.text = "none"
					)
					
				)
				on UV1clear pressed do (
					if (classof selection[1]) == Editable_mesh then (
						meshop.setMapSupport selection[1] 1 false
						numUV1.text = "none"
					)
					if (classof selection[1]) == Editable_Poly then (
						polyop.setMapSupport selection[1] 1 false
						numUV1.text = "none"
					)
					
				)
				on UV2clear pressed do (
					if (classof selection[1]) == Editable_mesh then (
						meshop.setMapSupport selection[1] 2 false
						numUV2.text = "none"
					)
					if (classof selection[1]) == Editable_Poly then (
						polyop.setMapSupport selection[1] 2 false
						numUV2.text = "none"
					)
					
				)
				
				on bModelInfo_rol open do (
					
					if $selection.count >= 1 then (
						if ((classof selection[1]) == Editable_mesh) or ((classof selection[1]) == Editable_Poly) then (
							ModelInfoRead selection[1]
							mName.text = (selection[1].name as string) + ":"
							numV.text = (selection[1].numverts as string) 
						)
					)  else mName.text = "-"
				)
				on btn_close pressed do DestroyDialog  bModelInfo_rol 
			)
			createDialog bModelInfo_rol 
		)

		
	on forceRBN changed state do (
		rbR.enabled = state
		rbF.enabled = state
		rbN.enabled = state
	)
 	on rbR changed state do (
		if state == true then (
			rbF.checked = false
			rbN.checked = false
		) else rbR.checked = true
	)
 	on rbF changed state do (
		if state == true then (
			rbR.checked = false
			rbN.checked = false
		) else rbF.checked = true
	)
 	on rbN changed state do (
		if state == true then (
			rbF.checked = false
			rbR.checked = false
		) else rbN.checked = true
	)
	
	on colbase pressed do (
		Cname = getopenfilename caption:"Collision Base File" types:"DFF File (*.dff)|*.dff|COL File (*.col)|*.col|"
		if Cname != undefined then (
			ctype = GetFilenameType Cname
			cb = fopen Cname "rb"
			case ctype of (
				".dff": (
					rult = findCOL3 cb 0x1803FFFF
					if rult == -1  then messagebox "This is not a SA DFF!" title:"Version No correct"
					else if rult == 0   then	messagebox "Can't find COL3!\nMake sure to select SA vehicle DFF only!" title:"NO COL3 in DFF"
					else Colsize = rult
					if rult < 8 then  Cname = undefined
					else colbase.text = filenameFromPath Cname
				)	
				".col": (
					rult = singleCOL cb
					if rult == -1 then messagebox "This is not a GTA Collision file" title:"File Error" 
					else if rult == 0 then messagebox "This file contains more than 1 Collision file" title:"File Error"
					else Colsize = rult
					if rult > 8 then colbase.text = filenameFromPath Cname
					else Cname = undefined
				)	
			)
			fclose cb
		)	
		noCOL.checked = false
		SAColBase = Cname
		if Cname == undefined then  colbase.text = "Sel COL"
	)
-- 
	on eGTA3 changed state do (
		if state == true then (
			SetINI "Exp_VER" "GTA3"
			SetINI "Exp_NVC" false
			_bNVC.checked = false
			eVC.checked = false
			eSA.checked = false
		) else eGTA3.checked = true
	)
	on eVC changed state do (
		if state == true then (
			SetINI "Exp_VER" "VC"
			_bNVC.checked = false
			SetINI "Exp_NVC" false
			eGTA3.checked = false
			eSA.checked = false
		) else eVC.checked = true
	)
	on eSA changed state do (
		if state == true then (
			SetINI "Exp_VER" "SA"
			eGTA3.checked = false
			eVC.checked = false
		) else eSA.checked = true
	)
	
	on BSexp pressed do (
		if $selection.count != 1 then messagebox "Select the skinned Character only!" title:"Selection Error"
		else (
			if (classof $.modifiers[1] != skin) then \
				messagebox "This object is not skinned correctly!\nSkin modifier must be on the topmost of the stack!!" title:"Skin Error"
			else (
				try (
					if eVC.checked == true then		ver = 0X0C02FFFF			--VC Version
					if eGTA3.checked == true then	ver = 0x0800FFFF			--Standard GTA3 Version
					if eSA.checked == true then		ver = 0x1803FFFF
					
					max modify mode
					bkup = $.name
					$.name = "CharExpTemp"
					global skn = $.modifiers[1]
					skn
					boneCount = skinOps.getNumberBones skn
					boneReady = true
					bonechain = #()
					for i = 1 to boneCount do (
						tmp = skinOps.getBoneName skn i 0
						tt = "getUserProp $'" + tmp + "' \"BoneType\""
						if (execute tt) == undefined then (
							boneReady = false
							exit
						)	
						tt = "getUserProp $'" + tmp + "' \"BoneID\""
						BID = execute tt
						if BID == undefined then (
							boneReady = false
							exit
						) else ( 
							if (BID==0)AND(ForceRBN.checked==true) do (
								if rbR.checked == true then (rbnm = "Ripped"; 	tt = "$'" + tmp + "'.name = \"Ripped\"")
								if rbF.checked == true then (rbnm = "Fat"; 		tt = "$'" + tmp + "'.name = \"Fat\"") 
								if rbN.checked == true then (rbnm = "Normal"; 	tt = "$'" + tmp + "'.name = \"Normal\"") 
								execute tt
								tmp = rbnm
							)
						)
						tb = "append bonechain $'" + tmp + "'"
						execute tb
					)--end for i
					$.name = bkup
					bonechain =  BoneArybyIndex bonechain
					if (boneReady == false)OR(bonechain == undefined) then messagebox "You didn't set   BoneIDs/BoneTypes   properly!\nEach bone must have  'BoneID' & 'BoneType'  in it's User Properities." title:"BoneID/BoneType Error"
					else (
						for i = 1 to $.numverts do (
							if skinOps.GetVertexWeightCount skn i == 0 then (boneReady = false; exit)
						)
					)
					if boneReady == false then messagebox "You didn't set   Skin/Vertices   properly!\nEach Vertex must be influence by at least 1 Bone." title:"Skin Error"
					else (
						fname = undefined
		
						if AppendFile.checked == true then (
							Sname = getopenfilename caption:"Append DFF File" types:"dff File (*.dff)|*.dff|"
							if Sname != undefined then (
								fo = fopen Sname "rb"
								if fo != undefined then  (
									no_clump = checkClump fo

									if no_clump == undefined then (
										messagebox "This DFF is locked !\nThe author of this model do not allow you to modify it.\n\nPlease contact the author for the permission." title:"Import Failed"
										fname = unefined
									) else (

										fseek fo (no_clump[no_clump.count]+4) #seek_set
										skip = readLong fo #unsigned
										readLong fo
										skip += (ftell fo)
										fname = (getFilenamePath Sname) + "temp.dff"
										if fname != undefined then (
											f = fopen fname "wb"
											fseek fo 0 #seek_set
											for i = 1 to skip do (
												writeByte f (readByte fo #unsigned)
											)--end for i
											fclose fo	
										)--end if fname	
									)   
								)--end if fo
							)--end if Sname
						) else (
							fname = getsavefilename caption:"Export DFF File" types:"dff File (*.dff)|*.dff|"
							if fname != undefined then (
								f = fopen fname "wb"
							)
						)--end if/else AppendFile
				
						if fname != undefined then (
							cuv = Unwrap_UVW ()
							addmodifier $ cuv before:1
							pbMax = 3
							clearListener()
							--suspendediting()
							disableSceneRedraw()
							setWaitCursor()
							enableUndo false
							errInfo_mass = true
							bNVC = _bNVC.checked
							chCol = noCOL.checked
							gUVpack = UVpack.checked
							gMeshFix = MeshFix.checked
							gVcDefolt = VCdef.value
							gNvcDefolt = NVCdef.value
							gValpha = vAlpha.checked
							format "\n=====================================\n"
							format ":       Mass DFF Export LOG        :\n=====================================\n\n"	
							if exp_lockDFF == true then format "   [!] noBack lock dff is enabled!\n"
							format "\n ======================== \n"
							try (
								wCharDFFout f $ bonechain false true CPV.checked NOR.checked 1.0 ver SAbodypart.checked lockdff.checked
							) catch (messageBox " [Error]: Skin export" title: "Error export dff")
							deletemodifier $ cuv
							fclose f
							exp_lockDFF = false
							DFFexPara.pb.value = 100.0
							
							displayTempPrompt  "Dff Export finished" 2000
							if AppendFile.checked == true then (
								deleteFile Sname
								renameFile fname Sname
								format "\nModels appended to file:% !\n" Sname
							)else	format "\nfile:% exported!\n" fname
				
						)--end if f!=undefined
		
					)--if/else boneReady
				) catch ()
				resumeediting()
				enableSceneRedraw()
				setArrowCursor()
				redrawViews()
				enableUndo true
				popPrompt()
			)--end check Skin modifier
		)--end check $	
	)--end on BSexp
	
	
	

	
fn checkHierarchyObj objArr = (
	for obj in objArr where (superclassof obj != light) do (
		if (superclassof obj == helper) then return false
		if obj.parent != undefined then (
			if superclassof obj.parent == GeometryClass then return false
		)
		if obj.children[1] != undefined then (
			if superclassof obj.children[1] != light then return false
		)
	)
	return true
)

fn getObjLight obj = (
	lightArr = #()
	for i = 1 to obj.children.count do (
		if superclassof obj.children[i] == light then append lightArr obj.children[i] else return undefined
	)
	return lightArr
)
fn checkObjL objArr = (
	local objCnt = 0
	for obj in objArr where (superclassof obj == GeometryClass ) do objCnt += 1
	if objCnt > 1 then return true else return false
)
	on exp pressed do (
		pb.value = 0
		pbcount = 0
		errInfo_mass = false
		errInfo_mass_ = false
		local skipSingleExp = false, checkRootL = false
		if $selection.count != 0 then (
			for lgh in selection where (superclassof lgh == light ) do (
				if lgh.children[1] == undefined and lgh.parent == undefined  then checkRootL = true
				if lgh.children[1] != undefined and lgh.parent == undefined  then checkRootL = true
			)
			matFound = false
			if checkRootL == false then (
				
				for objm in $selection  where (superclassof objm == GeometryClass ) do (
					if classof objm.material ==  Multimaterial then (
						for i = 1 to objm.material.count do (
							if objm.material[i] !=  undefined then (
								if classof objm.material[i] != Standardmaterial and classof objm.material[i]  !=  GTA_Mtl then matFound = true 
							)
						)
					) else
					if objm.material != undefined  and classof objm.material != Standardmaterial and classof objm.material !=  GTA_Mtl then matFound = true
				)
				if matFound == false then (
					nodeObjP = selection[1]
					while (nodeObjP != undefined) do (
						nodeObj = nodeObjP
						nodeObjP = nodeObj.parent
					)
					if (superclassof nodeObj != light ) then (
						-- MASS EXPORT
						if (superclassof nodeObj != helper) and noCOL.checked == true and AppendFile.checked == false and $selection.count > 1 then ( 
							--format "= % - %\n" (checkObjL $selection == true)  (checkHierarchyObj $selection == true)
							if (checkObjL $selection == true) and (checkHierarchyObj $selection == true) then (
								expfpath = getSavePath caption:"Mass export DFF Files to:" 
								skipSingleExp = true
								if expfpath != undefined then (
									
									gcount = 0
									for i  in $selection where (superclassof i == GeometryClass) do gcount += 1
									pbMax = 13 * gcount
									clearListener()
									suspendediting()
									disableSceneRedraw()
									setWaitCursor()
									enableUndo false
									errInfo_mass = true
									bNVC = _bNVC.checked
									chCol = noCOL.checked
									gUVpack = UVpack.checked
									gMeshFix = MeshFix.checked
									gVcDefolt = VCdef.value
									gNvcDefolt = NVCdef.value
									gValpha = vAlpha.checked
									
									if eVC.checked == true then		ver = 0X0C02FFFF			--VC Version
									if eGTA3.checked == true then	ver = 0x0800FFFF			--Standard GTA3 Version
									if eSA.checked == true then		ver = 0x1803FFFF			--SA Version
									format "\n=====================================\n"
									format ":       Mass DFF Export LOG        :\n=====================================\n\n"
									if exp_lockDFF == true then format "   [!] noBack lock dff is enabled!\n"
									try (
										for expObj in $selection where (superclassof expObj == GeometryClass) do (
											if expObj.numverts > 2 then (
													expObjArr = #()
												--expObj.transform = scaleMatrix [0,0,0]	

												append expObjArr expObj
												if expObj.children[1] != undefined then (
													lightArr = getObjLight expObj
													if lightArr != undefined then expObjArr += lightArr
												)
												if expfpath  != undefined then (
													fname = expfpath as string + "\\" + expObj.name as string + ".dff"
												)
												f = fopen fname "wb"
												if f != undefined then (
													geo_count = 0
													light_count = 0
													help_count = 0
													if exp_lockDFF == true then format "   [!] noBack lock dff is enabled!\n"
													for i  in expObjArr do (
														
														if (superclassof i == GeometryClass) then (
														geo_count+=1
														)
														if (superclassof i == light) then (
														light_count+=1
														)
														if (superclassof i == helper) then (
														help_count+=1
														)
													)
													pbUpdate()
													interfaceUpdate
													format "\n = info ======= rootObj: %\n   geometry: %\n   light:%\n   dummy: %\n" expObj.name geo_count light_count help_count
													DFFout f expObjArr false true CPV.checked NOR.checked 1.0 ver undefined 1 lockdff.checked
													fclose f
												)
											) else format "   - Error in mesh!\n"
										)
									) catch (
										local errMsg = getCurrentException()
										format "   [!] Exception during export: %\n" errMsg
										messageBox (" [Error]: write geometry\n\n" + errMsg) title: "Error export dff"
									)
									
									exp_lockDFF = false
									DFFexPara.pb.value = 100.0
									resumeediting()
									enableSceneRedraw()
									setArrowCursor()
									redrawViews()
									enableUndo true
									popPrompt()
									displayTempPrompt  "Dff Export finished" 2000
								)
							) 
						)
						if skipSingleExp == false then (
							defNull = false
							for tmpObj in $selection where (superclassof tmpObj == GeometryClass) do (
								if tmpObj.numverts < 3 then defNull = true
							)
							if defNull == true then (
								skipSingleExp = true
								MessageBox "Error in mesh!" title:"Export DFF - Model Geometry Error"
							)
						)
						--Upgradiable Parts--
						if skipSingleExp == false then (
							colcase = 0
							if noCOL.checked == true then colcase = 1
							if Vparts.checked == true then colcase = 2
								
							if (eSA.checked==true)AND(SAColBase==undefined)AND(colcase== 0) then messagebox "You need to supply a Collosion model for SA Export!"
							else (		
								RootObj = checkRoot $selection -- check one hierarchy
								if  RootObj != undefined then (
									----------------------
									--Scale the Root obj--
									----------------------
									bkupRootTran = RootObj.transform
									--expscale = RootObj.scale * ExSc.value
									--RootObj.transform = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]			
									if eVC.checked == true then		ver = 0X0C02FFFF			--VC Version
									if eGTA3.checked == true then	ver = 0x0800FFFF			--Standard GTA3 Version
									if eSA.checked == true then		ver = 0x1803FFFF			--SA Version
										
									fname = undefined
							
									if AppendFile.checked == true then (
										Sname = getopenfilename caption:"Append DFF File" types:"dff File (*.dff)|*.dff|"
										if Sname != undefined then (
											fo = fopen Sname "rb"
											if fo != undefined then  (
												no_clump = checkClump fo
												if no_clump == undefined then (
													messagebox "This DFF is locked !\nThe author of this model do not allow you to modify it.\n\nPlease contact the author for the permission." title:"Import Failed"
													fname = unefined
												) else (
													fseek fo (no_clump[no_clump.count]+4) #seek_set
													skip = readLong fo #unsigned
													readLong fo
													skip += (ftell fo)
													fname = (getFilenamePath Sname) + "temp.dff"
													if fname != undefined then (
														f = fopen fname "wb"
														fseek fo 0 #seek_set
														for i = 1 to skip do (
															writeByte f (readByte fo #unsigned)
														)--end for i
														fclose fo	
													)--end if fname	
												)
											)--end if fo
										)--end if Sname
									) else (
										fname = getsavefilename caption:"Export DFF File" types:"dff File (*.dff)|*.dff|"
										if fname != undefined then (
											f = fopen fname "wb"
										)
									)--end if/else AppendFile
								
									if f != undefined then (
										bNVC = _bNVC.checked
										chCol = noCOL.checked
										gUVpack = UVpack.checked
										gMeshFix = MeshFix.checked
										gVcDefolt = VCdef.value
										gNvcDefolt = NVCdef.value
										gValpha = vAlpha.checked
										geo_count = 0
										light_count = 0
										help_count = 0
										clearListener()
										suspendediting()
										disableSceneRedraw()
										setWaitCursor()
										enableUndo false
										format "\n=====================================\n"
										format ":           DFF Export LOG          :\n=====================================\n\n"
										expObjArr = #()
										--expObj = getRootObj $selection
										newHierarchyArr = #()
										hierarchyReSort $selection
										Allobjects = newHierarchyArr
										for i  in  Allobjects do (
											if (superclassof i == GeometryClass) then (
												geo_count+=1
											)
											if (superclassof i == light) then (
											light_count+=1
											)
											if (superclassof i == helper) then (
											help_count+=1
											)
										)
										pbMax = 7 + 6 * geo_count
										pbUpdate()
										interfaceUpdate
										if exp_lockDFF == true then format "   [!] noBack lock dff is enabled!\n"
										format " = info =\n   geometry: %\n   light:%\n   dummy: %\n" geo_count light_count help_count
										local result = undefined
										try (
											result = DFFout f Allobjects false true CPV.checked NOR.checked 1.0 ver SAColBase colcase lockdff.checked
										) catch (
											local errMsg = getCurrentException()
											format "   [!] Exception during export: %\n" errMsg
											messageBox (" [Error]: write geometry\n\n" + errMsg) title: "Error export dff"
										)
										if result == false then format "   [!] Warning: DFFout returned false (some objects couldn't be exported)\n"
										fclose f
										DFFexPara.pb.value = 100.0
										popPrompt()
										displayTempPrompt  "Dff Export finished" 2000
										resumeediting()
										enableSceneRedraw()
										setArrowCursor()
										redrawViews()
										enableUndo true
										exp_lockDFF = false
										if AppendFile.checked == true then (
											deleteFile Sname
											renameFile fname Sname
											format "\nModels appended to file:% !\n" Sname
										)else	format "\nfile:% exported!\n" fname
									
									)--end if f!=undefined	
								
									RootObj.transform = bkupRootTran		
								
								)--end if RootObj
							
							)
						)
					) else (MessageBox "The root object of the hierarchy can not be a LIGHT" title:"Export DFF - Selection Error")
				) else (MessageBox "Type of material should be only \"Standart\" or \"GTA Material\"!" title:"Export DFF - Model material Error")
			) else (MessageBox "Error in hierarchy of light!" title:"Export DFF - Model Selection Error")
		) else (MessageBox "Models not selected!" title:"Export DFF - Selection Error") --end

	)--end on exp

)--end rollout DFFexPara


rollout dmyHelper "Dummies/Bones Helper" (
	spinner dmyboxsize "Size: " range:[0.00000001,100000,dummysize]
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
global Kam_GTA
if Kam_GTA != undefined then ( closeRolloutFloater Kam_GTA; gc() )
Kam_GTA = newRolloutFloater "DFF IO" 200 530 10 50		
addRollout DFFinPara Kam_GTA rolledup:true
addRollout DFF2dfx Kam_GTA rolledup:true
addRollout DFFexPara Kam_GTA rolledup:false
addRollout dmyHelper Kam_GTA rolledup:true
addRollout aboutRoll Kam_GTA rolledup:true


