fn writeStringZero f str N = (
local i, len

writeString f str
len = str.count
if len<N do 
 for i = 1 to (N-len-1) do writeByte f 0x0 #unsigned
format "------/// %\n" (N-len-1)
N - len 
)

------------------------------------------------------------------------------------------------------
fn getKeys s havePos = (

local posKeys, rotKeys, AKeys = #()
local i, j, k, t

rcon = s.rotation.controller = linear_rotation ()
pcon = s.pos.controller = linear_position ()

rotKeys = rcon.keys
posKeys = pcon.keys

for i = 1 to rotKeys.count do (
 k = rotKeys[i].time
 if (findItem AKeys k) == 0 do append AKeys k
)

if havePos do
 for i = 1 to posKeys.count do (
  k = posKeys[i].time
  if (findItem AKeys k) == 0 do append AKeys k
 )
 
for i = 1 to AKeys.count-1 do -- sort
 for j = i+1 to AKeys.count do
   if AKeys[i]>AKeys[j] do swap AKeys[i] AKeys[j]

AKeys
)   


-------------------------------------------------------------------------

fn writeData f s AKeys havePos = (

local i, j, k, t
   
format "c 24\n%\n" s.name
writeStringZero f s.name 24
format "i 3\n"
format "% % %\n" (if havePos then 4 else 3) AKeys.count -1
if havePos then writeLong f 4 #unsigned
           else writeLong f 3 #unsigned
writeLong f AKeys.count #unsigned
writeLong f -1 #unsigned		   
format "w %\n" (if havePos then AKeys.count*8 else AKeys.count*5)

for i = 1 to AKeys.count do  (
 format "% % % % %" (at time AKeys[i] ((in coordsys parent s.rotation.x)*4096.0) as integer) \
                    (at time AKeys[i] ((in coordsys parent s.rotation.y)*4096.0) as integer) \
                    (at time AKeys[i] ((in coordsys parent s.rotation.z)*4096.0) as integer) \
					(at time AKeys[i] ((in coordsys parent s.rotation.w)*4096.0) as integer) \
					((AKeys[i] as integer)/80)
					
writeShort f (at time AKeys[i] ((in coordsys parent s.rotation.x)*4096.0) as integer) #signed
writeShort f (at time AKeys[i] ((in coordsys parent s.rotation.y)*4096.0) as integer) #signed
writeShort f (at time AKeys[i] ((in coordsys parent s.rotation.z)*4096.0) as integer) #signed
writeShort f (at time AKeys[i] ((in coordsys parent s.rotation.w)*4096.0) as integer) #signed
writeShort f ((AKeys[i] as integer)/80) #unsigned

 if havePos then (
    format " % % %"  (at time AKeys[i] ((in coordsys parent s.position.x)*1024.0) as integer) \
                     (at time AKeys[i] ((in coordsys parent s.position.y)*1024.0) as integer) \
                     (at time AKeys[i] ((in coordsys parent s.position.z)*1024.0) as integer)
					 
 writeShort f (at time AKeys[i] ((in coordsys parent s.position.x)*1024.0) as integer) #signed					 
 writeShort f (at time AKeys[i] ((in coordsys parent s.position.y)*1024.0) as integer) #signed
 writeShort f (at time AKeys[i] ((in coordsys parent s.position.z)*1024.0) as integer) #signed
					 
 ) -- if havePos					 					 
		
format "\n"					
)

AKeys
) -- end writeDATA


-------------------------------------------------------------------------------------------------------

fn writeSection f obj asubs exc skipPosKey = (
local AKeys = #(), i
local DataCount = 0, AnimCount = 0

for i = 1 to asubs.count do AKeys[i] = getKeys asubs[i] (not skipPosKey[i])

for i = 1 to asubs.count do 
 if not exc[i] do (
  AnimCount += 1
  if not skipPosKey[i] then
    DataCount += AKeys[i].count * 8
  else
    DataCount += AKeys[i].count * 5
 )

ClearListener ()
format "//\n//\n//\n//\n//Animation % starts here\n" obj.name
format "c 24\n%\n" obj.name
writeStringZero f obj.name 24
format "i 3\n" 
format "% % %\n" AnimCount (DataCount*2) 1
writeLong f AnimCount #unsigned
writeLong f (DataCount*2) #unsigned
writeLong f 1 #unsigned

for i = 1 to asubs.count do
 if not exc[i] do 
   writeData f asubs[i] AKeys[i] (not skipPosKey[i])  
   
) -- end writeSection
   
-------------------------------------------------------------------------------------------------------

fn getSubs s = (
local res = #(), i, subobj = s.children

if subobj.count>0 do 
for i = 1 to subobj.count do (
append res subobj[i]
if subobj[i].children.count > 0 do join res (getSubs subobj[i])
)

res
) -- end getSub

-------------------------------------------------------------------------------------------------------

rollout anim_rol "" width:145 height:224
(
	listBox chil "children objects" pos:[7,73] width:125 height:7
	checkbox skippos "skip pos" pos:[9,194] width:59 height:21
	button GO "EXPORT" pos:[18,4] width:102 height:18
	button APP "APPEND" pos:[18,26] width:102 height:18
	button gethi "get hierarhy selected" pos:[9,48] width:122 height:20
	checkbox exclu "exclude" pos:[73,194] width:59 height:21
	
local asubs = #(), i, names = #(), exc = #(), skipPosKey = #(), obj, AKeys, f

on gethi pressed do (
 if selection.count > 0 do
 if selection.count > 1 then messageBox "Select just 1 parent object"
 else (
  obj = selection[1]
  asubs = getSubs obj
  if asubs.count>0 do
   for i = 1 to asubs.count do (
    names[i] = asubs[i].name
	exc[i] = false
	skipPosKey[i] = true
	)
  chil.items = names
  chil.selection = 1
  exclu.checked = false
  skippos.checked = true
 ) --  
) -- pressed

on exclu changed arg do 
 if exc.count>0 do (
 exc[chil.selection] = arg
) --

on skippos changed arg do
 if exc.count>0 do (
 skipPosKey[chil.selection] = arg
) --

on chil selected arg do 
 if chil.Items.count>0 do (
 skippos.checked = skipPosKey[arg]
 exclu.checked = exc[arg]
) -- 

on GO pressed do ------------------------------------------------------ EXPORT
if asubs.count>0 do (                             
 fname = getSaveFileName caption:"export animation" \
                         types:"GTA animation (*.ifp)|*.ifp|"
 if fname != undefined do (
  f = fopen fname "wb"
  if f == undefined then messageBox "export error"
  else (
  writebyte f 65 #unsigned -- str = "ANP3"
  writebyte f 78 #unsigned
  writebyte f 80 #unsigned
  writebyte f 51 #unsigned
  
  writelong f 10 -- size
  aname = getFilenameFile fname
  writestringzero f aname 24
  writeLong f 1 #unsigned -- anims
  
  writeSection f obj asubs exc skipPosKey
  
  size = ftell f
  toEnd = (2048 - (mod size 2048)) as integer
  for i = 1 to toEnd do writebyte f 0
  fseek f 4 #seek_set
  writelong f (size - 8) #unsigned
  
  fclose f
 ) -- if f
 ) -- if fname					 
) -- go

on APP pressed do ------------------------------------------------------ APPEND
if asubs.count>0 do (                             
 fname = getSaveFileName caption:"append to file" \
                         types:"GTA animation (*.ifp)|*.ifp|"
 if fname != undefined do (
  f = fopen fname "rb+"
  if f == undefined then messageBox "export error"
  else (
  fseek f 4 #seek_set
  DataSize = readlong f #unsigned
  fseek f 32 #seek_set
  Nanims = readLong f #unsigned
  fseek f -4 #seek_cur
  writeLong f (Nanims + 1) #unsigned -- anims
  fseek f (DataSize + 8) #seek_set
  
  writeSection f obj asubs exc skipPosKey
  
  size = ftell f
  toEnd = (2048 - (mod size 2048)) as integer
  for i = 1 to toEnd do writebyte f 0
  fseek f 4 #seek_set
  writelong f (size - 8) #unsigned
  
  fclose f
 ) -- if f
 ) -- if fname					 
) -- append

) -- roll

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

try (closeRolloutFloater anim_flo) catch () 
anim_flo = newRolloutFloater "anim export" 160 260 20 130 
addRollout  anim_rol anim_flo