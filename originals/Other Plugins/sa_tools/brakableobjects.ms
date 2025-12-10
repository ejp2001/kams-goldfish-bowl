fn writeStringZero f str N = (
local i, len

writeString f str
len = str.count
if len<N do 
 for i = 1 to (N-len-1) do writeByte f 0x0 #unsigned
N - len 
)

----------------------------------------------------------------------------------------------------------------

fn getID n maxn = (mod (n-1) maxn) as integer + 1

----------------------------------------------------------------------------------------------------------------
fn getTextura m n = (
local mat, res = #()

if isKindOf m Multimaterial then mat = m[n]
else
  mat = m
  
if isKindof mat Standard then (
 if mat.diffuseMap!=undefined do res[1] = getFileNameFile mat.diffuseMap.fileName
 if mat.opacityMap!=undefined do res[2] = getFileNameFile mat.opacityMap.fileName
)
else
 if isKindOf mat Gta_Mtl do (
  if mat.ColorMap!=undefined do res[1] = getFileNameFile mat.ColorMap.fileName
  if mat.AlphaMap!=undefined do res[2] = getFileNameFile mat.AlphaMap.fileName
 )
res
) -- fn getTextura
----------------------------------------------------------------------------------------------------------------


fn writeMeshExtSection f obj par1 par2 par3 par4= (
local i, j, k
local NumMV = #(), MFace = #(), freeMap = #(), VC = #(), MV = #(), V = #(), FS = #(), MAT = #()
local NumF = obj.NumFaces, Textur = #(), Textura = #(), TexNum = 0, MaxID, ObjMat, aaa, ID, NumObj = 0

if not meshop.getMapSupport obj 0 do meshop.setMapSupport obj 0 true
NumMV[1] = meshop.getNumMapVerts obj 0
NumMV[2] = meshop.getNumMapVerts obj 1
ObjMat = obj.material
MaxID = getNumSubMtls ObjMat
if MaxID == 0 do MaxID = 1

for i = 1 to NumF do (
 MFace[1] = meshOp.getMapFace obj 0 i
 MFace[2] = meshOp.getMapFace obj 1 i
 ff = getFace obj i
 FS[i] = [MFace[2][1]-1, MFace[2][2]-1, MFace[2][3]-1]
 MAT[i] = getId (getFaceMatID obj i) MaxID
 if Textur[MAT[i]]==undefined do (
  aaa = getTextura obj.material MAT[i]
 if aaa[1]!=undefined then textur[MAT[i]]=aaa[1] else textur[MAT[i]] = ""
 if aaa[2]!=undefined then textura[MAT[i]]=aaa[2] else textura[MAT[i]] = ""
 )
 
 for j = 1 to 3 do
  if freeMap[MFace[2][j]]==undefined do (
   -- col = (meshOp.getMapVert obj 0 MFace[1][j]) * 255
   -- VC[MFace[2][j]] = (color (col[1] as integer) (col[2] as integer) (col[3] as integer))
   col = getVertColor obj MFace[1][j]
   VC[MFace[2][j]] = (color (col.r as integer) (col.g as integer) (col.b as integer) (col.a as integer))
   MV[MFace[2][j]] = meshOp.getMapVert obj 1 MFace[2][j]
   V[MFace[2][j]] = getVert obj ff[j]
   freeMap[MFace[2][j]] = 1
  )
)

vychet = #(); for i = 1 to MaxID do vychet[i]=1

for i = 1 to MaxID do
 if textur[i]==undefined then
  ( for j = i to MaxID do vychet[j] += 1 )
 else NumObj+=1

writebyte f par1 #unsigned
writebyte f par2 #unsigned
writebyte f par3 #unsigned
writebyte f par4 #unsigned

writelong f 1 #unsigned -- always 1
writelong f V.count #unsigned -- num verts
writelong f 0 #unsigned -- unknown

writelong f 0 #unsigned -- unknown
writelong f 0 #unsigned -- unknown
writelong f NumF #unsigned -- NUM FACES
writelong f 0 #unsigned -- unknown

writelong f 0 #unsigned -- unknown
writelong f NumObj #unsigned -- NUM OBJ
writelong f 0 #unsigned -- unknown
writelong f 0 #unsigned -- unknown

writelong f 0 #unsigned -- unknown
writelong f 0 #unsigned -- unknown


for i = 1 to V.count do (  -------------------------------------------  VERTS
 writefloat f V[i].x ; writefloat f V[i].y ; writefloat f V[i].z 
)

for i = 1 to MV.count do ( ------------------------------------------- UV COORDS
 writefloat f MV[i].x ; writefloat f MV[i].y
)

for i = 1 to VC.count do ( --------------------------------------------- V COLORS
 writebyte f VC[i].r ; writebyte f VC[i].g ; writebyte f VC[i].b ; writebyte f VC[i].a
)

for i = 1 to NumF do ( ------------------------------------------------ FACES
 writeshort f FS[i][1] ; writeshort f FS[i][2] ; writeshort f FS[i][3] 
)

for i = 1 to NumF do ( ----------------------------------------------- MAT ID
 writeshort f (MAT[i] - vychet[MAT[i]])
)


for i = 1 to MaxID do ( ---------------------------------------- TEXTURE
 if textur[i]!=undefined do
  if textur[i]!="" then writeStringZero f textur[i] 32
   else for j = 1 to 8 do writelong f 0
)

for i = 1 to MaxID do ( ----------------------------------------- TEXTURE A
if textur[i]!=undefined do
 if textura[i]!="" then writeStringZero f textura[i] 32
   else for j = 1 to 8 do writelong f 0
)

for i = 1 to NumObj*3 do writefloat f 1.0

--break ()
)-- fn


----------------------------------------------------------------------------------------------------------------

rollout MeshExt_rol "" width:190 height:105
(
	label lbl2 "unk1" pos:[7,47] width:31 height:20
	spinner u1 "" pos:[39,47] width:50 height:16 range:[0,255,100] type:#integer
	label lbl3 "unk2" pos:[96,47] width:31 height:20
	spinner u2 "" pos:[128,47] width:50 height:16 range:[0,255,100] type:#integer
	label lbl4 "unk3" pos:[8,72] width:31 height:20
	spinner u3 "" pos:[40,72] width:50 height:16 range:[0,255,100] type:#integer
	label lbl5 "unk4" pos:[97,72] width:31 height:20
	spinner u4 "" pos:[129,72] width:50 height:16 range:[0,255,100] type:#integer
	button exp "export section" pos:[9,6] width:168 height:30
	

on exp pressed do (

s = selection
if s.count != 1 then messageBox "select just 1 object"
else (
fname = getSaveFileName caption:"export section 0x253F2FD" \
                        types:"binary|*.bin" --"D:\\SA_MOD\\BRAKABLE\\sec_test1.bin"
if fname != undefined do (				
 f = fopen fname "wb"
 if f == undefined then messageBox "file is allredy used...."
 else (
  obj = copy s[1]
  ConvertToMesh obj
  writeMeshExtSection f obj u1.value u2.value u3.value u4.value
  delete obj
  fclose f
 ) -- if f
) -- fname
) -- s.count
) 

) -- rollout

try (closeRolloutFloater MeshExt_flo) catch ()
MeshExt_flo = NewRolloutFloater "0x253F2FD export" 210 130 100 120
addRollout MeshExt_rol MeshExt_flo