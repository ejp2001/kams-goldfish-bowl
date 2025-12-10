-- Created by John A. Martini and Andru Phoenix
	--John A. Martini
		-- JokerMartini@hotmail.com
		-- www.JokerMartini.com
	-- Andru J. Phoenix
		-- AndruServices@gmail.com
		-- www.bigseksi.com

--The Key Transfer Script--
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
(
--//Globals
global roSection1 -- Basic Parameters
global roSection2 -- Key Parameters
global roSection3 -- Advanced Parameters
global roSection4 -- About
global rfKeyTransfer
local floaterHeight
local floaterWidth

--//Locals
local userAnimatedObj = undefined
local userPinObj = undefined 
local userProxObj = undefined
local bufferedObjs = undefined	
local userOrderBy = "selection"
local offsetType = "relative"
local staggerEasing = "linear"	
local previewEnabled = false
local reverseKeys = false
local sortType = "radial"
local linearAxis = "Z"
	
--// Variables
KeysMin = 0
KeysMax = 0
ValueMin = 0
ValueMax = 0
IntensityMin = 1
IntensityMax = 1

obj_collection = #() -- stores preview objects
mtl_collection = #() -- stores original wirecolors

--// Easing Equations	
function easeInOutCubic t b c d = 
(
	-- itemIndex Zero FramesTotal itemCount
	_currentTime = t
	_beginValue = b
	_target = c
	_duration = d
	
	if ((t / (d * 0.5)) < 1) then 
	( 
		t = t / (d * 0.5)
		return (c/2*t*t*t + b) 
	) else 
	(
		t = t / (d * 0.5)
		return (c/2*((t-=2)*t*t + 2) + b)
	)
)

function easeInCubic t b c d = 
(
	t = t/d
	return c*(t)*t*t + b;
)

function easeOutCubic t b c d = 
(
	t = t / d - 1 
	return c*((t)*t*t + 1) + b;
)

function easeInCirc t b c d = 
(
	t = t / d
	return -c * (sqrt (1 - (t)*t) - 1) + b;
)

function easeOutCirc t b c d = 
(
	t = t / d - 1 
	return c * ( sqrt (1 - (t)*t) ) + b;
)

function easeInOutCirc t b c d = 
(	
	if ((t / (d * 0.5)) < 1) then 
	(
		t = t / (d * 0.5)
		return -c/2 * (sqrt (1 - t*t) - 1) + b;
	) else
	(
		t = t / (d * 0.5)
		t = t - 2
		return c/2 * (sqrt (1 - (t)*t) + 1) + b;
	)
)





--// Distance Array Sorters
local distanceHelper	

fn byRadial a b = --// qsort function that compares the distances from the proximity object of two objects (a & b) and returns a positive number if a is further than b
(
	local d = length (a.position - distanceHelper.position) - length(b.position - distanceHelper.position)
	case of
	(
		(d < 0): -1
		(d > 0): 1
		default: 0
	)
)

fn byLinear a b =
(	
	if(linearAxis == "X") then
	(
		aPos = (in coordsys distanceHelper a.pos).x
		bPos = (in coordsys distanceHelper b.pos).x	
	)
	if(linearAxis == "Y") then
	(
		aPos = (in coordsys distanceHelper a.pos).y
		bPos = (in coordsys distanceHelper b.pos).y
	)
	if(linearAxis == "Z") then
	(
		aPos = (in coordsys distanceHelper a.pos).z
		bPos = (in coordsys distanceHelper b.pos).z
	)
	if(aPos < 0) then aPos *= -1
	if(bPos < 0) then bPos *= -1	
	local d = aPos - bPos
	case of
	(
		(d < 0): -1
		(d > 0): 1
		default: 0
	)
)

--// Sorts a selection of objects by distance to an object, seperates the objects into groups based on a distance threshold and returns a multidimensional array populated by said groups
fn radialSort theSet theTarget =
(
	distanceHelper = theTarget -- creates an instance of theTarget. this is due to a sandbox limitation of qsort's complimentary function "byRadial"
	qsort theSet byRadial -- sorts a selection of objects by distance to an object	
	dist_collection = #(#(undefined))
	for i = 1 to theSet.count do --  seperates the objects into array with cached distance for dynamic group sorting
	(
		dist = distance theSet[i].position theTarget.position
		dist_collection[i] = #(theSet[i], dist)
	)	
	return dist_collection
)

fn linearSort theSet theTarget =
(
	distanceHelper = theTarget -- creates an instance of theTarget. this is due to a sandbox limitation of qsort's complimentary function "byRadial"
	qsort theSet byLinear -- sorts a selection of objects by distance to an object
	dist_collection = #(#(undefined))
	for i = 1 to theSet.count do --  seperates the objects into array with cached distance for dynamic group sorting
	(
		if(linearAxis == "X") then dist = (in coordsys theTarget theSet[i].pos).x
		if(linearAxis == "Y") then dist = (in coordsys theTarget theSet[i].pos).y
		if(linearAxis == "Z") then dist = (in coordsys theTarget theSet[i].pos).z	
		if(dist < 0) then dist *= -1		
		dist_collection[i] = #(theSet[i], dist)
	)	
	return dist_collection
)

--// Distance Array Grouper

fn groupByThreshold distanceArray threshold =
(
		groupCursor = 1 --tracks the current group objects are being sorted into
		objIndex = 1 -- tracks the current object being sorted
		distCursor = 0 -- tracks the current distance threshold
		groupArray = #(#(undefined)) -- creates an empty array to file the groups of objects into		
		for i = 1 to distanceArray.count do --  seperates the objects into groups based on a distance threshold 
		(
			dist = distanceArray[i][2]
			distLimit = (distCursor + threshold)			
			if(dist < distLimit ) then -- if distance is less than group tolerance
			(
				groupArray[groupCursor][objIndex] = distanceArray[i][1]		
				objIndex += 1 -- increment object index	
				-- proceed
			) else (
				distCursor = dist
				groupCount = groupArray[groupCursor].count
				if(groupCount >= 1 and groupArray[groupCursor][1] != undefined) then 
				(
					groupCursor += 1 -- increment group index
					objIndex = 1
					groupArray[groupCursor] = #(distanceArray[i][1])
					objIndex = 2 
				) else (
					groupArray[groupCursor][objIndex] = distanceArray[i][1]		
					objIndex += 1 -- increment object index	
				)		
				
			)	
		)	
		return groupArray -- returns a multidimensional array populated by said groups	
)

	
fn cacheWireMaterials userSel =
(
	obj_collection = #() -- stores preview objects
	mtl_collection = #() -- stores original wirecolors		
	if userSel.count !=0 then
	(						
		--// Storing the selected objects materials as arrays
		for o in userSel do 
		(
			try
			(
				m = o.wirecolor
				if m != undefined then
				(
					append obj_collection o
					append mtl_collection m
				)
			)
			catch
			(
			)
		)
		
	)
)

fn restoreWireMaterials =		
(
	--// Restore previous materials
	for i = 1 to obj_collection.count do 
	(
		try
		(
		obj_collection[i].wirecolor = mtl_collection[i]
		)
		catch
		(						
		)
	)
)

fn colorGroups theGroup = 
(
	if theGroup.count !=0 then
	(					
		color_01 = color 0 0 200
		color_02 = color 255 255 255
		stepsizeA_r = (color_02.r - color_01.r)/theGroup.count
		stepsizeA_g = (color_02.g - color_01.g)/theGroup.count
		stepsizeA_b = (color_02.b - color_01.b)/theGroup.count
		
		color_03 = color 0 200 0
		color_04 = color 255 255 255
		stepsizeB_r = (color_04.r - color_03.r)/theGroup.count
		stepsizeB_g = (color_04.g - color_03.g)/theGroup.count
		stepsizeB_b = (color_04.b - color_03.b)/theGroup.count				
		groupCursor = 1
		isOdd = true
		for s in theGroup do
		(
			newColorA = (color ((groupCursor*stepsizeA_r)+ color_01.r-stepsizeA_r) ((groupCursor*stepsizeA_g)+color_01.g-stepsizeA_g) ((groupCursor*stepsizeA_b)+color_01.b-stepsizeA_b))
			newColorB = (color ((groupCursor*stepsizeB_r)+ color_03.r-stepsizeB_r) ((groupCursor*stepsizeB_g)+color_03.g-stepsizeB_g) ((groupCursor*stepsizeB_b)+color_03.b-stepsizeB_b))
			
			for i in s do
			(
				i.wirecolor = newColorB
				if(isOdd) then ( i.wirecolor = newColorA ) else ( i.wirecolor = newColorB)
			)		
			groupCursor += 1
			if(isOdd) then ( isOdd = false ) else ( isOdd = true)
		)
	)
)

fn reverseArray theArray =
(	
	reversedArray = #()	
	for i = 1 to theArray.count do 
	(
		index = (theArray.count +1) - i
		reversedArray[index] = theArray[i]
	)
	return reversedArray
)

--//The Dialog
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--// Basic Parameters
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
rollout roSection1 "Basic Parameters"
(
	group "Animated Object"
	(
	pickButton btn_pickBox "Pick Animated Object" width:160 height:24 tooltip:"Pick Animated Object"
	)
	
	group "Transform Relation"
	(
	radioButtons rdooffsetType "" width:88 height:15 labels:#("Relative", "Absolute") offset:[-35,-2]
	)
	group "Position Axis's"
	(
	checkbox chkxPos "X" across: 3 offset:[0,0]
	checkbox chkyPos "Y" offset:[14,0]
	checkbox chkzPos "Z" offset:[24,0]
	)
	group "Orientation Axis's"
	(
	checkbox chkxRot "X" across: 3 offset:[0,0]
	checkbox chkyRot "Y" offset:[14,0]
	checkbox chkzRot "Z" offset:[24,0]
	)
	group "Scale Axis's"
	(
	checkbox chkxScale "X" across: 3 offset:[0,0]
	checkbox chkyScale "Y" offset:[14,0]
	checkbox chkzScale "Z" offset:[24,0]
	)
	group "Other"
	(
	checkbox chkVisibility "Visibility" offset:[0,0]
	)
	
	button btn_deleteKeys "Delete All Existing Keys" width:170 height:16
	button btn_transferAnimation "Transfer Animation" width:170 height:26 color:red
	
	
	
--// Delete Existing Keys
	on btn_deleteKeys pressed do
	(
	sliderTime = 0f
	userSel = getCurrentSelection ()
	deleteKeys userSel #allKeys
	)
	
--// Changes the Scale Controller from the default "Bezier Scale" to "Scale XYZ"
--// Scale XYZ allows us to transfer scale keys from the individual scale tracks.
	on btn_scaleXYZ pressed do
	for i in selection do
	(
	theController = ScaleXYZ()
	i.scale.controller = theController
	)

--// Replaces the button text with the users selection
	on btn_pickBox picked obj do
	(
		if obj != undefined then
		(
			btn_pickBox.text = obj.name
			userAnimatedObj = obj
			
			if(userProxObj == undefined) then
			(
				roSection3.btn_proxBox.text = obj.name
				userProxObj = obj
			)
		)
	)
	
--// Transform Relation Type
	on rdooffsetType changed stat do
	(
		if(stat == 1) then ( offsetType = "relative"	) else ( offsetType = "absolute" )
	)	

--// Scale Function for XYZ Controller
	fn checkSetXYZ theObject =
	(		
		sCtrl = theObject.scale.controller as string
		if(sCtrl != "Controller:ScaleXYZ") then -- if controller type isn't xyz then assign it
		(	
			theController = ScaleXYZ()
			theObject.scale.controller = theController 
		)
	)
	
--// Transfer Animation Button
	on btn_transferAnimation pressed do
(
	if(userAnimatedObj == undefined) then(			
		MessageBox "Pick an animated object"
		return()
	)
	
	if(userOrderBy == "proximity") then (
		if(userProxObj == undefined) then(			
			MessageBox "Pick a proximity object"
			return()
		)		
	)
	
	modCheck = false
	
	userSel = getCurrentSelection ()
	objectIntensity =for i=1 to userSel.count collect (random roSection2.spnIntensityMin.value roSection2.spnIntensityMax.value )

	--// The action scripts for X-Position
	
	if (chkxPos.state) then 
	(
		if(userAnimatedObj.position.x_position.controller.keys.count >= 1) then
		(
			--userSel = getCurrentSelection ()
			objectIndex = 1
			for s in userSel do
			(
				index = 1
				origin = s.pos.x
				offset = origin - userAnimatedObj.position.x_position.controller.keys[1].value
				for k in userAnimatedObj.position.x_position.controller.keys do
				(
					appendKey s.position.x_position.controller.keys k	
					if(roSection2.chkSkipFirst.state) then (
						if(index != 1) then ( s.position.x_position.controller.keys[index].value *= objectIntensity[objectIndex] )	
					) else (
						s.position.x_position.controller.keys[index].value *= objectIntensity[objectIndex]
					)					
					if(offsetType == "relative") then ( s.position.x_position.controller.keys[index].value += offset )
					index += 1
				)
				moveKeys s (random roSection2.spnKeysMin.value roSection2.spnKeysMax.value)
				objectIndex += 1
			)
			modCheck = true;
		)
	)
--// The action scripts for Y-Position		
	if (chkyPos.state) then 
	(
		if(userAnimatedObj.position.y_position.controller.keys.count >= 1) then
		(
			--userSel = getCurrentSelection ()
			objectIndex = 1
			for s in userSel do
			(
				index = 1
				origin = s.pos.y
				offset = origin - userAnimatedObj.position.y_position.controller.keys[1].value
				for k in userAnimatedObj.position.y_position.controller.keys do
				(
					appendKey s.position.y_position.controller.keys k
					if(roSection2.chkSkipFirst.state) then (
						if(index != 1) then ( s.position.y_position.controller.keys[index].value *= objectIntensity[objectIndex] )	
					) else (
						s.position.y_position.controller.keys[index].value *= objectIntensity[objectIndex]
					)					
					if(offsetType == "relative") then ( s.position.y_position.controller.keys[index].value += offset )
					index += 1
				)
				moveKeys s (random roSection2.spnKeysMin.value roSection2.spnKeysMax.value)
				objectIndex += 1
			)
			modCheck = true;
		)
	)
--// The action scripts for Z-Position	
	
	if (chkzPos.state) then 
	(
		if(userAnimatedObj.position.z_position.controller.keys.count >= 1) then
		(
			--userSel = getCurrentSelection ()
			objectIndex = 1
			for s in userSel do
			(
				index = 1
				origin = s.pos.z
				offset = origin - userAnimatedObj.position.z_position.controller.keys[1].value
				for k in userAnimatedObj.position.z_position.controller.keys do
				(
					appendKey s.position.z_position.controller.keys k					
					if(roSection2.chkSkipFirst.state) then (
						if(index != 1) then ( s.position.z_position.controller.keys[index].value *= objectIntensity[objectIndex] )	
					) else (
						s.position.z_position.controller.keys[index].value *= objectIntensity[objectIndex]
					)
									
					if(offsetType == "relative") then ( s.position.z_position.controller.keys[index].value += offset )
					index += 1
				)
				moveKeys s (random roSection2.spnKeysMin.value roSection2.spnKeysMax.value)
				objectIndex += 1
			)
			modCheck = true;
		)
	)
--// The action scripts for X-Rotation
	if (chkxRot.state) then 
	(
		if(userAnimatedObj.rotation.x_rotation.controller.keys.count >= 1) then
		(
			--userSel = getCurrentSelection ()
			objectIndex = 1
			for s in userSel do
			(
				for k in userAnimatedObj.rotation.x_rotation.controller.keys do
				(
					appendKey s.rotation.x_rotation.controller.keys k
					
				)
				moveKeys s (random roSection2.spnKeysMin.value roSection2.spnKeysMax.value)
				objectIndex += 1
			)
			modCheck = true;
		)
	)
--// The action scripts for Y-Rotation
	if (chkyRot.state) then 
	(
		if(userAnimatedObj.rotation.y_rotation.controller.keys.count >= 1) then
		(
			--userSel = getCurrentSelection ()
			objectIndex = 1
			for s in userSel do
			(
				for k in userAnimatedObj.rotation.y_rotation.controller.keys do
				(
					appendKey s.rotation.y_rotation.controller.keys k
				)
				moveKeys s (random roSection2.spnKeysMin.value roSection2.spnKeysMax.value)
				objectIndex += 1
			)
			modCheck = true;
		)
	)
--// The action scripts for Z-Rotation	
	if (chkzRot.state) then 
	(
		if(userAnimatedObj.rotation.z_rotation.controller.keys.count >= 1) then
		(
			--userSel = getCurrentSelection ()
			objectIndex = 1
			for s in userSel do
			(
				for k in userAnimatedObj.rotation.z_rotation.controller.keys do
				(
					appendKey s.rotation.z_rotation.controller.keys k
				)
				moveKeys s (random roSection2.spnKeysMin.value roSection2.spnKeysMax.value)
				objectIndex += 1
			)
			modCheck = true;
		)
	)
--// The action scripts for X-Scale
	if (chkxScale.state) then 
	(
		checkSetXYZ userAnimatedObj		
		if(userAnimatedObj.scale.y_scale.controller.keys.count >= 1) then
		(		
			--userSel = getCurrentSelection ()
			objectIndex = 1
			for s in userSel do
			(				
				checkSetXYZ s
				for k in userAnimatedObj.scale.x_scale.controller.keys do
				(
					appendKey s.scale.x_scale.controller.keys k
				)
				moveKeys s (random roSection2.spnKeysMin.value roSection2.spnKeysMax.value)
				objectIndex += 1
			)
			modCheck = true;
		)
			
	)
--// The action scripts for Y-Scale
	if (chkyScale.state) then 
	(
		checkSetXYZ userAnimatedObj		
		if(userAnimatedObj.scale.y_scale.controller.keys.count >= 1) then
		(
			--userSel = getCurrentSelection ()
			objectIndex = 1
			for s in userSel do
			(
				checkSetXYZ s
				for k in userAnimatedObj.scale.y_scale.controller.keys do
				(
					appendKey s.scale.y_scale.controller.keys k
				)
				moveKeys s (random roSection2.spnKeysMin.value roSection2.spnKeysMax.value)
				objectIndex += 1
			)
			modCheck = true;
		)
	)
--// The action scripts for Z-Scale
	if (chkzScale.state) then 
	(
		checkSetXYZ userAnimatedObj
		if(userAnimatedObj.scale.z_scale.controller.keys.count >= 1) then
		(
			--userSel = getCurrentSelection ()
			objectIndex = 1
			for s in userSel do
			(
				checkSetXYZ s
				for k in userAnimatedObj.scale.z_scale.controller.keys do
				(
					appendKey s.scale.z_scale.controller.keys k
				)
				moveKeys s (random roSection2.spnKeysMin.value roSection2.spnKeysMax.value)
				objectIndex += 1
			)
			modCheck = true;
		)
	)	
	
	if (chkVisibility.state) then 
	(
		if(userAnimatedObj.visibility.controller.keys .count >= 1) then
		(
			--userSel = getCurrentSelection ()
			for s in userSel do
			(					
				sCtrl = userAnimatedObj.visibility.controller as string
				case of
				(
					(sCtrl == "Controller:Bezier_Float"): (s.Visibility = bezier_float (); s.Visibility.controller = bezier_float ())
					(sCtrl == "Controller:Linear_Float"): (s.Visibility  = linear_float (); s.Visibility.controller = linear_float ())
				)			
				--s.visibility.controller.value = 1.0
				for k in userAnimatedObj.visibility.controller.keys do
				(
					appendKey s.visibility.controller.keys k
				)
				moveKeys s (random roSection2.spnKeysMin.value roSection2.spnKeysMax.value)
			)
			modCheck = true;
		)
	)	
	
	if(modCheck == true) then(
		staggerIndex = 0
		userSel = getCurrentSelection ()
		if(reverseKeys) then ( userSel = reverseArray userSel )
		if(userOrderBy == "selection") then(
			for s in userSel do
			(
				if (staggerEasing == "linear") then ( targetOffset = (staggerIndex * roSection3.spnStagger.value) + roSection3.spnStagger.value )
				if (staggerEasing == "cubicIn") then ( targetOffset = easeInCubic staggerIndex 0.0 roSection3.spnDuration.value (userSel.count + 0.0) )
				if (staggerEasing == "cubicOut") then ( targetOffset = easeOutCubic staggerIndex 0.0 roSection3.spnDuration.value (userSel.count + 0.0) )
				if (staggerEasing == "cubicInOut") then ( targetOffset = easeInOutCubic staggerIndex 0.0 roSection3.spnDuration.value (userSel.count + 0.0) )
				if (staggerEasing == "circIn") then ( targetOffset = easeInCirc staggerIndex 0.0 roSection3.spnDuration.value (userSel.count + 0.0) )
				if (staggerEasing == "circOut") then ( targetOffset = easeOutCirc staggerIndex 0.0 roSection3.spnDuration.value (userSel.count + 0.0) )
				if (staggerEasing == "circInOut") then ( targetOffset = easeInOutCirc staggerIndex 0.0 roSection3.spnDuration.value (userSel.count + 0.0) )
				moveKeys s (targetOffset)
				staggerIndex += 1
			)
		)
		if(userOrderBy == "proximity") then (
			
			bufferedObjs = case sortType of
			(
				"radial":	radialSort userSel userProxObj
				"linear":	linearSort userSel userProxObj
				default: radialSort userSel userProxObj
			)
			
			userSelGroups = groupByThreshold bufferedObjs roSection3.spnGroupTolerance.value
			if(reverseKeys) then ( userSelGroups = reverseArray userSelGroups )			
			--userSelGroups = proximitySort userSel userProxObj roSection3.spnGroupTolerance.value			
			
			groupCursor = 1
			for s in userSelGroups do
			(
				for i in s do
				(
					if (staggerEasing == "linear") then ( targetOffset = (groupCursor * roSection3.spnStagger.value) )					
					if (staggerEasing == "cubicIn") then ( targetOffset = easeInCubic groupCursor 0.0 roSection3.spnDuration.value (userSelGroups.count + 0.0) )
					if (staggerEasing == "cubicOut") then ( targetOffset = easeOutCubic groupCursor 0.0 roSection3.spnDuration.value (userSelGroups.count + 0.0) )
					if (staggerEasing == "cubicInOut") then ( targetOffset = easeInOutCubic groupCursor 0.0 roSection3.spnDuration.value (userSelGroups.count + 0.0) )
					if (staggerEasing == "circIn") then ( targetOffset = easeInCirc groupCursor 0.0 roSection3.spnDuration.value (userSelGroups.count + 0.0) )
					if (staggerEasing == "circOut") then ( targetOffset = easeOutCirc groupCursor 0.0 roSection3.spnDuration.value (userSelGroups.count + 0.0) )
					if (staggerEasing == "circInOut") then ( targetOffset = easeInOutCirc groupCursor 0.0 roSection3.spnDuration.value (userSelGroups.count + 0.0) )
					moveKeys i (targetOffset)						
				)		
				groupCursor += 1
			)
		)
	)
	)	

	on roSection1 rolledUp state do
	(
	if (state) then
	rfKeyTransfer.size.y += roSection1.height
	else
	rfKeyTransfer.size.y -= roSection1.height
	)
	
)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--//Key Parameters
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
rollout roSection2 "Key Parameters"
(
	group "Key Offset Variation"
	(
	label lbOffsetMin "Min:" width:20 height:16 across: 4 offset:[-11,0] 
	spinner spnKeysMin "" width:50 height:16 range:[-9999,9999,KeysMin] offset:[-21,0] tooltip:"Is the value used for the minimum offset of the keys in the timeline."
	label lbOffsetMax "Max:" width:22 height:16 offset:[-3,0]
	spinner spnKeysMax "" width:50 height:16 range:[-9999,9999,KeysMax] offset:[-10,0] tooltip:"Is the value used for the maximum offset of the keys in the timeline."
	)
	
 	group "Key Position Variation"
	(
	label lbIntensity "Pos. Intensity:" width:100 height:16 across: 2 offset:[8,0] 
	checkbox chkSkipFirst "Skip 1st Key" offset:[0,0] checked: true
	label lbIntensityMin "Min:" width:20 height:16 across: 4 offset:[-11,0] 
	spinner spnIntensityMin "" width:50 height:16 range:[-9999,9999,IntensityMin] offset:[-21,0] tooltip:"Is the value used for the minimum offset of the keys in the timeline."
	label lbIntensityMax "Max:" width:22 height:16 offset:[-3,0]
	spinner spnIntensityMax "" width:50 height:16 range:[-9999,9999,IntensityMax] offset:[-10,0] tooltip:"Is the value used for the maximum offset of the keys in the timeline."	
	) 

	on chkSkipFirst changed theState do
	(
		if(theState == false) then ( MessageBox "WARNING: By unchecking this option your objects will be irreversibly displaced in result of randomization.\nIt is recommended that you save a copy of your scene before you transfer keys! Just sayin'." )
	)
	
	on roSection2 rolledUp state do
	(
	if (state) then
	rfKeyTransfer.size.y += roSection2.height
	else
	rfKeyTransfer.size.y -= roSection2.height
	)
)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--//Advanced Parameters
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
rollout roSection3 "Advanced Parameters"
(

	group "Key Stagger"
	(
	label lbstaggerOffset "Delay:" width:40 height:16 across: 2 offset:[-20,0]
	spinner spnStagger "" width:50 height:16 range:[-9999,9999,0] offset:[0,0] 
	label lbDuration "Total Duration:" width:100 height:16 across: 2 offset:[10,0] enabled: false
	spinner spnDuration "" width:50 height:16 range:[0,9999,50] offset:[0,0] enabled: false 
	dropDownList dlEasingType "Offset Type:" width:122 height:40 items:#("Fixed", "Cubic In", "Cubic Out", "Cubic In/Out", "Circ In", "Circ Out", "Circ In/Out") offset:[-1,-5]
	radioButtons rdostaggerType "Order by:" width:88 height:46 labels:#("Selection", "Proximity to") offset:[-35,-2]
	pickButton btn_proxBox "Pick Object" width:160 height:24 tooltip:"Pick Proximity Object" enabled:false offset:[0,-15]
	radioButtons rdoSortType "" width:80 height:50 labels:#("Radial", "Linear") columns:2 across:2 offset:[11,3] enabled: false
	dropDownList dlLinearAxis "" width:60 height:40 items:#("X Axis", "Y Axis", "Z Axis") selection:3 offset:[23,0] enabled: false
	label lbGroupTolerance "Group If Between :" width:100 height:16 across: 2 offset:[7,-30] enabled: false
	spinner spnGroupTolerance "" width:50 height:16 range:[0,9999,50] offset:[0,-30]  enabled: false
	checkbutton ckbtnPreview "Preview Groups" width:160 height:24 enabled:false
	checkbox chkReverse "Reverse Order" offset:[0,0] checked: false
		
	)

	on spnGroupTolerance buttonDown do
	(
		
	)

	on spnGroupTolerance buttonup do
	(
		
	)
	
	on spnGroupTolerance changed val do
	(
		if(previewEnabled) then
		(		
			userSelGroups = groupByThreshold bufferedObjs roSection3.spnGroupTolerance.value
			if(reverseKeys) then ( userSelGroups = reverseArray userSelGroups)
			ckbtnPreview.caption = ((userSelGroups.count as string) +  " Groups")	
			colorGroups userSelGroups
		)
	)
	
	on ckbtnPreview changed st do 
	(
		if(userProxObj == undefined) then( --// If there isn't a proximity object	
			MessageBox "Pick a proximity object"
			ckbtnPreview.state = false
			return()
		) else 
		(	--// If there is a proximity object
			if st ==true then --// Button state checked TRUE
			(					
				previewEnabled = true
				userSel = getCurrentSelection ()				
				cacheWireMaterials userSel
				
				if userSel.count !=0 then
				(					
					bufferedObjs = case sortType of
					(
						"radial":	radialSort userSel userProxObj
						"linear":	linearSort userSel userProxObj
						default: radialSort userSel userProxObj
					)
					userSelGroups = groupByThreshold bufferedObjs roSection3.spnGroupTolerance.value
					if(reverseKeys) then ( userSelGroups = reverseArray userSelGroups)
					colorGroups userSelGroups
					ckbtnPreview.caption = ((userSelGroups.count as string) +  " Groups")	
				)
			)
			else --// Button state checked FALSE
			(
				previewEnabled = false
				restoreWireMaterials()
				ckbtnPreview.caption = "Preview Groups"
			)
		)
	)		
	
	
	
	on chkReverse changed theState do
	(
		if(theState) then 
		(  
			reverseKeys = true
			
			if(previewEnabled) then
			(		
				userSelGroups = groupByThreshold bufferedObjs roSection3.spnGroupTolerance.value
				userSelGroups = reverseArray userSelGroups
				colorGroups userSelGroups
			)				
			
		) else (
			reverseKeys = false			
			if(previewEnabled) then
			(				
				userSelGroups = groupByThreshold bufferedObjs roSection3.spnGroupTolerance.value
				colorGroups userSelGroups
			)
		)
		
	)
	
	
	--// Replaces the button text with the users selection
	on btn_proxBox picked obj do
	(
		if obj != undefined then
		(
			btn_proxBox.text = obj.name
			userProxObj = obj
			
			if(previewEnabled) then
			(		
				userSel = getCurrentSelection ()
				if userSel.count !=0 then
				(					
					restoreWireMaterials()
					userSel = getCurrentSelection ()				
					cacheWireMaterials userSel
					bufferedObjs = case sortType of
					(
						"radial":	radialSort userSel userProxObj
						"linear":	linearSort userSel userProxObj
						default: radialSort userSel userProxObj
					)
					userSelGroups = groupByThreshold bufferedObjs roSection3.spnGroupTolerance.value
					if(reverseKeys) then ( userSelGroups = reverseArray userSelGroups)
					colorGroups userSelGroups
					ckbtnPreview.caption = ((userSelGroups.count as string) +  " Groups")	
				)
			)
			
		)
	)
	
	on rdostaggerType changed stat do
	(
		if(stat == 1) then (
			btn_proxBox.enabled = lbGroupTolerance.enabled = spnGroupTolerance.enabled = ckbtnPreview.enabled = rdoSortType.enabled = false 
			if(sortType == "linear") then dlLinearAxis.enabled = false 
			userOrderBy = "selection"
		)
		if(stat == 2) then (
			btn_proxBox.enabled = lbGroupTolerance.enabled = spnGroupTolerance.enabled = ckbtnPreview.enabled = rdoSortType.enabled = true
			if(sortType == "linear") then dlLinearAxis.enabled = true 
			userOrderBy = "proximity"
		)
		--print rdostaggerType.state
	)
	
	on rdoSortType changed stat do
	(
		if(stat == 1) then (
			dlLinearAxis.enabled = false 
			sortType = "radial"
		)
		if(stat == 2) then (
			dlLinearAxis.enabled = true 
			sortType = "linear"
		)
		if(previewEnabled) then
		(		
			userSel = getCurrentSelection ()
			if userSel.count !=0 then
			(					
				restoreWireMaterials()
				userSel = getCurrentSelection ()				
				cacheWireMaterials userSel
				bufferedObjs = case sortType of
				(
					"radial":	radialSort userSel userProxObj
					"linear":	linearSort userSel userProxObj
					default: radialSort userSel userProxObj
				)
				userSelGroups = groupByThreshold bufferedObjs roSection3.spnGroupTolerance.value
				if(reverseKeys) then ( userSelGroups = reverseArray userSelGroups)
				colorGroups userSelGroups
				ckbtnPreview.caption = ((userSelGroups.count as string) +  " Groups")	
			)
		)
		--print rdostaggerType.state
	)

	on dlLinearAxis selected sel do
	(
		if(sel == 1) then (
			linearAxis = "X"
		)
		if(sel == 2) then (
			linearAxis = "Y"
		)
		if(sel == 3) then (
			linearAxis = "Z"
		)
		if(previewEnabled) then
		(		
			userSel = getCurrentSelection ()
			if userSel.count !=0 then
			(					
				restoreWireMaterials()
				userSel = getCurrentSelection ()				
				cacheWireMaterials userSel
				bufferedObjs = case sortType of
				(
					"radial":	radialSort userSel userProxObj
					"linear":	linearSort userSel userProxObj
					default: radialSort userSel userProxObj
				)
				userSelGroups = groupByThreshold bufferedObjs roSection3.spnGroupTolerance.value
				if(reverseKeys) then ( userSelGroups = reverseArray userSelGroups)
				colorGroups userSelGroups
				ckbtnPreview.caption = ((userSelGroups.count as string) +  " Groups")	
			)
		)
	)		
	
	on dlEasingType selected sel do
	(
		if(sel == 1) then (
			lbstaggerOffset.enabled = spnStagger.enabled = true 
			lbDuration.enabled = spnDuration.enabled = false
			staggerEasing = "linear"
		)
		if(sel == 2) then (
			lbstaggerOffset.enabled = spnStagger.enabled = false 
			lbDuration.enabled = spnDuration.enabled = true
			staggerEasing = "cubicIn"
		)
		if(sel == 3) then (
			lbstaggerOffset.enabled = spnStagger.enabled = false 
			lbDuration.enabled = spnDuration.enabled = true
			staggerEasing = "cubicOut"
		)		
		if(sel == 4) then (
			lbstaggerOffset.enabled = spnStagger.enabled = false 
			lbDuration.enabled = spnDuration.enabled = true
			staggerEasing = "cubicInOut"
		)
		if(sel == 5) then (
			lbstaggerOffset.enabled = spnStagger.enabled = false 
			lbDuration.enabled = spnDuration.enabled = true
			staggerEasing = "circIn"
		)
		if(sel == 6) then (
			lbstaggerOffset.enabled = spnStagger.enabled = false 
			lbDuration.enabled = spnDuration.enabled = true
			staggerEasing = "circOut"
		)
		if(sel == 7) then (
			lbstaggerOffset.enabled = spnStagger.enabled = false 
			lbDuration.enabled = spnDuration.enabled = true
			staggerEasing = "circInOut"
		)
		--print rdostaggerType.state



	)
	on roSection3 rolledUp state do
	(
	if (state) then
	rfKeyTransfer.size.y += roSection3.height
	else
	rfKeyTransfer.size.y -= roSection3.height
	)
)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--//About
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
rollout roSection4 "About"
(
	
	button btn_instructions "Instructions" width:83 height:16 across: 2 offset:[-6,0]
	button btn_credits "Credits" width:83 height:16 across: 2 offset:[6,0]
	
	--// Instructions
	on btn_instructions pressed do
	(
		rollout rlInstructions "Instructions"
		(
		Label Label0 "- Key Transfer -" align:#center offset:[0,14]
		Label Label1 "1. Pick animated reference object." align:#left offset:[14,14]
		Label Label2 "2. Set desired varions." align:#left offset:[14,0]
		Label Label3 "3. Select objects you wish to animate." align:#left offset:[14,0]
		Label Label4 "4. Choose axis's to transfer to." align:#left offset:[14,0]
		Label Label5 "5. Click Transfer Animation button." align:#left offset:[14,0]
		)
		createDialog rlInstructions 250 180	
	)
	
--// Credits
	on btn_credits pressed do
	(
		rollout rlCredits "Credits"
		(
		HyperLink KeyTransferSite "- Key Transfer -"  address:"http://www.scriptspot.com/3ds-max/scripts/key-transfer" color:black hovercolor:blue visitedcolor:black align:#center offset:[0,14]
		Label LabelVersion "Version 1.06 - 2010" align:#center
		Label LabelAuthor "Created by John A. Martini" align:#center offset:[0,14]
		HyperLink website "http://www.JokerMartini.com"  address:"http://www.JokerMartini.com" color:black hovercolor:blue visitedcolor:black align:#center
		Label LabelAuthor2 "and Andru J. Phoenix" align:#center offset:[0,14]
		HyperLink website2 "http://www.bigseksi.com"  address:"http://www.bigseksi.com" color:black hovercolor:blue visitedcolor:black align:#center		
		)
		createDialog rlCredits 250 180		
	)
	
	on roSection4 rolledUp state do
	(
	if (state) then
	rfKeyTransfer.size.y += roSection4.height
	else
	rfKeyTransfer.size.y -= roSection4.height
	)
)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
if (rfKeyTransfer != undefined) then CloseRolloutFloater rfKeyTransfer
floaterWidth = 194
floaterHeight = 850
rfKeyTransfer = newRolloutFloater "Key Transfer v1.06" floaterWidth floaterHeight 1200 300 

addRollout roSection3 rfKeyTransfer
addRollout roSection2 rfKeyTransfer
addRollout roSection1 rfKeyTransfer
addRollout roSection4 rfKeyTransfer

roSection1.open = true
roSection2.open = false
roSection3.open = false
roSection4.open = false
)
