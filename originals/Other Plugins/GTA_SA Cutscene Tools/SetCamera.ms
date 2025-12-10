fn DelComments s cs =
(
	local ss = trimLeft s -- trim line from the basic whitespace characters (space, tab, and newlines)
	local p = FindString ss cs -- how many characters before "cs" string
	if p == undefined then return ss -- if "cs" string not found then it's okay
	else
		if p > 1 then return substring ss 1 (p-1) -- if its not the line where "cs" string is the first one - then it's also okay
		else return "" -- else it's not okay
)

---------------------------------------------------//
rollout MCamera "Camera Position Editor"
(
	group "Load or Create Camera"
	(
		button btn_LCamer "Load from File" width:149 tooltip:"Loads a Camera and its animation from a .dat File."
		button btn_CCamer "Create Camera" width:149 tooltip:"Creates a new Target Camera system."
	)
	group "Edit FOV"
	(
		label FOVFrames "Total FOV keyframes: 0" align:#left
		button btn_GoToPrevFrame"<<" width:74 align:#left across:2 tooltip:"Go to the previous frame."
		button btn_GoToNextFrame ">>" width:74 align:#right tooltip:"Go to the next frame."
		spinner spn_FOV "FOV value: " range:[0.0, 175.0, 0] type:#float align:#left fieldwidth:45 across:2
		button btn_FOVSet "Set!" width:32 height:18 align:#right tooltip:"Applies FOV at the selected time."
		button btn_FOVDelete "Delete FOV keyframe" width:149 tooltip:"Deletes FOV at the selected time."
		button btn_FOVClear "Delete All FOV animation" width:149 tooltip:"Clears all keyframes of Camera FOV."
	)
	group "Create .dat file"
	(
		button btn_ECamer "Create file for selected" width:149 height:24 offset:[-1,5]tooltip:"Creates a .dat file which will contain animation of the selected camera."
	)
	
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	
	fn FOVInfoUpdate =
	(
		if selection.count == 1 then
		(
			if ((classOf $) == Targetcamera) do
			(
				if $.fov != undefined then
				(
					spn_FOV.enabled = true
					spn_FOV.value = $.curFOV
				)
				else
				(
					spn_FOV.value = 0
					spn_FOV.enabled = false
				)
			)
		)
		else
		(
			spn_FOV.value = 0
			spn_FOV.enabled = false
		)
	)
	
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/
	/*---------------------------------------------------------------------------------------------------*/

	on MCamera open do
	(
		callbacks.addScript #selectionSetChanged "MCamera.FOVInfoUpdate()" id:#gtacamerahelper
		FOVInfoUpdate()
	)

	on MCamera close do
	(
		callbacks.removeScripts id:#gtacamerahelper
	)
	
	on btn_FOVSet pressed do
	(
		if selection.count == 1 do
		(
			if ((classOf $) == Targetcamera) do
			(
				with Animate on
				(
					at time sliderTime $.curFOV = spn_FOV.value
				)
			)	
		)
	)
	
	
	
	
	
	
	
	
	
	
	
	on btn_CCamer pressed do
	(
		--Cam = targetCamera target:(targetObject ())
		--Cam.target.position = [-0.324,0.0,0.0]
		--TargetCamera name:cameraname target:(TargetObject name:(cameraname + ".Target")) isselected:on
		--Cam = targetCamera target:(TargetObject ())
		--Cam.target.name = Cam.name + ".Target"
		Cam = freecamera()
		Cam.type = #target
		Cam.target.position = [-0.324,0.0,0.0]
		Cam.fovType = 2
		select Cam
	)
		
	on btn_ECamer pressed do
	(
		local cam = undefined
		for obj in selection do
		(
			if ((classOf obj) == Targetcamera) then 
			(
				if obj != undefined then cam = obj	
			) 
		)	
		clearSelection()
		if cam != undefined then Select cam	
		else messageBox "Camera is not selected"
		if selection.count > 0 then
		( 
			if cam != undefined then
			(
				if frameRate == 30 then
				(
					local index1 = 0
					local index2 = 0
					local index3 = 0
					local index4 = 0
					local index1t = 0
					local index2t = 0
					local index3t = 0
					local index4t = 0
					--cam.FOV.controller = bezier_float()
					if cam.pos.controller.keys.count > 0 do index3 = cam.pos.controller.keys.count
					if cam.target.position.controller.keys.count > 0 do index4 = cam.target.position.controller.keys.count
					if (index3 > 1) and (index4 > 1) then 
					(  
						ultimatelastframetime = 0.0
						if cam.pos.controller.keys[cam.pos.controller.keys.count].time > ultimatelastframetime do ultimatelastframetime = cam.pos.controller.keys[cam.pos.controller.keys.count].time
						if cam.target.position.controller.keys[cam.target.position.controller.keys.count].time > ultimatelastframetime then
						(
							ultimatelastframetime = cam.target.position.controller.keys[cam.target.position.controller.keys.count].time
							index3 = index3 + 1
							index3t = 1
						)
						else
						(
							if cam.target.position.controller.keys[cam.target.position.controller.keys.count].time < ultimatelastframetime do
							(
								index4 = index4 + 1
								index4t = 1
							)
						)
						if cam.FOV.controller.keys.count > 0 do
						(
							index1 = cam.FOV.controller.keys.count
							if cam.FOV.controller.keys[cam.FOV.controller.keys.count].time < ultimatelastframetime do
							(
								index1 = index1 + 1
								index1t = 1
							)
						)
						if cam.controller.roll_angle.controller.keys.count > 0 do
						(
							index2 = numKeys cam.controller.roll_angle.controller
							if (getKeyTime cam.controller.roll_angle.controller (numKeys cam.controller.roll_angle.controller)) < ultimatelastframetime do
							(
								index2 = index2 + 1
								index2t = 1
							)
						)
						fname = getSaveFileName types:"Text file (*.dat)|*.dat" --|All files (*.*)|*.*"
						if fname != undefined then
						( 			
							f = createfile fname
							--------------------------------------------- BLOCK 1: Camera FOV Value
							if index1 > 0 then
							(
								format "%,\n" index1 to: f
								for i=1 to index1 do
								(
									if i == index1 and index1t == 1 then
									(
										fov2 = at time ultimatelastframetime cam.curFOV
										if (fov2 > 179.0) then fov2 = "179.0"
										else if 0.1 > fov2 then fov2 = 0.1
										format "%,%,%,%,\n" (ultimatelastframetime/frameRate) fov2 fov2 fov2 to: f 
									)
									else
									(
										--pos1 = getKeyTime cam.pos.controller i
										--str1= (pos1.frame as float)/frameRate
										--tm=cam.pos.controller.keys[i].time
										--fov1 = at time tm cam.targetDistance
										--if (fov1 > 99.0) then fov1 = "98.482513"
										--else if 60.0 > fov1 then fov1 = fov1 + 20.0
										--format "%f,%,%,%,\n" str1 fov1 fov1 fov1 to: f
										--fov1 = getKeyTime cam.FOV.controller i
										--str1= (fov1.frame as float)/frameRate
										tm=cam.FOV.controller.keys[i].time
										fov2 = at time tm cam.curFOV
										if (fov2 > 179.0) then fov2 = "179.0"
										else if 0.1 > fov2 then fov2 = 0.1
										format "%,%,%,%,\n" (tm/frameRate) fov2 fov2 fov2 to: f 
									)
								) 
							)
							else
							(
								format "2,\n" to: f 
								format "0.0f,45.0,45.0,45.0,\n" to: f
								format "%,45.0,45.0,45.0,\n" (ultimatelastframetime/frameRate) to: f
							)
							format ";\n" to: f
							--------------------------------------------- BLOCK 2: Camera Roll Angle - currently disabled
							/*if index2 > 0 then
							(
								format "%,\n" index2 to: f 
								for i=1 to index2 do
								(
									if i == index2 and index2t == 1 then
									(
										rollangle2 = at time ultimatelastframetime cam.controller.roll_angle
										format "%,%,%,%,\n" (ultimatelastframetime/frameRate) rollangle2 rollangle2 rollangle2 to: f 
									)
									else
									(
										--rollangle1 = getKeyTime cam.controller.roll_angle.controller i
										--str1= (rollangle1.frame as float)/frameRate
										tm=cam.controller.roll_angle.keys[i].time
										rollangle2 = at time tm cam.controller.roll_angle
										format "%,%,%,%,\n" (tm/frameRate) rollangle2 rollangle2 rollangle2 to: f 
										--format "%f,0.000000,0.000000,0.000000,\n" str1 to: f
									)
								)
							)
							else*/
							(
								format "2,\n" to: f 
								format "0.0f,0.0,0.0,0.0,\n" to: f
								format "%,0.0,0.0,0.0,\n" (ultimatelastframetime/frameRate) to: f
							)
							format ";\n" to: f
							--------------------------------------------- BLOCK 3: Camera Position
							format "%,\n" index3 to: f
							for i=1 to index3 do
							(
								if i == index3 and index3t == 1 then
								(
									str2= at time ultimatelastframetime cam.position.controller.x_position 
									str3= at time ultimatelastframetime cam.position.controller.y_position
									str4= at time ultimatelastframetime (cam.position.controller.z_position+1.0)
									format "%,%,%,%,%,%,%,%,%,%,\n" (ultimatelastframetime/frameRate) str2 str3 str4 str2 str3 str4 str2 str3 str4 to: f 
								)
								else
								(
									--pos1 = getKeyTime cam.pos.controller i
									--str1= (pos1.frame as float)/frameRate
									tm=cam.pos.controller.keys[i].time
									str2= at time tm cam.position.controller.x_position 
									str3= at time tm cam.position.controller.y_position
									str4= at time tm (cam.position.controller.z_position+1.0)
									format "%,%,%,%,%,%,%,%,%,%,\n" (tm/frameRate) str2 str3 str4 str2 str3 str4 str2 str3 str4 to: f
								)
							)
							format ";\n" to: f
							--------------------------------------------- BLOCK 4: Camera Target Position
							format "%,\n" index4 to: f
							for i=1 to index4 do
							(
								if i == index4 and index4t == 1 then
								(
									str2=at time ultimatelastframetime cam.target.position.controller.x_position--value
									str3=at time ultimatelastframetime cam.target.position.controller.y_position
									str4=at time ultimatelastframetime (cam.target.position.controller.z_position+1.0)
									format "%,%,%,%,%,%,%,%,%,%,\n" (ultimatelastframetime/frameRate) str2 str3 str4 str2 str3 str4 str2 str3 str4 to: f 
								)
								else
								(
									--tpos1 = getKeyTime cam.target.position.controller i
									--str1= (tpos1.frame as float)/frameRate
									tm=cam.target.position.controller.keys[i].time
									str2=at time tm cam.target.position.controller.x_position--value
									str3=at time tm cam.target.position.controller.y_position
									str4=at time tm (cam.target.position.controller.z_position+1.0)
									format "%,%,%,%,%,%,%,%,%,%,\n" (tm/frameRate) str2 str3 str4 str2 str3 str4 str2 str3 str4 to: f
								)
							)
							format ";\n;\n" to: f
							close f
							--------------------------------------------- BLOCK 5: Zero fill for divisibility with number 2048(for proper game reading)
							if fname != undefined do
							(
								f = fopen fname "ab"
								if f == undefined then messageBox "export error"
								else
								(
									fseek f 0 #seek_end
									size = ftell f
									fseek f size #seek_set
									nill = (2048 - (mod size 2048)) as integer
									for i = 1 to nill do writebyte f 0
									fclose f
							   ) -- if f
							)--fname !
							gc()
						) -- fname != undefined
					)-- index > 0
					else messageBox "Not enough keyframes!\nYou need at least 2 keyframes for camera and 2 for camera target!"
				)
				else messageBox "Frame rate(FPS) must be 30!"
			) --cam != undefined
		) --selection.count > 0
	) --end SCamer pressed

	on btn_LCamer pressed do
	(
		ZOffset = -1.0 -- Z coordinate offset(because of GTA problem bug)
		fname = GetOpenFileName types:"gta cutscene data|*.dat|"
		if fname!=undefined then
		(
			f = openFile fname
			if f!=undefined then
			(
				Cam = freecamera()
				Cam.type = #target
				Cam.target.position = [-0.324,0.0,0.0]
				Cam.fovType = 2 --(1 - Horizontal, 2 - Vertical, 3 - Diagonal)
				--Cam.fov.controller = bezier_float()
				select Cam
				--------------------------------------------- BLOCK 1: Camera FOV Value
				while not eof f do
				(
					s = DelComments (readline f) ";"
					if s!= "" then exit
				)
				fs = filterString s "," --Parses string based on " , " and returns an array of strings
				N = fs[1] as integer
				with Animate on
				(
					while not eof f do
					(
						s = DelComments (readline f) ";"
						if s!= "" then
						(
							fs = filterString s "," --Parses string based on " , " and returns an array of strings
							t = execute fs[1]
							t *= 30.0
							at time t Cam.curFOV = fs[2] as float
							N -= 1
						)
						if N == 0 then exit
					)
				)
				--------------------------------------------- BLOCK 2: Camera Roll Angle
				while not eof f do
				(
					s = DelComments (readline f) ";"
					if s!= "" then exit
				)
				fs = filterString s "," --Parses string based on " , " and returns an array of strings
				N = fs[1] as integer + 1 --"+ 1" part is a fix for standard animations
				with Animate on
				(
					while not eof f do
					(
						s = DelComments (readline f) ";"
						if s!= "" then
						(
							fs = filterString s "," --Parses string based on " , " and returns an array of strings
							t = execute fs[1]
							t *= 30.0
							at time t Cam.controller.roll_angle.controller.value = fs[2] as float
							N -= 1
						)
						else exit
						if N == 0 then exit
					)
				)
				--------------------------------------------- BLOCK 3: Camera Position
				while not eof f do
				(
					s = DelComments (readline f) ";"
					if s!= "" then exit
				)
				fs = filterString s "," --Parses string based on " , " and returns an array of strings
				N = fs[1] as integer
				--format "Block 3 = %\n" N
				with Animate on
				(
					while not eof f do
					(
						s = DelComments (readline f) ";"
						if s!= "" then
						(
							fs = filterString s "," --Parses string based on " , " and returns an array of strings
							t = execute fs[1]
							t *= 30.0
							at time t Cam.position.controller.value = [(fs[2] as float), (fs[3] as float), (fs[4] as float) + ZOffset]
							--format "-- % , %\n" t [(fs[2] as float), (fs[3] as float), (fs[4] as float)]
							N -= 1
						)
						if N == 0 then exit
					)
				)
				--------------------------------------------- BLOCK 4: Camera Target Position
				while not eof f do
				(
					s = DelComments (readline f) ";"
					if s!= "" then exit
				)
				fs = filterString s "," --Parses string based on " , " and returns an array of strings
				N = fs[1] as integer
				with Animate on
				(
					while not eof f do
					(
						s = DelComments (readline f) ";"
						if s!= "" then
						(
							fs = filterString s "," --Parses string based on " , " and returns an array of strings
							t = execute fs[1]
							t *= 30.0
							at time t Cam.target.position.controller.value = [(fs[2] as float), (fs[3] as float), (fs[4] as float) + ZOffset]
							animationRange = interval 0 (t + 1)
							N -= 1
						)
						if N == 0 then exit
					)
				)
			)
			else messageBox "Cant open file"
			close f
		)
	)--end LCamer pressed
)--end rollout

try (closeRolloutFloater DAT_Camera) catch ()
DAT_Camera = newRolloutFloater "Camera Export" 190 350 10 90
addRollout MCamera DAT_Camera