-- GTA IFP Animation Import/Export Tools
-- For skeletal animations and bone keyframes
-- 
-- Original by Kam (2005)
-- Modified by E2001 (2024-2026)
--
-- Separated from Character IO for standalone animation management

-- MUTEX: Close other IFP tools to prevent global variable conflicts
try (closeRolloutFloater Kam_GTAsaIFP) catch ()

-- Get script directory for relative paths
global ifpScriptPath = getFilenamePath(getThisScriptFilename())

-- Animation functions: Use 2018 Goldfish version (enhanced features)
fileIn (scriptspath+"\\GTA_Tools_2026\\gtaIFPio_Fn.ms") quiet:true

AnimInfo = #()
ifpname = undefined
PendingAnimData = #()  -- Stores data for new animations not yet written to file

/*
=============================================================================
   SECTION 1: ANIMATION (IFP) MANAGEMENT
   Uses: gtaIFPio_Fn.ms (2018 Goldfish Edition)
   Status: Working correctly
=============================================================================
*/

-- ===========================
-- ROLLOUT 1: ANIMATION
-- ===========================
rollout animateRoll "Animation" (
	local HInfo = undefined
	
	button loadifp "Load IFP File" width:120 align:#center tooltip:"Load skeletal animation file (.ifp) for editing"
	label lbl1 "Anim. File:" align:#left offset:[30,5]
	label lbl2 "Total Animation:" align:#left offset:[30,0]
	label lbl3 "Internal Name:" align:#left offset:[30,0]
	listbox AnimList height:10
	
	label lblSpacer1 "" height:8
	
	button btnRename "Rename" width:80 tooltip:"Rename selected animation (use Save File after)" across:2
	button btnDelete "Delete" width:80 tooltip:"Remove selected animation from list (use Save File after)"
	button btnMoveUp "Move UP" width:80 tooltip:"Move animation up in list order (affects in-game loading)" across:2
	button btnMoveDown "Move DOWN" width:80 tooltip:"Move animation down in list order (affects in-game loading)"
	button btnSaveNew "Add New Animation" width:120 tooltip:"Add current timeline as new animation to loaded IFP" align:#center
	button ReplaceAnim "Replace Animation" width:120 align:#center tooltip:"Replace selected animation with current timeline"
	button saveAnim "Export New IFP" width:120 align:#center tooltip:"Export current timeline as brand new IFP file"
	radioButtons formatType "Format:" labels:#("ANP3 (SA)", "ANPK (III/VC)") columns:2 default:1 align:#center offset:[0,0] tooltip:"SA uses ANP3 format, III/VC use ANPK format"
	checkbox useBoneID "Sibling" align:#left checked:false enabled:false offset:[85,-5]
	
	label lblSpacer2 "" height:8
	
	button RecOrg "M" width:17 align:#left tooltip:"Memorize current pose as original (for Reset button)" across:3
	button apyAnim "Apply Animation" width:86 align:#center tooltip:"Apply selected animation to character bones (matches by name)"
	button ResetPose "R" width:17 align:#right tooltip:"Reset character to memorized original pose"
	checkbox skipPos "Skip Position keys" align:#right offset:[5,-4] tooltip:"Ignore position keyframes (rotation only, for in-place animations)"
	
	label lblSpacer3 "" height:8
	
	spinner astart "Start" fieldwidth:30 type:#integer range:[0,10000,0] across:2 tooltip:"Starting frame for batch export"
	spinner aend "End" fieldwidth:30 type:#integer range:[0,10000,0] tooltip:"Ending frame for batch export"
	button batAnim "Batch Animation" width:122 align:#center tooltip:"Export multiple animations at once (range-based)"
	
	label lblSpacer4 "" height:8
	
	button btnSaveFile "Save File" width:120 tooltip:"Save all changes (rename/delete/move) to IFP file" align:#center
	label lblInfo3 "Use 'Save File' after renaming/deleting/moving" align:#center
	
	-- ===========================
	-- EVENT HANDLERS - ANIMATION
	-- ===========================
	
	-- Load IFP file and display animation list
	on loadifp pressed do (
		bkfile = ifpname
		ifpname = getOpenFileName caption:"Open GTA Animation File" types:"IFP animation (*.ifp)|*.ifp|All files (*.*)|*.*|"
		if (ifpname != undefined) then (
			f = fopen ifpname "rb"
			HInfo = ReadifpHeader f
			if HInfo == undefined then (
				fclose f
				messagebox "Header Data not correct!" Title:"IFP File Error"
			) 
			else (
				lbl1.text = "Anim. File: " + (filenameFromPath ifpname)
				lbl2.text = "Total Animation: " + (HInfo[1] as string)
				lbl3.text = "Internal Name: " + HInfo[2]
		
				AnimInfo = ifpAnimInfo f HInfo[1] HInfo[3]
				if AnimInfo == undefined then (
					fclose f
					messagebox "Animation Data not correct!!" Title:"IFP File Error"
				) else ( 
					AnimList.items = AnimInfo[1]
					PendingAnimData = #()  -- Clear pending animations when loading new file
					
					-- Auto-detect format and set radio buttons
					if AnimInfo[3] == 0x4B504E41 then (
						formatType.state = 2  -- ANPK (III/VC)
						useBoneID.enabled = true
					) else (
						formatType.state = 1  -- ANP3 (SA)
						useBoneID.enabled = false
					)
				)--end if/else AnimInfo
				fclose f
				astart.value = 1
				aend.value = HInfo[1]
			)--end if/else HInfo
		) else ifpname = bkfile
	)--end on loadifp
	
	-- Spinner range validation handlers
	on astart changed val do (
		if val < 1 then astart.value = 1
		if HInfo != undefined then (
			if astart.value > HInfo[1] then astart.value = HInfo[1]
			if astart.value > aend.value then aend.value = astart.value	
		) else astart.value = 0
	)
	
	on aend changed val do (
		if val < 1 then aend.value = 1
		if HInfo != undefined then (
			if aend.value > HInfo[1] then aend.value = HInfo[1]
			if aend.value < astart.value then astart.value = aend.value
		) else aend.value = 0
	)
	
	-- Record original pose for reset
	on RecOrg pressed do (
		OrginAry = #()
		for i = 1 to $selection.count do (
			setUserProp $selection[i] "OrgPos" $selection[i].pos
			setUserProp $selection[i] "OrgRot" [$selection[i].rotation.x,$selection[i].rotation.y,$selection[i].rotation.z]
			setUserProp $selection[i] "OrgRotW" $selection[i].rotation.w
			setUserProp $selection[i] "Orgscl" $selection[i].scale
		)	
		RecOrg.text = "**"
	)
	
	-- Reset to original pose
	on ResetPose pressed do (
		sliderTime = 0
		for i = 1 to $selection.count do (
			deletekeys $selection[i].pos.controller
			deletekeys $selection[i].rotation.controller
			deletekeys $selection[i].scale.controller
			try (
				tp = readvalue ((getUserProp $selection[i] "OrgRot") as stringstream)
				tpW = getUserProp $selection[i] "OrgRotW"
				$selection[i].rotation = (quat tp.x tp.y tp.z tpW)
				$selection[i].scale = readvalue ((getUserProp $selection[i] "Orgscl") as stringstream)
				$selection[i].pos = readvalue ((getUserProp $selection[i] "OrgPos") as stringstream)
			) catch (RecOrg.text = "M")
		)--end for i	
	)
	
	-- Apply selected animation to timeline
	on apyAnim pressed do (
		if (AnimList.selection > 0)AND($selection.count >0) then (
			rult = resetPost $selection slidertime
			if rult == false then RecOrg.text = "M"
			select $*
			f = fopen ifpname "rb"
			fseek f AnimInfo[2][AnimList.selection] #seek_set

			format "\nAnime: % at [%]\n" AnimList.selected (ftell f)
			
			ApplyAnim f ($selection as array) skipPos.checked slidertime AnimInfo[3]
		
			fclose f
			gc()
		)
	)--end on apyAnim
	
	-- Double-click animation list to apply
	on AnimList doubleclicked idx do (
		rult = resetPost $selection slidertime
		if rult == false then RecOrg.text = "M"
		select $*
		for i = 1 to $selection.count do (
			deletekeys $selection[i].pos.controller
			deletekeys $selection[i].rotation.controller
			deletekeys $selection[i].scale.controller
		)--end for i
		sliderTime = 0
		f = fopen ifpname "rb"
		fseek f AnimInfo[2][AnimList.selection] #seek_set

		format "\nAnime: % at [%]\n" AnimList.selected (ftell f)

		ApplyAnim f ($selection as array) skipPos.checked slidertime AnimInfo[3]
	
		fclose f
		gc()
	)--end on AnimList doubleclicked
	
	-- Batch apply multiple animations
	on batAnim pressed do (
		if (AnimList.selection > 0)AND($selection.count >0) then (
			sliderTime = 0
			if (getUserProp $selection[1] "OrgPos") == undefined then (
				for i = 1 to $selection.count do (
					setUserProp $selection[i] "OrgPos" $selection[i].pos
					setUserProp $selection[i] "OrgRot" [$selection[i].rotation.x,$selection[i].rotation.y,$selection[i].rotation.z]
					setUserProp $selection[i] "OrgRotW" $selection[i].rotation.w
					setUserProp $selection[i] "Orgscl" $selection[i].scale
				)
			)
			
			f = fopen ifpname "rb"
			for tt = astart.value to aend.value do (
				rult = resetPost $selection slidertime
				if rult == false then RecOrg.text = "M"
			
				fseek f AnimInfo[2][tt] #seek_set

				format "Anime: % at [%]\n" AnimInfo[1][tt] (ftell f)
			
				ApplyAnim f ($selection as array) skipPos.checked slidertime AnimInfo[3]

				animationRange = interval 0 (animationRange.end + 1)
				slidertime = animationRange.end
		
				gc()
			)--end for tt
			fclose f
			animationRange = interval 0 (animationRange.end - 1)
		)
	)--end on batAnim
	
	-- Animation management handlers
	on btnRename pressed do (
		if AnimList.selection == 0 then (
			messagebox "Please select an animation to rename!" title:"No Selection"
		) else (
			local oldName = AnimList.selected
			local selIndex = AnimList.selection
			global renameDialogResult = oldName
			
			-- Create a simple rollout for input
			rollout renameDialog "Rename Animation" (
				edittext txtName "New name:" text:renameDialogResult fieldwidth:150
				button btnOK "OK" width:80 align:#center
				button btnCancel "Cancel" width:80 align:#center offset:[0,-26]
				
				on btnOK pressed do (
					renameDialogResult = txtName.text
					destroyDialog renameDialog
				)
				on btnCancel pressed do (
					destroyDialog renameDialog
				)
			)
			
			createDialog renameDialog 200 90 modal:true
			local newNameInput = renameDialogResult
			
			if newNameInput != "" and newNameInput != oldName then (
				AnimInfo[1][selIndex] = newNameInput
				AnimList.items = AnimInfo[1]
				AnimList.selection = selIndex
				format "Renamed: % -> %\n" oldName newNameInput
			)
		)
	)
	
	on btnDelete pressed do (
		if AnimList.selection == 0 then (
			messagebox "Please select an animation to delete!" title:"No Selection"
		) else (
			animName = AnimList.selected
			result = queryBox ("Delete animation: " + animName + "?") title:"Confirm Delete"
			if result then (
				deleteItem AnimInfo[1] AnimList.selection
				deleteItem AnimInfo[2] AnimList.selection
				HInfo[1] = HInfo[1] - 1
				AnimList.items = AnimInfo[1]
				lbl2.text = "Total Animation: " + (HInfo[1] as string)
				format "Deleted: %\n" animName
			)
		)
	)
	
	on btnMoveUp pressed do (
		if AnimList.selection == 0 then (
			messagebox "Please select an animation to move!" title:"No Selection"
		) else if AnimList.selection == 1 then (
			messagebox "Animation is already at the top!" title:"Can't Move"
		) else (
			idx = AnimList.selection
			-- Swap with previous animation
			tempName = AnimInfo[1][idx]
			tempData = AnimInfo[2][idx]
			AnimInfo[1][idx] = AnimInfo[1][idx-1]
			AnimInfo[2][idx] = AnimInfo[2][idx-1]
			AnimInfo[1][idx-1] = tempName
			AnimInfo[2][idx-1] = tempData
			AnimList.items = AnimInfo[1]
			AnimList.selection = idx - 1
			format "Moved up: %\n" tempName
		)
	)
	
	on btnMoveDown pressed do (
		if AnimList.selection == 0 then (
			messagebox "Please select an animation to move!" title:"No Selection"
		) else if AnimList.selection == AnimInfo[1].count then (
			messagebox "Animation is already at the bottom!" title:"Can't Move"
		) else (
			idx = AnimList.selection
			-- Swap with next animation
			tempName = AnimInfo[1][idx]
			tempData = AnimInfo[2][idx]
			AnimInfo[1][idx] = AnimInfo[1][idx+1]
			AnimInfo[2][idx] = AnimInfo[2][idx+1]
			AnimInfo[1][idx+1] = tempName
			AnimInfo[2][idx+1] = tempData
			AnimList.items = AnimInfo[1]
			AnimList.selection = idx + 1
			format "Moved down: %\n" tempName
		)
	)
	
	on btnSaveNew pressed do (
		if ifpname == undefined then (
			messagebox "Please load an IFP file first!" title:"No IFP Loaded"
		) else if AnimInfo[3] != 0x33504E41 then (
			messagebox "Save New only works with SA format IFP files currently.\n\nVC format support coming soon." title:"Format Not Supported"
		) else (
			select $*
			if $selection.count == 0 then (
				messagebox "No objects selected! Select bones with BoneID properties." title:"No Selection"
			) else (
				-- Filter to only objects with BoneID
				for obj in $selection where (getUserProp obj "BoneID") == undefined do deselect obj
				
				if $selection.count == 0 then (
					messagebox "No bones with BoneID found! Set BoneID user properties on bones." title:"No Bones"
				) else (
					-- Create input dialog
					rollout newAnimDialog "Save New Animation" (
						local newAnimResult = "NEW_ANIM"
						edittext txtName "Animation name:" text:"NEW_ANIM" fieldwidth:150
						button btnOK "OK" width:80 align:#center
						button btnCancel "Cancel" width:80 align:#center offset:[0,-26]
						
						on btnOK pressed do (
							newAnimResult = txtName.text
							destroyDialog newAnimDialog
						)
						on btnCancel pressed do (
							newAnimResult = ""
							destroyDialog newAnimDialog
						)
						
						fn getResult = (
							return newAnimResult
						)
					)
					
					createDialog newAnimDialog 200 90 modal:true
					local newAnimName = newAnimDialog.getResult()
					
					if newAnimName != "" then (
						-- Check for duplicate names
						if findItem AnimInfo[1] newAnimName != 0 then (
							messagebox ("Animation '" + newAnimName + "' already exists!") title:"Duplicate Name"
						) else (
							try (
								-- Export animation to temp file
								tempFile = (getFilenamePath ifpname) + "temp_new_anim.bin"
								ff = fopen tempFile "wb"
								
								local animLength = ExpsaIFP ff ($selection as array) newAnimName
								
								fclose ff
								
								if animLength != undefined then (
									-- Read animation data back
									ff = fopen tempFile "rb"
									newAnimData = #()
									fseek ff 0 #seek_end
									dataSize = ftell ff
									
									if dataSize > 28 then (  -- Minimum valid SA animation size
										fseek ff 0 #seek_set
										for i = 1 to dataSize do (
											append newAnimData (readByte ff)
										)
										fclose ff
										deleteFile tempFile
										
										-- Validate: read back name from first 24 bytes
										validName = ""
										for b = 1 to 24 do (
											if newAnimData[b] == 0 then exit
											validName += bit.intAsChar newAnimData[b]
										)
										
										format "Exported animation data: name='%', size=%\n" validName dataSize
										
										if validName == newAnimName then (
											-- Store in pending array (offset will be updated when saved)
											append PendingAnimData newAnimData
											
											-- Add to AnimInfo arrays
											append AnimInfo[1] newAnimName
											append AnimInfo[2] -1  -- Placeholder offset, will be set during Save File
											
											-- Update UI
											AnimList.items = AnimInfo[1]
											AnimList.selection = AnimInfo[1].count
											lbl2.text = "Total Animation: " + (AnimInfo[1].count as string)
											
											format "Added new animation: % (% bytes, pending save)\n" newAnimName dataSize
											format "Click 'Save File' to write changes to disk.\n"
											
											messagebox ("Added new animation: " + newAnimName + "\n\nClick 'Save File' button to write to disk.") title:"Animation Added"
										) else (
											messagebox ("Export validation failed!\n\nExpected name: " + newAnimName + "\nGot name: " + validName) title:"Export Error"
											format "Export validation failed: expected '%', got '%'\n" newAnimName validName
										)
									) else (
										fclose ff
										deleteFile tempFile
										messagebox ("Animation data too small (" + (dataSize as string) + " bytes)\n\nMake sure bones have animation keys.") title:"Export Failed"
										format "Export failed: data too small (% bytes)\n" dataSize
									)
								) else (
									fclose ff
									deleteFile tempFile
									messagebox "Failed to export animation data!" title:"Export Failed"
								)
								
							) catch (
								try (fclose ff) catch()
								try (deleteFile tempFile) catch()
								messagebox ("Error creating animation:\n" + (getCurrentException())) title:"Export Error"
								format "Export error: %\n" (getCurrentException())
							)
						)
					)
				)
			)
		)
	)
	
	-- Save File button - Rebuilds entire IFP after rename/delete/move operations
	on btnSaveFile pressed do (
		if ifpname == undefined then (
			messagebox "No IFP file loaded!" title:"No File"
		) else (
			result = queryBox "Save all management changes (rename/delete/move) to file?\n\nThis will rebuild the entire IFP file." title:"Confirm Save"
			if result then (
				try (
					-- Backup original file
					backupName = ifpname + ".bak"
					DOSCommand ("copy \"" + ifpname + "\" \"" + backupName + "\"")
					
					-- Create a sorted mapping to read animations in physical file order
					f = fopen ifpname "rb"
					
					-- Build array of [index, offset] pairs, separate pending from existing
					sortedMapping = #()
					pendingIndices = #()
					
					for i = 1 to AnimInfo[1].count do (
						if AnimInfo[2][i] == -1 then (
							-- This is a pending new animation
							append pendingIndices i
						) else (
							-- Existing animation in file
							append sortedMapping #(i, AnimInfo[2][i])
						)
					)
					
					-- Sort existing animations by offset (physical file order)
					qsort sortedMapping (fn cmp a b = ( if a[2] < b[2] then -1 else if a[2] > b[2] then 1 else 0 ))
					
					-- Read all animation data - build properly indexed array
					animDataArray = #()
					for i = 1 to AnimInfo[1].count do append animDataArray undefined  -- Initialize all slots
					
					-- Read existing animations from file
					for i = 1 to sortedMapping.count do (
						origIndex = sortedMapping[i][1]  -- Original logical index
						offset = sortedMapping[i][2]      -- Physical offset in file
						
						fseek f offset #seek_set
						
						-- Determine animation data length from physical order
						if i < sortedMapping.count then (
							dataLength = sortedMapping[i+1][2] - offset
						) else (
							-- Last animation: calculate from header instead of EOF (file may have padding)
							fseek f offset #seek_set
							-- Read name field
							local animName = readString f
							local skipBytes = 23 - animName.count
							fseek f skipBytes #seek_cur
							-- Read bone count and frame data size
							local boneCount = readLong f
							local frameDataSize = readLong f
							-- Total animation size: name(24) + boneCount(4) + frameSize(4) + unknown(4) + frameData + boneHeaders
							dataLength = 36 + frameDataSize + (36 * boneCount)
							format "Last animation '%': calculated length %L bytes (not EOF)\n" animName dataLength
						)
						
						-- Read animation data
						fseek f offset #seek_set
						animData = #()
						for b = 1 to dataLength do (
							append animData (readByte f)
						)
						
						-- Store in logical position
						animDataArray[origIndex] = animData
					)
					fclose f
					
					-- Add pending animations from memory
					local pendingIdx = 1
					for idx in pendingIndices do (
						animDataArray[idx] = PendingAnimData[pendingIdx]
						pendingIdx += 1
					)
					
					-- Write new IFP file with animations in new order
					tempName = (getFilenamePath ifpname) + "temp_rebuild.ifp"
					ff = fopen tempName "wb"
					
					if ff == undefined then (
						messagebox ("Failed to create temp file!\nPath: " + tempName + "\n\nCheck if directory exists and is writable.") title:"File Creation Error"
						try (fclose f) catch()
						return undefined
					)
					
					if AnimInfo[3] == 0x33504E41 then (
						-- SA format header
						writeLong ff AnimInfo[3] #unsigned  -- ANP3
						writeLong ff 0  -- File length placeholder
						writeString ff HInfo[2]  -- Name string (null-terminated)
						skipbyte = 23 - HInfo[2].count
						for i = 1 to skipbyte do writeByte ff 0  -- Pad to 24 bytes total
						writeLong ff AnimInfo[1].count  -- Animation count
					) else (
						-- VC format header
						writeLong ff AnimInfo[3] #unsigned  -- ANPK
						writeLong ff 0  -- File length placeholder
						writeLong ff 0x4F464E49 #unsigned  -- INFO
						infoLength = HInfo[2].count + 1 + 4  -- string + null + count
						skipbyte = 4 - (mod (HInfo[2].count + 1) 4)
						if skipbyte != 4 then infoLength += skipbyte
						writeLong ff infoLength
						writeLong ff AnimInfo[1].count  -- Animation count
						writeString ff HInfo[2]  -- Name string
						if skipbyte != 4 then (
							for i = 1 to skipbyte do writeByte ff 0  -- 4-byte alignment padding
						)
					)
					
					-- Write all animations in new order
					for i = 1 to animDataArray.count do (
						animData = animDataArray[i]
						
						if animData == undefined then (
							format "ERROR: Animation % has undefined data!\n" i
							continue
						)
						
						-- Always update embedded animation name (for renames and new animations)
						if AnimInfo[3] == 0x33504E41 then (
							-- SA format: name is first 24 bytes of animation data
							newName = AnimInfo[1][i]
							nameBytes = #()
							
							-- Convert string to byte array
							for c = 1 to newName.count do (
								append nameBytes (bit.charasint newName[c])
							)
							append nameBytes 0  -- Null terminator
							
							-- Pad to 24 bytes
							while nameBytes.count < 24 do append nameBytes 0
							
							-- Replace first 24 bytes with current name from AnimInfo
							for b = 1 to 24 do (
								animData[b] = nameBytes[b]
							)
							
							-- Debug: Verify embedded name
							local embeddedName = ""
							for b = 1 to 24 do (
								if animData[b] == 0 then exit
								embeddedName += bit.intAsChar animData[b]
							)
							format "  Embedded name in data: '%'\n" embeddedName
							
						) else (
							-- VC format: NAME chunk structure - more complex, skip for now
							-- Would need to parse NAME chunk and adjust lengths
						)
						
						-- Write animation data
						for b in animData do (
							writeByte ff b
						)
					)
					
					-- Update file length in header
					local totalSize = ftell ff
					fileLength = totalSize - 8
					fseek ff 4 #seek_set
					writeLong ff fileLength
					fclose ff
					
					-- Backup and replace original with rebuilt file
					DOSCommand ("copy \"" + ifpname + "\" \"" + backupName + "\"")
					deleteFile ifpname
					renameFile tempName ifpname
					
					-- Reload file to rebuild AnimInfo with correct offsets
					f = fopen ifpname "rb"
					HInfo = ReadifpHeader f
					AnimInfo = ifpAnimInfo f HInfo[1] HInfo[3]
					fclose f
					
					AnimList.items = AnimInfo[1]
					lbl2.text = "Total Animation: " + (HInfo[1] as string)
					
					-- Clear pending animations after successful save
					PendingAnimData = #()
					local msg = "File saved successfully with " + (AnimInfo[1].count as string) + " animations!\n\nBackup: " + (filenameFromPath backupName)
					messagebox msg title:"Save Complete"
					
				) catch (
					try (fclose f) catch()
					try (fclose ff) catch()
					local errMsg = getCurrentException()
					format "\n!!! SAVE ERROR !!!\n%\n" errMsg
					messagebox ("Error saving file:\n" + errMsg) title:"Save Failed"
				)
			)
		)
	)
	
	-- Animation format changes
	on formatType changed state do (
		-- State 1 = ANP3 (SA), State 2 = ANPK (III/VC)
		if state == 2 then (
			useBoneID.enabled = true
		) else (
			useBoneID.enabled = false
		)
	)
	
	on useBoneID changed state do (
		if useBoneID.checked == true then useBoneID.text = "Bone ID"
		else useBoneID.text = "Sibling"
	)
	
	-- Replace animation in loaded IFP file
	on ReplaceAnim pressed do (
		select $*
		sliderTime = 0
		if (AnimList.selection != 0)AND($selection.count >0) then (
			OK2Append = false
			-- Verify format matches: State 1 = ANP3 (0x33504E41), State 2 = ANPK (0x4B504E41)
			if (formatType.state == 2)AND(AnimInfo[3] == 0x4B504E41) then OK2Append = true
			if (formatType.state == 1)AND(AnimInfo[3] == 0x33504E41) then OK2Append = true
			if OK2Append == false then (
				messagebox "Cannot replace animation:\n\nFile format does not match selected format.\n\nANP3 (SA) and ANPK (III/VC) cannot be mixed." title: "IFP Format Mismatch"
			) else (
				for obj in $selection where (getUserProp obj "BoneID") == undefined do deselect obj

				try (	--undefined*undefined
					Sname = (getFilenamePath ifpname) + "ttemp.bin"
					format "\nReplace Anime: % at [%]\n" AnimList.selected AnimInfo[2][AnimList.selection]
					ff = fopen Sname "wb"
					f = fopen ifpname "rb"
					fseek f 0 #seek_end
					edf = ftell f
					fseek f 0 #seek_set
					for i = 1 to AnimInfo[2][AnimList.selection] do (
						writebyte ff (readByte f)
					)--end for i
		
					if AnimInfo[3] == 0x33504E41 then thisLength = ExpsaIFP ff ($selection as array) AnimList.selected
					else  thisLength = expAnim ff ($selection as array) useBoneID.checked AnimList.selected
		
					if AnimList.selection != AnimInfo[2].count then (
						fseek f AnimInfo[2][(AnimList.selection + 1)] #seek_set
						for i = AnimInfo[2][(AnimList.selection + 1)] to (edf - 1) do (
							writebyte ff (readByte f)
						)--end for i
					)--end if
		
					fclose f
					animLength = (ftell ff) - 8
					fseek ff 4 #seek_set
					writeLong ff animLength
					fclose ff
					gc()
			
					deleteFile ifpname
					renameFile Sname ifpname
			
					f = fopen ifpname "rb"
					HInfo = ReadifpHeader f
					AnimInfo = ifpAnimInfo f HInfo[1] HInfo[3]
					fclose f

					format "DONE!!\n\n"	

				) catch (
					fclose ff
					fclose f
					-----------------------
					--This is GMax output--
					-----------------------
					Sname = (getFilenamePath ifpname) + "ReplaceIFP.txt"
					ss = "" as stringstream

					if AnimInfo[3] == 0x33504E4 then thisLength = gExpsaIFP ss ($selection as array) AnimList.selected
					else  thisLength = gm_expAnim ss $selection useBoneID.checked AnimList.selected

					f = fopen ifpname "rb"

					if AnimList.selection != AnimInfo[2].count then (
						oldLength = AnimInfo[2][(AnimList.selection + 1)] - AnimInfo[2][AnimList.selection]
					) else (
						fseek f 0 #seek_end
						oldLength = (ftell f ) - AnimInfo[2][AnimList.selection]
					)
					thisoffset = thisLength - oldLength

					fseek f 4 #seek_set
					IFPLength = readLong f
					readLong f				
					infolength = readLong f

					clearlistener()
					format "<!-- path=\"%\" -->\n" Sname
					format"//\n//\n//This is Header Section\n//Please Replace this over the original Header\n"  

					if AnimInfo[3] == 0x33504E41 then (
						format "c 4\nANP3\ni 1\n%\n" (IFPLength + thisoffset)
						format "c 24\n%\ni 1\n%\n//\n//\n" HInfo[2] HInfo[1]
					) else (
						format "c 4\nANPK\ni 1\n%\n" (IFPLength + thisoffset)
						format "c 4\nINFO\ni 2\n% %\n" infolength (readLong f)
						format "c %\n%\n//\n//\n" (infolength - 4) (readString f)
					)
					format "%\n//" (ss as string)

					fclose f
				)
				gc()
			)
		)--end if AnimList.selection
	)--end on ReplaceAnim 
	
	-- Export selection as new IFP file
	on saveAnim pressed do (
		if (AnimList.selection != 0)AND($selection.count >0) then (
			Sname = getSaveFileName caption:"Save GTA Animation file" types:"IFP animation (*.ifp)|*.ifp"
			if Sname != undefined then (
				for obj in $selection where (getUserProp obj "BoneID") == undefined do deselect obj
			
				try (	--undefined*undefined
					f = fopen Sname "wb"

					if formatType.state == 1 then (   					--ANP3 (SA)
						writeLong f 0x33504E41		--ANP3
						writeLong f 0
						writeString f "KamMaxScriptExp"
						for i = 1 to 8 do ( writeByte f 0 )
						writeLong f 1

						thisLength = ExpsaIFP f ($selection as array) AnimList.selected
						size = ftell f
						fseek f 4 #seek_set
						writeLong f (size - 8)
					) else (   					   									--ANPK (III/VC)
						writeLong f 0x4B504E41		--ANPK
						writeLong f 0
						writeLong f 0x4F464E49		--INFO
						writeLong f 20
						writeLong f 1
						writeString f "KamMaxScriptExp"
			
						thisLength = expAnim f ($selection as array) useBoneID.checked AnimList.selected
						size = ftell f
						fseek f 4 #seek_set
						writeLong f (size - 8)
					)
					format "Size:%\n" (thisLength as integer)
					format "DONE!!\n\n"
					fclose f	
				) catch (
					fclose ff
					fclose f
					-----------------------
					--This is GMax output--
					-----------------------
					Sname = (substring Sname 1 (Sname.count - 4)) + ".txt"
					ss = "" as stringstream

					clearlistener()
					format "<!-- path=\"%\" -->\n" Sname
					format"//\n//\n//This is Header Section\n"  

					if formatType.state == 1 then (   					--ANP3 (SA)
						thisLength = gExpsaIFP ss ($selection as array) AnimList.selected
						format "c 4\nANP3\ni 1\n%\n" (thisLength + 28)
						format "c 24\nKamMaxScriptExp\n//\n//\n"
						format "i 1\n1\n"
					) else (																		--ANPK (III/VC)
						thisLength = gm_expAnim ss ($selection as array) useBoneID.checked AnimList.selected
						format "c 4\nANPK\ni 1\n%\n" (thisLength + 28)
						format "c 4\nINFO\ni 2\n20 1\n"
						format "c 16\nKamMaxScriptExp\n//\n//\n"
					)	

					format "%\n//" (ss as string)
				)--end try/catch
				gc()
			)--end if Sname
		)--end if AnimList.selection
	)--end on saveAnim
)--end rollout animateRoll

/*
=============================================================================
   SECTION 2: ABOUT
=============================================================================
*/

-- ===========================
-- ROLLOUT 2: ABOUT
-- ===========================
rollout aboutRoll "About" (
	label l1 "GTA IFP Animation IO V2.0"
	label l1a "February, 2026"
	label l2 "Code based on Kam's GTA_IFP_IO v1.1"
	label l2a "and 2018 Goldfish Edition."
	label l2b ""
	label l3 "Enhanced by E2001"
	label l3a "Animation management tools"
)

/*
=============================================================================
   FLOATER CREATION
=============================================================================
*/

if Kam_GTAsaIFP != undefined then ( closeRolloutFloater Kam_GTAsaIFP; gc() )
Kam_GTAsaIFP = newRolloutFloater "Animation IFP IO" 220 600 10 30
addRollout animateRoll Kam_GTAsaIFP
addRollout aboutRoll Kam_GTAsaIFP rolledup:true
