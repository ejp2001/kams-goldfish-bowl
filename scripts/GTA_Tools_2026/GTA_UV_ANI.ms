-- GTA UV Sprite Animation Tool
-- Based on TVanimationHelper from SA_TOOLS
-- Restored to original behavior by E2001 2026

rollout tv_roll "" width:414 height:100
(
	edittext comline "" pos:[2,63] width:405 height:20
	label lbl1 "command line" pos:[12,47] width:196 height:15
	label lbl2 "U count" pos:[7,6] width:46 height:15
	label lbl3 "V count" pos:[7,25] width:46 height:15
	spinner Ucount "" pos:[57,6] width:46 height:16 range:[1,100,2] type:#integer
	spinner Vcount "" pos:[57,26] width:46 height:16 range:[1,100,3] type:#integer
	button go "GO" pos:[110,3] width:150 height:56
	--bitmap bmp2 "Bitmap" pos:[5,87] width:400 height:400
	materialButton pickmat "pick material" pos:[265,4] width:140 height:54
	
local frames = #(), dTime = #()
local i, j, bmap


fn DeleteSpaces str = (
local res = "", i, k
local ucase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local lcase = "abcdefghijklmnopqrstuvwxyz"

for i = 1 to str.count do 
 if str[i] != " " do 
  if (k = findString ucase str[i])==undefined then res += str[i]
   else res += lcase[k]

res
) -- end fn


fn getFrameOffset frame = (
local res = #()
res[1] = - (mod (frame - 1) Ucount.value)
res[2] = - floor ((frame - 1) / Ucount.value) --as integer
res
) -- end fn




fn compile str = (
local i, j, n, fs, s, ss, n, n1, n2, dn, bmap
frames = #()
dTime = #()

fs = filterString str ";"
format "---fs---%\n" fs

for i = 1 to fs.count do (
 AnimTime = 30f
 n = findString fs[i] "time="
 if n != undefined then (AnimTime = (((substring fs[i] (n+5) 100) as float) * 30) as time
                         s = substring fs[i] 1 (n-1))
				   else  s = fs[i]
 frames[i] = #()
 
 if s.count > 0 then (
 NumF = 0
 ss = filterString s ","
 Fcount = NumF
 for j = 1 to ss.count do (
  if (n = findstring ss[j] "..") != undefined then (
   n1 = (substring ss[j] 1 n) as integer
   n2 = (substring ss[j] (n+2) -1) as integer
   if n2 > n1 then dn = 1
    else
	 dn = -1
   while n1!=n2 do (
    Numf +=1 ; frames[i][NumF] = n1
	n1 += dn
   )
   
   Numf +=1 ; frames[i][NumF] = n2
  ) -- if 
  else (Numf +=1 ; frames[i][NumF] = ss[j] as integer)
  
 dTime[i] = AnimTime / (NumF - Fcount)
 ) -- ss.count; j loop
 ) -- if s.count >0
 else  (frames[i][1] = frames[i-1][frames[i-1].count]
        dTime[i] = AnimTime)
 
 ) -- i loop
 
format "%----%\n" frames dTime
) -- end compile	





on pickmat picked mtl do (
 if isKindOf mtl Gta_Mtl then
  if mtl.colormap == undefined then messageBox "No texture in material"
  else (
   bmap = mtl.colorMap
   pickMat.text = mtl.name
   bmap.coords.u_offset.controller = linear_float ()
   bmap.coords.v_offset.controller = linear_float ()
   bmap.coords.u_tiling.controller = linear_float ()
   bmap.coords.v_tiling.controller = linear_float ()
   --bmp2.fileName = bmap.fileName
   comline.text = "1.." + (Ucount.value * Vcount.value) as string + ",time=1.0"
  )
 else
 if  isKindOf mtl Standard then
  if mtl.DiffuseMap == undefined then messageBox "No texture in material"
  else (
   bmap = mtl.DiffuseMap
   pickMat.text = mtl.name
   bmap.coords.u_offset.controller = linear_float ()
   bmap.coords.v_offset.controller = linear_float ()
   bmap.coords.u_tiling.controller = linear_float ()
   bmap.coords.v_tiling.controller = linear_float ()   
   --bmp2.fileName = bmap.fileName
   comline.text = "1.." + (Ucount.value * Vcount.value) as string + ",time=1.0"
  )
  else  (
   pickMat.material = undefined
   pickMat.text = "pick material"
   MessageBox "select Standard or KAM's GTA material"
   --bmp2.bitmap = undefined
   comline.text = ""
  )
) -- on pickMat pressed


	
on go pressed do 
 if comline.text.count>0 then (
 cline = DeleteSpaces comline.text
 
 compile cline
 
 CurTime = AnimationRange.start
 --animate on (
 -- at time CurTime bmap.coords.u_tiling = 1.0/Ucount.value
 -- at time CurTime bmap.coords.v_tiling = 1.0/Vcount.value
 -- )
 --AddOffset = #(((Ucount.value as float) - 1.0)/2.0, ((Vcount.value as float) - 1.0)/2.0)
 
 for i = 1 to dTime.count do (
  if frames[i].count>0 then 
   for j = 1 to frames[i].count do (
   Foffset = getFrameOffset frames[i][j]
   format "## %\n" Foffset
    animate on (
	 at time CurTime bmap.coords.u_offset = Foffset[1]/Ucount.value -- + AddOffset[1]
	 at time CurTime bmap.coords.v_offset = Foffset[2]/Vcount.value -- + AddOffset[2]
	 CurTime += dTime[i]
	 at time (CurTime - 1t) bmap.coords.u_offset = Foffset[1]/Ucount.value -- + AddOffset[1]
	 at time (CurTime - 1t) bmap.coords.v_offset = Foffset[2]/Vcount.value -- + AddOffset[2]
	 ) -- animate on
  ) -- j loop
  else CurTime += dTime[i]
 ) -- i loop
 
 Foffset = getFrameOffset frames[1][1]
 animate on (
  at time CurTime bmap.coords.u_offset = Foffset[1]/Ucount.value
  at time CurTime bmap.coords.v_offset = Foffset[2]/Vcount.value
 )
 
 animationRange = (interval AnimationRange.start CurTime)
 
) -- on go preesed
	
) -- end rollout

-------------------------------------------------------------------------------------------------------

try (closeRolloutFloater tv_flo) catch () 
tv_flo = newRolloutFloater "tv anim helper" 425 125 20 130 
addRollout  tv_roll tv_flo
