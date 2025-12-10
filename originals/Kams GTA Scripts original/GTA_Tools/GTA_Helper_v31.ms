fn RecHier ObjectSet = (
	Oary = #()
	Pary = #()
	ref = undefined
	for obj in ObjectSet do (
		append Oary obj.name
		try ( append Pary obj.parent.name ) 
		catch ( 
			append Pary undefined 
			ref = obj.name
		)
	)--end for
	return #(Oary,Pary,ref)
)

fn AutoLink ObjectSet RecAry = (
	if ObjectSet.count == RecAry[1].count then ( 
--format "Total objects:%\n" ObjectSet.count
		for i = 1 to ObjectSet.count do (
			obj = ObjectSet[i]
--format "This:%[%]\n" obj.name i
			idx = finditem RecAry[1] obj.name
			if idx == 0 then (
				txt = "Can't found part:" + obj.name + "\n\nFailed in Auto Hierarchy Link."		
				messagebox txt title:"Parts Error!"
				return false
			)--end if no found--
			if RecAry[2][idx] != undefined then (
				pnt = execute ("$'" + RecAry[2][idx] + "'")
				obj.parent = pnt
				if obj.parent == undefined then (
					txt = "Can't found part:" + RecAry[2][idx] + "\n\nFailed in Auto Hierarchy Link."		
					messagebox txt title:"Parts Error!"
					return false
				)
			) else 	obj.parent = undefined
--format "%->%\n" obj.name RecAry[2][idx]
		)--end for
		return true
	) else (
		Messagebox "Total Parts not the same!\n\nFailed in Auto Hierarchy Link." title:"Count Error"
		return false
	)
)

fn DetachFacebySmoothGroup obj fastmode = (
	msh = snapshot obj
	--Collect SmoothGroup--
	sgary = #()
	for i = 1 to msh.numfaces do (
		sg = getfacesmoothgroup	msh i
		if sgary[sg] != undefined then append sgary[sg] i
		else sgary[sg] = #(i)
	)
--format "Face:%\tSGARY:%\n" msh.numfaces sgary.count
	if fastmode then max hide command panel toggle
	max modify mode
	select msh
	subobjectLevel = 3

	--Detach meshes by smoothgroup--
	for i = 1 to sgary.count do (

		-- ary != undefined, this group used --
		if sgary[i] != undefined then (
			try (
				meshop.detachFaces msh sgary[i] delete:false asMesh:false
			) catch (
				setFaceSelection msh sgary[i]
				meshops.detach msh
			)
		)--end if
	)--end for i

	subobjectLevel = 0
	if fastmode then max hide command panel toggle
	
	return msh
	
)--end fn

fn AutoXform obj SnapMesh ResultToMesh PivotState = (
	HieAry = for cld in obj.children collect cld
	for cld in HieAry do cld.parent = undefined
	if SnapMesh then (
		msh = snapshot obj
		msh.name = obj.name
		obj.name += "_org"
		hide obj
	) else msh = obj
	pvt = msh.pivot
	bkpos = msh.pos
	bkrot = msh.rotation
	bkscl = msh.scale
	msh.transform = (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
	xf = xform()
	addmodifier msh xf
	xf.gizmo.scale = bkscl
	xf.gizmo.rotation = bkrot
	xf.gizmo.pos = bkpos
	case PivotState of (
		1: msh.pivot = pvt
		2: msh.pivot = msh.center
		3: try (msh.pivot = msh.parent.center) catch (msh.pivot = pvt)
	)
	msh.parent = obj.parent
	for cld in HieAry do cld.parent = msh
	if ResultToMesh then convertToMesh msh
	return msh
)

rollout helproll01 "Links Helper" (
	group "Auto Hierarchy Link" (
		button RHier "Record Hierarchy" width:120 align:#center tooltip:"Select all objects in Hierarchy"
		button AHier "Auto Link" width:120 align:#center tooltip:"Select all objects to Link"
	)
	group "" (
		button XFhlp "Size/Alignment Solver" width:120 align:#center
  		checkbutton npvt "Stay" width:40 align:#center tooltip:"Pivot -> Unchange" across:3
  		checkbutton cpvt "Center" width:40 align:#center tooltip:"Pivot -> Center to Object" checked:true
    	checkbutton ppvt "Parent" width:40 align:#center tooltip:"Pivot -> Center to Parent"
		checkbox bkup "Backup Original" align:#left
		checkbox toemsh "Convert To EMesh" align:#left
	)
		group "" (
		button obj2dmy "Object to Dummy" width:120 align:#center
		spinner bs "Size" fieldwidth:45 range:[0,100000,1] align:#right
		checkbox delobj "Delete object"
	)
	on RHier pressed do (
		RecHierAry = RecHier ($selection as array)
		if RecHierAry[3] != undefined then RHier.text = RecHierAry[3]
		else (
			RecHierAry = undefined
			RHier.text = "Record Hierarchy"
		)
	)
    on AHier pressed do (
        if RecHierAry != undefined then
            rult = AutoLink ($selection as array) RecHierAry
        if rult == true then format "DONE!!!\n"
    )
	on npvt changed state do (
		if state == false then npvt.checked = true
		else (
			cpvt.checked = false
			ppvt.checked = false
		)
	)
	on cpvt changed state do (
		if state == false then cpvt.checked = true
		else (
			npvt.checked = false
			ppvt.checked = false
		)
	)
	on ppvt changed state do (
		if state == false then ppvt.checked = true
		else (
			cpvt.checked = false
			npvt.checked = false
		)
	)	
	on XFhlp pressed do (
		if $selection.count > 0 then (
			if npvt.checked then PivotState = 1
			if cpvt.checked then PivotState = 2
			if ppvt.checked then PivotState = 3
			SelAry = $selection as array
			for obj in SelAry where (SuperClassof obj == GeometryClass) do
				AutoXform obj bkup.checked toemsh.checked PivotState
		)
	)
	on obj2dmy pressed do (
		if $selection.count > 0 then (
			SelAry = $selection as array
			for obj in SelAry where (SuperClassof obj == GeometryClass) do (
				dmy = dummy boxsize:[bs.value/10,bs.value/10,bs.value/10]
				dmy.transform = obj.transform
				dmy.parent = obj.parent
				dmy.name = obj.name
				for cld in obj.children do cld.parent = dmy
				if delobj.checked then delete obj
				else (
					obj.name += "_org"
					hide obj				
				)
			)
		)	
	)

)--end rollout helproll01

rollout helproll02 "EMesh Helper" (
	group "" (
		button NorSolve "Smooth Group Solver" width:120 align:#center
		checkbox erobj "Delete old mesh"
		checkbutton Dsr "Disable Scene Redraw" width:120 align:#center tooltip:"Operation will be a bit faster!"
	)
	group "UV Flipper" (
		radiobuttons UVsel "" labels:#("Flip U", "Flip V")
		button FlipUV "Flip UV" width:120 align:#center
	)	

	on FlipUV pressed do (
		if selection.count >0 then (
			for i = 1 to selection.count do (
				--------------------
				--Flip X direction--
				-------------------- 
				if UVsel.state == 1 then (
					try (
						tt = selection[i].numTverts
						for j = 1 to tt do (
							tpget = getTvert selection[i] j
							tpget.x = 1 - tpget.x
							setTvert selection[i] j tpget
						)--end for jj
						Format "% flipped\n" selection[i].name
					) catch( format "%  is not a Editable Mesh!?\n" selection[i].name )--end try				
				)--end if state == 1
				--------------------
				--Flip Y direction--
				-------------------- 
				if UVsel.state == 2 then (
					try (
						tt = selection[i].numTverts
						for j = 1 to tt do (
							tpget = getTvert selection[i] j
							tpget.y = 1 - tpget.y
							setTvert selection[i] j tpget
						)--end for jj
						Format "% flipped\n" selection[i].name
					) catch( format "%  is not a Editable Mesh!?\n" selection[i].name )--end try			
				)--end if state == 2
			)--end for i		
		) else ( 
			messagebox "Nothing Selected" title:"Selection Error"
		)--end if/else selection.count
	)
    
	on NorSolve pressed do (
		if $selection.count > 0 then (
			if Dsr.checked then (
				DisableSceneRedraw()
				max hide command panel toggle
				fastmode = false
			) else fastmode = true
			SelAry = $selection as array
			for obj in SelAry where (SuperClassof obj == GeometryClass) do (
				tmp = DetachFacebySmoothGroup obj fastmode
				tmp.name = obj.name
				obj.name += "_org"
				tmp.parent = obj.parent				
				cldAry = for cld in obj.children collect cld
				for cld in cldAry do cld.parent = tmp
				if erobj.checked then delete obj
				else hide obj
			)--end for 
			EnableSceneRedraw()
			ForceCompleteRedraw()
			if  not fastmode then max hide command panel toggle
		)--end if
	)
)--end rollout helproll02

rollout helpabout "About" (
	label lbl1 "by Kam 17Aug05" align:#right
	label lbl2 "kam.lai@ntlworld.com" align:#right
)

if Kam_GTAhelper != undefined then ( closeRolloutFloater Kam_GTAhelper; gc() )
Kam_GTAhelper = newRolloutFloater "GTA Helper V3.11" 175 400 10 100		
addRollout helproll01 Kam_GTAhelper
addRollout helproll02 Kam_GTAhelper rolledup:true
addRollout helpabout Kam_GTAhelper rolledup:true