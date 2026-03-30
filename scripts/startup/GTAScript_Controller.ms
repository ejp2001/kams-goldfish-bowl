try ( closeUtility Kams_Scripts) catch ()

utility Kams_Scripts "GTA Tools 2026" (
	group "" (
		button script01 "DFF IO" width:140 align:#center
		button script06 "Character IO" width:140 align:#center offset:[0,-5]
		button script02 "Collision IO" width:140 align:#center offset:[0,-5]
		button script03 "Map IO" width:140 align:#center offset:[0,-5]
	)
	on script01 pressed do ( 
			try ( fileIn (scriptspath+"\\GTA_Tools_2026\\GTA_DFF_IO.ms")   )
		catch messagebox "Could not load DFF IO script." title:"Can't find DFF IO script"
	)		
	
	on script06 pressed do (
		try ( fileIn (scriptspath+"\\GTA_Tools_2026\\GTA_CHAR_IO.ms")   )
		catch messagebox "Could not load Character IO script." title:"Can't find Character IO script"
	)

	on script02 pressed do (   
		try ( fileIn (scriptspath+"\\GTA_Tools_2026\\GTA_COL_IO.ms")   )
		catch messagebox "Could not load COL IO script." title:"Can't find COL IO script"
	)

	on script03 pressed do ( 
		try ( fileIn (scriptspath+"\\GTA_Tools_2026\\GTA_Map_IO.ms")   )
		catch messagebox "Could not load Map IO script." title:"Can't find Map IO script"
	)
	
	on script12a pressed do ( 
		try ( fileIn (scriptspath+"\\GTA_Tools_2026\\tools\\2dfx_light_editor.ms")   )
		catch messagebox "Could not load 2dfx Light Editor script." title:"Can't find 2dfx Light Editor script"
	)
	
	on script12b pressed do ( 
		try ( fileIn (scriptspath+"\\GTA_Tools_2026\\tools\\2dfx_particle_editor.ms")   )
		catch messagebox "Could not load 2dfx Particle Editor script." title:"Can't find 2dfx Particle Editor script"
	)
	
	on script12c pressed do ( 
		try ( fileIn (scriptspath+"\\GTA_Tools_2026\\tools\\2dfx_attractor_editor.ms")   )
		catch messagebox "Could not load 2dfx Attractor Editor script." title:"Can't find 2dfx Attractor Editor script"
	)
	
	group "Animation" (
		button script13 "IFP IO" width:140 align:#center tooltip:"Load, edit, and export IFP animation files"
		button script14 "UV Animation" width:140 align:#center tooltip:"Create UV sprite animations from texture atlases" offset:[0,-5]
		button script15 "Anim Bake" width:140 align:#center tooltip:"Bake biped animation to GTA character bones" offset:[0,-5]
		button script05 "IFP dump" width:140 align:#center tooltip:"This script is for GMax only" offset:[0,-5]
	)
	
	on script13 pressed do (
		try ( fileIn (scriptspath+"\\GTA_Tools_2026\\GTA_IFP_IO.ms")   )
		catch messagebox "Could not load IFP IO script." title:"Can't find IFP IO script"
	)
	
	on script14 pressed do (
		try ( fileIn (scriptspath+"\\GTA_Tools_2026\\GTA_UV_ANI.ms")   )
		catch messagebox "Could not load UV Animation script." title:"Can't find UV Animation script"
	)
	
	on script15 pressed do (
		local animBakePath = (scriptspath+"\\GTA_Tools_2026\\GTA_AnimBake.ms")
		if doesFileExist animBakePath then
		(
			try ( fileIn animBakePath )
			catch messagebox ("Could not load Anim Bake script.\n\nPath:\n" + animBakePath + "\n\nError:\n" + (getCurrentException() as string)) title:"Anim Bake Load Error"
		)
		else
		(
			messagebox ("Anim Bake script file not found:\n\n" + animBakePath + "\n\nCopy GTA_AnimBake.ms into GTA_Tools_2026.") title:"Can't find Anim Bake script"
		)
	)
	
	on script05 pressed do (
				try ( fileIn (scriptspath+"\\GTA_Tools_2026\\GTA_IFP_dump.ms")   )
			catch messagebox "Could not load IFP IO script." title:"Can't find Animation IO script"
		)

	group "Tools" (
		button script04 "Prelite Tools" width:140 align:#center
		button script12a "2dfx Light" width:140 align:#center
		button script12b "2dfx Particle" width:140 align:#center
		button script12c "2dfx Attractor" width:140 align:#center
	)

	on script04 pressed do (
		try (DestroyDialog G_PrelitTools) catch()
		rollout G_PrelitTools "Prelit Tools"  (
			group "show vertex color" (
				button _day_btn "DAY"  align:#left across:3 
				button _off_btn "Off"  align:#left  width:40 offset:[-4,0]
				button _night_btn "NIGHT"  align:#right 
			)
			group "Set Prelit to Sel Models" (
				colorPicker day_cp "Day  " color:[255,255,255] width:111 height:20 align:#left
				colorPicker nig_cp "Night" color:[0,0,0] width:111 height:20 align:#left
			)
			group "Vertex coping" (
				spinner prVal "+/- value:" width:90 height:16 range:[-255,255,0] type:#integer align:#center
				button DtoN "Day to Night"  height:28 align:#left  across:2 width:68
				button NtoD "Night to Day"  height:28 width:68 align:#right
				button DtoD "Day to Day"  height:24 align:#left  across:2 width:64 offset:[0,5]
				button NtoN "Night to Night"  height:24 width:72 align:#right offset:[0,5]
			)

			on _off_btn pressed do
				if $selection != undefined then (
					for o in $selection where (superclassof o  == GeometryClass ) do (
						o.showVertexColors = false
					)
					completeRedraw()
				)
				
			on _night_btn pressed do
				if $selection != undefined then (
					for o in $selection where (superclassof o  == GeometryClass ) do (
						o.showVertexColors = true
						o.vertexColorType = #illum
					)
					completeRedraw()
				)
			on _day_btn pressed do
				if $selection != undefined then (
					for o in $selection where (superclassof o  == GeometryClass ) do (
						o.showVertexColors = true
						o.vertexColorType = #color
					)
					completeRedraw()
				)
			
			on DtoD pressed do (	
				if $selection !=undefined then (
					suspendediting()
					disableSceneRedraw()
					setWaitCursor()
					enableUndo false
					try (
						for obj in $selection where (superclassof obj == GeometryClass ) do (
							if (classof obj) != Editable_Poly then convertToPoly obj
							if polyop.getMapSupport obj 0 == true then (
								for i = 1 to polyOp.getNumMapVerts obj 0 do (
								  tmp1 = polyOp.getMapVert obj 0 i
								  tmp1 *= 255.0
								  tmp1 += prVal.value
								  tmp1 /= 255.0
									if tmp1[1] > 1.0 then tmp1[1] = 1.0
									if tmp1[2] > 1.0 then tmp1[2] = 1.0
									if tmp1[3] > 1.0 then tmp1[3] = 1.0						
									if tmp1[1] < 0.0  then tmp1[1] = 0.0
									if tmp1[2] < 0.0  then tmp1[2] = 0.0
									if tmp1[3] < 0.0  then tmp1[3] = 0.0
								  polyOp.setMapVert obj 0 i tmp1
								)
								addModifier obj (VertexPaint ())
								collapseStack obj
								format "\nVertex Coping: done! %\n" obj.name
							)
						)
					) catch ( format "\nVertex Coping: error!\n")
					resumeediting()
					enableSceneRedraw()
					setArrowCursor()
					redrawViews()
					enableUndo true
				)
			)
			
			on NtoN pressed do (	
				if $selection !=undefined then (
					suspendediting()
					disableSceneRedraw()
					setWaitCursor()
					enableUndo false
					clearlistener()
					try (
						for obj in $selection where (superclassof obj == GeometryClass ) do (
							if (classof obj) != Editable_Poly then convertToPoly obj
							if polyop.getMapSupport obj -1 == true then (
								for i = 1 to polyOp.getNumMapVerts obj -1 do (
								  tmp1 = polyOp.getMapVert obj -1 i
								  tmp1 *= 255.0
								  tmp1 += prVal.value
								  tmp1 /= 255.0
									if tmp1[1] > 1.0 then tmp1[1] = 1.0
									if tmp1[2] > 1.0 then tmp1[2] = 1.0
									if tmp1[3] > 1.0 then tmp1[3] = 1.0						
									if tmp1[1] < 0.0  then tmp1[1] = 0.0
									if tmp1[2] < 0.0  then tmp1[2] = 0.0
									if tmp1[3] < 0.0  then tmp1[3] = 0.0
									polyOp.setMapVert obj -1 i tmp1
								)
								addModifier obj (VertexPaint ())
								collapseStack obj
								format "\nVertex Coping: done! %\n" obj.name
							)
						)
					) catch ( format "\nVertex Coping: error!\n")
					resumeediting()
					enableSceneRedraw()
					setArrowCursor()
					redrawViews()
					enableUndo true
				)
			)
			
			on DtoN pressed do (	
				if $selection !=undefined then (
					suspendediting()
					disableSceneRedraw()
					setWaitCursor()
					enableUndo false
					try (
						for obj in $selection where (superclassof obj == GeometryClass ) do (
							if (classof obj) != Editable_Poly then convertToPoly obj
							if polyop.getMapSupport obj 0 == true then (
								polyOp.setMapSupport obj -1 false
								polyOp.setMapSupport obj -1 true
								vcnum = polyOp.getNumMapVerts obj 0
								polyOp.setNumMapVerts obj -1 vcnum
								for i = 1 to vcnum do (
								  tmp1 = polyOp.getMapVert obj 0 i
								  tmp1 *= 255.0
								  tmp1 += prVal.value
								  tmp1 /= 255.0
									if tmp1[1] > 1.0 then tmp1[1] = 1.0
									if tmp1[2] > 1.0 then tmp1[2] = 1.0
									if tmp1[3] > 1.0 then tmp1[3] = 1.0						
									if tmp1[1] < 0.0  then tmp1[1] = 0.0
									if tmp1[2] < 0.0  then tmp1[2] = 0.0
									if tmp1[3] < 0.0  then tmp1[3] = 0.0
								  polyOp.setMapVert obj -1 i tmp1
								)
								vcfaces = polyOp.getNumMapFaces obj 0
								polyOp.setnummapfaces obj -1 vcfaces
								for i = 1 to vcfaces do (
									tmp1 = polyOp.getMapFace obj 0 i
									polyOp.setMapFace obj -1 i tmp1
								)
								format "\nVertex Coping: done! %\n" obj.name
							) else format "\nVertex Coping: error! obj % not have this map support\n" obj.name
						)
					) catch ( format "\nVertex Coping: error!\n")
					resumeediting()
					enableSceneRedraw()
					setArrowCursor()
					redrawViews()
					enableUndo true
				)
			)
			on NtoD pressed do (	
				if $selection !=undefined then (
					suspendediting()
					disableSceneRedraw()
					setWaitCursor()
					enableUndo false
					try (
						for obj in $selection where (superclassof obj == GeometryClass ) do (
							if (classof obj) != Editable_Poly then convertToPoly obj
							if polyop.getMapSupport obj -1 == true then (
								polyOp.setMapSupport obj 0 false
								polyOp.setMapSupport obj 0 true
								vcnum = polyOp.getNumMapVerts obj -1
								polyOp.setNumMapVerts obj 0 vcnum
								for i = 1 to vcnum do (
								  tmp1 = polyOp.getMapVert obj -1 i
								  tmp1 *= 255.0
								  tmp1 += prVal.value
								  tmp1 /= 255.0
									if tmp1[1] > 1.0 then tmp1[1] = 1.0
									if tmp1[2] > 1.0 then tmp1[2] = 1.0
									if tmp1[3] > 1.0 then tmp1[3] = 1.0						
									if tmp1[1] < 0.0  then tmp1[1] = 0.0
									if tmp1[2] < 0.0  then tmp1[2] = 0.0
									if tmp1[3] < 0.0  then tmp1[3] = 0.0
								  polyOp.setMapVert obj 0 i tmp1
								)
								vcfaces = polyOp.getNumMapFaces obj -1
								polyOp.setnummapfaces obj 0 vcfaces
								for i = 1 to vcfaces do (
									tmp1 = polyOp.getMapFace obj -1 i
									polyOp.setMapFace obj 0 i tmp1
								)
								format "\nVertex Coping: done! %\n" obj.name
							) else format "\nVertex Coping: error! obj % not have this map support\n" obj.name
						)
						
					) catch ( format "\nVertex Coping: error!\n")
					resumeediting()
					enableSceneRedraw()
					setArrowCursor()
					redrawViews()
					enableUndo true
				)
			)

			on day_cp changed arg do (
				for obj in $selection where superclassof obj == GeometryClass do (
					convertToPoly obj
					polyOp.defaultMapFaces obj 0
					for i = 1 to obj.numverts do polyOp.setMapVert obj 0 i (arg/255.0)
					completeRedraw()
				)
			)
			on nig_cp changed arg do (
				for obj in $selection  where superclassof obj == GeometryClass do (
					convertToPoly obj
					polyOp.defaultMapFaces obj -1
					for i = 1 to obj.numverts do polyOp.setMapVert obj -1 i (arg/255.0)
					completeRedraw()
				)
			)
		)
		createDialog G_PrelitTools
	)

	-----------------------------------------
	button script08 "About"  align:#left height:16 tooltip:"Authors"
	on script08 pressed do (
		try (DestroyDialog KAM_About) catch()
		rollout KAM_About "Contributors"    (
			label about_1 "[19.12.05]" offset: [0.0,7.0,0.0]
			label about_2 "Kam, Odie, Pioneer"
			HyperLink l_top "Original Release - Gta Forums" align:#center   height:18 address:"http://gtaforums.com/topic/218318-rel-kams-maxscript-going-over-quick-update/" color:(color 10 147 225) hovercolor:(color 94 198 255) visitedcolor:(color 10 147 225)
			
			label about_3 " Includes code from:" offset: [0.0,7.0,0.0]
			label about_0 "2018 Update by Goldfish"
			label about_4 "DexX SA Tools"
			label about_5 "Various AI sources"
			
			label about_6 " -- 2026 Edition --" offset: [0.0,7.0,0.0]
			label about_7 "Last update: 30.03.2026"
			label about_8 "Additional AI code"
			label about_9 "at the direction of E2001"
			HyperLink l_bottom "See Repo For Updates" align:#center   height:18 address:"https://github.com/ejp2001/kams-goldfish-bowl" color:(color 10 147 225) hovercolor:(color 94 198 255) visitedcolor:(color 10 147 225)			
			
		)
		createDialog KAM_About
	)

)
openUtility Kams_Scripts
