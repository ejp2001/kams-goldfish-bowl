rollout Lode_ANPK "ANPK animation" 
(
local Nanims = undefined
local FAnimName = undefined
local fanpk = undefined
local LodCheck = undefined
local O_Name = #() 
local N_Ofs_obj = #()
local AnimName = #()
local N_objAnim = #()
local EndAn = #()
local BonCheck = undefined

	button Loadbtn "Load IFP" width:120
	label lbl1 "Anim. File:" align:#left
	label lbl2 "Total Animation:" align:#left
	label lbl3 "Internal Name:" align:#left
	listBox mAnimList selection:1  height:6

	button ReOrg "M" width:23 align:#left tooltip:"Record Original Pose of selected object" across:3
	button ApAnim "Apply Animation" width:92 align:#center toolTip:"Apply Animation" 
	button ResetP "R" width:23 align:#right tooltip:"Reset Pose to original"

	group "Batch Import Animation"(
		spinner astart "Start" fieldwidth:30 type:#integer range:[0,10000,0] across:2
		spinner aend "End" fieldwidth:30 type:#integer range:[0,10000,0]
		button batAnim "Batch Animation" width:122 align:#center tooltip:"Only Selected objects with SAME Name in the animation will be applied"
	)	
	group "Export Animation" (
	    listBox parentList selection:1  height:4 
		button chParent "Check Parent" width:102 tooltip:"Actor or Object Animation" align:#center offset:[0,5] 
	    editText addTextAnim "Anim. Name" text:"" LabelOnTop:true align:#center width:148 height:18 offset:[0,5]
		button cObjs "Create new anim" width:102 toolTip:"Save Animation to new file" align:#center offset:[0,1] enabled:false
		button addObj "Add Animation" width:102 toolTip:"Add Animation to file" align:#center offset:[0,1] enabled:false
		button RobjAnim "Replace" width:102 tooltip:"Replace selected Animation" align:#center offset:[0,1] enabled:false 
			
	)
	progressbar anim_create color:red
---------------------------------------------------///	
fn Ceck_kayEmpty Obj = ( 
 for i=1 to Obj.count do (   
	slidertime = animationRange.start 
	n = Obj[i].rotation.controller.keys.count  
	if n == 0 then (   
		addNewKey Obj[i].rotation.controller animationRange.start 
		addNewKey Obj[i].pos.controller animationRange.start 
		slidertime = animationRange.end 
		addNewKey Obj[i].rotation.controller animationRange.end 
		addNewKey Obj[i].pos.controller animationRange.end 
	)
 )
 slidertime = animationRange.start 
)
---------------------------------------------------///
fn Btn_enabled enabl =
(
 cObjs.enabled = enabl
 addObj.enabled = enabl
 RobjAnim.enabled = enabl
)
---------------------------------------------------///
fn Obj_pts Obj_Ch =   
( 
local Obj_pt 
  while Obj_Ch.parent != undefined do  
  (  
    Obj_pt = Obj_Ch.parent 
    Obj_Ch = Obj_pt  
	--format "Obj_pt=%\n" Obj_pt.name 
  ) 
Obj_pt   
)  
------------------------------------------------///

fn uppercase instring = ( 
local upper, lower, outstring 
  upper="ABCDEFGHIJKLMNOPQRSTUVWXYZ" 
  lower="abcdefghijklmnopqrstuvwxyz"
  outstring=copy instring
	for i=1 to outstring.count do ( 
		j=findString lower outstring[i]
		if (j != undefined) do outstring[i]=upper[j]
	)
  outstring 
) -- end of fn uppercase
--------------------------------------------------------
fn writeStringZero f str N = (
local i, len
 writeString f str
 len = str.count
 if len<N do 
  for i = 1 to (N-len-1) do writeByte f 0x0 #unsigned
  N - len 
)
----------------------------------------------
fn writeNameAnim f str = (
local len, N, ND

writeString f str
len = str.count
N = Len +1
ND = N 
 while ND != 1.0 do ( 
    ND  = N 
    if N == 12 then ND = 1.0
    else (
         while ND > 1.0 do ND = ND/2.0 
         if ND != 1.0 then (
             writeByte f 0x0 #unsigned
             N += 1 
	  )--if ND !=
    )--if N == 12
 )--while ND !
)

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
-------------------------------------------------------------///

fn loadIFP f = (
	AnimT = readlong f #unsigned --ANPK 
	if not AnimT == 0x4B504E41 then (
	    LodCheck = False
	    format "Not ANPK format\n"
     ) 
	else
	(
	fseek f 4 #seek_set  
	DataSize = readlong f #unsigned  
	fseek f 12 #seek_set
	HeaderL = readlong f #unsigned  
	fseek f 16 #seek_set  
	Nanims = readLong f #unsigned   
	fseek f 20 #seek_set  
	FAnimName = ReadString f  
	fseek f HeaderL #seek_set  
	HiHeaderL = HeaderL 
	nnName = readlong f #unsigned 
	while nnName != 0x454D414E do (  
		HiHeaderL +=1 
		fseek f HiHeaderL #seek_set  
		nnName = readlong f #unsigned 
	)
	for i=1 to Nanims do ( 
	  O_Name[i] = HiHeaderL  
	  HiHeaderL +=4 
	  fseek f HiHeaderL #seek_set  
	  aNameL = readlong f #unsigned 
	  HiHeaderL +=4 
	  fseek f HiHeaderL #seek_set 
	  AnimName[i] = ReadString f 
	
	  HiHeaderL +=aNameL 
	  fseek f HiHeaderL #seek_set 
	  nDGAN = readlong f #unsigned 
	    while nDGAN != 0x4E414744 do (  
		      HiHeaderL +=1 
		      fseek f HiHeaderL #seek_set  
		      nDGAN = readlong f #unsigned 
	     )
	  HiHeaderL +=4 
	  fseek f HiHeaderL #seek_set 
	  endanimation = readlong f #unsigned 
	  OHeaderL = HiHeaderL + 12
	  fseek f OHeaderL #seek_set 
	  N_objAnim[i] = readlong f #unsigned 
	  OHeaderL += 8
	  N_Ofs_obj[i] = OHeaderL 
	  HiHeaderL += endanimation + 4 
	  EndAn[i] = HiHeaderL
	  fseek f HiHeaderL #seek_set 
	 -- format "AnimName= %\n" AnimName[i] 
	 -- format "N_objAnim= %\n" N_objAnim[i]
	 -- format "N_Ofs_obj= %\n" N_Ofs_obj[i]
	  LodCheck = true
	  )
	)
) -- loadIFP
--------------------------------------------------////

fn ApActorAnim f N_Ofs N_obj Ttime= (
local  Bon_ID = #() 
local  objNam, Nframes, nnam 
local animR = 0.0
local nameAppend
  for i=1 to selection.count do (
	Bon_ID[i] = (getUserProp selection[i] "BoneID")
	if (selection[i].name == " HeadNub") or (selection[i].name == " L Finger0Nub") then Bon_ID[i] = -1
    if (selection[i].name == " R Finger0Nub") or (selection[i].name == " L Toe0Nub") then Bon_ID[i] = -1
    if (selection[i].name == " R Toe0Nub") then Bon_ID[i] = -1
)
for i=1 to selection.count do (
    if selection[i].name == "Normal" then ( 
	selection[i].name = "root"
    exit
	)
)
for i=1 to N_obj do (
  N_Ofs += 4
  fseek f N_Ofs #seek_set
  objEndofs = readlong f #unsigned
  N_Ofs += 4
  objEndofss = objEndofs + N_Ofs
  N_Ofs += 8
  fseek f N_Ofs #seek_set
  NameObj = ReadString f 
  N_Ofs += 28
  fseek f N_Ofs #seek_set
  Nframes = readlong f #unsigned
  N_Ofs += 12
  fseek f N_Ofs #seek_set
  IDBon = readlong f #unsigned
  N_Ofs += 4
  fseek f N_Ofs #seek_set
  nameAppend = false
  For i=1 to selection.count do (
      local nnam = uppercase(trimLeft (selection[i].name))
      If (nnam == uppercase(trimLeft(NameObj))) and (IDBon == Bon_ID[i]) then (
          objNam = selection[i]
          nameAppend = true
          exit
       ) 
  )
  if nameAppend == true then (
   KRTs = readlong f #unsigned  
   N_Ofs += 8 
   fseek f N_Ofs #seek_set 
	case KRTs of (
		 0x3030524B: (cln = 5; TypeStr = "KROO")
		 0x3054524B: (cln = 8; TypeStr = "KRTO")
		 0x5354524B: (cln = 11; TypeStr = "KRTS")
	)--end case
    for j=1 to Nframes do (
        rx = readfloat f; ry = readfloat f; rz = readfloat f; rw = readfloat f
										
		case KRTs of (
			 0x3030524B: ( -- KR00
				            t = readfloat f
							t *= 30.0
							t += Ttime
						 )
			 0x3054524B: ( -- KRT0
							px = readfloat f; py = readfloat f; pz = readfloat f
							t = readfloat f
							t *= 30.0
							t += Ttime
						 )
			 0x5354524B: ( -- KRTS
							px = readfloat f; py = readfloat f; pz = readfloat f
							sx = readfloat f; sy = readfloat f; sz = readfloat f
							t = readfloat f
							t *= 30.0
							t += Ttime
						 )
		)--end case
 			animate on
			 at time t 
			 (
				in coordsys parent objNam.rotation.controller.value = (quat rx ry rz rw)
				if cln > 5 then in coordsys parent objNam.position = [px,py,pz]
				if cln > 8 then in coordsys parent objNam.scale = [sx,sy,sz]
--				format " % % % %" rx ry rz rw 
--				if cln > 5 then format " % % %" px py pz
--				if cln > 8 then format " % % %" sx sy sz
--               format "t=% %\n" t objNam
			 ) --
		   animationRange = interval 0 (t + 1)
		   if animR < t then animR = t 
	)--for
	
	fseek f objEndofss #seek_set
   N_Ofs = objEndofss

  ) else (
  fseek f objEndofss #seek_set
  N_Ofs = objEndofss
  )
 anim_create.value = 100.*i/selection.count
)
if animR > 0.0 then animationRange = interval 0 animR

) --ApActorAnim
---------------------------------------------------///

fn ApObjAnim f N_Ofs N_obj Ttime= (
local  Bon_ID = #() 
local animR = 0.0
local  objNam, Nframes, nnam 
local nameAppend
  for i=1 to selection.count do (
	Bon_ID[i] = (getUserProp selection[i] "BoneID")
	   if Bon_ID[i]==undefined then Bon_ID[i] = -1
)
for i=1 to N_obj do (
  N_Ofs += 4
  fseek f N_Ofs #seek_set
  objEndofs = readlong f #unsigned
  N_Ofs += 4
  objEndofss = objEndofs + N_Ofs
  N_Ofs += 8
  fseek f N_Ofs #seek_set
  NameObj = ReadString f 
  N_Ofs += 28
  fseek f N_Ofs #seek_set
  Nframes = readlong f #unsigned
  N_Ofs += 12
  fseek f N_Ofs #seek_set
  IDBon = readlong f #unsigned
  N_Ofs += 4
  fseek f N_Ofs #seek_set
  nameAppend = false
  For i=1 to selection.count do (
  local nnam = uppercase(trimLeft(selection[i].name))
  If (nnam == uppercase(trimLeft(NameObj))) then ( 
   objNam = selection[i]
   nameAppend = true
   exit
   ) 
  )
  if nameAppend == true then (
   KRTs = readlong f #unsigned  
   N_Ofs += 8 
   fseek f N_Ofs #seek_set 
	case KRTs of (
		 0x3030524B: (cln = 5; TypeStr = "KROO")
		 0x3054524B: (cln = 8; TypeStr = "KRTO")
		 0x5354524B: (cln = 11; TypeStr = "KRTS")
	)--end case
    for j=1 to Nframes do ( 
        rx = readfloat f; ry = readfloat f; rz = readfloat f; rw = readfloat f 
										
		case KRTs of ( 
			 0x3030524B: ( -- KR00 
				            t = readfloat f 
							t *= 30.0 
							t += Ttime
						 ) 
			 0x3054524B: ( -- KRT0 
							px = readfloat f; py = readfloat f; pz = readfloat f 
							t = readfloat f 
							t *= 30.0 
							t += Ttime
						 )
			 0x5354524B: ( -- KRTS 
							px = readfloat f; py = readfloat f; pz = readfloat f 
							sx = readfloat f; sy = readfloat f; sz = readfloat f 
							t = readfloat f 
							t *= 30.0 
							t += Ttime
						 ) 
		)--end case 
			animate on 
			 at time t  
			 (
				 in coordsys parent objNam.rotation.controller.value = (quat rx ry rz rw)
				 if cln > 5 then in coordsys parent objNam.position = [px,py,pz]
				 if cln > 8 then in coordsys parent objNam.scale = [sx,sy,sz]
--				 format " % % % %" rx ry rz rw 
--				 if cln > 5 then format " % % %" px py pz
--				 if cln > 8 then format " % % %" sx sy sz
--                 format " %\n" t 
			 ) --
            animationRange = interval 0 (t + 1) 
			if animR < t then animR = t 
	)--for

	fseek f objEndofss #seek_set
   N_Ofs = objEndofss

  ) else (
  fseek f objEndofss #seek_set
  N_Ofs = objEndofss
  )
 anim_create.value = 100.*i/selection.count

)
if animR > 0.0 then animationRange = interval 0 animR
) --ApObjAnim
-------------------------------------------------------------------------------------------------------

fn writeANOData f Aname = (
local objec1 = #() --, objec = #()
for i = 1 to selection.count do objec1[i] = selection[i]
writeLong f 0x454D414E --NAME
writeLong f (Aname.count + 1)
writeNameAnim f Aname
writeLong f 0x4E414744 --DGAN
ofAnim = ftell f
writeLong f 0 -- sise anim
writeLong f 0x4F464E49 --INFO
writeLong f 0x08 --- Offset to first object (usually 0x08)
writeLong f objec1.count
writeLong f 0x562F6570 --pe/V -- NULL
	 for i = 1 to objec1.count do (
        local KRTs 	 
 	    local n=objec1[i].rotation.controller.keys.count
		writeLong f 0x4E415043 --CPAN
		OffsetOBJ = ftell f
		writeLong f 0 -- OffsetOBJ
		writeLong f 0x4D494E41 --ANIM
		writeLong f 0x0000002C --0x2C
		writeStringZero f objec1[i].name 28 
		writeLong f n --0 -- Nkey
		writeLong f 0 -- NILL
		if i == 1 then writeLong f (TicksPerFrame * animationRange.end) --writeLong f  (n - 1) 
		else writeLong f 0  -- Next sibling
		writeByte f 0xFF -- Previous sibling
		writeByte f 0xFF 
		writeByte f 0xFF  
		writeByte f 0xFF
		    if objec1[i].position.controller.keys.count > 0 then ( 
			    writeLong f 0x3054524B --KRT0 
			    KRTs = 1
		    )else ( --sKRT = 0x3054524B --"KRT0" 
                writeLong f 0x3030524B --KR00    
			    KRTs = 0  
            ) --sKRT = 0x3030524B --KR00    
		    endFrame = ftell f  
		    writeLong f 0 --endFrame 
		   -- format "%\n" objec1[i].name  
			for j = 1 to n do  (  
				    local tm=objec1[i].rotation.controller.keys[j].time 
				    if i == 1 then (  
				        r = at time tm (objec1[i].transform as quat) 
				        if KRTs == 1 then p = at time tm objec1[i].pos 
				    ) else ( 
				        r = at time tm ((objec1[i].transform * (inverse objec1[i].parent.transform)) as quat) 
				        if KRTs == 1 then p = at time tm (objec1[i].pos * (inverse objec1[i].parent.transform)) 
				    ) -- else 
				    WriteFloat f (r.x)  
				    WriteFloat f (r.y) 
				    WriteFloat f (r.z)
				    WriteFloat f (r.w) 
				    if KRTs == 1 then ( 
				        WriteFloat f (p.x)		 
				        WriteFloat f (p.y) 
				        WriteFloat f (p.z)
				    )
				    WriteFloat f ((tm.frame as float)/30.0) 
			) -- for j
		osize = ftell f 
		fseek f OffsetOBJ #seek_set
		writelong f (osize - (OffsetOBJ + 4))  ---#unsigned
		fseek f endFrame #seek_set
		writelong f (osize - (endFrame + 4))  ---#unsigned
		fseek f osize #seek_set 
        anim_create.value = 100.*i/objec1.count
	  )
asize = ftell f 
fseek f ofAnim #seek_set
writelong f (asize - (ofAnim + 4))  ---#unsigned
fseek f asize #seek_set 

) 
-------------------------------------------------------------------------------------------------------

fn writeActorAnim  f Aname= (
Local BonObj = #(), BonName = #(), Bon_ID = #()
local ofAnim, OffsetOBJ, endFrame, osize, asize
    for i=1 to selection.count do BonObj[i] = selection[i]
	for i=1 to BonObj.count do (
	    if BonObj[i].name == "Normal" then BonName[i] = "root"
	    else BonName[i] = BonObj[i].name
	    Bon_ID[i] = (getUserProp selection[i] "BoneID") 
	    if (selection[i].name == " HeadNub") or (selection[i].name == " L Finger0Nub") then Bon_ID[i] = -1
	    if (selection[i].name == " R Finger0Nub") or (selection[i].name == " L Toe0Nub") then Bon_ID[i] = -1
	    if (selection[i].name == " R Toe0Nub") then Bon_ID[i] = -1
	   -- format "% BoneID= %\n" BonName[i] Bon_ID[i]
	)
   writeLong f 0x454D414E --NAME
   writeLong f (Aname.count + 1)
   writeNameAnim f Aname
   writeLong f 0x4E414744 --DGAN
   ofAnim = ftell f
   writeLong f 0 -- sise anim
   writeLong f 0x4F464E49 --INFO
   writeLong f 0x08 --- Offset to first object (usually 0x08)
   writeLong f BonObj.count
   writeLong f 0x562F6570 --pe/V -- NULL
    for i = 1 to BonObj.count do (
        local KRTs 	 
	    local n=BonObj[i].rotation.controller.keys.count
	    writeLong f 0x4E415043 --CPAN 
	    OffsetOBJ = ftell f 
	    writeLong f 0 -- OffsetOBJ 
	    writeLong f 0x4D494E41 --ANIM 
	    writeLong f 0x0000002C --0x2C 
	    writeStringZero f BonName[i] 28  
	    writeLong f n --0 -- Nkey 
	    writeLong f 0 -- NILL
	    writeLong f (n - 1) -- Next sibling
	    writeLong f Bon_ID[i] -- Previous sibling
		    if BonObj[i].position.controller.keys.count > 0 then (
			    writeLong f 0x3054524B --KRT0
			    KRTs = 1
		    )else ( --sKRT = 0x3054524B --"KRT0"
                writeLong f 0x3030524B --KR00   
			    KRTs = 0 
            ) --sKRT = 0x3030524B --KR00  
		     endFrame = ftell f 
		     writeLong f 0 --endFrame
		    -- format "%\n" BonName[i] 
			for j = 1 to n do  ( 
				local tm=BonObj[i].rotation.controller.keys[j].time
				if Bon_ID[i] == 0 then ( 
				   r = at time tm (BonObj[i].transform as quat)
				   if KRTs == 1 then p = at time tm BonObj[i].pos
				) else (
				   r = at time tm ((BonObj[i].transform * (inverse BonObj[i].parent.transform)) as quat)
				   if KRTs == 1 then p = at time tm (BonObj[i].pos * (inverse BonObj[i].parent.transform))
				) -- else
				    WriteFloat f (r.x)
				    WriteFloat f (r.y)
				    WriteFloat f (r.z)
				    WriteFloat f (r.w) 
				    if KRTs == 1 then (
				        WriteFloat f (p.x)		 
				        WriteFloat f (p.y) 
				        WriteFloat f (p.z)
				    )
				    WriteFloat f ((tm.frame as float)/30.0)
			) -- for j	
	osize = ftell f 
	fseek f OffsetOBJ #seek_set
	writelong f (osize - (OffsetOBJ + 4))  ---#unsigned
	fseek f endFrame #seek_set
	writelong f (osize - (endFrame + 4))  ---#unsigned
	fseek f osize #seek_set 
    anim_create.value = 100.*i/BonObj.count
    )
  asize = ftell f 
  fseek f ofAnim #seek_set
  writelong f (asize - (ofAnim + 4))  ---#unsigned
  fseek f asize #seek_set 

) --writeActorAnim
----------------------------------------------------------///
on chParent pressed do 
(
 local objec = #(), objec1 = #()
 parentList.items = objec1
 if $selection.count >0 then 
 (
        local check = true
        local SC = selection.count
        local Obj_pt = undefined
         while check == true do
         ( 
           if SC > 0 then 
           (
             Obj_pt=Obj_pts selection[SC]
             if Obj_pt != undefined then check = false 
             else  SC -= 1
           )
           else check = false
           )
     if Obj_pt == undefined then format "Not parent on selection % %\n" selection[selection.count].name selection.count
     else 
     ( 
      objec = getSubs Obj_pt 
      deselect selection  
      if (uppercase(Obj_pt.name)) != "SKIN_MESH" then select Obj_pt
      for i=1 to objec.count do selectmore objec[i]  
	  objec = #()
      for i=1 to selection.count do append objec1 selection[i].name
	  if (getUserProp selection[1] "SPunknown") == undefined then 
	  (
	    parentList.items = objec1
        parentList.selection = 1   
		parentList.enabled = true 
		Btn_enabled true
		BonCheck = false
	  )else(
	     parentList.items = objec1
         parentList.selection = 1 
		 parentList.enabled = false
	     Btn_enabled true
		 BonCheck = true
	  )
    --  if (uppercase(selection[1].name) == "ROOT") or (uppercase(selection[1].name) == "NORMAL" ) then 
      --(
	  --   parentList.items = objec1
      --   parentList.selection = 1 
	--	 parentList.enabled = false
	--     Btn_enabled true
		 --BonCheck = true
	--	 if (getUserProp selection[1] "SPunknown") == undefined then BonCheck = false 
	--	 else BonCheck = true
		 
    --  )else(
    --     parentList.items = objec1
      --   parentList.selection = 1   
	--	 parentList.enabled = true 
	--	 Btn_enabled true
	--	 BonCheck = false
	 -- )	
     ) 
 )
)
---------------------------------------------------------///
on Loadbtn pressed do (
fanpk  = getOpenFileName caption:"Load file animation" \
                         types:"GTA animation (*.ifp)|*.ifp|"
if fanpk != undefined do (  
    f = fopen fanpk "rb" 
          if f == undefined then messageBox "export error" 
          else (
		  ClearListener ()
          AnimName = #() 
          O_Name = #() 
          mAnimList.items = AnimName  
          loadIFP f
		   if (LodCheck == true) then (
		      lbl1.text = "Anim. File: " + (filenameFromPath fanpk) 
              lbl2.text = "Total Animation: " + (Nanims as string) 
              lbl3.text = "Internal Name: " + FAnimName
              mAnimList.items = AnimName 
		      mAnimList.selection = 1
			  astart.value = 1
			  aend.value = Nanims
		   )
     fclose f   
     gc()
   )
  )	
) -- on Loadbtn pressed
-----------------------------------------------------------------///
on ResetP pressed do (
sliderTime = 0
for i = 1 to $selection.count do (
	deletekeys $selection[i].pos.controller
	deletekeys $selection[i].rotation.controller
	deletekeys $selection[i].scale.controller
	try (
		tp = readvalue ((getUserProp $selection[i] "OrgRot") as stringstream)
		tpW = getUserProp $selection[i] "OrgRotW"
		$selection[i].rotation = (quat tp.x tp.y tp.z tpW)
		$selection[i].scale	= readvalue ((getUserProp $selection[i] "Orgscl") as stringstream)
		$selection[i].pos	= readvalue ((getUserProp $selection[i] "OrgPos") as stringstream)
	) catch (ReOrg.text = "M")
)--end for i	
)

-----------------------------------------------------------------///
on ReOrg pressed do (
OrginAry = #()
for i = 1 to $selection.count do (
	setUserProp $selection[i] "OrgPos" $selection[i].pos
	setUserProp $selection[i] "OrgRot" [$selection[i].rotation.x,$selection[i].rotation.y,$selection[i].rotation.z]
	setUserProp $selection[i] "OrgRotW" $selection[i].rotation.w
	setUserProp $selection[i] "Orgscl" $selection[i].scale
)	
ReOrg.text = "W"
)
-----------------------------------------------------------------///
on ApAnim pressed do ( 
local BonCh
ApAnim.enabled = false
   if (mAnimList.selection > 0)AND($selection.count >0) then (
        local check = true
        local SC = selection.count
        local Obj_pt = undefined
         while check == true do
         ( 
           if SC > 0 then 
           (
             Obj_pt=Obj_pts selection[SC]
             if Obj_pt != undefined then check = false 
             else  SC -= 1
           )
           else check = false
           )

      if Obj_pt == undefined then format "Not parent on selection % %\n" selection[selection.count].name selection.count
      else 
      ( 
	    local objec = #()
        objec = getSubs Obj_pt 
        deselect selection  
        if (uppercase(Obj_pt.name)) != "SKIN_MESH" then select Obj_pt
        for i=1 to objec.count do selectmore objec[i]   
	    objec = #()
        for i=1 to selection.count do append objec selection[i]
	    deselect selection 
        for i=1 to objec.count do selectmore objec[i] 

    --    if (uppercase(selection[1].name) == "ROOT") or (uppercase(selection[1].name) == "NORMAL" ) then 
	--	(
         if (getUserProp selection[1] "SPunknown") == undefined then BonCh = false 
		 else BonCh = true
		
      --  ) else (
      --       BonCh = false
		--)	
       format "\nAnime: % at [%]\n" selection[1].name BonCh 
	   if fanpk != undefined do (  
	      f = fopen fanpk "rb"  
		  if f == undefined then messageBox "export error"  
		  else ( 
		     sliderTime = 0
		    -- ClearListener ()
		     fseek f N_Ofs_obj[mAnimList.selection] #seek_set 
		     format "\nAnime: % at [%]\n" mAnimList.selected (ftell f)
		             if BonCh == true then (
		               -- format "Actor Anim BonCheck=% selection.count=%\n" BonCh selection.count
		                ApActorAnim f N_Ofs_obj[mAnimList.selection] N_objAnim[mAnimList.selection] sliderTime
		             )else(
		               -- format "OBJ Anim BonCheck=% selection.count=%\n" BonCh selection.count
		                ApObjAnim f N_Ofs_obj[mAnimList.selection] N_objAnim[mAnimList.selection] sliderTime
		             )
			 fclose f 
			 anim_create.value = 0 
		   ) -- if f 
	    ) -- if fanpk 
     ) --Obj_pt =
   ) --if (AnimList.selection	
ApAnim.enabled = true
) --on apyAnim pressed		
----------------------------------------------------------------///

on addObj pressed do (
local objec = #()
 if $selection.count >0 then (
    for obj in $selection where (getUserProp obj "FrameName") == "Skin_Mesh" do deselect obj
	if parentList.selection > 0 then
    (
	   if ($selection.count >0) then ( 
		  if (addTextAnim.text != "")and (addTextAnim.text.count > 4) then (   
		             ANIMname = trimright addTextAnim.text   
			         ANIMname1 = trimLeft ANIMname  
					 ANIMname2 = uppercase (ANIMname1) 
					 check = false 
			          for I = 1 to Nanims do ( 
			            if ANIMname2 == uppercase (mAnimList.items[I]) then (  
				        check = true 
				        exit
				        )--if
			          )--for
		  if check == false then (  
			  n = selection[1].rotation.controller.keys.count  
			  if n != 0 then ( 
			     ClearListener ()			  
				   ANIMname = trimright addTextAnim.text
					ANIMname1 = trimLeft ANIMname
					format "Create ANPK\n\n"
					if fanpk != undefined do ( 
					  f = fopen fanpk "rb+"
			          if f == undefined then messageBox "export error"
			          else (
			             AnimT = readlong f #unsigned
					     if AnimT == 0x4B504E41 then (
						    fseek f 4 #seek_set
						    DataSize = readlong f #unsigned
						    fseek f 16 #seek_set
						    Nanims = readLong f #unsigned
						    fseek f -4 #seek_cur
						    writeLong f (Nanims + 1) #unsigned -- anims
						    fseek f (DataSize + 8) #seek_set
				            if BonCheck == true then (
					            Ceck_kayEmpty ($selection as array)		    
		                       -- format "Actor Anim BonCheck=% selection.count=%\n" BonCheck selection.count
					            writeActorAnim f ANIMname1
		                    )else( 
		                         Obj_pt = getNodeByName parentList.selected
								 if Obj_pt != selection[1] then 
								 (
							       deselect selection 								 
		                           select Obj_pt
		                           objec = getSubs Obj_pt
		                           For i= 1 to objec.count do selectmore objec[i] 
                                 ) 
		                        -- format "Actor Anim BonCheck=% selection.count=%\n" BonCheck selection.count
					             Ceck_kayEmpty ($selection as array)						 
		                         writeANOData f ANIMname1
		                    )  
						    size = ftell f
						    toEnd = (2048 - (mod size 2048)) as integer
						    for i = 1 to toEnd do writebyte f 0
						    fseek f 4 #seek_set
						    writelong f (size - 8) #unsigned
					        format "Created ANPK\n\n"
					        Btn_enabled false	
							objec = #()
                            parentList.items = objec					
						)	--if AnimT
					  ) -- else if f == undefined  
					  fclose f
			        if fanpk != undefined do (  
					  f = fopen fanpk "rb" 
			          if f == undefined then messageBox "export error" 
			          else ( 
			  		       AnimName = #() 
			               O_Name = #() 
			               mAnimList.items = AnimName 
			               loadIFP f
			                  if (LodCheck == true) then (
					              lbl1.text = "Anim. File: " + (filenameFromPath fanpk) 
			                      lbl2.text = "Total Animation: " + (Nanims as string) 
			                      lbl3.text = "Internal Name: " + FAnimName
			                      mAnimList.items = AnimName 
					              mAnimList.selection = Nanims --1
						  		  astart.value = 1
			                      aend.value = Nanims
					          )
					  anim_create.value = 0
			 		  fclose f   
					  gc()
			          )
			       )						  
			    ) --if fanpk != undefined do			 
			  ) -- if n != 0 
		    ) --if check == false 
		  ) -- if (addTextAnim.text != "")
	    ) -- if (mAnimList.selection > 0)AND($selection.count >0)
    ) -- parentList.selection > 0 	 
  ) -- if selection.count > 0
) --addObj
-----------------------------------------------------------------------------------------///
on cObjs pressed do (
local objec = #()
if $selection.count >0 then ( 
   for obj in $selection where (getUserProp obj "FrameName") == "Skin_Mesh" do deselect obj
   if parentList.selection > 0 then 
   (
	   if (selection.count > 0) and (addTextAnim.text != "")and (addTextAnim.text.count > 4) then ( 
		  n = selection[1].rotation.controller.keys.count  
		 if n != 0 then (  
		    fanpk = getSaveFileName caption:"export animation" \
		                           types:"GTA animation (*.ifp)|*.ifp|"
		   if fanpk != undefined do (
		      f = fopen fanpk "wb"
			  if f == undefined then messageBox "export error"
			  else (
			     ClearListener ()
			     aname = getFilenameFile fanpk
				  if aname.count > 7 then
				  (
					  local my_str_msg = "Can't save animation \"" + aname + "\"!\nThe name can't be longer than 7 characters!"
					  messageBox my_str_msg title:"ERROR"
				  )
				  else
				  (
					 ARCname = uppercase(aname)  
					 StEdit = ARCname.count 
					 StEdit1 = StEdit + 5 
					 if (StEdit > 4) and (8 > StEdit) then ( 
						ANIMname = trimright addTextAnim.text
						ANIMname1 = trimLeft ANIMname
						format "Create ANPK\n\n"
						writeLong f 0x4B504E41		--ANPK
						writeLong f 0              -- sise
						writeLong f 0x4F464E49		--INFO
						writeLong f StEdit1        --20
						writeLong f 1            --n anim
						writeNameAnim f ARCname
						format "------///% %\n" ARCname StEdit1
							if BonCheck == true then (
								  Ceck_kayEmpty ($selection as array)
								  --format "Actor Anim BonCheck=% selection.count=%\n" BonCheck selection.count
								  writeActorAnim f ANIMname1 
							 )else( 
									 Obj_pt = getNodeByName parentList.selected
									 if Obj_pt != selection[1] then 
									 (
									   deselect selection 								 
									   select Obj_pt
									   objec = getSubs Obj_pt
									   For i= 1 to objec.count do selectmore objec[i] 
									 )						       
								  --  format "OBJ Anim BonCheck=% selection.count=%\n" BonCheck selection.count
									Ceck_kayEmpty ($selection as array)
									writeANOData f ANIMname1  
							 ) 
						  size = ftell f 
						  toEnd = (2048 - (mod size 2048)) as integer
						  for i = 1 to toEnd do writebyte f 0
						  fseek f 4 #seek_set
						  writelong f (size - 8) #unsigned
						  format "Created ANPK\n\n"
						  Btn_enabled false
						  objec = #()
						  parentList.items = objec
					  ) --  if StEdit  
					  fclose f
					  if fanpk != undefined do (  
						 f = fopen fanpk "rb" 
						 if f == undefined then messageBox "export error" 
						   else ( 
							   AnimName = #() 
							   O_Name = #() 
							   mAnimList.items = AnimName 
							   loadIFP f
							   if (LodCheck == true) then (
								  lbl1.text = "Anim. File: " + (filenameFromPath fanpk) 
								  lbl2.text = "Total Animation: " + (Nanims as string) 
								  lbl3.text = "Internal Name: " + FAnimName
								  mAnimList.items = AnimName 
								  astart.value = 1
								  aend.value = Nanims							  
								  mAnimList.selection = Nanims --1
								)
							  anim_create.value = 0
							 fclose f   
							 gc()
						  )
					  )	
				  )					  
			   ) -- if f
		    ) -- if fanpk
		  ) -- if n != 0
	    ) -- if (selection.count > 0) and (addTextAnim.text != "")
    ) -- parentList.selection > 0 
  ) --if $selection.count >0 then 
) --cObjs 
---------------------------------------------------------------------//
on RobjAnim pressed do (
local objec = #()
if (mAnimList.selection != 0) AND ($selection.count >0) then ( 
  for obj in $selection where (getUserProp obj "FrameName") == "Skin_Mesh" do deselect obj
  if parentList.selection > 0 then
  (
	   if $selection.count >0 then (
	      n = selection[1].rotation.controller.keys.count    
	      if n != 0 then (  
		   if fanpk != undefined do (  
		      ffanpk = (getFilenamePath fanpk) + "ttemp.bin" 
		      ff = fopen ffanpk "wb" 
		      f = fopen fanpk "rb"  
		    if f == undefined then ( 
			   fclose f   
			   fclose ff  
			   deleteFile ffanpk 
		       messageBox "export error"
		    )else(
			  AnimT = readlong f #unsigned
		 	  if AnimT != 0x4B504E41 then ( 
			     fclose f  
			     fclose ff  
			     deleteFile ffanpk 
		         messageBox "Not ANPK error" 
		      ) else (	
			     ClearListener ()	
		  		fseek f 4 #seek_set
		  		DataSize = readlong f #unsigned
		        fseek f 0 #seek_set
			        for i = 1 to O_Name[mAnimList.selection] do writebyte ff (readByte f)
		                    if BonCheck == true then (
					            Ceck_kayEmpty ($selection as array)		    
		                      --  format "Actor Anim BonCheck=% selection.count=%\n" BonCheck selection.count
					            writeActorAnim ff mAnimList.selected
		                    )else( 
		                         Obj_pt = getNodeByName parentList.selected
								 if Obj_pt != selection[1] then 
								 (
							       deselect selection 		 						 
		                           select Obj_pt
		                           objec = getSubs Obj_pt 
		                           For i= 1 to objec.count do selectmore objec[i]  
                                 )							
		                      --   format "Actor Anim BonCheck=% selection.count=%\n" BonCheck selection.count
					             Ceck_kayEmpty ($selection as array)						 
		                         writeANOData ff mAnimList.selected
		                    )
					      if mAnimList.selection != Nanims then ( 
						      fseek f EndAn[mAnimList.selection] #seek_set 
							  for i = EndAn[mAnimList.selection] to (DataSize + 7) do writebyte ff (readByte f) 
					       )--end if 		
 				          format "%\n" mAnimList.selected
				          size = ftell ff 
		                  toEnd = (2048 - (mod size 2048)) as integer 
		                  for i = 1 to toEnd do writebyte ff 0 
		                  fseek ff 4 #seek_set 
		                  writelong ff (size - 8) #unsigned 
		                  format "Created ANPK\n\n" 
						  objec = #()
						  parentList.items = objec
				          fclose f 
			              fclose ff
				          deleteFile fanpk
				          renameFile ffanpk fanpk
		                  if fanpk != undefined do (   
				            f = fopen fanpk "rb"  
				            if f == undefined then messageBox "export error"  
				            else (  
						        AnimName = #()  
					            O_Name = #()  
					            mAnimList.items = AnimName  
					            loadIFP f 
				                  if (LodCheck == true) then ( 
						              lbl1.text = "Anim. File: " + (filenameFromPath fanpk)  
				                      lbl2.text = "Total Animation: " + (Nanims as string)  
				                      lbl3.text = "Internal Name: " + FAnimName 
				                      mAnimList.items = AnimName  
						              mAnimList.selection = mAnimList.selection --1 
						           )
						        anim_create.value = 0 
				 		        fclose f   
						        gc()
					        )
		                 )
                   Btn_enabled false 						 
			    ) --if AnimT			
		      ) -- else if f == undefined
		    ) --if fanpk != undefined
	      ) -- if n
	    )  -- if $selection.count >0
	) --parentList.selection > 0   
  ) --if mAnimList.selection 
) --RobjAnim
---------------------------------------------------------------------//
on batAnim pressed do ( 
local BonCh
 if (mAnimList.selection > 0)AND($selection.count >0) then (
	 sliderTime = 0
		if (getUserProp $selection[1] "OrgPos") == undefined then (
				for i = 1 to $selection.count do (
					setUserProp $selection[i] "OrgPos" $selection[i].pos 
					setUserProp $selection[i] "OrgRot" [$selection[i].rotation.x,$selection[i].rotation.y,$selection[i].rotation.z] 
					setUserProp $selection[i] "OrgRotW" $selection[i].rotation.w 
					setUserProp $selection[i] "Orgscl" $selection[i].scale 
				)
		)
	 -- for obj in $selection where (getUserProp obj "FrameName") == "Skin_Mesh" do deselect obj
        local check = true
        local SC = selection.count
        local Obj_pt = undefined
         while check == true do
         ( 
           if SC > 0 then 
           (
             Obj_pt=Obj_pts selection[SC]
             if Obj_pt != undefined then check = false 
             else  SC -= 1
           )
           else check = false
           )
      if Obj_pt == undefined then format "Not parent on selection % %\n" selection[selection.count].name selection.count
      else 
      ( 
	    local objec = #()
        objec = getSubs Obj_pt 
        deselect selection  
        if (uppercase(Obj_pt.name)) != "SKIN_MESH" then select Obj_pt
        for i=1 to objec.count do selectmore objec[i]   
	    objec = #()
        for i=1 to selection.count do append objec selection[i]
	    deselect selection 
        for i=1 to objec.count do selectmore objec[i] 

   --     if (uppercase(selection[1].name) == "ROOT") or (uppercase(selection[1].name) == "NORMAL" ) then 
--		( --BonCh = true
		 if (getUserProp selection[1] "SPunknown") == undefined then BonCh = false 
		 else BonCh = true
		
  --      ) else (
  --           BonCh = false
--		)
		f = fopen fanpk "rb"
		  if f != undefined then (
			for tt = astart.value to aend.value do ( 
		        fseek f N_Ofs_obj[tt] #seek_set 
		        format "\nAnime: % at [%]\n" mAnimList.selected (ftell f) 
		            if BonCh == true then (
		             --   format "Actor Anim BonCh=% selection.count=%\n" BonCh selection.count 
		                ApActorAnim f N_Ofs_obj[tt] N_objAnim[tt] sliderTime 
		             )else( 
		             --   format "OBJ Anim BonCh=% selection.count=%\n" BonCh selection.count 
		                ApObjAnim f N_Ofs_obj[tt] N_objAnim[tt] sliderTime 
		             )
				animationRange = interval 0 (animationRange.end + 3) 
				slidertime = animationRange.end 
				gc() 
			) --end for tt
			fclose f 
			animationRange = interval 0 (animationRange.end - 3) 
			anim_create.value = 0 
            slidertime = animationRange.start
			
		  ) --f != 
	   ) --Obj_pt =
	) --mAnimList.selection
)--end on batAnim

------------------------------------------//
on astart changed val do ( 
        if val < 1 then astart.value = 1
		if Nanims != undefined then (
	        if astart.value > Nanims then astart.value = Nanims
	        if astart.value > aend.value then aend.value = astart.value	
		) else astart.value = 0
)
    --
on aend changed val do (
        if val < 1 then aend.value = 1
		if Nanims != undefined then (
	        if aend.value > Nanims then aend.value = Nanims
    	    if aend.value < astart.value then astart.value = aend.value
		) else aend.value = 0
)

------------------------------------------//	
) --rollout 

rollout aboutRoll "About" ( 
	label n1 "ANPK animation Export"
	label n6 " "	
	label n2 "by yelmi" align:#left across:2 
	label n3 "http://yelmi.com/" align:#right --across:2 
	label n4 "coauthor:- DENISka" 
	label n5 "Used code GTA_IFP_IO.ms"
	label n7 "by Kam"
)

if Loder_ANPK != undefined then ( closeRolloutFloater Loder_ANPK; gc() )
Loder_ANPK = newRolloutFloater "ANPK animation" 185 595 10 5 
addRollout Lode_ANPK Loder_ANPK
addRollout aboutRoll Loder_ANPK rolledup:true

