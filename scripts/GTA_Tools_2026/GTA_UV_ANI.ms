-- GTA UV Sprite Animation Tool
-- Standalone UV animation sequencer for sprite sheets and texture atlases
-- Original code by Kam/Goldfish, extracted as standalone by E2001 2026

rollout tv_roll "UV Sprite Animation" width:220 height:140
(
	edittext comline "" pos:[2,63] width:220 height:20
	label lbl1 "Adjust Sequence and Duration" pos:[12,47] width:196 height:15
	label lbl2 "U count" pos:[7,6] width:46 height:15
	label lbl3 "V count" pos:[7,25] width:46 height:15
	spinner Ucount "" pos:[57,6] width:46 height:16 range:[1,100,2] type:#integer
	spinner Vcount "" pos:[57,26] width:46 height:16 range:[1,100,3] type:#integer
	materialButton pickmat "pick material" pos:[115,5] width:100 height:38
	bitmap bmp2 "Bitmap" pos:[5,87] width:128 height:128	
	label lbl4 "Set UV Count before picking material. Command line will be filled in automatically. Set time as float." pos:[138,86] width:84 height:90
	button go "Create Animation" pos:[138,180] width:84 height:38
	
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
   n1 = (substring ss[j] 1 (n-1)) as integer
   n2 = (substring ss[j] (n+2) 100) as integer
   dn = if n2>n1 then 1 else -1
   while n1 != n2 do (
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
	bmap = mtl.colormap
	comline.text = "1.." + ((Ucount.value * Vcount.value) as string)
	bmp2.bitmap = bmap.bitmap
	bmap.coords.u_tiling = 1.0/Ucount.value
	bmap.coords.v_tiling = 1.0/Vcount.value
	bmap.coords.u_offset = 0.0
	bmap.coords.v_offset = 0.0
	if bmap.coords.V_Tile==off then bmap.coords.V_Tile = on
	if bmap.coords.U_Tile==off then bmap.coords.U_Tile = on
  )
 else
 if  isKindOf mtl Standard then
  if mtl.DiffuseMap == undefined then messageBox "No texture in material"
  else (
	bmap = mtl.DiffuseMap
	comline.text = "1.." + ((Ucount.value * Vcount.value) as string)
	bmp2.bitmap = bmap.bitmap
	bmap.coords.u_tiling = 1.0/Ucount.value
	bmap.coords.v_tiling = 1.0/Vcount.value
	bmap.coords.u_offset = 0.0
	bmap.coords.v_offset = 0.0
	if bmap.coords.V_Tile==off then bmap.coords.V_Tile = on
	if bmap.coords.U_Tile==off then bmap.coords.U_Tile = on
  )
  else  (
   messageBox "This Material type is not supported by script.\nPlease use Gta_Mtl or Standard Material with texture." title:"Material type Error"
  )
)


	
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
	animate on (
	 at time CurTime bmap.coords.u_offset = Foffset[1]/Ucount.value
	 at time CurTime bmap.coords.v_offset = Foffset[2]/Vcount.value
	)
	CurTime += dTime[i]
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

global UV_ANI_floater
if UV_ANI_floater != undefined then ( closeRolloutFloater UV_ANI_floater; gc() )
UV_ANI_floater = newRolloutFloater "UV Sprite Animation" 230 250 10 50		
addRollout tv_roll UV_ANI_floater
