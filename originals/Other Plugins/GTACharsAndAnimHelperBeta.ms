/**************************************************************************************************************************
// This script was made by Shagg_E
// http://newrockstar.do.am
// http://youtube.com/user/NewrockstarGames
//
// Some parts of code of "Helper Manager" by Lorne Brooks have been used in this script.
// Email: lbtools2k@gmail.com
//
// This script is not copyrighted, please feel free to modify or distribute.
**************************************************************************************************************************/

global NewBH_Number = 1000
global NewHI_Number = 0
--global NewHIE_Number = 0
global NewAO_Number = 0
global NewBiped_Number = 1000
global Char_Helper_Rollout
callbacks.removeScripts id:#charhelper
global g_LBTools_HM

struct s_LBTools_helperManager
(
	/*==================================================================================
	// Structure variables
	====================================================================================*/

	HelperManagerFloater,
	Main_Rollout,
	AddToSelection_Rollout,
	AddHelpers_Rollout,
	About_Rollout,
	HM_Pos,
	helperSize = 0.01, --// Size variable for point and dummy helpers
	a_newPoints = #(), --// Used by the add helpers method
	a_newDummies = #(), --// Used by the add helpers method

	/*==================================================================================
	// Structure functions
	====================================================================================

	f_getAllChildren
	f_selectHierarchyRoot
	f_selectHierarchy
	f_findSkinModifier
	f_collectSkinMeshes
	f_collectSkinBoneLists
	f_collectWeightMeshes
	f_helperManager

	===================================================================================*/

	fn f_getAllChildren obj &a_nodes:#() = --// Recursive function
	(
		for c in obj.children do
		(
			append a_nodes c
			f_getAllChildren c a_nodes:a_nodes
		)
		a_nodes
	),

	fn f_selectHierarchyRoot obj = --// Recursive function
	(
		if selection.count > 0 do
		(
			if obj.parent != undefined do
			(
				select obj.parent
				f_selectHierarchyRoot selection[1]
			)
		)
	),

	fn f_selectHierarchy obj =
	(
		if selection.count > 0 do
		(
			f_selectHierarchyRoot obj
			select (f_getAllChildren selection[1] a_nodes:(selection as array))
		)
	),

	fn f_findSkinModifier obj =
	(
		local skinFound = false
		for i = 1 to obj.modifiers.count do
		(
			if classof obj.modifiers[i] == Skin do
			(
				skinFound = true
				exit
			)
		)
		skinFound
	),

	fn f_collectSkinMeshes a_origBones =
	(
		local a_skins = #()
		for obj in geometry do
		(
			if (f_findSkinModifier obj) do
			(
				--// Compare a bone in the Skin list for a match with a corresponding bone in the original hierarchy array
				select obj
				setCommandPanelTaskMode #modify
				modPanel.setCurrentObject obj.modifiers[#Skin]
				local boneListCount = skinOps.GetNumberBones obj.skin
				if boneListCount > 0 do
				(
					local boneName = skinOps.getBoneName obj.skin 1 1
					for i = 1 to a_origBones.count do
					(
						if boneName == a_origBones[i].name do
						(
							append a_skins obj
							exit
						)
					)
				)
			)
		)
		clearSelection()
		a_skins
	),

	fn f_collectSkinBoneLists a_meshes =
	(
		local a_boneLists = #()
		for obj in a_meshes do
		(
			append a_boneLists #(obj)
			select obj
			setCommandPanelTaskMode #modify
			modPanel.setCurrentObject obj.modifiers[#Skin]
			local boneListCount = skinOps.GetNumberBones obj.skin
			if boneListCount > 0 do
			(
				for i = 1 to boneListCount do
				(
					append a_boneLists[a_boneLists.count] (skinOps.getBoneName obj.skin i 1)
				)
			)
		)
		a_boneLists
	),

	fn f_collectWeightMeshes a_meshes =
	(
		local a_skinWeights = #()
		for obj in a_meshes do
		(
			skinUtils.ExtractSkinData obj
			append a_skinWeights (getNodeByName ("SkinData_" + obj.name))
		)
		a_skinWeights
	)
)
g_LBTools_HM = s_LBTools_helperManager()

fn SelectHierarchyRootOnly obj =
(
	if obj.parent != undefined do
	(
		select obj.parent
		SelectHierarchyRootOnly selection[1]
	)
)

fn SelectAllChildren obj =
(
	if obj.children.count > 0 do
	(
		for child in obj.children do
		(
			selectmore child
			SelectAllChildren child
		)
	)
)

fn SelectAllHierarchy obj =
(
	SelectHierarchyRootOnly obj
	if selection[1] != undefined do SelectAllChildren selection[1]
)

fn IncreaseBHNumber =
(
	for obj in objects do
	(
		if getUserProp obj "BHNumber" != undefined then
		(
			local OldBH_Number = getUserProp obj "BHNumber"
			if OldBH_Number > NewBH_Number then NewBH_Number = OldBH_Number
		)
	)
	NewBH_Number = NewBH_Number + 1
)	

fn IncreaseHIBoneNumber =
(	
	for obj in objects do
	(
		if getUserProp obj "HIBoneNumber" != undefined then
		(
			local OldHI_Number = getUserProp obj "HIBoneNumber"
			if OldHI_Number > NewHI_Number then NewHI_Number = OldHI_Number
		)
	)
	NewHI_Number = NewHI_Number + 1
)

/*
fn IncreaseHIEyesNumber =
(	
	for obj in objects do
	(
		if getUserProp obj "HIEyesNumber" != undefined then
		(
			local OldHIE_Number = getUserProp obj "HIEyesNumber"
			if OldHIE_Number > NewHIE_Number then NewHIE_Number = OldHIE_Number
		)
	)
	NewHIE_Number = NewHIE_Number + 1
)*/

fn IncreaseAONumber =
(	
	for obj in objects do
	(
		if getUserProp obj "AOBoneNumber" != undefined then
		(
			local OldAO_Number = getUserProp obj "AOBoneNumber"
			if OldAO_Number > NewAO_Number then NewAO_Number = OldAO_Number
		)
	)
	NewAO_Number = NewAO_Number + 1
)

fn IncreaseBipedNumber =
(
	for obj in objects do
	(
		if getUserProp obj "BipedNumber" != undefined then
		(
			local OldBiped_Number = getUserProp obj "BipedNumber"
			if OldBiped_Number > NewBiped_Number then NewBiped_Number = OldBiped_Number
		)
	)
	NewBiped_Number = NewBiped_Number + 1
)

fn RoundUp2 RValue RAccValue =
(
	return ((ceil (RValue / RAccValue)) * RAccValue)
)

/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

rollout Char_Helper_Rollout "Char Helper" width:132 height:170
(
	group "Set BoneID"-- and FrameNames"
	(
		spinner spn_BoneID "BoneID: " range:[0, 100000, 0] type:#integer align:#left offset:[2,0] fieldwidth:45 across:2
		button btn_BoneIDSet "Set" width:25 height:18 pos:[116,25] tooltip:"Applies BoneID for selected bone."
		--edittext txt_FrameName "FrameName:" text:"Bone Name" height:18 fieldWidth:127 labelOnTop:true across:2
		--button btn_FrameNameSet "Set" width:25 height:18 pos:[144,66] align:#right tooltip:"Applies FrameName for selected bone."
		--checkbox chkbx_RenameBone "Rename bone too" align:#left checked:true tooltip:"Also renames bone too."
	)
	group "Create bones"
	(
		button btn_CreateRootB "Create Root" width:71 align:#left across:2 tooltip:"Creates a Root bone at the center of scene."
		button btn_CreateChildB "Add Children" width:76 align:#right tooltip:"Adds children bone for selected one.\nSelect ONE bone and push this button."
	)
	group "Indexes and Types of bones"
	(
		button btn_SetBoneIDnTypes "Calculate for all hierarchy" tooltip:"Automatically calculates BoneType and BoneIndex parameters for custom bone hierarchy.\nSelect any bone of hierarchy and push this button."
	)
	
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	
	fn BoneIDsAndFrameNames =
	(
		if selection.count == 1 then
		(
			if getUserProp $ "BoneID" != undefined or getUserProp $ "BoneId" != undefined then
			(
				spn_BoneID.enabled = true
				if getUserProp $ "BoneID" != undefined  then spn_BoneID.value = getUserProp $ "BoneID"
				else spn_BoneID.value = getUserProp $ "BoneId"
			)
			else
			(
				spn_BoneID.value = 0
				spn_BoneID.enabled = false
			)
			/*if getUserProp $ "FrameName" != undefined then
			(
				txt_FrameName.enabled = true
				txt_FrameName.text = getUserProp $ "FrameName"
			)
			else
			(
				txt_FrameName.text = "<no data>"
				txt_FrameName.enabled = false
			)*/
		)
		else
		(
			spn_BoneID.value = 0
			spn_BoneID.enabled = false
			/*if selection.count > 1 then
			(
				txt_FrameName.text = "<multiple selected>"
			)
			else
			(
				txt_FrameName.text = "<none selected>"
			)
			txt_FrameName.enabled = false*/
		)
	)
	
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/

	on Char_Helper_Rollout open do
	(
		callbacks.addScript #selectionSetChanged "Char_Helper_Rollout.BoneIDsAndFrameNames()" id:#charhelper
		BoneIDsAndFrameNames()
	)

	on Char_Helper_Rollout close do
	(
		callbacks.removeScripts id:#charhelper
	)

/*	on spn_BoneID entered val do
	(
		if selection.count == 1 do
		(
			--setUserProp $ "BoneID" spn_BoneID.value
			if getUserProp $ "BoneID" != undefined do setUserProp $ "BoneID" spn_BoneID.value
			if getUserProp $ "BoneId" != undefined do setUserProp $ "BoneId" spn_BoneID.value
		)
	)*/
	
/*	on spn_BoneID changed val do
	(
		if selection.count == 1 do
		setUserProp $ "BoneID" spn_BoneID.value
	)*/
	
	on btn_BoneIDSet pressed do
	(
		if selection.count == 1 do
		(
			if getUserProp $ "BoneID" != undefined do setUserProp $ "BoneID" spn_BoneID.value
			if getUserProp $ "BoneId" != undefined do setUserProp $ "BoneId" spn_BoneID.value
		)
	)

/*	on txt_FrameName entered txt do
	(
		if selection.count == 1 do
		setUserProp $ "FrameName" (replace_LF_with_CRLF txt_FrameName.text)
		--//setUserPropBuffer $ (replace_LF_with_CRLF spn_FrameName.text)
	)*/
	
/*	on txt_FrameName changed txt do
	(
		if selection.count == 1 do
		setUserProp $ "FrameName" (replace_LF_with_CRLF txt_FrameName.text)
	)*/
	
	/*on btn_FrameNameSet pressed do
	(
		if selection.count == 1 do
		(
			if chkbx_RenameBone.state do $.name = txt_FrameName.text
			txt_FrameName.text = stripSpace txt_FrameName.text
			setUserProp $ "FrameName" txt_FrameName.text
		)
	)*/

	on btn_CreateRootB pressed do
	(
		clearselection()
		local nrtbn = bone pos: [0.0,0.0,0.0] wirecolor:yellow
		nrtbn.name = "Root"
		setUserProp nrtbn "BoneID" "0"
		--setUserProp nrtbn "FrameName" "Root"
		local nrtbnTempDummy = dummy boxsize:([0.001,0.001,0.001])
		nrtbn.baseobject = nrtbnTempDummy
		delete nrtbnTempDummy
		select nrtbn
	)	
	
	on btn_CreateChildB pressed do
	(
		if selection.count == 1 then
		(
			local nrtbnParent = selection[1]
			local nrtbn = bone wirecolor:yellow
			nrtbn.transform = nrtbnParent.transform
			local nrtbnParentChildCountS = (nrtbnParent.children.count + 1) as string
			local nrtbnName = nrtbnParent.name + "Ch" + nrtbnParentChildCountS
			nrtbn.name = nrtbnName
			--g_LBTools_HM.f_selectHierarchy selection[1]
			SelectAllHierarchy selection[1]
			local nrtbnBoneID = selection.count as string
			clearselection()
			setUserProp nrtbn "BoneID" nrtbnBoneID
			--setUserProp nrtbn "FrameName" (stripSpace nrtbnName)
			nrtbn.parent = nrtbnParent
			local nrtbnTempDummy = dummy boxsize:([0.001,0.001,0.001])
			nrtbn.baseobject = nrtbnTempDummy
			delete nrtbnTempDummy
			select nrtbn
		)
		else messageBox "Select ONE bone and THEN push that button!" title:"ERROR"
	)
	
	on btn_SetBoneIDnTypes pressed do
	(
		if (queryBox "Have you selected any bone of hierarchy?" title:"WARNING") do
		(
			if selection[1] != undefined and (selection[1].children.count > 0 OR selection[1].parent != undefined) then
			(
				--g_LBTools_HM.f_selectHierarchy selection[1]
				SelectAllHierarchy selection[1]
				for s in selection do
				(
					setUserProp s "BoneIndex" "fuckyouasshole"
				)
				clearselection()
				for o in objects where getUserProp o "BoneIndex" == "fuckyouasshole" do selectmore o --// New Selection Order(as in the hierarchy)
				local NewBoneIndex = 0
				for s in selection do
				(
					setUserProp s "BoneIndex" NewBoneIndex
					NewBoneIndex = NewBoneIndex + 1
				)
				local a = #()
				local ChildrenLevel = 0
				local PreviousBoneIndex = 0
				for s in selection do
				(
					local p = s.parent
					if p == undefined then
					(
						setUserProp s "BoneType" "0" --// is the last or only child, has children
					)
					else
					(
						if getUserProp p "BoneIndex" == PreviousBoneIndex then
						(
							ChildrenLevel = ChildrenLevel + 1
							a[ChildrenLevel*3+1] = 0
							a[ChildrenLevel*3+3] = getUserProp p "BoneIndex"
						)
						else
						(
							while getUserProp p "BoneIndex" != a[ChildrenLevel*3+3] do
							(
								ChildrenLevel = ChildrenLevel - 1
							)
						)
						a[ChildrenLevel*3+1] = a[ChildrenLevel*3+1] + 1
						a[ChildrenLevel*3+2] = getUserProp p "BoneIndex"
						if a[ChildrenLevel*3+1] == p.children.count then
						(
							if s.children.count == 0 then
							(
								setUserProp s "BoneType" "1" --// is the last or only child, hasn't children
							)
							else
							(
								setUserProp s "BoneType" "0" --// is the last or only child, has children
							)
						)
						else
						(
							if s.children.count == 0 then
							(
								setUserProp s "BoneType" "3" --// not the only and not last child, hasn't children
							)
							else
							(
								setUserProp s "BoneType" "2" --// not the only and not last child, has children
							)
						)
						PreviousBoneIndex = getUserProp s "BoneIndex"
					)
				)
				messagebox "Now your custom bone hierarchy is ready for use in game!" title:"Done!"
			)
			else messageBox "You picked the wrong house, fool!\n(Select any bone of hierarchy and THEN push that button!)\n" title:"ERROR"
		)
	)
) --// end rollout

/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

rollout Anim_Helper_Rollout "Anim Helper" width:132 height:170
(
	group "Select bones"
	(
		button SelectAllBones "All" width:25 pos:[8,25] across:3 tooltip:"Automatically will select all bones of picked bone's hierarchy.\nSelect any bone and push this button."
		button SelectAllExceptRootBone "Except Root" width:73 pos:[36,25] tooltip:"Automatically will select all bones of picked bone's hierarchy, except Root bone.\nSelect any bone and push this button."
		button SelectOnlyRootBone "Only Root" width:57 pos:[112,25] tooltip:"Automatically will select only Root bone of picked bone's hierarchy.\nSelect any bone and push this button."
	)
	group "Skin Mesh Triggers"
	(
		button SMTrigFreeze "Freeze" width:57 align:#left across:2 tooltip:"Freezes/unfreezes skin mesh.\nSelect any bone/helper or skin mesh and push this button."
		button SMTrigXRay "Transparency" width:90 align:#right tooltip:"Enables/Disables transparency for skin mesh.\nSelect any bone/helper or skin mesh and push this button."
	)
	group "Create/Delete HI Solver"
	(
		button CreateHISolver1 "One bone" width:67 align:#left across:2 tooltip:"Creates HI Solver for selected bone.\nSelect ONE bone/helper and push this button."
		button CreateHISolver2 "Bone + Joint" width:80 align:#right tooltip:"Creates HI Solver for selected bone and its parent joint.\nSelect ONE bone/helper and push this button."
		button CreateHISolverEyes "Eyes" width:32 align:#left across:2 tooltip:"Creates HI Solver for selected eye pupils' bones.\nSelect ALL eye pupils' bones/helpers and push this button."
		button DeleteHISolver "Delete for all selected" width:115 align:#right tooltip:"Deletes selected HI Solvers or HI Solvers for selected bones.\nWorks only for HI Solvers that were created by this script!\nSelect all needed bones or/and HI solvers and push this button."
	)
	group "Attach/Detach object"
	(
		button AttachObjTo "Attach to selected" width:97 align:#left across:2 tooltip:"Attaches object to selected bone/helper/object.\nSelect ONE bone/helper/object and push this button."
		button DetachObj "Detach" width:50 align:#right tooltip:"Detaches selected attached objects or attached objects for selected bones/helpers/objects.\nWorks only for objects that were attached by this script!\nSelect all needed bones/helpers/objects and push this button."
	)
	group "Change animation speed"
	(
		button CASIncrease "Increase..." width:68 height:16 align:#left across:2 tooltip:"Increases selected animation as many times as specified in right field.\nIf you want slow down the animation by 2 times, then choose \"0,5\" in that field.\nSelect all needed bones/helpers/objects, then select needed anim keys interval or the first and the last keys of needed interval and push this button."
		spinner spn_CASIncBy "...by:" range:[0.001, 1000.0, 2.0] type:#float align:#right fieldwidth:45
		checkbox chkbx_CASAccuracy "Accuracy" align:#left checked:true across:2 tooltip:"Round-up the number of frames of the new animation range to the value that was chosen in the right field.\nIf you increased your animation that has 25,0 frames by 2,0 times then the new range will be 12,5.\nBut if THIS checkbox was checked and value \"1,0\" was chosen - the new range will be 13,0."
		spinner spn_CASAccuracyVal "upto:" range:[0.1, 1.0, 1.0] type:#float align:#right fieldwidth:45
	)
	group "Before Export: Bake HI anim"
	(
		button CreateKeysFAB "For all selected bones/solvers" tooltip:"Creates anim keys for all selected bones that uses HI Solvers or for bones that uses selected HI Solvers.\nWorks only for HI Solvers that were created by this script!\nUse this before animation export.\nSelect all needed bones or/and HI solvers and push this button."
		checkbox chkbx_DetailedHIAnim "Detailed" align:#left checked:true across:2 tooltip:"Bakes more detailed animation by adding extra anim keys every few frames. Choose frame interval in the \"Int\" field."
		spinner spn_DetailedHIAnim "Int:" range:[0.001, 1000.0, 1.0] type:#float align:#right fieldwidth:45
	)
	group "Before Export: Bake Attached"
	(
		button CreateKeysFAO "For all selected objects" tooltip:"Creates anim keys for all selected attached objects or attached objects for selected bones/helpers/objects.\nWorks only for objects that were attached by this script!\nUse this before animation export.\nSelect all needed bones/helpers/objects and push this button."
		checkbox chkbx_DetailedAOAnim "Detailed" align:#left checked:true across:2 tooltip:"Bakes more detailed animation by adding extra anim keys every few frames. Choose frame interval in the \"Int\" field."
		spinner spn_DetailedAOAnim "Int:" range:[0.001, 1000.0, 1.0] type:#float align:#right fieldwidth:45
	)
	group "Before Export: Delete anim keys"
	(
		button DelPosKeys "Del Pos keys(all except Root)" tooltip:"All bones except Root bone must have rotation(green) keys only(for correct animation), so you need to delete position(red) keys for them.\nUse this before animation export.\nSelect all needed bones(except Root) and push this button."
		button DelScaKeys "Del Scale keys(not important)" tooltip:"Bones can have rotation(green, all bones) and position(red, Root bone only) keys but it's also recommended to delete scale(blue) keys for them.\nActually, I don't know how scale keys can damage your animation, because it seems the game doesn't read them.\nBut I made this option for the future purposes and also because I can.\nUse this(or not) before animation export.\nSelect all needed bones and push this button."
	)
	
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	
	fn RemoveHISolver BakeHIAnimFlag bool_DetailedHIAnim float_DetailedHIAnim =
	(
		local selectionArr = selection as array
		for s in selectionArr do
		(
			if getUserProp s "HISolverNumber" != undefined or getUserProp s "HICBoneNumber" != undefined do
			(
				local HISelectNumber
				if getUserProp s "HISolverNumber" != undefined then HISelectNumber = getUserProp s "HISolverNumber"
				else HISelectNumber = getUserProp s "HICBoneNumber"
				for obj in objects do
				(
					if getUserProp obj "HIBoneNumber" ==  HISelectNumber do selectmore obj
				)
			)
		)
		maxOps.setKeyMode = true
		maxOps.setKeyMode = false
		selectionArr = selection as array
		for s in selectionArr do
		(
			if isValidNode s do
			(
				if getUserProp s "HIBoneNumber" != undefined and getUserProp s "HIBoneNumber" != -1 do
				(
					local HI_BoneNumber = getUserProp s "HIBoneNumber"
					local helpersArr = helpers as array
					for obj in helpersArr do
					(
						if isValidNode obj do
						(
							if getUserProp obj "HISolverNumber" != undefined do
							(
								local HI_SolverNumber = getUserProp obj "HISolverNumber"
								if HI_SolverNumber == HI_BoneNumber and getUserProp obj "HISolverType" != 3 do
								(
									local HI_SolverType = getUserProp obj "HISolverType"
									local HIBoneChild
									local HIBoneGChild
									if s.children.count > 0 do
									(
										for HBC in s.children do
										(
											if getUserProp HBC "HICBoneNumber" == HI_BoneNumber do
											(
												HIBoneChild = HBC
												if HI_SolverType == 2 and HIBoneChild.children.count > 0 then
												(
													for HBGC in HIBoneChild.children do
													(
														if getUserProp HBGC "HICBoneNumber" == HI_BoneNumber do
														(
															HIBoneGChild = HBGC
															continue
														)
													)
												)
												else
												(
													continue
												)
											)
										)
									)
									local snhelper
									local HIBoneChildnhelper
									local HIBoneGChildnhelper
									if HI_SolverType != 4 then
									(
										for HHAll in helpers do
										(
											if getUserProp HHAll "HIHelperNumber" == HI_BoneNumber do snhelper = HHAll
											if getUserProp HHAll "HICHelperNumber" == HI_BoneNumber do HIBoneChildnhelper = HHAll
											if getUserProp HHAll "HIGCHelperNumber" == HI_BoneNumber do HIBoneGChildnhelper = HHAll
										)
									)
									else
									(
										for HHAll in helpers do
										(
											local sHIEyesNumber = getUserProp s "HIEyesNumber" 
											if getUserProp HHAll "HIHelperNumber" == HI_BoneNumber and getUserProp HHAll "HIEyesNumber" == sHIEyesNumber do snhelper = HHAll
											if getUserProp HHAll "HICHelperNumber" == HI_BoneNumber and getUserProp HHAll "HIEyesNumber" == sHIEyesNumber do HIBoneChildnhelper = HHAll
										)
									)
									
									
									
									if BakeHIAnimFlag == 1 do
									(
										if obj.position.controller.keys.count > 0 or obj.rotation.controller.keys.count > 0 do
										(
											if obj.position.controller.keys.count > 0 do
											(
												if snhelper != undefined do
												(
													deselectKeys snhelper.rotation.controller
													selectKeys snhelper.rotation.controller obj.position.controller.keys[1].time obj.position.controller.keys[obj.position.controller.keys.count].time
													deleteKeys snhelper.rotation.controller #selection
												)
												if HIBoneChildnhelper != undefined do
												(
													deselectKeys HIBoneChildnhelper.rotation.controller
													selectKeys HIBoneChildnhelper.rotation.controller obj.position.controller.keys[1].time obj.position.controller.keys[obj.position.controller.keys.count].time
													deleteKeys HIBoneChildnhelper.rotation.controller #selection
												)
												if HIBoneGChildnhelper != undefined do
												(
													deselectKeys HIBoneGChildnhelper.rotation.controller
													selectKeys HIBoneGChildnhelper.rotation.controller obj.position.controller.keys[1].time obj.position.controller.keys[obj.position.controller.keys.count].time
													deleteKeys HIBoneGChildnhelper.rotation.controller #selection
												)
											)
											if obj.rotation.controller.keys.count > 0 do
											(
												if HIBoneGChildnhelper != undefined do
												(
													deselectKeys HIBoneGChildnhelper.rotation.controller
													selectKeys HIBoneGChildnhelper.rotation.controller obj.rotation.controller.keys[1].time obj.rotation.controller.keys[obj.rotation.controller.keys.count].time
													deleteKeys HIBoneGChildnhelper.rotation.controller #selection
												)
											)
											with Animate on
											(
												local HIAnimRangeStart
												local HIAnimRangeEnd
												if obj.position.controller.keys.count > 0 do
												(
													HIAnimRangeStart = obj.position.controller.keys[1].time
													if obj.position.controller.keys.count > 1 do HIAnimRangeEnd = obj.position.controller.keys[obj.position.controller.keys.count].time
													if snhelper != undefined do
													(
														for i = 1 to obj.position.controller.keys.count do
														(
															at time obj.position.controller.keys[i].time
															(
																snhelper.transform = s.transform
																if HIBoneChild != undefined and HIBoneChildnhelper != undefined do
																(
																	HIBoneChildnhelper.transform = HIBoneChild.transform
																)
																if HIBoneGChild != undefined and HIBoneGChildnhelper != undefined do
																(
																	HIBoneGChildnhelper.transform = HIBoneGChild.transform
																)
															)
														)
														if (HI_SolverType == 1 or HI_SolverType == 4) and s.parent != undefined do
														(
															local sBoneParent = s.parent
															if sBoneParent.rotation.controller.keys.count > 0 do
															(
																for i = 1 to sBoneParent.rotation.controller.keys.count do
																(
																	if sBoneParent.rotation.controller.keys[i].time >= obj.position.controller.keys[1].time and sBoneParent.rotation.controller.keys[i].time <= obj.position.controller.keys[obj.position.controller.keys.count].time do
																	(
																		at time sBoneParent.rotation.controller.keys[i].time
																		(
																			snhelper.transform = s.transform
																			if HIBoneChild != undefined and HIBoneChildnhelper != undefined do
																			(
																				HIBoneChildnhelper.transform = HIBoneChild.transform
																			)
																		)
																	)
																)
															)
														)
													)
												)
												if obj.rotation.controller.keys.count > 0 do
												(
													if HIAnimRangeStart != undefined then
													(
														if HIAnimRangeStart > obj.rotation.controller.keys[1].time do HIAnimRangeStart = obj.rotation.controller.keys[1].time
													)
													else HIAnimRangeStart = obj.rotation.controller.keys[1].time
													if obj.rotation.controller.keys.count > 1 do
													(
														if HIAnimRangeEnd != undefined then
														(
															if HIAnimRangeEnd < obj.rotation.controller.keys[obj.rotation.controller.keys.count].time do HIAnimRangeEnd = obj.rotation.controller.keys[obj.rotation.controller.keys.count].time
														)
														else HIAnimRangeEnd = obj.rotation.controller.keys[obj.rotation.controller.keys.count].time
													)
													for i = 1 to obj.rotation.controller.keys.count do
													(
														at time obj.rotation.controller.keys[i].time
														(
															if HI_SolverType == 1 or HI_SolverType == 4 then
															(
																if HIBoneChild != undefined and HIBoneChildnhelper != undefined do
																(
																	HIBoneChildnhelper.transform = HIBoneChild.transform
																)
															)
															else
															(
																if HIBoneGChild != undefined and HIBoneGChildnhelper != undefined do
																(
																	HIBoneGChildnhelper.transform = HIBoneGChild.transform
																)
															)
														)
													)
													if (HI_SolverType == 1 or HI_SolverType == 4) and s.parent != undefined do
													(
														local sBoneParent = s.parent
														if sBoneParent.rotation.controller.keys.count > 0 do
														(
															for i = 1 to sBoneParent.rotation.controller.keys.count do
															(
																if sBoneParent.rotation.controller.keys[i].time >= obj.rotation.controller.keys[1].time and sBoneParent.rotation.controller.keys[i].time <= obj.rotation.controller.keys[obj.rotation.controller.keys.count].time do
																(
																	at time sBoneParent.rotation.controller.keys[i].time
																	(
																		if HIBoneChild != undefined and HIBoneChildnhelper != undefined do
																		(
																			HIBoneChildnhelper.transform = HIBoneChild.transform
																		)
																	)
																)
															)
														)
													)
												)
												if bool_DetailedHIAnim and HIAnimRangeStart != undefined and HIAnimRangeEnd != undefined do
												(
													if HIAnimRangeStart < HIAnimRangeEnd and (HIAnimRangeEnd - HIAnimRangeStart) > float_DetailedHIAnim do
													(
														local DetailedHIAnimCurrentTime = HIAnimRangeStart
														DetailedHIAnimCurrentTime += float_DetailedHIAnim
														while DetailedHIAnimCurrentTime < HIAnimRangeEnd do
														(
															at time DetailedHIAnimCurrentTime
															(
																if snhelper != undefined do snhelper.transform = s.transform
																if HIBoneChild != undefined and HIBoneChildnhelper != undefined do HIBoneChildnhelper.transform = HIBoneChild.transform
																if HIBoneGChild != undefined and HIBoneGChildnhelper != undefined do HIBoneGChildnhelper.transform = HIBoneGChild.transform
															)
															DetailedHIAnimCurrentTime += float_DetailedHIAnim
														)
													)
												)
											)
										)
									)
									setUserProp s "HIBoneNumber" -1
									if HI_SolverType == 1 or HI_SolverType == 4 then
									(
										if HIBoneChild != undefined do
										(
											HIBoneChild.rotation.controller = Euler_XYZ()
											setUserProp HIBoneChild "HICBoneNumber" -1
										)
									)
									else
									(
										if HIBoneChild != undefined do setUserProp HIBoneChild "HICBoneNumber" -1
										if HIBoneGChild != undefined do
										(
											HIBoneGChild.rotation.controller = Euler_XYZ()
											setUserProp HIBoneGChild "HICBoneNumber" -1
										)
									)
									for obj2 in helpersArr do
									(
										if isValidNode obj2 do
										(
											if getUserProp obj2 "HISolverNumber" != undefined do
											(
												if getUserProp obj2 "HISolverNumber" == HI_BoneNumber do
												(
													if HI_SolverType == 4 then
													(
														if getUserProp obj2 "HISolverType" != 3 then
														(
															local HIBonesRemaining = 0
															for obj3 in objects do
															(
																if getUserProp obj3 "HIBoneNumber" != undefined do
																(
																	if getUserProp obj3 "HIBoneNumber" == HI_BoneNumber do
																	(
																		HIBonesRemaining = 1
																	)
																)
															)
															if HIBonesRemaining == 0 do delete obj2
														)
														else
														(
															if getUserProp obj2 "HIEyesNumber" == getUserProp s "HIEyesNumber" do delete obj2
														)
													)
													else delete obj2
												)
											)
										)
									)
									deleteKeys s.rotation.controller #allKeys
									if HIBoneChild != undefined do deleteKeys HIBoneChild.rotation.controller #allKeys
									if HIBoneGChild != undefined do deleteKeys HIBoneGChild.rotation.controller #allKeys
									with Animate on
									(
										if snhelper != undefined do
										(
											if snhelper.rotation.controller.keys.count > 0 do
											(
												for i = 1 to snhelper.rotation.controller.keys.count do
												(
													at time snhelper.rotation.controller.keys[i].time
													(
														s.transform = snhelper.transform
														if HIBoneChild != undefined do
														(
															if HI_SolverType == 2 do
															(
																HIBoneChild.transform = HIBoneChildnhelper.transform
															)
														)
													)
												)
											)
										)
										if HIBoneChild != undefined and HIBoneChildnhelper != undefined do
										(
											if HIBoneChildnhelper.rotation.controller.keys.count > 0 do
											(
												for i = 1 to HIBoneChildnhelper.rotation.controller.keys.count do
												(
													at time HIBoneChildnhelper.rotation.controller.keys[i].time
													(
														HIBoneChild.transform = HIBoneChildnhelper.transform
													)
												)
											)
											if HI_SolverType == 2 and HIBoneGChild != undefined and HIBoneGChildnhelper != undefined do
											(
												if HIBoneGChildnhelper.rotation.controller.keys.count > 0 do
												(
													for i = 1 to HIBoneGChildnhelper.rotation.controller.keys.count do
													(
														at time HIBoneGChildnhelper.rotation.controller.keys[i].time
														(
															HIBoneGChild.transform = HIBoneGChildnhelper.transform
														)
													)
												)
											)
										)
									)
									if snhelper != undefined do delete snhelper
									if HIBoneChildnhelper != undefined do delete HIBoneChildnhelper
									if HIBoneGChildnhelper != undefined do delete HIBoneGChildnhelper
									deleteKeys s.position.controller
									deleteKeys s.scale.controller
									if HIBoneChild != undefined do
									(
										deleteKeys HIBoneChild.position.controller
										deleteKeys HIBoneChild.scale.controller
									)
									if HIBoneGChild != undefined do
									(
										deleteKeys HIBoneGChild.position.controller
										deleteKeys HIBoneGChild.scale.controller
									)
								)
							)
						)
					)
				)
			)
		)
		clearselection()
	)
	
	/*---------------------------------------------------------------------------------------------------*/

	fn RemoveAOLink BakeAOAnimFlag bool_DetailedAOAnim float_DetailedAOAnim =
	(
		local selectionArr = selection as array
		for s in selectionArr do
		(
			if getUserProp s "AOBoneNumber" != undefined do
			(
				local AOSelectNumber = getUserProp s "AOBoneNumber"
				for obj in objects do
				(
					if getUserProp obj "AObjectNumber" ==  AOSelectNumber do selectmore obj
				)
			)
		)
		maxOps.setKeyMode = true
		maxOps.setKeyMode = false
		selectionArr = selection as array
		for s in selectionArr do
		(
			if isValidNode s do
			(
				if getUserProp s "AObjectNumber" != undefined and getUserProp s "AObjectNumber" != -1 do
				(
					local AObject_Number = getUserProp s "AObjectNumber"
					local AOBone
					local AObjecthelper
					for AOBAll in objects do
					(
						if getUserProp AOBAll "AOBoneNumber" == AObject_Number do AOBone = AOBAll
					)
					for AOHAll in helpers do
					(
						if getUserProp AOHAll "AOHelperNumber" == AObject_Number do AObjecthelper = AOHAll
					)
					if BakeAOAnimFlag == 1 and AObjecthelper != undefined do
					(
						if s.position.controller.keys.count > 0 or s.rotation.controller.keys.count > 0 do
						(
							if s.position.controller.keys.count > 0 do
							(
								deselectKeys AObjecthelper.position.controller
								selectKeys AObjecthelper.position.controller s.position.controller.keys[1].time s.position.controller.keys[s.position.controller.keys.count].time
								deleteKeys AObjecthelper.position.controller #selection
								deselectKeys AObjecthelper.rotation.controller
								selectKeys AObjecthelper.rotation.controller s.position.controller.keys[1].time s.position.controller.keys[s.position.controller.keys.count].time
								deleteKeys AObjecthelper.rotation.controller #selection
							)
							if ClassOf s != targetcamera then
							(
								if s.rotation.controller.keys.count > 0 do
								(
									deselectKeys AObjecthelper.position.controller
									selectKeys AObjecthelper.position.controller s.rotation.controller.keys[1].time s.rotation.controller.keys[s.rotation.controller.keys.count].time
									deleteKeys AObjecthelper.position.controller #selection
									deselectKeys AObjecthelper.rotation.controller
									selectKeys AObjecthelper.rotation.controller s.rotation.controller.keys[1].time s.rotation.controller.keys[s.rotation.controller.keys.count].time
									deleteKeys AObjecthelper.rotation.controller #selection
								)
							)
							else
							(
								/*if s.controller.roll_angle.keys.count > 0 do
								(
									deselectKeys AObjecthelper.position.controller
									selectKeys AObjecthelper.position.controller s.controller.roll_angle.keys[1].time s.controller.roll_angle.keys[s.controller.roll_angle.keys.count].time
									deleteKeys AObjecthelper.position.controller #selection
									deselectKeys AObjecthelper.rotation.controller
									selectKeys AObjecthelper.rotation.controller s.controller.roll_angle.keys[1].time s.controller.roll_angle.keys[s.controller.roll_angle.keys.count].time
									deleteKeys AObjecthelper.rotation.controller #selection
								)*/
							)
							with Animate on
							(
								local AOAnimRangeStart
								local AOAnimRangeEnd
								if s.position.controller.keys.count > 0 do
								(
									AOAnimRangeStart = s.position.controller.keys[1].time
									if s.position.controller.keys.count > 1 do AOAnimRangeEnd = s.position.controller.keys[s.position.controller.keys.count].time
									for i = 1 to s.position.controller.keys.count do
									(
										at time s.position.controller.keys[i].time
										(
											AObjecthelper.transform = s.transform
										)
									)
								)
								if ClassOf s != targetcamera then
								(
									if s.rotation.controller.keys.count > 0 do
									(
										if AOAnimRangeStart != undefined then
										(
											if AOAnimRangeStart > s.rotation.controller.keys[1].time do AOAnimRangeStart = s.rotation.controller.keys[1].time
										)
										else AOAnimRangeStart = s.rotation.controller.keys[1].time
										if s.rotation.controller.keys.count > 1 do
										(
											if AOAnimRangeEnd != undefined then
											(
												if AOAnimRangeEnd < s.rotation.controller.keys[s.rotation.controller.keys.count].time do AOAnimRangeEnd = s.rotation.controller.keys[s.rotation.controller.keys.count].time
											)
											else AOAnimRangeEnd = s.rotation.controller.keys[s.rotation.controller.keys.count].time
										)
										for i = 1 to s.rotation.controller.keys.count do
										(
											at time s.rotation.controller.keys[i].time
											(
												AObjecthelper.transform = s.transform
											)
										)
									)
								)
								else
								(
									/*if s.controller.roll_angle.keys.count > 0 do
									(
										if AOAnimRangeStart != undefined then
										(
											if AOAnimRangeStart > s.controller.roll_angle.keys[1].time do AOAnimRangeStart = s.controller.roll_angle.keys[1].time
										)
										else AOAnimRangeStart = s.controller.roll_angle.keys[1].time
										if s.controller.roll_angle.keys.count > 1 do
										(
											if AOAnimRangeEnd != undefined then
											(
												if AOAnimRangeEnd < s.controller.roll_angle.keys[s.controller.roll_angle.keys.count].time do AOAnimRangeEnd = s.controller.roll_angle.keys[s.controller.roll_angle.keys.count].time
											)
											else AOAnimRangeEnd = s.controller.roll_angle.keys[s.controller.roll_angle.keys.count].time
										)
										for i = 1 to s.controller.roll_angle.keys.count do
										(
											at time s.controller.roll_angle.keys[i].time
											(
												AObjecthelper.transform = s.transform
											)
										)
									)*/
								)
								if AOBone != undefined and AOAnimRangeStart != undefined and AOAnimRangeEnd != undefined do
								(
									if AOAnimRangeStart < AOAnimRangeEnd do
									(
										if AOBone.position.controller.keys.count > 0 do
										(
											for i = 1 to AOBone.position.controller.keys.count do
											(
												if AOBone.position.controller.keys[i].time > AOAnimRangeStart and AOBone.position.controller.keys[i].time < AOAnimRangeEnd do
												(
													at time AOBone.position.controller.keys[i].time
													(
														AObjecthelper.transform = s.transform
													)
												)
											)
										)
										if AOBone.rotation.controller.keys.count > 0 do
										(
											for i = 1 to AOBone.rotation.controller.keys.count do
											(
												if AOBone.rotation.controller.keys[i].time > AOAnimRangeStart and AOBone.rotation.controller.keys[i].time < AOAnimRangeEnd do
												(
													at time AOBone.rotation.controller.keys[i].time
													(
														AObjecthelper.transform = s.transform
													)
												)
											)
										)
									)
								)
								if bool_DetailedAOAnim and AOAnimRangeStart != undefined and AOAnimRangeEnd != undefined do
								(
									if AOAnimRangeStart < AOAnimRangeEnd and (AOAnimRangeEnd - AOAnimRangeStart) > float_DetailedAOAnim do
									(
										local DetailedAOAnimCurrentTime = AOAnimRangeStart
										DetailedAOAnimCurrentTime += float_DetailedAOAnim
										while DetailedAOAnimCurrentTime < AOAnimRangeEnd do
										(
											at time DetailedAOAnimCurrentTime
											(
												AObjecthelper.transform = s.transform
											)
											DetailedAOAnimCurrentTime += float_DetailedAOAnim
										)
									)
								)
							)
						)
					)
					setUserProp s "AObjectNumber" -1
					if getUserProp s "AOHadParent" != undefined and getUserProp s "AOHadParent" == 1 then
					(
						local AOOriginalParent
						for AOAllO in objects do
						(
							if getUserProp AOAllO "AOParentNumber" == AObject_Number do
							(
								AOOriginalParent = AOAllO
								setUserProp AOAllO "AOParentNumber" -1
							)
						)
						if	AOOriginalParent != undefined then s.parent = AOOriginalParent
						else s.parent = undefined
						setUserProp s "AOHadParent" -1
					)
					else s.parent = undefined
					if AObjecthelper != undefined do setUserProp AObjecthelper "AOHelperNumber" -1
					if AOBone != undefined do setUserProp AOBone "AOBoneNumber" -1
					deleteKeys s.position.controller #allKeys
					if ClassOf s != targetcamera then deleteKeys s.rotation.controller #allKeys
					else
					(
						--deleteKeys s.controller.roll_angle.controller #allKeys
						s.controller.roll_angle.controller = bezier_float()
						for AOAllO in objects do
						(
							if isValidNode AOAllO do
							(
								if getUserProp AOAllO "AOCHelperNumber" == AObject_Number do
								(
									setUserProp AOAllO "AOCHelperNumber" -1
									--delete AOAllO
								)
							)
						)
					)
					with Animate on
					(
						if AObjecthelper != undefined do
						(
							if AObjecthelper.position.controller.keys.count > 0 do
							(
								for i = 1 to AObjecthelper.position.controller.keys.count do
								(
									at time AObjecthelper.position.controller.keys[i].time
									(
										s.transform = AObjecthelper.transform
										if ClassOf s == targetcamera do
										(
											if AObjecthelper.transform.row2.z < 0.0 then s.controller.roll_angle = 180.0+(AObjecthelper.transform.rotation as eulerangles).y
											else	s.controller.roll_angle = -(AObjecthelper.transform.rotation as eulerangles).y
										)
									)
								)
							)
							if AObjecthelper.rotation.controller.keys.count > 0 do
							(
								for i = 1 to AObjecthelper.rotation.controller.keys.count do
								(
									at time AObjecthelper.rotation.controller.keys[i].time
									(
										s.transform = AObjecthelper.transform
										if ClassOf s == targetcamera do
										(
											if AObjecthelper.transform.row2.z < 0.0 then s.controller.roll_angle = 180.0+(AObjecthelper.transform.rotation as eulerangles).y
											else	s.controller.roll_angle = -(AObjecthelper.transform.rotation as eulerangles).y
										)
									)
								)
							)											
						)
					)
					if AObjecthelper != undefined do delete AObjecthelper
					deleteKeys s.scale.controller
				)
			)
		)
		clearselection()
	)
	
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	
	on SelectAllBones pressed do
	(
		if selection[1] != undefined then
		(
			if selection[1].children.count > 0 OR selection[1].parent != undefined then
			(
				--g_LBTools_HM.f_selectHierarchy selection[1]
				SelectHierarchyRootOnly selection[1]
				local RootBone = selection[1]
				clearselection()
				select RootBone
				SelectAllHierarchy selection[1]
			)
		)
	)

	on SelectAllExceptRootBone pressed do
	(
		if selection[1] != undefined then
		(
			if selection[1].children.count > 0 OR selection[1].parent != undefined then
			(
				--g_LBTools_HM.f_selectHierarchy selection[1]
				SelectHierarchyRootOnly selection[1]
				local RootBone = selection[1]
				clearselection()
				select RootBone
				SelectAllHierarchy selection[1]
				deselectnode selection[1]
			)
		)
	)

	on SelectOnlyRootBone pressed do
	(
		if selection[1] != undefined then
		(
			if selection[1].children.count > 0 OR selection[1].parent != undefined then
			(
				--g_LBTools_HM.f_selectHierarchy selection[1]
				--local RootBone = selection[1]
				--clearselection()
				--select RootBone
				SelectHierarchyRootOnly selection[1]
				local RootBone = selection[1]
				clearselection()
				select RootBone
			)
		)
	)

	on SMTrigFreeze pressed do
	(
		if selection[1] != undefined then
		(
			local s_Array = selection as array
			local s = selection[1]
			clearselection()
			select s
			if SuperclassOf s == GeometryClass and (classof s) == Editable_Mesh and (g_LBTools_HM.f_findSkinModifier s) then
			(
				for obj in s do
				(
					if obj.isFrozen == true then
					(
						unfreeze obj
					)
					else
					(
						freeze obj
						obj.showFrozenInGray = false
					)
				)
			)
			else-- if getUserProp s "FrameName" != undefined then
			(
				--g_LBTools_HM.f_selectHierarchy s
				SelectAllHierarchy s
				local s_Hierarchy = selection as array
				local s2 = g_LBTools_HM.f_collectSkinMeshes s_Hierarchy --// Returns any skin meshes (if any) associated with the picked hierarchy
				if s2.count > 0 then
				(
					for obj in s2 do
					(
						if obj.isFrozen == true then
						(
							unfreeze obj
						)
						else
						(
							freeze obj
							obj.showFrozenInGray = false
						)
					)
				)
				else if getUserProp s "SkinMeshName" != undefined then
				(
					local SkinMeshName = getUserProp s "SkinMeshName"
					local MeshFound = false
					for obj in geometry do
					(
						if (classof obj) == Editable_Mesh and obj.name == SkinMeshName then
						(
							if obj.isFrozen == true then
							(
								unfreeze obj
							)
							else
							(
								freeze obj
								obj.showFrozenInGray = false
							)
							MeshFound = true
						)
					)
					if MeshFound == false then
					(
						local my_str_msg = "SkinMesh \"" + SkinMeshName + "\" didn't found!"
						messageBox my_str_msg title:"ERROR"
					)
				)
			)
			clearselection()
			for obj in s_Array do
			(
				selectmore obj
			)
		)
	)

	on SMTrigXRay pressed do
	(
		if selection[1] != undefined then
		(
			maxOps.setKeyMode = true
			maxOps.setKeyMode = false
			local s_Array = selection as array
			local s = selection[1]
			clearselection()
			select s
			if SuperclassOf s == GeometryClass and (classof s) == Editable_Mesh and (g_LBTools_HM.f_findSkinModifier s) then
			(
				for obj in s do
				(
					if ((getVisController obj) == undefined) do
					(
						obj.visibility = bezier_float()
					)
					if obj.visibility.controller.value != 0.6 then
					(
						obj.visibility.controller.value = 0.6
						obj.backfaceCull = true
					)
					else
					(
						obj.visibility.controller.value = 1.0
						obj.backfaceCull = false
					)
				)
			)
			else-- if getUserProp s "FrameName" != undefined then
			(
				--g_LBTools_HM.f_selectHierarchy s
				SelectAllHierarchy s
				local s_Hierarchy = selection as array
				local s2 = g_LBTools_HM.f_collectSkinMeshes s_Hierarchy --// Returns any skin meshes (if any) associated with the picked hierarchy
				if s2.count > 0 then
				(
					for obj in s2 do
					(
						if ((getVisController obj) == undefined) do
						(
							obj.visibility = bezier_float()
						)
						if obj.visibility.controller.value != 0.6 then
						(
							obj.visibility.controller.value = 0.6
							obj.backfaceCull = true
						)
						else
						(
							obj.visibility.controller.value = 1.0
							obj.backfaceCull = false
						)
					)
				)
				else if getUserProp s "SkinMeshName" != undefined then
				(
					local SkinMeshName = getUserProp s "SkinMeshName"
					local MeshFound = false
					for obj in geometry do
					(
						if (classof obj) == Editable_Mesh and obj.name == SkinMeshName then
						(
							if ((getVisController obj) == undefined) do
							(
								obj.visibility = bezier_float()
							)
							if obj.visibility.controller.value != 0.6 then
							(
								obj.visibility.controller.value = 0.6
								obj.backfaceCull = true
							)
							else
							(
								obj.visibility.controller.value = 1.0
								obj.backfaceCull = false
							)
							MeshFound = true
						)
					)
					if MeshFound == false then
					(
						local my_str_msg = "SkinMesh \"" + SkinMeshName + "\" didn't found!"
						messageBox my_str_msg title:"ERROR"
					)
				)
			)
			clearselection()
			for obj in s_Array do
			(
				selectmore obj
			)
		)
	)

	on CreateHISolver1 pressed do
	(
		maxOps.setKeyMode = true
		maxOps.setKeyMode = false
		if selection.count == 1 then
		(
			local s = selection[1]
			local p = s.parent
			if p != undefined then
			(
				IncreaseHIBoneNumber()
				local snhelper = point size:0.1
				local HIBoneParentnhelper = point size:0.1
				with Animate on
				(
					if s.rotation.controller.keys.count > 0 then
					(
						for i = 1 to s.rotation.controller.keys.count do
						(
							at time s.rotation.controller.keys[i].time
							(
								snhelper.transform = s.transform
							)
						)
					)
					else
					(
						at time sliderTime
						(
							snhelper.transform = s.transform
						)
					)
					if p.rotation.controller.keys.count > 0 then
					(
						for i = 1 to p.rotation.controller.keys.count do
						(
							at time p.rotation.controller.keys[i].time
							(
								HIBoneParentnhelper.transform = p.transform
							)
						)
					)
					else
					(
						at time sliderTime
						(
							HIBoneParentnhelper.transform = p.transform
						)
					)
				)
				setUserProp snhelper "HICHelperNumber" NewHI_Number
				setUserProp HIBoneParentnhelper "HIHelperNumber" NewHI_Number
				maxOps.setKeyMode = true
				deleteKeys s.rotation.controller #allKeys
				deleteKeys p.rotation.controller #allKeys
				s.transform= snhelper.transform
				p.transform = HIBoneParentnhelper.transform
				addNewKey s.rotation.controller sliderTime
				addNewKey p.rotation.controller sliderTime
				maxOps.setKeyMode = false
				freeze snhelper
				hide snhelper
				freeze HIBoneParentnhelper
				hide HIBoneParentnhelper
				local IkChain01 = IKSys.ikChain p s "IKHISolver"
				IkChain01.transform.controller.posThresh = 0.001
				IkChain01.transform.controller.rotThresh = 0.001
				IkChain01.transform.controller.iterations = 1000
				IkChain01.transform.controller.goalsize = 0.1
				IkChain01.name = (s.name + " Chain")
				setUserProp p "HIBoneNumber" NewHI_Number
				setUserProp s "HICBoneNumber" NewHI_Number
				local newhelper = point size:0.4
				newhelper.size = 0.4
				newhelper.name = "HI_" + s.name
				newhelper.position = s.position
				newhelper.cross = false
				newhelper.box = true
				--newhelper.drawontop = true
				newhelper.wirecolor = (color 255 0 0)
				IkChain01.wirecolor = (color 255 0 0)
				IkChain01.parent = newhelper
				setUserProp newhelper "HISolverNumber" NewHI_Number
				setUserProp newhelper "HISolverType" 1 -- "One bone" type
				setUserProp IkChain01 "HISolverNumber" NewHI_Number
				setUserProp IkChain01 "HISolverType" 3
				freeze IkChain01
				IkChain01.showFrozenInGray = false
				s.rotation.controller = Orientation_Constraint()
				s.rotation.controller.appendTarget newhelper 50.0
				select newhelper
				maxOps.setKeyMode = true
				newhelper.transform = snhelper.transform
				addNewKey newhelper.rotation.controller sliderTime
				addNewKey newhelper.position.controller sliderTime
				maxOps.setKeyMode = false
			)
			else messageBox "Selected bone hasn't parent bone!" title:"ERROR"
		)
		else messageBox "Select ONE bone/helper and THEN push that button!" title:"ERROR"
	)

	on CreateHISolver2 pressed do
	(
		maxOps.setKeyMode = true
		maxOps.setKeyMode = false
		if selection.count == 1 then
		(
			local s = selection[1]
			local p = s.parent
			if p != undefined then
			(
				local p2 = p.parent
				if p2 != undefined then
				(
					IncreaseHIBoneNumber()
					local snhelper = point size:0.1
					local HIBoneParentnhelper = point size:0.1
					local HIBoneGParentnhelper = point size:0.1
					with Animate on
					(
						if s.rotation.controller.keys.count > 0 then
						(
							for i = 1 to s.rotation.controller.keys.count do
							(
								at time s.rotation.controller.keys[i].time
								(
									snhelper.transform = s.transform
								)
							)
						)
						else
						(
							at time sliderTime
							(
								snhelper.transform = s.transform
							)
						)
						if p.rotation.controller.keys.count > 0 then
						(
							for i = 1 to p.rotation.controller.keys.count do
							(
								at time p.rotation.controller.keys[i].time
								(
									HIBoneParentnhelper.transform = p.transform
								)
							)
						)
						else
						(
							at time sliderTime
							(
								HIBoneParentnhelper.transform = p.transform
							)
						)
						if p2.rotation.controller.keys.count > 0 then
						(
							for i = 1 to p2.rotation.controller.keys.count do
							(
								at time p2.rotation.controller.keys[i].time
								(
									HIBoneGParentnhelper.transform = p2.transform
								)
							)
						)
						else
						(
							at time sliderTime
							(
								HIBoneGParentnhelper.transform = p2.transform
							)
						)
					)
					setUserProp snhelper "HIGCHelperNumber" NewHI_Number
					setUserProp HIBoneParentnhelper "HICHelperNumber" NewHI_Number
					setUserProp HIBoneGParentnhelper "HIHelperNumber" NewHI_Number
					maxOps.setKeyMode = true
					deleteKeys s.rotation.controller #allKeys
					deleteKeys p.rotation.controller #allKeys
					deleteKeys p2.rotation.controller #allKeys
					s.transform= snhelper.transform
					p.transform = HIBoneParentnhelper.transform
					p2.transform = HIBoneGParentnhelper.transform
					addNewKey s.rotation.controller sliderTime
					addNewKey p.rotation.controller sliderTime
					addNewKey p2.rotation.controller sliderTime
					maxOps.setKeyMode = false
					freeze snhelper
					hide snhelper
					freeze HIBoneParentnhelper
					hide HIBoneParentnhelper
					freeze HIBoneGParentnhelper
					hide HIBoneGParentnhelper
					local IkChain01 = IKSys.ikChain p2 s "IKHISolver"
					IkChain01.transform.controller.posThresh = 0.001
					IkChain01.transform.controller.rotThresh = 0.001
					IkChain01.transform.controller.iterations = 1000
					IkChain01.transform.controller.goalsize = 0.1
					IkChain01.name = (s.name + " Chain")
					setUserProp p2 "HIBoneNumber" NewHI_Number
					setUserProp p "HICBoneNumber" NewHI_Number
					setUserProp s "HICBoneNumber" NewHI_Number
					local newhelper = point size:0.4
					newhelper.size = 0.4
					newhelper.name = "HI_" + s.name
					newhelper.position = s.position
					newhelper.cross = false
					newhelper.box = true
					--newhelper.drawontop = true
					newhelper.wirecolor = (color 255 0 0)
					IkChain01.wirecolor = (color 255 0 0)
					IkChain01.parent = newhelper
					setUserProp newhelper "HISolverNumber" NewHI_Number
					setUserProp newhelper "HISolverType" 2 -- "Bone + Joint" type
					setUserProp IkChain01 "HISolverNumber" NewHI_Number
					setUserProp IkChain01 "HISolverType" 3
					freeze IkChain01
					IkChain01.showFrozenInGray = false
					s.rotation.controller = Orientation_Constraint()
					s.rotation.controller.appendTarget newhelper 50.0
					select newhelper
					maxOps.setKeyMode = true
					newhelper.transform = snhelper.transform
					addNewKey newhelper.rotation.controller sliderTime
					addNewKey newhelper.position.controller sliderTime
					maxOps.setKeyMode = false
				)
				else messageBox "Selected bone hasn't parent joint!" title:"ERROR"
			)
			else messageBox "Selected bone hasn't parent bone!" title:"ERROR"
		)
		else messageBox "Select ONE bone/helper and THEN push that button!" title:"ERROR"
	)

	on CreateHISolverEyes pressed do
	(
		maxOps.setKeyMode = true
		maxOps.setKeyMode = false
		if selection.count > 0 then
		(
			if selection[1].parent != undefined then
			(
				--IncreaseHIEyesNumber()
				local NewHIE_Number = 0
				IncreaseHIBoneNumber()
				local newhelper = point size:0.1
				newhelper.size = 0.1
				newhelper.name = "HI_Eyes" + (NewHI_Number as string)
				newhelper.cross = false
				newhelper.box = true
				--newhelper.drawontop = true
				newhelper.wirecolor = (color 255 0 0)
				setUserProp newhelper "HISolverNumber" NewHI_Number
				setUserProp newhelper "HISolverType" 4 -- "Eyes" type
				selectionArr = selection as array
				for s in selectionArr do
				(
					local p = s.parent
					if p != undefined then
					(
						NewHIE_Number = NewHIE_Number + 1
						local snhelper = point size:0.1
						local HIBoneParentnhelper = point size:0.1
						with Animate on
						(
							if s.rotation.controller.keys.count > 0 then
							(
								for i = 1 to s.rotation.controller.keys.count do
								(
									at time s.rotation.controller.keys[i].time
									(
										snhelper.transform = s.transform
									)
								)
							)
							else
							(
								at time sliderTime
								(
									snhelper.transform = s.transform
								)
							)
							if p.rotation.controller.keys.count > 0 then
							(
								for i = 1 to p.rotation.controller.keys.count do
								(
									at time p.rotation.controller.keys[i].time
									(
										HIBoneParentnhelper.transform = p.transform
									)
								)
							)
							else
							(
								at time sliderTime
								(
									HIBoneParentnhelper.transform = p.transform
								)
							)
						)
						setUserProp snhelper "HICHelperNumber" NewHI_Number
						setUserProp HIBoneParentnhelper "HIHelperNumber" NewHI_Number
						setUserProp snhelper "HIEyesNumber" NewHIE_Number
						setUserProp HIBoneParentnhelper "HIEyesNumber" NewHIE_Number
						
						maxOps.setKeyMode = true
						deleteKeys s.rotation.controller #allKeys
						deleteKeys p.rotation.controller #allKeys
						s.transform= snhelper.transform
						p.transform = HIBoneParentnhelper.transform
						addNewKey s.rotation.controller sliderTime
						addNewKey p.rotation.controller sliderTime
						maxOps.setKeyMode = false
						freeze snhelper
						hide snhelper
						freeze HIBoneParentnhelper
						hide HIBoneParentnhelper
						local IkChain01 = IKSys.ikChain p s "IKHISolver"
						IkChain01.transform.controller.posThresh = 0.001
						IkChain01.transform.controller.rotThresh = 0.001
						IkChain01.transform.controller.iterations = 1000
						IkChain01.transform.controller.goalsize = 0.1
						IkChain01.name = (s.name + " Chain")
						setUserProp p "HIBoneNumber" NewHI_Number
						setUserProp s "HICBoneNumber" NewHI_Number
						
						setUserProp p "HIEyesNumber" NewHIE_Number
						setUserProp s "HIEyesNumber" NewHIE_Number
						
						newhelper.position = s.position
						
						IkChain01.wirecolor = (color 255 0 0)
						IkChain01.parent = newhelper
						
						setUserProp IkChain01 "HISolverNumber" NewHI_Number
						setUserProp IkChain01 "HISolverType" 3
						setUserProp IkChain01 "HIEyesNumber" NewHIE_Number
						
						freeze IkChain01
						IkChain01.showFrozenInGray = false
						--s.rotation.controller = Orientation_Constraint()
						--s.rotation.controller.appendTarget newhelper 50.0
					)
					else messageBox "One of selected bones hasn't parent bone!" title:"ERROR"
				)
				select newhelper
				maxOps.setKeyMode = true
				--newhelper.transform = snhelper.transform
				addNewKey newhelper.rotation.controller sliderTime
				addNewKey newhelper.position.controller sliderTime
				maxOps.setKeyMode = false
			)
			else messageBox "One of selected bones hasn't parent bone!" title:"ERROR"
		)
		else messageBox "Select ALL eye pupils' bones/helpers and THEN push that button!" title:"ERROR"
	)
	
	on AttachObjTo pressed do
	(
		maxOps.setKeyMode = true
		maxOps.setKeyMode = false
		if selection.count == 1 then
		(
			local s = selection[1]
			if (queryBox "Select the object that you want to attach to this bone/helper/object...\n\nDo you want to continue?" title:"Attention!") do
			(
				clearSelection()
				local pickedObject = pickObject prompt:"Select the object that you want to attach to this bone/helper/object..." rubberBand:[s.pos.x,s.pos.y,s.pos.z]
				if pickedObject != undefined AND pickedObject != #escape do
				(
					select pickedObject
					IncreaseAONumber()
					local pohelper = point size:0.1
					with Animate on
					(
						if ClassOf pickedObject != targetcamera then
						(
							if pickedObject.rotation.controller.keys.count > 0 then
							(
								for i = 1 to pickedObject.rotation.controller.keys.count do
								(
									at time pickedObject.rotation.controller.keys[i].time
									(
										pohelper.transform = pickedObject.transform
									)
								)
							)
							else
							(
								at time sliderTime
								(
									pohelper.transform = pickedObject.transform
								)
							)
						)
						else
						(
							if pickedObject.controller.roll_angle.controller.keys.count > 0 then
							(
								for i = 1 to pickedObject.controller.roll_angle.controller.keys.count do
								(
									at time pickedObject.controller.roll_angle.controller.keys[i].time
									(
										pohelper.transform = pickedObject.transform
									)
								)
							)
							else
							(
								at time sliderTime
								(
									pohelper.transform = pickedObject.transform
								)
							)
						)
						if pickedObject.position.controller.keys.count > 0 then
						(
							for i = 1 to pickedObject.position.controller.keys.count do
							(
								at time pickedObject.position.controller.keys[i].time
								(
									pohelper.transform = pickedObject.transform
								)
							)
						)
						else
						(
							at time sliderTime
							(
								pohelper.transform = pickedObject.transform
							)
						)
					)
					setUserProp pohelper "AOHelperNumber" NewAO_Number
					maxOps.setKeyMode = true
					if ClassOf pickedObject != targetcamera then deleteKeys pickedObject.rotation.controller #allKeys
					else deleteKeys pickedObject.controller.roll_angle.controller #allKeys
					deleteKeys pickedObject.position.controller #allKeys
					at time sliderTime pickedObject.transform= pohelper.transform
					if ClassOf pickedObject != targetcamera do addNewKey pickedObject.rotation.controller sliderTime
					--else addNewKey pohelper.rotation.controller sliderTime
					addNewKey pickedObject.position.controller sliderTime
					maxOps.setKeyMode = false
					if pickedObject.parent != undefined do
					(
						setUserProp pickedObject "AOHadParent" 1
						setUserProp pickedObject.parent "AOParentNumber" NewAO_Number
					)
					pickedObject.parent = s
					if ClassOf pickedObject == targetcamera do
					(
						local crollanglehelper = point size:0.1
						at time sliderTime
						(
							crollanglehelper.transform = pohelper.transform
						)
						crollanglehelper.parent = s
						pickedObject.controller.roll_angle.controller = Float_Script()
						pickedObject.controller.roll_angle.controller.addNode "crah" (crollanglehelper)
						--pickedObject.controller.roll_angle.controller.script = "-0.0175*(crah.transform.rotation as eulerangles).y"
						--pickedObject.controller.roll_angle.controller.script = "0.0175*atan2(crah.transform.row1.z)(crah.transform.row3.z)"
						--pickedObject.controller.roll_angle.controller.script = "-0.0175*crah.rotation.y_rotation"
						--pickedObject.controller.roll_angle.controller.script = "-0.0175*(atan2(crah.transform.row3.y)(crah.transform.row3.z)+atan2(crah.transform.row3.x)(crah.transform.row3.z))"
						--pickedObject.controller.roll_angle.controller.script = "-0.0175*crah.rotation.y_rotation"
						pickedObject.controller.roll_angle.controller.script = "if crah.transform.row2.z < 0.0 then
roll_angle = 3.1416+0.0175*(crah.transform.rotation as eulerangles).y
else
roll_angle = -0.0175*(crah.transform.rotation as eulerangles).y"--"0.00875*((ftest.transform.rotation as eulerangles).x+ftest.rotation.x_rotation)"
						setUserProp crollanglehelper "AOCHelperNumber" NewAO_Number
						freeze crollanglehelper
						hide crollanglehelper
					)
					freeze pohelper
					hide pohelper
					setUserProp s "AOBoneNumber" NewAO_Number
					setUserProp pickedObject "AObjectNumber" NewAO_Number
					if ClassOf pickedObject != targetcamera do pickedObject.parent = s
					local my_str_msg = "Object \"" + pickedObject.name + "\" has been successfully attached to \"" + s.name + "\"."
					messagebox my_str_msg title:"Done!"
				)
			)
		)
		else messageBox "Select ONE bone/helper/object and THEN push that button!" title:"ERROR"
	)
	
	on CASIncrease pressed do
	(
		maxOps.setKeyMode = true
		maxOps.setKeyMode = false
		if spn_CASIncBy.value != 1.0 do
		(
			local CASAnimRangeStart
			local CASAnimRangeEnd
			for s in selection do
			(
				if s.position.controller.keys.count > 0 do
				(
					for i = 1 to s.position.controller.keys.count do
					(
						if isKeySelected s.position.controller i do
						(
							if CASAnimRangeStart != undefined then
							(
								if CASAnimRangeStart > s.position.controller.keys[i].time then
								(
									if CASAnimRangeEnd == undefined do CASAnimRangeEnd = CASAnimRangeStart
									CASAnimRangeStart = s.position.controller.keys[i].time
								)
								else
								(
									if CASAnimRangeEnd != undefined then
									(
										if CASAnimRangeEnd < s.position.controller.keys[i].time do CASAnimRangeEnd = s.position.controller.keys[i].time
									)
									else CASAnimRangeEnd = s.position.controller.keys[i].time
								)
							)
							else CASAnimRangeStart = s.position.controller.keys[i].time
						)
					)
				)
				if s.rotation.controller.keys.count > 0 do
				(
					for i = 1 to s.rotation.controller.keys.count do
					(
						if isKeySelected s.rotation.controller i do
						(
							if CASAnimRangeStart != undefined then
							(
								if CASAnimRangeStart > s.rotation.controller.keys[i].time then
								(
									if CASAnimRangeEnd == undefined do CASAnimRangeEnd = CASAnimRangeStart
									CASAnimRangeStart = s.rotation.controller.keys[i].time
								)
								else
								(
									if CASAnimRangeEnd != undefined then
									(
										if CASAnimRangeEnd < s.rotation.controller.keys[i].time do CASAnimRangeEnd = s.rotation.controller.keys[i].time
									)
									else CASAnimRangeEnd = s.rotation.controller.keys[i].time
								)
							)
							else CASAnimRangeStart = s.rotation.controller.keys[i].time
						)
					)
				)
			)
			if CASAnimRangeStart != undefined and CASAnimRangeEnd != undefined do
			(
				if CASAnimRangeStart < CASAnimRangeEnd do
				(
					local OldAnimStretch = CASAnimRangeEnd - CASAnimRangeStart
					OldAnimStretch = (OldAnimStretch as float)/TicksPerFrame
					local NewAnimStretchFactor = 1.0 / spn_CASIncBy.value
					local NewAnimStretch = OldAnimStretch * NewAnimStretchFactor
					if chkbx_CASAccuracy.state do
					(
						NewAnimStretch = RoundUp2 NewAnimStretch spn_CASAccuracyVal.value
						NewAnimStretchFactor = NewAnimStretch / OldAnimStretch
					)
					local NewAnimShift = NewAnimStretch - OldAnimStretch
					/*
					local CASAnimRangeStartS = CASAnimRangeStart as string
					local CASAnimRangeEndS = CASAnimRangeEnd as string
					local NewAnimStretchS = NewAnimStretch as string
					local NewAnimShiftS = NewAnimShift as string
					local NewAnimStretchFactorS = NewAnimStretchFactor as string
					local CASAccuracyValS = (spn_CASAccuracyVal.value * 100.0) as string
					local my_str_msg = "Frames: from " + CASAnimRangeStartS + " to " + CASAnimRangeEndS + " !\nStretch:" + NewAnimStretchS + " !\n" + NewAnimStretchFactorS
					messagebox my_str_msg title:"TEST!"
					*/
					if NewAnimShift != 0.0 do
					(
						local NewAnimRangeShift
						if NewAnimShift > 0.0 then
						(
							for s in selection do
							(
								if s.position.controller.keys.count > 0 do
								(
									for i = s.position.controller.keys.count to 1 by -1 do
									(
										if s.position.controller.keys[i].time >= CASAnimRangeEnd then
										(
											moveKey s.position.x_position.controller i NewAnimShift
											moveKey s.position.y_position.controller i NewAnimShift
											moveKey s.position.z_position.controller i NewAnimShift
										)
										else if s.position.controller.keys[i].time > CASAnimRangeStart do
										(
											NewAnimRangeShift = ((s.position.controller.keys[i].time - CASAnimRangeStart) * NewAnimStretchFactor) - (s.position.controller.keys[i].time - CASAnimRangeStart)
											moveKey s.position.x_position.controller i NewAnimRangeShift
											moveKey s.position.y_position.controller i NewAnimRangeShift
											moveKey s.position.z_position.controller i NewAnimRangeShift
										)
									)
								)
								if s.rotation.controller.keys.count > 0 do
								(
									for i = s.rotation.controller.keys.count to 1 by -1 do
									(
										if s.rotation.controller.keys[i].time >= CASAnimRangeEnd then
										(
											moveKey s.rotation.x_rotation.controller i NewAnimShift
											moveKey s.rotation.y_rotation.controller i NewAnimShift
											moveKey s.rotation.z_rotation.controller i NewAnimShift
										)
										else if s.rotation.controller.keys[i].time > CASAnimRangeStart do
										(
											NewAnimRangeShift = ((s.rotation.controller.keys[i].time - CASAnimRangeStart) * NewAnimStretchFactor) - (s.rotation.controller.keys[i].time - CASAnimRangeStart)
											moveKey s.rotation.x_rotation.controller i NewAnimRangeShift
											moveKey s.rotation.y_rotation.controller i NewAnimRangeShift
											moveKey s.rotation.z_rotation.controller i NewAnimRangeShift
										)
									)
								)
							)
						)
						else
						(
							for s in selection do
							(
								if s.position.controller.keys.count > 0 do
								(
									for i = 1 to s.position.controller.keys.count do
									(
										if s.position.controller.keys[i].time > CASAnimRangeStart do
										(
											if s.position.controller.keys[i].time < CASAnimRangeEnd then
											(
												NewAnimRangeShift = ((s.position.controller.keys[i].time - CASAnimRangeStart) * NewAnimStretchFactor) - (s.position.controller.keys[i].time - CASAnimRangeStart)
												moveKey s.position.x_position.controller i NewAnimRangeShift
												moveKey s.position.y_position.controller i NewAnimRangeShift
												moveKey s.position.z_position.controller i NewAnimRangeShift
											)
											else
											(
												moveKey s.position.x_position.controller i NewAnimShift
												moveKey s.position.y_position.controller i NewAnimShift
												moveKey s.position.z_position.controller i NewAnimShift
											)
										)
									)
								)
								if s.rotation.controller.keys.count > 0 do
								(
									for i = 1 to s.rotation.controller.keys.count do
									(
										if s.rotation.controller.keys[i].time > CASAnimRangeStart do
										(
											if s.rotation.controller.keys[i].time < CASAnimRangeEnd then
											(
												NewAnimRangeShift = ((s.rotation.controller.keys[i].time - CASAnimRangeStart) * NewAnimStretchFactor) - (s.rotation.controller.keys[i].time - CASAnimRangeStart)
												moveKey s.rotation.x_rotation.controller i NewAnimRangeShift
												moveKey s.rotation.y_rotation.controller i NewAnimRangeShift
												moveKey s.rotation.z_rotation.controller i NewAnimRangeShift
											)
											else
											(
												moveKey s.rotation.x_rotation.controller i NewAnimShift
												moveKey s.rotation.y_rotation.controller i NewAnimShift
												moveKey s.rotation.z_rotation.controller i NewAnimShift
											)
										)
									)
								)
							)
						)
					)
				)
			)
		)
	)
	
	on DeleteHISolver pressed do
	(
		RemoveHISolver 0 0 0.0
	)

	on CreateKeysFAB pressed do
	(
		RemoveHISolver 1 chkbx_DetailedHIAnim.state spn_DetailedHIAnim.value
	)
	
	on DetachObj pressed do
	(
		RemoveAOLink 0 0 0.0
	)

	on CreateKeysFAO pressed do
	(
		RemoveAOLink 1 chkbx_DetailedAOAnim.state spn_DetailedAOAnim.value
	)
	
	on DelPosKeys pressed do
	(
		for s in selection do
		(
			deleteKeys s.position.controller
		)
	)
	
	on DelScaKeys pressed do
	(
		for s in selection do
		(
			deleteKeys s.scale.controller
		)
	)

) --// end rollout

/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

rollout Hierarchies_Rollout "Bone Hierarchy Conversion" width:132 height:170
(
	group "Biped settings"
	(
		button CreateBipedBeta "Create Biped for selected" width:160 height:22 align:#center tooltip:"Creates Biped for picked bones' hierarchy."
		
		
	)
	
	group "Bones System settings"
	(
		checkbutton chkbtn_replaceWithBones "Replace With Bones System" width:160 height:22 align:#center tooltip:"Duplicates a picked hierarchy with a new Bones System. If any skinned meshes are found, it will re-skin them to a matching hierarchy of point helpers that are constrained to the new bones. The skin helpers will be added to a new scene layer called #__SkinHelpers__# then frozen."
		checkbox chkbx_xAxisAlignedBones " X-Axis Aligned Bones" align:#left across:2 checked:true tooltip:"The existing hierarchy is aligned so that joints point down the X-axis. This is the default alignment for a newly created Bones System."
		checkbox chkbx_message " M" align:#right offset:[8,0] enabled:false checked:true tooltip:"Display a message when X-Axis Aligned Bones is turned off and Replace With Bones System is pressed."
		checkbox chkbx_createDisplayBones " Create Display Bones" align:#left offset:[12,0] checked:true enabled:false tooltip:"Display bones will be created between the real bones. They will be added to a new scene layer called #__DisplayBones__# then frozen."
		checkbox chkbx_keepOrigHierarchy " Keep Original Hierarchy" align:#left checked:false tooltip:"The original hierarchy will not be deleted after the new bones have been added."
		--checkbox chkbx_bakeBones " Bake Keys" align:#left checked:false tooltip:"Sets animation keys on the new bones based on a selected and animated hierarchy."
		checkbox chkbx_SMXRay " Skin Mesh \"X-Ray\" Mode" align:#left checked:true tooltip:"Sets Skin Mesh transparency after bones replace will be done."
		checkbox chkbx_NBAsBoxes " Show bones as boxes" align:#left checked:false tooltip:"Displays new bones as boxes(some versions of 3ds Max doesn't display new bones in wireframe mode, so check it if you have this problem)."
		label lbl_gap ""
		spinner spn_boneSize "Bone Size: " range:[0.01, 1000, 0.02] align:#left offset:[2,0] fieldwidth:45 across:2
		button btn_sizeApply "Apply" width:50 height:18 align:#right tooltip:"Applies the size value set in the spinner to the selected bones."
	)
	
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	
	fn f_findHierarchyRoot obj = --// Recursive function
	(
		if obj != undefined do
		(
			if isValidnode obj.parent then
			(
				f_findHierarchyRoot obj.parent
			)
			else
			(
				obj
			)
		)
	)

	/*---------------------------------------------------------------------------------------------------*/

	fn f_recursiveBakeKeys obj = --// Recursive function
	(
		for c in obj.children do
		(
			local n = getNodeByName (replace c.name 1 3 "")
			with Animate on
			(
				for t = animationRange.start to animationRange.end do
				(
					at time t
					(
						c.transform = n.transform
					)
				)
			)
			f_recursiveBakeKeys c
		)
	)

	/*---------------------------------------------------------------------------------------------------*/

	fn f_recursiveBakeKeysBones b = --// Recursive function
	(
		for c in b.children do
		(
			local n = getNodeByName ("ORIG_" + (replace c.name 1 5 ""))
			with Animate on
			(
				for t = animationRange.start to animationRange.end do
				(
					at time t
					(
						c.transform = n.transform
					)
				)
			)
			f_recursiveBakeKeysBones c
		)
	)

	/*---------------------------------------------------------------------------------------------------*/

	fn f_bakeBones a_newBones a_oldBones =
	(
		local rootBone = f_findHierarchyRoot a_newBones[1]
		local origRootBone = getNodeByName ("ORIG_" + (replace rootBone.name 1 5 ""))
		with Animate on
		(
			for t = animationRange.start to animationRange.end do
			(
				at time t
				(
					rootBone.transform = origRootBone.transform
				)
			)
		)
		--// Bake the child bones
		f_recursiveBakeKeysBones rootBone
	)

	/*---------------------------------------------------------------------------------------------------*/

	fn f_createNewBones a_origNodes bool_Xaxis =
	(
		local a_newBones = #() --// Array of all new bones
		local a_connectorBones = #() --// Array of display connector bones
		local a_namesMatch = #() --// Nested array of name strings that holds a mapping of the original bone name to the new bone system node, as well as a count of the children nodes
		local root = f_findHierarchyRoot	a_origNodes[1]

		for o in a_origNodes do
		(
			--// Create the initial bone and align it to the original node
			if o.parent == undefined do
			(
				local parentTrans = o.transform
				local parentPos = parentTrans.translation
				local b = BoneSys.createBone parentPos (parentPos + 1) o.dir
				b.transform = o.transform
				b.name = "Bone_#" + o.name
				if bool_Xaxis then
				(
					b.width = Hierarchies_Rollout.spn_boneSize.value
					b.height = Hierarchies_Rollout.spn_boneSize.value
				)
				else
				(
					b.width = Hierarchies_Rollout.spn_boneSize.value / 10.0
					b.height = Hierarchies_Rollout.spn_boneSize.value / 10.0
				)
				append a_newBones b
			)

			--// Create the child bones and align them to their corresponding nodes
			for i = 1 to o.children.count do
			(
				local c = o.children[i]
				local parentTrans = o.transform
				local parentPos = parentTrans.translation

				if bool_Xaxis then
				(
					local b = BoneSys.createBone parentPos (parentPos + Hierarchies_Rollout.spn_boneSize.value/2 + 0.01) o.dir
					b.width = Hierarchies_Rollout.spn_boneSize.value
					b.height = Hierarchies_Rollout.spn_boneSize.value
				)
				else
				(
					local b = BoneSys.createBone o.transform.pos c.transform.pos [0,0,1]
					b.width = Hierarchies_Rollout.spn_boneSize.value / 10.0
					b.height = Hierarchies_Rollout.spn_boneSize.value / 10.0
				)
				b.transform = c.transform
				b.name = "Bone_#" + c.name

				append a_newBones b

				--// If the original hierarchy nodes were not X-axis aligned, create display only bones between each real bone
				if bool_Xaxis == false AND Hierarchies_Rollout.chkbx_createDisplayBones.checked do
				(
					local b = BoneSys.createBone o.transform.pos c.transform.pos [0,0,1]
					b.name = "Bone_#" + o.name + "#DisplayBone"
					b.width = Hierarchies_Rollout.spn_boneSize.value
					b.height = Hierarchies_Rollout.spn_boneSize.value
					append a_connectorBones b
				)
			)
		)

		--// Record a mapping of the original hierarchy
		local a_parentMap = #()
		for o in a_origNodes do
		(
			append a_parentMap #(o.name)
			if o.parent != undefined then
			(
				append a_parentMap[a_parentMap.count] o.parent.name
			)
			else
			(
				append a_parentMap[a_parentMap.count] "SCENE"
			)
		)

		--// Link the new bones in the same hierarchy using the parent mapping array
		for b in a_newBones do --// a_newBones is an array of nodes
		(
			for a_map in a_parentMap do --// a_map is #(<object>, <parent>)
			(
				if a_map[2] != "SCENE" AND (filterString b.name "#").count != 3 do --// Not the root bone and not the display connector bones
				(
					if a_map[1] == (filterString b.name "#")[2] do
					(
						local parentNode = getNodeByName a_map[2]
						local boneParent = getNodeByName ("Bone_#" + parentNode.name)
						b.parent = boneParent
					)
				)
			)
		)

		--// Create display only bones if required
		if bool_Xaxis == false AND Hierarchies_Rollout.chkbx_createDisplayBones.checked do
		(
			--// Create a new scene layer and freeze it
			if LayerManager.getLayerFromName "#__DisplayBones__#" == undefined do
			(
				LayerManager.newLayerFromName "#__DisplayBones__#"
			)
			local layerDisplayBones = LayerManager.getLayerFromName "#__DisplayBones__#"
			layerDisplayBones.isFrozen = true

			--// Constrain the display connector bones to their main bone parents, then add them to the scene layer
			for b in a_connectorBones do
			(
				local parentName = (filterString b.name "#")[2]
				local parentNode = getNodeByName ("Bone_#" + parentName)

				b.controller = Link_Constraint()
				b.controller.addTarget parentNode 0
				setTransformLockFlags b #{1..9} --// Lock all the transforms (display panel)
				layerDisplayBones.addNode b
				b.showFrozenInGray = off
			)
		)

		a_newBones
	)

	/*---------------------------------------------------------------------------------------------------*/

	fn f_renameNewBones a_bones =
	(
		for b in a_bones do
		(
			local a_name = (filterString b.name "#")
			if a_name.count < 3 then --// Main bone
			(
				b.name = a_name[2]
			)
			else --// Display connector bone
			(
				b.name = (a_name[2] + "#" + a_name[3])
			)
		)
	)

	/*---------------------------------------------------------------------------------------------------*/

	fn f_duplicateHierarchyWithBones bool_XAxisAligned a_origHierarchy bool_keepOrigJoints =
	(
		local a_newHierarchy = #()

		if bool_XAxisAligned then
		(
			--// Create a new bones system from the original hierarchy for nodes that are aligned so that the bones point down the X-axis
			a_newHierarchy = f_createNewBones a_origHierarchy true
		)
		else
		(
			--// Create a new bones system from the original hierarchy for nodes that are not aligned so that the bones point down the X-axis
			a_newHierarchy = f_createNewBones a_origHierarchy false
		)

		--// Rename the original hierarchy
		for o in a_origHierarchy do
		(
			local tempnewbone = getNodeByName ("Bone_#" + o.name)
			setUserPropBuffer tempnewbone (getUserPropBuffer o)
			o.name = ("ORIG_" + o.name)
		)

		--// Rename the replacement bones to the old names
		f_renameNewBones a_newHierarchy

		a_newHierarchy
	)

	/*---------------------------------------------------------------------------------------------------*/

	fn f_createSkinHelpers a_bones =
	(
		--// Create a new scene layer then hide and freeze it
		if LayerManager.getLayerFromName "#__SkinHelpers__#" == undefined do
		(
			LayerManager.newLayerFromName "#__SkinHelpers__#"
		)
		local layerSkinHelpers = LayerManager.getLayerFromName "#__SkinHelpers__#"
		layerSkinHelpers.isFrozen = true

		local root = f_findHierarchyRoot	a_bones[1]
		local a_points = #()
		for b in a_bones do
		(
			local p = point size:g_LBTools_HM.helperSize
			append a_points p
			p.axistripod = off
			p.box = off
			p.cross = on
			p.name = "PT_" + b.name
			p.transform = b.transform
			layerSkinHelpers.addNode p
			--// Add constraints
			p.pos.controller = position_list()
			p.pos.controller.Available.controller = Position_Constraint()
			p.position.controller.setActive 2
			p.position.controller[2].appendTarget b 100.0
			p.rotation.controller = rotation_list()
			p.rotation.controller.Available.controller = Orientation_Constraint()
			p.rotation.controller.setActive 2
			p.rotation.controller[2].appendTarget b 100.0
		)
		--// Link the helpers into the same hierarchy as the original bones
		for p in a_points do
		(
			for b in a_bones do
			(
				if (replace p.name 1 3 "") == b.name do
				(
					if b.parent != undefined do
					(
						p.parent = getNodeByName ("PT_" + b.parent.name)
					)
					exit
				)
			)
		)
		--// Rename the points to be the same as the original nodes
		for i = 1 to a_bones.count do
		(
			a_points[i].name = a_bones[i].name
		)
		select a_points
		$selection.wirecolor = (color 14 255 2)
		$selection.showFrozenInGray = false
		$selection.xray = true
	)

	/*---------------------------------------------------------------------------------------------------*/

	fn f_replaceHierarchy thePickedNode bool_XAxisAligned bool_keepOrigJoints bool_SMXRay bool_NBAsBoxes =  --bool_bakeBones
	(
		IncreaseBHNumber()
		local NewBH_NumberS = substring (NewBH_Number as string) 2 -1
		local SkinMeshName
		g_LBTools_HM.f_selectHierarchy thePickedNode
		for b in selection do
		(
			b.name = NewBH_NumberS + b.name
		)
		local a_origHierarchy = selection as array --// An array to hold the original hierarchy for deleting later on
		local a_skinMeshes = g_LBTools_HM.f_collectSkinMeshes a_origHierarchy --// Returns any skin meshes (if any) associated with the picked hierarchy
		local a_newBones = #()

		if a_skinMeshes.count > 0 then --// Skinned meshes were found associated with the hierarchy
		(
			local a_skinBoneLists = g_LBTools_HM.f_collectSkinBoneLists a_skinMeshes --// Returns the skin meshes along with all their bones as a nested array, to rebuild the skin modifiers later
			local a_weightMeshes = g_LBTools_HM.f_collectWeightMeshes a_skinMeshes --// Returns the meshes created using Skin Utilities extract, for later reapplication of skin vertex weights

			--// Remove the skin modifiers
			for obj in a_skinMeshes do
			(
				collapseStack obj
			)

			a_newBones = f_duplicateHierarchyWithBones bool_XAxisAligned a_origHierarchy bool_keepOrigJoints

			--// Create a duplicate hierarchy of the new bones using point helpers and constrain them to the new bones
			f_createSkinHelpers a_newBones

			--// Add new skin modifers to the meshes using the new bones hierarchy then reappy skin weights and delete the skin weights meshes
			for obj in a_skinMeshes do
			(
				unfreeze obj
				addModifier obj (Skin())
				setCommandPanelTaskMode #modify
				modPanel.setCurrentObject obj.modifiers[#Skin]
				local meshFoundIndex = 0
				for i = 1 to a_skinBoneLists.count do
				(
					if a_skinBoneLists[i][1] == obj do
					(
						meshFoundIndex = i
						exit
					)
				)
				for boneNameIndex = 2 to a_skinBoneLists[meshFoundIndex].count do
				(
					--//skinOps.addbone obj.modifiers[1] (getNodeByName ("BH_#" + NewBH_NumberS + a_skinBoneLists[meshFoundIndex][boneNameIndex])) 1
					skinOps.addbone obj.modifiers[1] (getNodeByName a_skinBoneLists[meshFoundIndex][boneNameIndex]) 1
				)
				select obj
				selectmore (getNodeByName("SkinData_" + obj.name))
				skinUtils.ImportSkinDataNoDialog true false false false false 1.0 0
				obj.name = "SM_" + NewBH_NumberS + obj.name
				SkinMeshName = obj.name
				obj.wirecolor = (color 97 89 159)
				freeze obj
				obj.showFrozenInGray = false
				if bool_SMXRay do
				(
					if ((getVisController obj) == undefined) do
					(
						obj.visibility = bezier_float()
					)
					obj.visibility.controller.value = 0.6
					obj.backfaceCull = true
				)
				for boneNameIndex = 2 to a_skinBoneLists[meshFoundIndex].count do
				(
					local BoneHelper = getNodeByName a_skinBoneLists[meshFoundIndex][boneNameIndex]
				)
			)
			delete a_weightMeshes
		)
		else --// Just create the hierarchy without skin operations
		(
			a_newBones = f_duplicateHierarchyWithBones bool_XAxisAligned a_origHierarchy bool_keepOrigJoints
		)

		--// Rescale the real bones (Note: for non X-axis aligned bones, they will just become small rather than properly scaled from parent to child)
		for b in a_newBones do
		(
			b.resetBoneStretch()
		)

		--// Bake the bones to follow the original hierarchy
		/*if bool_bakeBones do
		(
			f_bakeBones a_newBones a_origHierarchy
		)*/

		--// Delete the original hierarchy
		if bool_keepOrigJoints == false do
		(
			delete a_origHierarchy
		)

		if LayerManager.getLayerFromName "#__SkinBones__#" == undefined do
		(
			LayerManager.newLayerFromName "#__SkinBones__#"
		)
		local layerSkinBones = LayerManager.getLayerFromName "#__SkinBones__#"
		--layerSkinBones.isFrozen = true
		layerSkinBones.display = #wireframe
		if bool_NBAsBoxes == true then layerSkinBones.boxMode = true

		for b in a_newBones do
		(
			layerSkinBones.addNode b
			--//b.visibility = 0
			b.displayByLayer = true
			--(layermanager.getlayerfromname (b.layer.name)).display = #wireframe
			b.wirecolor = (color 255 222 170)
			b.name = substring b.name 4 -1
			--//b.showFrozenInGray = false
			setUserProp b "SkinMeshName" SkinMeshName
			setUserProp b "BHNumber" NewBH_Number
			--//b.xray = true
			--//b.primaryVisibility = true
		)

		select a_newBones
	)

	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	
	on CreateBipedBeta pressed do
	(
		messagebox "This feature isn't complete yet, sorry!" title:"SORRY, DUDE."
	)
	
	on CreateBiped pressed do
	(
		local my_str_msg = "WARNING! You're going to create Biped for your bones' hierarchy.\n\n" +
		"Before doing this, make sure your bones' hierarchy belongs to humanoid creature,\n" +
		"in particular it MUST have GTA-bones(VC or SA)!\n\n" +
		"Have you selected any bone of hierarchy?"
		if (queryBox my_str_msg title:"WARNING") do
		(
			if selection[1] != undefined and (selection[1].children.count > 0 OR selection[1].parent != undefined) then
			(
				maxOps.setKeyMode = true
				maxOps.setKeyMode = false	
				IncreaseBipedNumber()
				SelectAllHierarchy selection[1]
				local OrigBonesArr = selection as array
				
				
				
				local NewBiped = biped.createNew 1.8 0.0 [0.0,0.0,1.8] neckLinks:1 spineLinks:2 fingers:1 fingerLinks:1 toes:1 toeLinks:1 trianglePelvis:false
				NewBiped.transform.controller.figureMode = true
				local NewBipedRootName = NewBiped.name
				local NewBipedRootNameLength = NewBipedRootName.count
				local NewBipedName = "Bpd" + substring (NewBiped_Number as string) 2 -1
				select NewBiped
				SelectAllHierarchy NewBiped
				local NewBipedBonesArr = selection as array
				NewBiped.name = NewBipedName
				local NewBipedBoneNumber = 0
				local BipedBonesMatches = 0
				local BipedRootBone
				local BipedPelvisBone
				local BipedSpineBone
				local BipedSpine1Bone
				local BipedLeftThighBone
				local BipedRightThighBone
				local OrigRootBone
				local OrigPelvisBone
				local OrigSpineBone
				local OrigSpine1Bone
				local OrigLeftThighBone
				local OrigRightThighBone
				
				local BipedBonesHelper0 = point size:0.1
				BipedBonesHelper0.box = true
				BipedBonesHelper0.wirecolor = (color 255 0 0)
				local BipedBonesHelper1 = point size:0.1
				BipedBonesHelper1.box = true
				BipedBonesHelper1.wirecolor = (color 0 255 0)
				local BipedBonesHelper2 = point size:0.1
				BipedBonesHelper2.box = true
				BipedBonesHelper2.wirecolor = (color 0 0 255)
				local BipedBonesHelper3 = point size:0.1
				BipedBonesHelper3.box = true
				BipedBonesHelper3.wirecolor = (color 255 255 0)
				BipedBonesHelper3.parent = BipedBonesHelper2
				BipedBonesHelper2.parent = BipedBonesHelper1
				BipedBonesHelper1.parent = BipedBonesHelper0
				
				for b in NewBipedBonesArr do
				(
					setUserProp b "BipedNumber" NewBiped_Number
					NewBipedBoneNumber = NewBipedBoneNumber + 1
					setUserProp b "BipedBoneNumber" NewBipedBoneNumber
					if b != NewBipedBonesArr[1] then
					(
						local NewBipedBoneName = substring b.name (NewBipedRootNameLength + 2) -1
						--messagebox NewBipedBoneName title:"TEST!"
						b.name = NewBipedName + " " + NewBipedBoneName
						if NewBipedBoneName == "Pelvis" do BipedPelvisBone = b
						if NewBipedBoneName == "Spine" do BipedSpineBone = b
						if NewBipedBoneName == "Spine1" do BipedSpine1Bone = b
						if NewBipedBoneName == "L Thigh" do BipedLeftThighBone = b
						if NewBipedBoneName == "R Thigh" do BipedRightThighBone = b
						for ob in OrigBonesArr do
						(
							if ob.name == NewBipedBoneName or ob.name == ("Bip01 " + NewBipedBoneName) or ob.name == (" " + NewBipedBoneName) or ob.name == (" " + substituteString NewBipedBoneName "Forearm" "ForeArm") do
							(
								setUserProp ob "BipedNumberB" NewBiped_Number
								setUserProp ob "BipedBoneNumberB" NewBipedBoneNumber
								setUserProp b "BipedBoneName" NewBipedBoneName
								setUserProp ob "BipedBoneNameB" NewBipedBoneName
								BipedBonesMatches = BipedBonesMatches + 1
								--Scale Biped bones
								if ob.children.count > 0 and ob.name != "Head" and ob.name != " Head" do
								(
									if ob.name != "L Foot" and ob.name != "R Foot" and ob.name != " L Foot" and ob.name != " R Foot" then
									(
										local OrigBoneLength = length (ob.children[1].pos - ob.pos)
										setUserProp ob "BipedBoneL" OrigBoneLength
										biped.setTransform b #scale [OrigBoneLength,OrigBoneLength,OrigBoneLength] false
									)
									else
									(
										BipedBonesHelper0.transform = ob.parent.parent.transform
										BipedBonesHelper1.transform = ob.parent.transform
										BipedBonesHelper2.transform = ob.transform
										BipedBonesHelper3.transform = ob.children[1].transform
										BipedBonesHelper0.rotation.x_rotation = 0.0
										BipedBonesHelper0.rotation.y_rotation = 0.0
										BipedBonesHelper0.rotation.z_rotation = 0.0
										BipedBonesHelper1.rotation.x_rotation = 0.0
										BipedBonesHelper1.rotation.y_rotation = 0.0
										BipedBonesHelper1.rotation.z_rotation = 0.0
										BipedBonesHelper2.rotation.x_rotation = 0.0
										BipedBonesHelper2.rotation.y_rotation = 0.0
										BipedBonesHelper2.rotation.z_rotation = 0.0
										BipedBonesHelper3.rotation.x_rotation = 0.0
										BipedBonesHelper3.rotation.y_rotation = 0.0
										BipedBonesHelper3.rotation.z_rotation = 0.0
										
										local FootHeightDirectionVector = BipedBonesHelper0.pos - BipedBonesHelper2.pos
										
										local FootXLength = BipedBonesHelper2.pos.x - BipedBonesHelper3.pos.x
										local FootYLength = BipedBonesHelper2.pos.y - BipedBonesHelper3.pos.y
										local FootZLength = BipedBonesHelper2.pos.z - BipedBonesHelper3.pos.z
										
										local FootHeightDirectionVectorNormal = sqrt(FootHeightDirectionVector.x * FootHeightDirectionVector.x + FootHeightDirectionVector.y * FootHeightDirectionVector.y + FootHeightDirectionVector.z * FootHeightDirectionVector.z)
										
										local FootXVectorCosine = FootHeightDirectionVector.x * FootXLength / (FootHeightDirectionVectorNormal * sqrt(FootXLength * FootXLength))
										local FootYVectorCosine = FootHeightDirectionVector.y * FootYLength / (FootHeightDirectionVectorNormal * sqrt(FootYLength * FootYLength))
										local FootZVectorCosine = FootHeightDirectionVector.z * FootZLength / (FootHeightDirectionVectorNormal * sqrt(FootZLength * FootZLength))
										
										local BiggerCosine = -1.0
										local FootHeight = 0.0
										if FootXVectorCosine > BiggerCosine do
										(
											BiggerCosine = FootXVectorCosine
											FootHeight = FootXLength
										)
										if FootYVectorCosine > BiggerCosine do
										(
											BiggerCosine = FootYVectorCosine
											FootHeight = FootYLength
										)
										if FootZVectorCosine > BiggerCosine do
										(
											BiggerCosine = FootZVectorCosine
											FootHeight = FootZLength
										)
										FootHeight = sqrt(FootHeight*FootHeight)
										
										local FootHypotenuse = length (ob.children[1].pos - ob.pos)--(BipedBonesHelper2.pos - BipedBonesHelper3.pos)
										local FootLength = sqrt(FootHypotenuse*FootHypotenuse - FootHeight*FootHeight)
										
										biped.setTransform b #scale [FootHeight,FootLength*1.25,FootLength*0.5] false
										biped.setTransform b.children[1] #scale [FootLength*0.25,FootHeight*0.1,FootLength*0.5] false
										
										--BipedBonesHelper0.transform.rotation = quat 0.0 0.0 0.0 1.0
										--BipedBonesHelper0.pos = ob.parent.parent.pos
										--BipedBonesHelper1.transform.rotation = quat 0.0 0.0 0.0 1.0
										--BipedBonesHelper2.transform.rotation = quat 0.0 0.0 0.0 1.0
										--BipedBonesHelper3.transform.rotation = quat 0.0 0.0 0.0 1.0
										
										
										
										
										/*
										ob.transform.rotation = quat 0.0 0.0 0.0 1.0
										BipedBonesHelper0.parent = ob.parent
										BipedBonesHelper0.transform = ob.transform
										BipedBonesHelper1.transform = ob.children[1].transform
										BipedBonesHelper1.parent = BipedBonesHelper0
										BipedBonesHelper0.rotation = quat 0.0 0.0 0.0 1.0
										BipedBonesHelper0.pos = ob.pos
										--BipedBonesHelper1.parent = undefined
										*/
										
										
										/*BipedBonesHelper0.pos = ob.pos
										BipedBonesHelper0.transform.rotation = ob.transform.rotation
										BipedBonesHelper1.pos = ob.children[1].pos
										BipedBonesHelper1.transform.rotation = ob.children[1].transform.rotation
										
										BipedBonesHelper1.parent = BipedBonesHelper0
										BipedBonesHelper0.rotation = quat 0.0 0.0 0.0 1.0
										BipedBonesHelper0.pos = ob.pos
										
										BipedBonesHelper1.parent = undefined
										*/
										
										
										
										/*
										BipedBonesHelper0.pos = ob.parent.parent.pos
										--BipedBonesHelper0.transform.rotation = ob.parent.transform.rotation
										BipedBonesHelper1.pos = ob.children[1].pos
										--BipedBonesHelper1.transform.rotation = ob.children[1].transform.rotation
										
										--BipedBonesHelper0.parent = ob.parent
										BipedBonesHelper1.parent = BipedBonesHelper0
										
										--BipedBonesHelper0.pos = biped.getTransform b #pos
										--BipedBonesHelper0.transform.rotation = biped.getTransform b #rotation
										
										local IkChain01 = IKSys.ikChain BipedBonesHelper0 BipedBonesHelper1 "IKHISolver"
										IkChain01.transform.controller.posThresh = 0.001
										IkChain01.transform.controller.rotThresh = 0.001
										IkChain01.transform.controller.iterations = 1000
										IkChain01.transform.controller.goalsize = 0.1
										--IkChain01.name = (s.name + " Chain")
										
										IkChain01.pos = ob.pos
										delete IkChain01
										
										local OrigFootHeight = length (BipedBonesHelper1.pos - ob.pos)
										local OrigFootLength = length (BipedBonesHelper1.pos - ob.children[1].pos)
										
										--local OrigFootVector = ob.pos - ob.children[1].pos
										
										
										biped.setTransform b #scale [OrigFootHeight,OrigFootLength,OrigFootLength*0.5] false
										
										--biped.setTransform b #scale [abs (BipedBonesHelper0.pos.z - BipedBonesHelper1.pos.z), abs OrigFootVector.y / 0.8, abs (OrigFootVector.y + OrigFootVector.z) * 0.5] false
										*/
										
										
									)
								)
								if NewBipedBoneName == "Pelvis" do OrigPelvisBone = ob
								if NewBipedBoneName == "Spine" do OrigSpineBone = ob
								if NewBipedBoneName == "Spine1" do OrigSpine1Bone = ob
								if NewBipedBoneName == "L Thigh" do OrigLeftThighBone = ob
								if NewBipedBoneName == "R Thigh" do OrigRightThighBone = ob
							)
						)
					)
					else
					(
						for ob in OrigBonesArr do
						(
							if ob.name == "Root" do
							(
								setUserProp ob "BipedNumberB" NewBiped_Number
								setUserProp ob "BipedBoneNumberB" NewBipedBoneNumber
								setUserProp b "BipedBoneName" "Root"
								setUserProp ob "BipedBoneName" "Root"
								BipedRootBone = b
								OrigRootBone = ob
								BipedBonesMatches = BipedBonesMatches + 1
							)
						)
					)
				)
				delete BipedBonesHelper0
				delete BipedBonesHelper1
				delete BipedBonesHelper2
				delete BipedBonesHelper3
				
				my_str_msg = "Bones matches: " + (BipedBonesMatches as string) + " !\n" + "LOL"
				messagebox my_str_msg title:"TEST!"
				--Scale Biped Pelvis
				if BipedPelvisBone != undefined and OrigLeftThighBone != undefined and OrigRightThighBone != undefined do
				(
					local OrigBoneLength = length (OrigLeftThighBone.pos - OrigRightThighBone.pos)
					biped.setTransform BipedPelvisBone #scale [OrigBoneLength,OrigBoneLength,OrigBoneLength] false
				)
				
				--NewBiped.transform.controller.trianglePelvis = false
				--NewBiped.transform.controller.trianglePelvis = true
				--NewBiped.transform.controller.trianglePelvis = false
				--NewBiped.transform.controller.trianglePelvis = true
				
				--NewBiped.transform.controller.sepSpineTracks = true
				--NewBiped.transform.controller.sepSpineTracks = false
				--NewBiped.transform.controller.sepSpineTracks = true
				--NewBiped.transform.controller.sepSpineTracks = false
				--NewBiped.transform.controller.sepLegsTracks = true
				--if BipedPelvisBone != undefined and BipedSpineBone != undefined do
				--(
					
					--BipedSpineBone.rotation.controller = undefined
					--BipedSpineBone.rotation.controller.appendTarget BipedPelvisBone 50.0
				--)
				
				
				local BipedBonesHelpersArr = #()
				BipedBonesHelpersArr.count = OrigBonesArr.count
				
				
				my_str_msg = "Bones array: " + (BipedBonesHelpersArr.count as string) + " !\n" + "LOL"
				messagebox my_str_msg title:"TEST!"
				
				--Move Biped Bones' Helpers
				for i = 1 to BipedBonesHelpersArr.count do
				(
					BipedBonesHelpersArr[i] = point size:0.1
					BipedBonesHelpersArr[i].pos = OrigBonesArr[i].pos
				
				
				
				)
				
				local BipedBonesHelper0 = point size:0.1
				BipedBonesHelper0.box = true
				BipedBonesHelper0.wirecolor = (color 255 0 0)
				local BipedBonesHelper1 = point size:0.1
				BipedBonesHelper1.box = true
				BipedBonesHelper1.wirecolor = (color 0 255 0)
				local BipedBonesHelper2 = point size:0.1
				BipedBonesHelper2.box = true
				BipedBonesHelper2.wirecolor = (color 0 0 255)
				
				BipedBonesHelper0.pos = biped.getTransform BipedRootBone #pos
				BipedBonesHelper0.transform.rotation = biped.getTransform BipedRootBone #rotation
				BipedBonesHelper0.parent = BipedRootBone
				BipedBonesHelper1.pos = biped.getTransform BipedSpineBone #pos
				BipedBonesHelper1.transform.rotation = biped.getTransform BipedSpineBone #rotation
				BipedBonesHelper1.parent = BipedBonesHelper0
				BipedBonesHelper2.pos = biped.getTransform BipedLeftThighBone #pos
				BipedBonesHelper2.transform.rotation = biped.getTransform BipedLeftThighBone #rotation
				BipedBonesHelper2.parent = BipedBonesHelper0
				
				--Move Biped Bones
				for b in NewBipedBonesArr do
				(
					NewBipedBoneNumber = -1
					if getUserProp b "BipedBoneNumber" != undefined do
					(
						if b != BipedRootBone and b != BipedPelvisBone do--then
						(
							NewBipedBoneNumber = getUserProp b "BipedBoneNumber"
						)
						--else
						--(
							--if b == BipedRootBone do	NewBipedBoneNumber = getUserProp BipedPelvisBone "BipedBoneNumber"
							--if b == BipedPelvisBone do NewBipedBoneNumber = getUserProp BipedPelvisBone "BipedBoneNumber"
						--)
					)
					if NewBipedBoneNumber != -1 then
					(
						for ob in OrigBonesArr do
						(
							if getUserProp ob "BipedBoneNumberB" != undefined and getUserProp ob "BipedBoneNumberB" == NewBipedBoneNumber do
							(
								biped.setTransform b #pos ob.pos false
								--biped.setTransform b #rotation ob.rotation false -- (quat 0 0 0 1) false --ob.rotation false
								
								biped.setTransform b #rotation (eulerToQuat (ob.transform.rotation as eulerangles) order:1) false
								
								if b.children.count > 0 do--then
								(
									if getUserProp b.children[1] "BipedBoneNumber" != undefined do
									(
										local NewBipedChildBoneNumber = getUserProp b.children[1] "BipedBoneNumber"
										for ob2 in OrigBonesArr do
										(
											if getUserProp ob2 "BipedBoneNumberB" != undefined and getUserProp ob2 "BipedBoneNumberB" == NewBipedChildBoneNumber do
											(
												if ob.name != "L Foot" and ob.name != "R Foot" and ob.name != " L Foot" and ob.name != " R Foot" then
												(
													--BipedBonesHelper0.pos = ob.pos --biped.getTransform b #pos
													--BipedBonesHelper0.rotation = ob.rotation --biped.getTransform b #rotation
													BipedBonesHelper0.transform = ob.transform
													BipedBonesHelper0.parent = b
													
													--BipedBonesHelper1.pos = biped.getTransform b.children[1] #pos
													BipedBonesHelper1.transform = b.children[1].transform
													--BipedBonesHelper1.parent = BipedBonesHelper0
													
													local IkChain01 = IKSys.ikChain BipedBonesHelper0 BipedBonesHelper1 "IKHISolver"
													IkChain01.transform.controller.posThresh = 0.001
													IkChain01.transform.controller.rotThresh = 0.001
													IkChain01.transform.controller.iterations = 1000
													IkChain01.transform.controller.goalsize = 0.1
													--IkChain01.name = (s.name + " Chain")
													IkChain01.pos = ob2.pos
													delete IkChain01
													
													biped.setTransform b #rotation (eulerToQuat (BipedBonesHelper0.transform.rotation as eulerangles) order:1) false
												)
												else
												(
													BipedBonesHelper0.parent = undefined
													BipedBonesHelper0.transform = ob.transform
													BipedBonesHelper1.transform = ob2.transform
													BipedBonesHelper0.transform = b.transform
													
													local IkChain01 = IKSys.ikChain BipedBonesHelper0 BipedBonesHelper1 "IKHISolver"
													IkChain01.transform.controller.posThresh = 0.001
													IkChain01.transform.controller.rotThresh = 0.001
													IkChain01.transform.controller.iterations = 1000
													IkChain01.transform.controller.goalsize = 0.1
													--IkChain01.name = (s.name + " Chain")
													IkChain01.pos = ob2.pos
													delete IkChain01
													
													biped.setTransform b #rotation (eulerToQuat (BipedBonesHelper0.transform.rotation as eulerangles) order:1) false
													
													
													
													
													
													
													
													
													
													
													
												)
											)
										)
									)
								)
								
								
								
								--else
								--(
								--	biped.setTransform b #rotation (eulerToQuat (ob.transform.rotation as eulerangles) order:1) false
								--)
							)
						)
					)
					else
					(
						if b == BipedRootBone do
						(
							biped.setTransform b #pos OrigSpineBone.pos false
							local IkChain01 = IKSys.ikChain BipedBonesHelper0 BipedBonesHelper1 "IKHISolver"
							IkChain01.transform.controller.posThresh = 0.001
							IkChain01.transform.controller.rotThresh = 0.001
							IkChain01.transform.controller.iterations = 1000
							IkChain01.transform.controller.goalsize = 0.1
							--IkChain01.name = (s.name + " Chain")
							IkChain01.pos = OrigSpine1Bone.pos
							delete IkChain01
							
							--biped.setTransform b #pos (OrigPelvisBone.pos) false
							biped.setTransform b #pos (OrigLeftThighBone.pos - (OrigLeftThighBone.pos - OrigRightThighBone.pos)*0.5) false
							
							local IkChain01 = IKSys.ikChain BipedBonesHelper0 BipedBonesHelper2 "IKHISolver"
							IkChain01.transform.controller.posThresh = 0.001
							IkChain01.transform.controller.rotThresh = 0.001
							IkChain01.transform.controller.iterations = 1000
							IkChain01.transform.controller.goalsize = 0.1
							--IkChain01.name = (s.name + " Chain")
							IkChain01.pos = OrigLeftThighBone.pos
							delete IkChain01
							biped.setTransform b #rotation (eulerToQuat (BipedBonesHelper0.transform.rotation as eulerangles) order:1) false
							
							
						)						
					)
				)
				
				
				
				
				
				
				
				
				
				
				
				
				
				--NewBiped.transform.controller.figureMode = false
				
				/*
				for b in NewBipedBonesArr do
				(
					NewBipedBoneNumber = -1
					if getUserProp b "BipedBoneNumber" != undefined do
					(
						if b != BipedRootBone and b != BipedPelvisBone then
						(
							NewBipedBoneNumber = getUserProp b "BipedBoneNumber"
						)
						else
						(
							if b == BipedRootBone do	NewBipedBoneNumber = getUserProp BipedPelvisBone "BipedBoneNumber"
							if b == BipedPelvisBone do NewBipedBoneNumber = getUserProp BipedPelvisBone "BipedBoneNumber"
						)
					)
					
					for ob in OrigBonesArr do
					(
						if getUserProp ob "BipedBoneNumberB" != undefined and getUserProp ob "BipedBoneNumberB" == NewBipedBoneNumber do
						(
							
							biped.setTransform b #pos ob.pos false
							--biped.setTransform b #rotation ob.rotation false -- (quat 0 0 0 1) false --ob.rotation false
							
							biped.setTransform b #rotation (eulerToQuat (ob.transform.rotation as eulerangles) order:1) false
							
						)
					)
				)
				*/
				
				
				
				
				
				
				
								
				--for s in selectionArr do
				--(
				
				
				
				
				
				--local NewBipedRootNumber = substring NewBipedRootName 4 -1
				--my_str_msg = "Biped number: " + NewBipedRootNumber + " !\n" + "Chars: " + (NewBipedRootNameLength as string) + " !\n" + "LOL"
				--messagebox my_str_msg title:"TEST!"
				
				
				
				
				
				
				--clearselection()
			
			
			)
			else
			(
				messageBox "You picked the wrong house, fool!\n(Select any bone of hierarchy and THEN push that button!)\n" title:"ERROR"
			)
		)
	)
	
	
	
	
	
	
	
	
	
	
	on spn_boneSize changed val do
	(
		for b in selection do
		(
			if classof b == BoneGeometry do
			(
				b.width = val
				b.height = val
			)
		)
	)

	on btn_sizeApply pressed do
	(
		for b in selection do
		(
			if classof b == BoneGeometry do
			(
				b.width = spn_boneSize.value
				b.height = spn_boneSize.value
			)
		)
	)

	on chkbx_xAxisAlignedBones changed state do
	(
		if state then
		(
			chkbx_message.enabled = false
			chkbx_createDisplayBones.enabled = false
		)
		else
		(
			chkbx_message.enabled = true
			chkbx_createDisplayBones.enabled = true
		)
	)

	on chkbtn_replaceWithBones changed state do
	(
		if state do
		(
			if chkbx_xAxisAlignedBones.checked == false do
			(
				str_msg = "Warning: The X-Axis Aligned Bones option has been turned off.\n\n" +
				"This means that new bones will be created using an alternative algorithm," +
				" which creates small bones that are aligned to the original hierarchy nodes. These bones will be used for joint selection.\n\n" +
				"It will then create 'display-only' bones between the aligned bones for visualization purposes and freeze them in a scene layer called #__DisplayBones__#," +
				" unless Create Display Bones has been disabled.\n\n" +
				"This is because 3ds Max can only create bones pointing down the X-axis and have visual geometry match it, but your existing hierarchy joints might not do that" +
				" (i.e. they point down Y or Z). The small bones will align to the original hierarchy (to preserve animation), but the display-only bones will not.\n\n" +
				"TIP #1: For all end joints that are not nubs (e.g. fingers, toes or head), it is recommended that additional nubs be added and linked to these prior to using the script." +
				" The new nubs should be aligned based on the forward axis (Y or Z) of the their parent joint. This will help the display-only bones generate at the ends of the hierarchy." +
				" Then after the script has run you can manually delete the added nub bones (they will appear longer).\n\n" +
				"TIP #2: You might also want to enable Display Links for all the small bones to make selection easier.\n\n" +
				"This message can be disabled by unchecking the 'M' checkbox."
				messagebox str_msg title:"Message"
			)

			local my_str_msg = "WARNING! Replacing Bones Hierarchy to Bones System will lead to impossibility to export your character to the game later!\n\n" +
			"This replacing is needed for easily animation only, so\n" +
			"SAVE or BACKUP YOUR CHARACTER BEFORE REPLACING HIS BONE HIERARCHY!\n\n" +
			"Have you selected any bone of hierarchy?"
			if (queryBox my_str_msg title:"WARNING") do
			(
				if selection[1] != undefined and (selection[1].children.count > 0 OR selection[1].parent != undefined) then
				(
					maxOps.setKeyMode = true
					maxOps.setKeyMode = false
					select selection[1]
					f_replaceHierarchy selection[1] chkbx_xAxisAlignedBones.state chkbx_keepOrigHierarchy.state chkbx_SMXRay.state chkbx_NBAsBoxes.state  --chkbx_bakeBones.state
					messagebox "Replace With Bones System completed.\n\nNew scene layers may have been added." title:""
				)
				else
				(
					messageBox "You picked the wrong house, fool!\n(Select any bone of hierarchy and THEN push that button!)\n" title:"ERROR"
				)
				--)
				chkbtn_replaceWithBones.state = false
			)
			chkbtn_replaceWithBones.state = false
		)
	)
) --// end rollout

/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

rollout Info_Rollout "Info" width:132 height:30
(
	group "Some Info"
	(
		button HelpButton "Help/How-to" across:2 width:90 pos:[13,25] tooltip:"Push this button to see some help info"
		button AboutButton "About" width:58 pos:[106,25] tooltip:"Push this button to see some extra info"
	)

	on HelpButton pressed do
	(
		local my_str_msg = "\"GTA Chars And Anim Helper\" gives you\nthe ability to skip some boring moments\nof skinning and animation of the characters\nfor GTA: Vice City and San Andreas.\n\nSOME options potentially can be used for\nGTA 3/4/5 modding.\n\n" +
		"Point to any button with the mouse cursor\nto see some extra info.\n\nThat's all, dudes."
		messageBox my_str_msg title:"Help for C&A Helper...nice title, genius!"
	)

	on AboutButton pressed do
	(
		try (DestroyDialog AboutDialog) catch()
		rollout AboutDialog "GTA Chars&Anim Helper v.0.91b" width:275 height:415
		(
			label abd1 "\"GTA Chars And Anim Helper\" v.0.91 (Open Beta)" align:#left
			label abd2 ""
			label abd3 "Made by Shagg_E, 2019:" align:#left
			HyperLink nrsite "http://newrockstar.do.am" address:"http://newrockstar.do.am" color: (color 0 127 0) hovercolor:(color 0 191 0) visitedcolor:(color 0 95 0)
			HyperLink ytchannel "https://youtube.com/user/NewrockstarGames" address:"https://youtube.com/user/NewrockstarGames" color: (color 191 0 0) hovercolor:(color 255 0 0) visitedcolor:(color 127 0 0)
			label abd4 ""
			label abd5 "Some parts of the code of \"Helper Manager\"" align:#left
			label abd6 "by Lorne Brooks have been used in this script:" align:#left
			HyperLink lbemail "lbtools2k@gmail.com" address:"mailto:lbtools2k@gmail.com" color: (color 0 0 255) hovercolor:(color 0 0 255) visitedcolor:(color 0 0 191)
			label abd7 ""
			label abd8 "Also, I want to credit these people:" align:#left
			label abd9 "Kam - for his incredible scripts," align:#left
			label abd10 "Yelmi and Deniska - for all their animations researches," align:#left
			label abd11 "The Hero - for \"RW File Converter\" and Mr. Jago -" align:#left
			label abd12 "for \"Moddable cutscene actors for Vice City\", which" align:#left
			label abd13 "helped me a lot to learn CS characters' structure," align:#left
			label abd14 "Wesser - for his Endorphin research, which" align:#left
			label abd15 "inspired me to work with Biped stuff," align:#left
			label abd16 "and many other guys who made all this possible!" align:#left
			label abd17 ""
			label abd18 "This script is not copyrighted, please feel free" align:#left
			label abd19 "to modify or distribute!" align:#left
		)
		createDialog AboutDialog
	)
) --// end rollout

/*********************************************************************************************************************************************************************/
--// MACRO CALLS FOR UI
/*********************************************************************************************************************************************************************/

try (closeRolloutFloater dostrib_flo) catch ()
dostrib_flo = NewRolloutFloater "C&A Helper" 190 615 50 100
addRollout Char_Helper_Rollout dostrib_flo rolledUp:true
addRollout Anim_Helper_Rollout dostrib_flo
addRollout Hierarchies_Rollout dostrib_flo rolledUp:true
addRollout Info_Rollout dostrib_flo rolledUp:true

/*********************************************************************************************************************************************************************/