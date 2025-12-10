fn no_comments str = 
(
 local n
 local s
 n = findString str "#"
 if n != undefined then 
    if n>1 then 
	   s = subString str 1 (n-1)
	else s = ""
 else s = str
 s = trimLeft (trimRight s)
) -- end no_comments

--------------------------------------------------------------------

rollout occl_rol "occlu io" width:100 height:100
(
	button imp "import" pos:[11,7] width:68 height:18
	button exp "export" pos:[11,34] width:68 height:18
	
on imp pressed do (

    fname = getOpenFileName caption:"select ipl" \
            types:"gta ipl file|*.ipl|all format|*.*|"
    if fname != undefined do (
	 f = openFile fname
	 
	er_code = 0
	
    do         -- file pos to cull
     if not eof f then (
       s = readLine f
       s = no_comments s
       if s == "occl" do exit
     )
        else ( er_code = 1 
	       exit )
    while true


    if er_code == 0 then (
	  n = 0
      do
	   if not eof f then (
	    s = readLine f
        s = no_comments s
		if trimLeft(trimRight s) == "end" do exit
		fs = filterstring s ","
		if fs.count>6  do (
		                    n +=1
							b = box ()
							b.name = "occlu" + (n as string)
							b.position = [fs[1] as float, fs[2] as float, fs[3] as float]
							b.width = (fs[4] as float)
							b.length = (fs[5] as float)
							b.height = (fs[6] as float)
							b.rotation.z_rotation = fs[7] as float
		                  )
	   )
	    else (er_code = 2 
		      exit)
	  while true

	)
	else format "occl not found\n"
	
	) -- fname
) -- on imp do

on exp pressed do (
  s = selection
  if s.count>0 then (
   er_code = 0
   clearListener ()
   
   for o in s do (
    rotz = o.rotation.z_rotation
	o.rotation.z_rotation = 0
	rotx = o.rotation.z_rotation
	o.rotation.x_rotation = 0
	roty = o.rotation.z_rotation
	o.rotation.y_rotation = 0
	gab = o.max - o.min
	format "%, %, %, %, %, %, %, 0.0, 0.0, 0\n" \
	        o.position[1] o.position[2] o.position[3]\
			o.width o.length o.height rotz
    o.rotation.z_rotation = rotz
    o.rotation.x_rotation = rotx
    o.rotation.y_rotation = roty	
   )
  )
  else format "no occlu selected\n"
) -- on exp preesed

) -- occclu rollout

try (closeRolloutFloater occl_flo) catch () 
occl_flo = newRolloutFloater "" 100 90 20 130 
addRollout occl_rol occl_flo