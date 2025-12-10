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

fn lowercase str = 
(
 local i, j, ucase, lcase, result
 ucase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
 lcase = "abcdefghijklmnopqrstuvwxyz"
 
 result = copy str
 for i = 1 to result.count do
  (
   j = findString ucase result[i]
   if j != undefined  do result[i] = lcase[j]
  )
 result
) -- end fn lowercase

-----------------------------------------------------------------------------------------------------

rollout idetxd_rol "IDE TXD tool" width:144 height:149
(
	button createide "Create IDE" pos:[10,12] width:122 height:23 
	edittext txdname "" pos:[9,59] width:122 height:17 
	label lbl1 "TXD name" pos:[13,40] width:67 height:14 
	spinner idestart "" pos:[72,83] width:60 height:16 range:[0,100000,0] type:#integer
	label lbl2 "IDE start" pos:[15,83] width:50 height:21 
	GroupBox grp1 "" pos:[3,1] width:136 height:153 
	--button gettexture "Texture Names by TXD" pos:[10,148] width:121 height:21 
	spinner dist "" pos:[72,104] width:60 height:16 range:[0,100000,0] type:#integer 
	label lbl5 "Distance" pos:[15,104] width:50 height:21
	spinner objflag "" pos:[72,126] width:60 height:16 range:[0,100000,0] type:#integer
	label dddddfs "FLAG" pos:[15,126] width:50 height:21
	

on createide pressed do (
ide = idestart.value
clearListener ()
if $ == undefined then messagebox "no object selected"
else 
  for obj in $ do (
    format "%, %, %, %, %\n" ide obj.name txdname.text dist.value objflag.value
    ide += 1
  )
) -- pressed
) -- rollout

-----------------------------------------------------------------------------------------------------
try (closeRolloutFloater idetxd_flo) catch () 
idetxd_flo = newRolloutFloater "" 160 195 20 150 
addRollout  idetxd_rol idetxd_flo