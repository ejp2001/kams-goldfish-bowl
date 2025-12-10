---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------


plugin simpleObject sa_cull
name:"sa_cull"
classID:#(14534555,54321155)
category:"Standart"
( 

parameters main rollout:params
(
height type:#worldUnits ui:height default:5
width type:#worldUnits ui:width default:5
length type:#float ui:length default:5
par4 type:#worldUnits ui:par4 default:0
par8 type:#worldUnits ui:par8 default:0
chk1 type:#boolean ui:chk1 default:false
chk2 type:#boolean ui:chk2 default:false
chk3 type:#boolean ui:chk3 default:false
chk4 type:#boolean ui:chk4 default:false
chk5 type:#boolean ui:chk5 default:false
chk6 type:#boolean ui:chk6 default:false
chk7 type:#boolean ui:chk7 default:false
chk8 type:#boolean ui:chk8 default:false
chk9 type:#boolean ui:chk9 default:false
chk10 type:#boolean ui:chk10 default:false
chk11 type:#boolean ui:chk11 default:false
chk12 type:#boolean ui:chk12 default:false
chk13 type:#boolean ui:chk13 default:false
chk14 type:#boolean ui:chk14 default:false
mir_dir type:#integer ui:mir_dir default:1
unk11 type:#integer ui:unk11 default:0
)

rollout params "cull param"
(   
    local kl , kw
	
	spinner width "Width" pos:[37,7] width:89 height:16 range:[-1000,1000,5] type:#worldunits
	spinner length "length" pos:[36,28] width:89 height:16 range:[-1000,1000,5] type:#float
	spinner height "Height" pos:[36,49] width:89 height:16 range:[-1000,1000,5] type:#worldunits
	spinner par4 "par4" pos:[36,70] width:68 height:16 range:[-1000,1000,0] type:#worldunits
	spinner par8 "par8" pos:[36,90] width:68 height:16 range:[-1000,1000,0] type:#worldunits
	checkbox chk1 "mirror" pos:[7,115] width:65 height:15 checked:false
	checkbox chk2 "screen" pos:[7,135] width:65 height:15 checked:false enabled:false
	checkbox chk3 "4" pos:[7,155] width:65 height:15 checked:false
	checkbox chk4 "no weath" pos:[7,175] width:65 height:15 checked:false
	checkbox chk5 "16" pos:[6,195] width:65 height:15 checked:false
	checkbox chk6 "32" pos:[7,215] width:65 height:15 checked:false
	checkbox chk7 "64" pos:[7,235] width:65 height:15 checked:false
	checkbox chk8 "128" pos:[96,116] width:56 height:15 checked:false
	checkbox chk9 "256" pos:[96,136] width:56 height:15 checked:false
	checkbox chk10 "512" pos:[96,156] width:56 height:15 checked:false
	checkbox chk11 "1024" pos:[96,176] width:56 height:15 checked:false
	checkbox chk12 "2048" pos:[96,196] width:56 height:15 checked:false
	checkbox chk13 "police" pos:[96,216] width:56 height:15 checked:false
	checkbox chk14 "8192" pos:[96,236] width:56 height:15 checked:false
	checkbox locky "" pos:[115,72] width:16 height:15 checked:false
	checkbox lockx "" pos:[115,90] width:16 height:15 checked:false
	dropDownList mir_dir "" pos:[79,300] width:77 height:21 items:#("north","south","west","east","top","floor")
	label lbl1 "mirror direction" pos:[3,300] width:71 height:22
	spinner unk11 "unknown" pos:[10,267] width:140 height:16 range:[0,10000000000,0] type:#integer
	
	
	on chk1 changed theState do 
           if theState then  
		               ( --mir_dir.enabled  = true
					     par4.value = 0.0
						 --par4.enabled = false
						 par8.value = 0.0
						 --par8.enabled = false
						 --unk11.enabled = false
					   )
		               else  
					   ( --mir_dir.enabled  = false
						 --par4.enabled = true
						 --par8.enabled = true
                         --unk11.enabled = true					   
					   )

	
	on locky changed theState do kl = par4.value/length.value
	

	on lockx changed theState do kw = par8.value/width.value

		   
	on width changed val do 
	 if lockx.checked then par8.value = width.value*kw
	 
	on length changed val do 
	 if locky.checked then par4.value = length.value*kl 

)

on buildMesh do
(
local x0, x1, x2, x3, y0, y1, y2, y3, k4, k8, k48, d1, d2
if (abs length)>0.0001 then k4 = par4/length
                       else k4 = 0
if (abs width)>0.0001  then k8 = par8/width
                       else k8=0
k48 = k4*k8

x0 = - width - par4
y0 = - length - par8

d1 = 2*length*(1 + k4*k4)

y1 = y0 + d1/(1 - k48)
x1 = x0 - k8*(y1 - y0)

d2 = 2*width*(1 + k8*k8)

x2 = x0 + d2/(1 - k48)
y2 = y0 - k4*(x2 - x0)

y3 = (y1 + k4*(x1 - x2) - k48*y2) / (1 - k48)
x3 = x2 - k8*(y3 - y2)

setMesh mesh \
verts:#([x0,y0,0],[x1,y1,0],[x2,y2,0],[x3,y3,0], \
        [x0,y0,0],[x1,y1,0],[x2,y2,0],[x3,y3,0]) \
faces:#([1,3,2], [2,3,4], [5,6,7], [7,6,8])

extrudeFace mesh #(1,2) height 100 dir:#common
)

tool create
(
on mousePoint click do
case click of
(
1: nodeTM.translation = gridPoint
3: #stop
)
on mouseMove click do
case click of
(
2: (width = gridDist.x; length = gridDist.y)
3: height = gridDist.z
)
)
)


---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

--------------------------- CULL IO

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

-----------------------------------------------------------------------------------

rollout cull_rol "CULL" width:182 height:150
(
	button imp "IMPORT" pos:[100,24] width:60 height:27				 
	button exp "EXPORT" pos:[24,24] width:60 height:27
	button conv "BOX TO CULL" pos:[30,64] width:120 height:27
	button creat "CREATE" pos:[60,96] width:60 height:27
  
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
       if s == "cull" do exit
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
		if fs.count>10 do 
		 (
		  p = #()
		  for i = 1 to 9 do p[i] = fs[i] as float
		  p[10] = fs[10] as integer
		  p[11] = fs[11] as integer
		  if fs.count>11 then 
		   (
		    p[12] = fs[12] as integer
		    p[13] = fs[13] as integer
            p[14] = fs[14] as float		    
		   )

mm = sa_cull height:(p[9]-p[6]) par4:p[4] par8:p[8]
mm.width = p[7]
mm.length = p[5]
mm.position = [p[1], p[2], p[6]]
mm.xray = true
	 if (bit.and p[10] 1) > 0 do mm.chk1 = true
	 if (bit.and p[10] 2) > 0 do mm.chk2 = true
	 if (bit.and p[10] 4) > 0 do mm.chk3 = true
	 if (bit.and p[10] 8) > 0 do mm.chk4 = true
	 if (bit.and p[10] 16) > 0 do mm.chk5 = true
	 if (bit.and p[10] 32) > 0 do mm.chk6 = true
	 if (bit.and p[10] 64) > 0 do mm.chk7 = true
	 if (bit.and p[10] 128) > 0 do mm.chk8 = true
	 if (bit.and p[10] 256) > 0 do mm.chk9 = true
	 if (bit.and p[10] 512) > 0 do mm.chk10 = true
	 if (bit.and p[10] 1024) > 0 do mm.chk11 = true
	 if (bit.and p[10] 2048) > 0 do mm.chk12 = true
	 if (bit.and p[10] 4096) > 0 do mm.chk13 = true
	 if (bit.and p[10] 8192) > 0 do mm.chk14 = true
if mm.chk1 then (
 if (p[11]==0) and (p[12]==-1) and (p[13]==0) do mm.mir_dir = 1
 if (p[11]==0) and (p[12]==1) and (p[13]==0) do mm.mir_dir = 2
 if (p[11]==1) and (p[12]==0) and (p[13]==0) do mm.mir_dir = 3
 if (p[11]==-1) and (p[12]==0) and (p[13]==0) do mm.mir_dir = 4
 if (p[11]==0) and (p[12]==0) and (p[13]==-1) do mm.mir_dir = 5
 if (p[11]==0) and (p[12]==0) and (p[13]==1) do mm.mir_dir = 6
) -- if mirror
else mm.unk11 = p[11]
setuserpropbuffer mm fs[7]	 
          
		  ) -- if fs.count>10
		
	   )
	    else (er_code = 2 
		      exit)
	  while true
    ) -- if er_code / find cull
    else  format "\"cull\" line no fount\n"
	
	close f
	) -- if fname
  )

-----------------------------------------------------------------------------------
on exp pressed do (
  s = $selection
  if s.count>0 then (
   clearListener ()
   
   for o in s do 
    if (classOf o) == sa_cull do 
	( 
	 eff = 0
	 if o.chk2 do eff += 2
	 if o.chk3 do eff += 4
	 if o.chk4 do eff += 8
	 if o.chk5 do eff += 16
	 if o.chk6 do eff += 32
	 if o.chk7 do eff += 64
	 if o.chk8 do eff += 128
	 if o.chk9 do eff += 256
	 if o.chk10 do eff += 512
	 if o.chk11 do eff += 1024
	 if o.chk12 do eff += 2048
	 if o.chk13 do eff += 4096
	 if o.chk14 do eff += 8192
	 
	 if o.chk1 then (
	   eff += 1
	   format "%, %, %, 0, %, %, %, 0, %, %, " \
	         o.position[1] o.position[2] o.position[3] \
			 (o.length) (o.min.z) (o.width) (o.max.z) eff
	   if o.mir_dir == 1 then format "0, -1, 0, %\n" -o.max.y
	   if o.mir_dir == 2 then format "0, 1, 0, %\n" o.min.y
	   if o.mir_dir == 3 then format "1, 0, 0, %\n" o.min.x
	   if o.mir_dir == 4 then format "-1, 0, 0, %\n" -o.max.x
	   if o.mir_dir == 5 then format "0, 0, -1, %\n" -o.max.z
	   if o.mir_dir == 6 then format "0, 0, 1, %\n" o.min.z
     ) --- if mirror
	 else 
	  (
	   format "%, %, %, %, %, %, %, %, %, %, %\n" \
	         o.position[1] o.position[2] o.position[3]\
			(o.par4) (o.length) (o.min.z) (o.width) \
			(o.par8) (o.max.z) eff (o.unk11)
	  ) -- if not mirror
	 )  -- if is cull
  )
  else format "no objects selected\n"
   
) -- on exp 

-----------------------------------------------------------------------------------

on creat pressed do (
   cu = sa_cull ()
   cu.xray = true
)


on conv pressed do (
s = $selection as array
clearSelection ()
if s.count>0 do 
 for i = 1 to s.count do
  if (classOf s[i]) == box do (
   cu = sa_cull width:(s[i].width/2) length:(s[i].length/2) \
                height:(s[i].height) par4:0 par8:0
   cu.position = s[i].position
   cu.xray = true
   delete s[i]
   SelectMore cu
  ) 
)
   
) -- rollout cull_rol

try (closeRolloutFloater cull_flo) catch () 
cull_flo = newRolloutFloater "CULL IO" 195 180 20 130 
addRollout  cull_rol cull_flo 


