-- s = selection as array
-- Dir = "D:\\SA_MOD\\COL_TEST\\"

fn COL_SCRIPT_EXPORT s Dir = (
local o, obj, f, fname, NVerts, Nfaces, V, m, i, mat, Vf, colsph = #(), colbox = #(), ch


for o in s do 
if o.parent == undefined then (
 obj = o.mesh
 fname = Dir + "\\" + o.name + ".cst"
 f = CreateFile fname
 
 format "CST2\n\n" to:f
 
 NVerts = obj.NumVerts
 format "%, Vertex\n" NVerts to:f
 
 for i = 1 to NVerts do (
  V = in coordsys local (getVert obj i)
  format "%, %, %\n" V.x V.y V.z to:f
 )
 
 Nfaces = obj.NumFaces
 format "\n%, Face\n" NFaces to:f
 m = o.material
 
 for i = 1 to NFaces do (
  Vf = GetFace obj i
  mmm = getFaceMatID obj i
  if m!=undefined then
    if isKindOf m MultiMaterial then
	  if isKindOf m[getFaceMatID obj i] GTA_COLSurface then mat = m[getFaceMatID obj i].surface
	  else mat = (mmm-1)-- (getFaceMatID obj i) - 1
	else
	  if isKindOf m GTA_COLSurface then mat = m.surface
	  else mat = (mmm-1)  -- ((getFaceMatID obj i) -1)
  else 
   mat = 0
  format "%, %, %, %, 0, 0, 20\n" ( Vf[1] as integer -1) ( Vf[3] as integer -1)( Vf[2] as integer -1) mat to:f
 )

 --if o.children.count > 0 do (
 --for i = 1 to o.children.count do (
 -- m = (ch = o.children[i]).material
 -- if isKindOf m GTA_COLSurface then Mat = m.surface else Mat = 0
 -- if classof ch == Sphere then 
 -- append colsph (ch.position.x as string +", "+ ch.position.y as string +", "+ ch.position.z as string +", "+ \
 --                 ch.radius as string +", "+ Mat as string + ", 0, 187, 0\n")
 -- if classof ch == Box then 
 --    append colbox (ch.min.x as string +", "+ ch.min.y as string +", "+ ch.min.z as string +", "+ \
 --	                ch.max.x as string +", "+ ch.max.y as string +", "+ ch.max.z as string +", "+ \
 --                  Mat as string + ", 0, 187, 0\n")  
 --) -- for i
 
 --if colsph.count>0 then (
 --  format "\n%, Sphere\n" colsph.count to:f
 --  for i = 1 to colsph.count do format colsph[i] to:f
 --)
 
 --if colbox.count>0 then (
 --  format "\n%, Box\n" colbox.count to:f
 --  for i = 1 to colbox.count do format colbox[i] to:f
 --)
 
 --) -- if s.children
 
 close f
 )
 
 ) -- fn
 
 -----------------------------------------------------------------------------------------
 -----------------------------------------------------------------------------------------
 -----------------------------------------------------------------------------------------
 -----------------------------------------------------------------------------------------
 -----------------------------------------------------------------------------------------


objs = selection
if objs.count==0 then messageBox "select col objects"
else (
 opath = getSavePath caption:"select output path"
 if opath != undefined then
    COL_SCRIPT_EXPORT objs opath
) -- obj.count