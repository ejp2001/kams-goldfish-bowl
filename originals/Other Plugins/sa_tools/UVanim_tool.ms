-----------------------------------------------------------------------------------------------
fn copyData f1 f2 N = (
local i, b
 for i = 1 to N do (b = readByte f1 ; writeByte f2 b ) 
) 
-----------------------------------------------------------------------------------------------

fn copyHeader f H = (
 writeLong f H[1]
 writeLong f H[2]
 writeLong f H[3]
)

-----------------------------------------------------------------------------------------------

fn readHeader f = (
 local i, res = #()
 b = readLong f #unsigned
 res[1] = b
 b = readLong f #unsigned
 res[2] = b
 b = readLong f #unsigned
 res[3] = b
 res
)

-----------------------------------------------------------------------------------------------
fn findHeader f ID Size = (
 local res = #(), H, EndPos = ftell f + Size
 res[4] = false
 
 while ftell f < EndPos do
 if not res[4] then (
  H = readHeader f
  if H[3] == 0x1803FFFF then 
   if H[1] == ID then ( res[1] = H[1]
                        res[2] = H[2]
						res[3] = H[3]
                        res[4] = true ) 
   else 
     res = findHeader f ID H[2]
  else 
     fseek f (Size-12) #seek_cur -- pass data
 ) else exit -- if res == true
 
 res
) -- end findHeader

-------------------------------------------------------------------------------------------
fn GetAKeys bmap = (
local AKeys = #(), Keys_u_offset, Keys_v_offset, Keys_u_tiling, Keys_v_tiling
local AStartKey, AEndKey, i, k

Keys_u_offset = bmap.coords.u_offset.keys
Keys_v_offset = bmap.coords.v_offset.keys
Keys_u_tiling = bmap.coords.u_tiling.keys
Keys_v_tiling = bmap.coords.v_tiling.keys
--Keys_w_angle = bmap.coords.w_angle.keys

AStartKey = animationRange.start
AEndKey = animationRange.end

append AKeys AStartKey
append AKeys AEndKey

for i = 1 to Keys_u_offset.count do (
 k = Keys_u_offset[i].time
  if k>=AStartKey and k<=AEndKey do 
   if (findItem AKeys k) == 0 do append AKeys k
)
for i = 1 to Keys_v_offset.count do (
 k = Keys_v_offset[i].time
  if k>=AStartKey and k<=AEndKey do
   if (findItem AKeys k) == 0 do append AKeys k
)
for i = 1 to Keys_u_tiling.count do (
 k = Keys_u_tiling[i].time
  if k>=AStartKey and k<=AEndKey do
   if (findItem AKeys k) == 0 do append AKeys k
)
for i = 1 to Keys_v_tiling.count do (
 k = Keys_v_tiling[i].time
  if k>=AStartKey and k<=AEndKey do
   if (findItem AKeys k) == 0 do append AKeys k
)

for i = 1 to AKeys.count-1 do
 for j = i+1 to AKeys.count do
   if AKeys[i]>AKeys[j] do swap AKeys[i] AKeys[j]
   
AKeys   

) -- end GetAKeys

-----------------------------------------------------------------------------------------------

fn getAData bmap AKeys = (
local i, uo, vo, ut, vt, res = #()

for i = 1 to AKeys.count do (
 -- SliderTime = AKeys[i]
 at time AKeys[i] uo = bmap.coords.u_offset
 at time AKeys[i] vo = bmap.coords.v_offset
 at time AKeys[i] ut = bmap.coords.u_tiling
 at time AKeys[i] vt = bmap.coords.v_tiling
 res[i] = #((AKeys[i] as float)/4800.0, 0.0, ut, vt, 0.0, -uo, vo, i-2 )
)

SliderTime = 0

res
)
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

rollout UVanimTool_rol "" width:190 height:364
(
	button exp "Append animation" pos:[25,280] width:138 height:26
	materialButton pickMat "pick material" pos:[24,18] width:135 height:24
	bitmap bmp2 "Bitmap" pos:[25,49] width:128 height:128
	groupBox grp1 "" pos:[3,4] width:183 height:176
	
	
	groupBox grp2 "" pos:[3,182] width:183 height:140
	button SelectDFF "Select DFF" pos:[14,195] width:161 height:26
	dropdownlist TList "Texture to aplay" pos:[9,224] width:171 height:5
	
local bmap, TexNum, TexList, AMatList, f, fname, ASize
	
on pickMat picked mtl do (
 if isKindOf mtl Gta_Mtl then 
  if mtl.colormap == undefined then messageBox "No texture in material" 
  else (
   bmap = mtl.colorMap
   pickMat.text = mtl.name
   bmap.coords.u_offset.controller = linear_float ()
   bmap.coords.v_offset.controller = linear_float ()
   bmap.coords.u_tiling.controller = linear_float ()
   bmap.coords.v_tiling.controller = linear_float ()
   bmp2.fileName = bmap.fileName
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
   bmp2.fileName = bmap.fileName
  )
  else  (
   pickMat.material = undefined
   pickMat.text = "pick material"
   MessageBox "select Standard or KAM's GTA material"
   bmp2.bitmap = undefined
  )
) -- on pickMat pressed

on SelectDFF pressed do (
 fname = getOpenFileName caption:"select DFF" types:"DFF (*.dff)|*.dff|"
 if fname != undefined do (
  f = fopen fname "rb"
  if f == undefined then ( messageBox "Can't open file"
                           SelectDFF.text = "Select DFF")
  else (
	TexNum = 0
	TexList = #()
	AMatList = #()
	ASize = #()
	DataSize = getFileSize fname
	SelectDFF.text = getFileNameFile fname
	
	while true do (
	 FH = findHeader f 0x07 DataSize
	 if not FH[4] do exit
	 TexNum += 1	 
	 CurPos = ftell f
	 DataSize = FH[2]
	 FH = findHeader f 0x06 DataSize
	 CurPos2 = ftell f
	 if FH[4] then (
	  fseek f 28 #seek_cur
	  TexList[TexNum] = readString f
      fseek f (CurPos2 + FH[2]) #seek_set
	  H = readHeader f
	  ASize[TexNum] = H[2]	  
	  fseek f CurPos #seek_set
	  FH = findHeader f 0x135 DataSize
	  if FH[4] then (
	   H = ReadHeader f
	   fseek f 4 #seek_cur
	   AMatList[TexNum] = readString f
	  )
	  else AMatList[TexNum] = undefined
	 )
	 else ( AMatList[TexNum] = undefined ; TexList[TexNum] = "<-- no texture -->")
	 
	 fseek f CurPos #seek_set
	 DataSize = getFileSize fname - ftell f
   ) -- while
   
   TTList = #()
   for i = 1 to TexList.count do 
    if AMatList[i] != undefined then TTList[i] = TexList[i] + " (A)"
	                            else TTList[i] = TexList[i]
   TList.Items = TTList
   if TexNum>30 then TList.height = 29*10
                else TList.height = TexNum * 10 + 20
   
  ) -- end else f==undefined  
 ) -- if fname != undefined					 
) -- on DFF pressed

	
on exp pressed do
 if bmap == undefined then MessageBox "Select material"
 else
  if f == undefined then MessageBox "Select DFF"
  else
    if (findItem AMatList PickMat.material.name) > 0 and
	    TList.selection != (findItem AMatList PickMat.material.name) then
	      messageBox "need rename your material (DFF have material with same name)"
	else 
	if TList.items[TList.selection] == "<-- no texture -->" then 
	      MessageBox "<-- no texture --> in dropdown list its mean NO TEXTURE"
	else (
	 FPath = getFileNamePath fname
	 tempfname = FPath + "temp_" + (filenameFromPath fname)
	 tempf = fopen tempfname "wb"
	 fseek f 4 #seek_set
	 AnimSize = readLong f #unsigned
	 fseek f 0 #seek_set

	 AKeys = GetAKeys bmap
	 AData = getAData bmap AKeys
	 
     SizeInc = 84 - ASize[TList.selection]										   
	 
	 AReplace = if AMatList[TList.selection]!= undefined then true
	                                                     else false
	 
	 AMatList[TList.selection] = PickMat.material.name
	 AMats = 0
	 for i = 1 to AMatList.count do
	       if AMatList[i] != undefined do AMats += 1   
			  
	 
	 -- UV Anim Dictionary
	 writeLong tempf 0x2B
	 writeLong tempf 0
	 writeLong tempf 0x1803FFFF	
 
	 -- UV Anim Dictionary/struc
	 writeLong tempf 0x01
	 writeLong tempf 4
	 writeLong tempf 0x1803FFFF	
     writeLong tempf AMats
	 
	 -- Old Animations
	 for i = 1 to AMats do (
	  FH = findHeader f 0x1B AnimSize
	  if FH[4] do (
	  CurPos = ftell f
	  fseek f 24 #seek_cur
	  str = readString f
	  fseek f CurPos #seek_set
	  if (findItem AMatList str) != TList.selection and (findItem AMatList str)>0 then (
	   copyHeader tempf FH
	   copyData f tempf FH[2]
	  )
	  else fseek f FH[2] #seek_cur
	  ) -- FH[4]
	 ) -- for i
	 
	 -- New Anim header
	 writeLong tempf 0x1B
	 writeLong tempf (88 + AKeys.count*32)
	 writeLong tempf 0x1803FFFF
	 -- New Anim Data
	 CurPos = ftell tempf
	 writeLong tempf 256 #unsigned
	 writeLong tempf 449 #unsigned
     writeLong tempf (AKeys.count) #unsigned
	 writeFloat tempf 0.0
	 writeFloat tempf ((AKeys[AKeys.count] as float)/4800.0)
	 writeLong tempf 0  #unsigned
	 writeString tempf AMatList[TList.selection]
	 fseek tempf (CurPos+88) #seek_set

     for i = 1 to AKeys.count do (
	  for j = 1 to 7 do writeFloat tempf AData[i][j]
	  writeLong tempf AData[i][8]
	 )
	 
	 CurPos = ftell tempf
	 fseek tempf 4 #seek_set
	 writeLong tempf (CurPos - 12) -- set Anim Size
	 fseek tempf CurPos #seek_set 
	 
	 fseek f 0 #seek_set                        --- copy CLUMP
	 FH = findHeader f 0x10 (FSize = getFileSize fname)
	 FH[2] += SizeInc + (if not AReplace and AMats == 1 then 36 else 0)
	 copyHeader tempf FH
	 
	 H = readHeader f  --- Clump/stru
	 copyHeader tempf H
	 copyData f tempf H[2]
	 
	 H = readHeader f  --- Clump/frame list
	 copyHeader tempf H
	 copyData f tempf H[2]
	 
	 H = readHeader f  --- Clump/geom list
	 H[2] += SizeInc
	 copyHeader tempf H
	 
	 H = readHeader f  --- Clump/geom list / stru
	 copyHeader tempf H
	 copyData f tempf H[2]
	 
	 H = readHeader f  --- Clump/glist/geometrya
	 H[2] += SizeInc
	 copyHeader tempf H
	 
	 H = readHeader f  --- Clump/glist/geomertia / stru
	 copyHeader tempf H
	 copyData f tempf H[2]
	 
	 H = readHeader f  --- Clump/..../Matlist
	 H[2] += SizeInc
	 copyHeader tempf H
	 
	 H = readHeader f  --- Clump/..../Matlist/stru
	 copyHeader tempf H
	 copyData f tempf H[2]
	 
	 for i = 1 to TList.items.count do 
	  if i != TList.selection then ( 
	   H = readHeader f  -- material
	   copyHeader tempf H
	   copyData f tempf H[2]	  
	  ) 
	  else (
	   H = readHeader f  -- material 
	   H[2] += SizeInc
       copyHeader tempf H
  	   H = readHeader f  --- ../ stru
	   copyHeader tempf H
	   copyData f tempf H[2]
  	   H = readHeader f  --- ../ texture
	   copyHeader tempf H
	   copyData f tempf H[2]
  	   H = readHeader f  --- ../ exten
	   fseek f H[2] #seek_cur
       H[2] = 84
	   copyHeader tempf H
	   H[1] = 0x120; H[2] = 12 ; copyHeader tempf H
	   writeLong tempf 5 #unsigned 
	   writeLong tempf 5 #unsigned 
	   writeLong tempf 0 #unsigned 
	   H[1] = 0x135; H[2] = 48 ; copyHeader tempf H
	   H[1] = 0x01; H[2] = 36 ; copyHeader tempf H
	   CurPos = ftell tempf
	   writeLong tempf 1 #unsigned
	   writeString tempf AMatList[i]
	   for j = 1 to 32 do writeByte tempf 0 
       fseek tempf (CurPos+36) #seek_set
	  ) -- end if i!= .... / else 
	 
	 if not AReplace and AMats == 1 do (	 
	  CurPos = ftell f
	  FH = findHeader f 0x14 (getFileSize fname - CurPos)
	  DSize = ftell f - CurPos - 12
      fseek f CurPos #seek_set	 
	  copyData f tempf DSize
	  FH[2] += 36
	  copyHeader tempf FH
	  fseek f 12 #seek_cur
  	  H = readHeader f  --- ..Atomik / stru
	  copyHeader tempf H
	  copyData f tempf H[2]	  
  	  H = readHeader f  --- ..Atomik / exten
	  H[2]=36
	  copyHeader tempf H
	  H[1] = 0x1F; H[2] = 8 ; copyHeader tempf H
	  writeLong tempf 288 #unsigned
	  writeLong tempf 0 #unsigned
	  H[1] = 0x120; H[2] = 4 ; copyHeader tempf H
	  writeLong tempf 1 #unsigned
	 )
	  
	 while (ftell f) < (getFileSize fname) do ( --- copy to end
	  b = readbyte f #unsigned
	  writeByte tempf b #unsigned
	 )
	 
	 format "Data appended\n"
	 fclose f
	 f = undefined
	 fclose tempf
	 tempf = undefined
	 --copyFile tempfname fname
     --deleteFile tempfname
	 TList.items = #()
     SelectDFF.text = "Select DFF"
    ) -- end on exp
		
) -- roll

try (closeRolloutFloater uvtool_flo) catch () 
uvtool_flo = newRolloutFloater "UV anim export" 205 360 20 130 
addRollout  UVanimTool_rol uvtool_flo