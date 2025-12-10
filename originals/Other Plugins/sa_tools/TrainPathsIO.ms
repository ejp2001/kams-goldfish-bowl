rollout train_rol "train paths io" width:128 height:127
(
	button imp "IMPORT" pos:[12,8] width:100 height:27 toolTip:"import train path"
	button expt "EXPORT" pos:[12,46] width:100 height:27 toolTip:"export selected path only"
	button stan "SET STATION" pos:[13,85] width:100 height:27 \
	                          toolTip:"sets train station at path vertex selection"

---------------------------------------------------------------------------------------------

on imp pressed do (
fname = getOpenFileName caption:"select dat"  types:"train path (*.dat)|*.dat|"

if fname != undefined do (
 f = openFile fname
 
 s = readline f
 
 if execute s > 0 do (
  ss = SplineShape pos:[0, 0, 0]
  addNewSpline ss
  stops = "0"
  
  while not eof f do (
   s = readline f
   fs = filterString s ", "
   if fs.count > 0 do ( 
    n = addKnot ss 1 #corner #line [fs[1] as float, fs[2] as float, fs[3] as float]
	if fs[4] == "1" do (
	 p = point pos:[fs[1] as float, fs[2] as float, fs[3] as float] \
	           size:20 box:true centerMarker:true
	 p.wireColor = [255, 0, 0]
	 p.parent = ss
	 p.name = "train_station"
	)
   )
  )
  updateShape ss
  setUserPropBuffer ss stops
 )
 close f
)
) -- on imp

---------------------------------------------------------------------------------------------

on expt pressed do (
 s = selection[1]
 if s != undefined then 
  if (isKindOf s line) or (isKindOf s SplineShape) then (
  fname = getSaveFileName caption:"save train path to..." \
                          types:"train path (*.dat)|*.dat|"
  if fname != undefined do (
   f = createFile fname
   n = numKnots s
   ch = s.children
   -- clearListener ()
   format "%\n" n to:f
   
   for i = 1 to n do (
     p = getKnotPoint s 1 i
     format "% % % " (p.x as string) (p.y as string) (p.z as string) to:f
	 isStation = 0
	 if ch.count>0 do (
	  i = 1 
	  while i<=ch.count do (
	   r = distance ch[i].position p
	   if r<0.5 do (
	    isStation = 1
		exit
	   )
	  i += 1
	  )
	 )
	 format "%\n" isStation to:f
   )	--- for i
   
  close f
  ) -- if fname != undefined					   
  )
  else messagebox "selected must be SplineShape or Line"
 else messageBox "no path selected" 
)

---------------------------------------------------------------------------------------------

on stan pressed do (
s = selection[1]
 if s != undefined then 
  if (isKindOf s line) or (isKindOf s SplineShape) then
   if subObjectLevel == 1 then (
    n = getKnotSelection s 1
	if n.count>0 then 
	 for i = 1 to n.count do (
	  r = getKnotPoint s 1 n[i]
	  p = point pos:r size:20 box:true centerMarker:true
	  p.wireColor = [255, 0, 0]
	  p.parent = s
	  p.name = "train_station"
	 )
	else messagebox "no vertex selected"
   )
   else messagebox "subObjectLevel must be vertex"
  else messagebox "selected must be SplineShape or Line"
 else messageBox "no path selected" 
)

) -- rollout

---------------------------------------------------------------------------------------------
try (closeRolloutFloater train_flo) catch () 
train_flo = newRolloutFloater "TRAIN PATHS IO" 140 150 20 130 
addRollout  train_rol train_flo