
rollout NewIFP_and_Add "GTA SA ANP3 animation" --width:162 height:300
(
local FourCC = undefined
local Offset_END_File = undefined
local FileName = undefined
local NumberAnim = undefined
--local NeoHeader = undefined
local StartAnimOffset = #()
local LodCheck = undefined
local AnimName = #()
--local Offset_END_ANIM = #()
local fanp3 = undefined

	button loadifpR "Load IFP" width:102
	label lbl1 "" align:#left
	label lbl2 "" align:#left
	label lbl3 "" align:#left
	listbox AnimListR height:10
    
		button ReOrg "M" width:23 align:#left tooltip:"Record Original Pose of selected object" across:3
	    button ApAnim "Apply Animation" width:92 align:#center toolTip:"Apply Animation" 
	    button ResetP "R" width:23 align:#right tooltip:"Reset Pose to original"
      group "Batch Import Animation"( 
		spinner astart "Start" fieldwidth:30 type:#integer range:[0,10000,0] across:2
		spinner aend "End" fieldwidth:30 type:#integer range:[0,10000,0]
		button batAnim "Batch Animation" width:122 align:#center tooltip:"Only Selected objects with SAME Name in the animation will be applied"
	   )
	  group "Export Animation" (
	    editText addTextAnim "Anim. Name" text:"" LabelOnTop:true  align:#center width:148 height:18 offset:[0,5]
		button saveAnimR "Create new anim" width:102 toolTip:"Save Animation to new file" align:#center offset:[0,5]
        button addAnim "Add Animation" width:102 enabled:false toolTip:"Add Animation to file" align:#center offset:[0,5]
		button RepAnim "Replace" width:102 enabled:false toolTip:"Replace selected Animation" align:#center offset:[0,5]
        )

fn Get_selectionsKey_Count NumbKey = (
--Local NumbKey = 0
 for i=1 to selection.count do (
    n=selection[i].rotation.controller.keys.count
	if n > 0 then NumbKey +=1
  ) --for 
NumbKey 
)
----------------------------------//
fn WriteAnimDATA f Name_Anim = (
           local Size_frame_data = 0
           local ObjNum = #()
		   local Frame_type = #()
		   Local Bon_ID = #()
            writeString f Name_Anim
            StEdit = 23 - Name_Anim.count
			for i = 1 to StEdit do ( writeByte f 0 )
			writeLong f (Get_selectionsKey_Count 0) #unsigned -- Number of Objects
			Local J = 0
			for i=1 to selection.count do (
              n=selection[i].rotation.controller.keys.count
			  --format "n=%\n" n
	           if n > 0 then (
			     np = selection[i].pos.controller.keys.count
				 J += 1
                   if np > 0 then (
				      Size_frame_data += np * 16 
					Frame_type[J] = 4  
				    )else (
					  Size_frame_data += n * 10
					 Frame_type[J] = 3 
					)  
				 ObjNum[J] = selection[i] 
				 Bon_ID[J] = (getUserProp ObjNum[J] "BoneID")
	             --format "ObjNum=% Frame_type=%\n" ObjNum[J].name Frame_type[J]
			   ) --if n > 0
            ) --for 
            --format "Size_frame_data=%\n" Size_frame_data
            writeLong f Size_frame_data --Size of frame data
            writeLong f 1 --Unknown, always 1 
			for J=1 to ObjNum.count do ( 
			     writeString f ObjNum[J].name
                 StEdit = 23 - ObjNum[J].name.count
			     for i = 1 to StEdit do ( writeByte f 0 )
				 writeLong f Frame_type[J] #unsigned -- Frame type
				 n= ObjNum[J].rotation.controller.keys.count
				 writeLong f n #unsigned -- Number of Frames
                 writeLong f Bon_ID[J] #unsigned -- Bone ID
                 for i = 1 to n do  (
				   tm=ObjNum[J].rotation.controller.keys[i].time
				   --format "tm=%\n" tm
				      writeShort f (at time tm ((in coordsys parent ObjNum[J].rotation.x)*4096.0) as integer) #signed
                      writeShort f (at time tm ((in coordsys parent ObjNum[J].rotation.y)*4096.0) as integer) #signed
                      writeShort f (at time tm ((in coordsys parent ObjNum[J].rotation.z)*4096.0) as integer) #signed
                      writeShort f (at time tm ((in coordsys parent ObjNum[J].rotation.w)*4096.0) as integer) #signed
                      writeShort f ((tm as integer)/80) #unsigned

                     if Frame_type[J] == 4  then (
                        writeShort f (at time tm ((in coordsys parent ObjNum[J].position.x)*1024.0) as integer) #signed					 
                        writeShort f (at time tm ((in coordsys parent ObjNum[J].position.y)*1024.0) as integer) #signed
                        writeShort f (at time tm ((in coordsys parent ObjNum[J].position.z)*1024.0) as integer) #signed
                      ) -- Frame_type[J] == 4
				   

				 ) --for i = 1 to n
				 
			) --for J=1 to ObjNum[J].count do 	 

) --WriteAnimDATA
----------------------------------//
fn uppercase instring = 
( local upper, lower, outstring 
upper="ABCDEFGHIJKLMNOPQRSTUVWXYZ" 
lower="abcdefghijklmnopqrstuvwxyz"
outstring=copy instring
for i=1 to outstring.count do
( j=findString lower outstring[i]
if (j != undefined) do outstring[i]=upper[j]
)
outstring 
) -- end of fn uppercase
--------------------------------//
fn load_IFP f = (
Offset_END_ANIM = #()
AnimName = #()
StartAnimOffset = #()
FourCC = readlong f #unsigned --ANP3 
if FourCC != 0x33504E41 then (
	    LodCheck = False
	    format "Not ANP3 format\n"
     ) 
	else
	(
	  fseek f 4 #seek_set
	  Offset_END_File = readlong f #unsigned
	  fseek f 8 #seek_set
	  FileName = ReadString f
	  fseek f 32 #seek_set
	  NumberAnim = readlong f #unsigned
	  Local LocalOffset = 36
	  for i=1 to NumberAnim do (
	    StartAnimOffset[i] = LocalOffset
		--format "StartAnimOffset[%]=%\n" i StartAnimOffset[i]
	    fseek f LocalOffset #seek_set
		AnimName[i] = ReadString f
		LocalOffset += 24
		fseek f LocalOffset #seek_set
		NObj = readlong f #unsigned
        LocalOffset += 12
		fseek f LocalOffset #seek_set
          if LocalOffset < Offset_END_File then
		    (
			  local n = 0
			  while n < NObj do
			   (
			    if LocalOffset < Offset_END_File then
		         (

			    LocalOffset += 24
		        fseek f LocalOffset #seek_set
                Frametype = readlong f #unsigned 
				--format "Frametype=%\n" Frametype
				LocalOffset += 4
		        fseek f LocalOffset #seek_set
                NumberFrames = readlong f #unsigned 
				LocalOffset += 8
		        fseek f LocalOffset #seek_set
				if  Frametype == 3 then LocalOffset += (NumberFrames*10)
                if  Frametype == 4 then LocalOffset += (NumberFrames*16)
				fseek f LocalOffset #seek_set

			    n += 1
			   ) else n = NObj
			   )
			)

	  )
	  LodCheck = true
	)
)
--------------------------------------//
fn App_SA_Anim f AName ST_OFFSET sTime = (
Local Bon_ID = #()
for i=1 to selection.count do 
 ( 
   Bon_ID[i] = (getUserProp selection[i] "BoneID")
  )
local objNam
local animR = 0
Name_Anim = ReadString f
--format "Name_Anim=%\n" Name_Anim
ST_OFFSET += 24
fseek f ST_OFFSET #seek_set
NObj = readlong f #unsigned
--format "NObj=%\n" NObj
ST_OFFSET += 12
fseek f ST_OFFSET #seek_set
              local n = 0
			  while n < NObj do
			   (
			    Name_Anim = ReadString f
                --format "Name_OBJ=%\n" Name_Anim
			    ST_OFFSET += 24
                fseek f ST_OFFSET #seek_set 
				--format "[%]\n\n" (ftell f)
				Frametype = readlong f #unsigned 
				--format "Frametype=%\n" Frametype

                ST_OFFSET += 4
                fseek f ST_OFFSET #seek_set 
				NumberFrames = readlong f #unsigned 
				--format "NumberFrames=%\n" NumberFrames

				ST_OFFSET += 4
                fseek f ST_OFFSET #seek_set
                ID_Bone = readlong f #unsigned 
				--format "ID_Bone=%\n" ID_Bone

                ST_OFFSET += 4
                fseek f ST_OFFSET #seek_set
				nameAppend = false
				objNam = undefined
               
				For i=1 to selection.count do (
      	          If (ID_Bone == Bon_ID[i]) then (
                    objNam = selection[i]
                    nameAppend = true
                    exit
                   ) 
				 )
			--	 format "nameAppend=%\n" nameAppend
                 if nameAppend == true then (
                  --  format "objNam=% ID_Bone=%\n " objNam.name ID_Bone
					for j=1 to NumberFrames do (
					   rx = (ReadShort f)/ 4096.0
					   ry = (ReadShort f)/ 4096.0
                       rz = (ReadShort f)/ 4096.0
                       rw = (ReadShort f)/ 4096.0
					   t = (readShort f)/2.0 + sTime
                       t = execute ( (t as string) + "f" )
					--   format "% % % % %\n" rx ry rz rw t
					   if Frametype == 4 then (
					       px = (ReadShort f)/1024.0
                           py = (ReadShort f)/1024.0
                           pz = (ReadShort f)/1024.0
						   --format "% % %\n" px py pz
					    ) --if Frametype == 4 then 
					     animate on
			             at time t --t 
			               (
				            in coordsys parent objNam.rotation.controller.value = inverse((quat rx ry rz rw))
							if Frametype == 4 then in coordsys parent objNam.position = [px,py,pz]
	
				           )

                       if animR < t then animR = t --t 
					) --for j=1 to NumberFrames
					
				  ) --if nameAppend == true
				      
						case Frametype of (
						   3 : ST_OFFSET += (NumberFrames*10)
                           4 : ST_OFFSET += (NumberFrames*16)
						 )
                        fseek f ST_OFFSET #seek_set
				--   format "nameAppend=%\n" nameAppend


			    n += 1
			   )
            --   format "n=%\n" n
if animR > 0 then animationRange = interval 0 animR
) --fn App_SA_Anim

----------------------------------------------///

on ResetP pressed do (
if realTimePlayback = true then stopAnimation()
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
if realTimePlayback = true then stopAnimation()
OrginAry = #()
for i = 1 to $selection.count do (
	setUserProp $selection[i] "OrgPos" $selection[i].pos
	setUserProp $selection[i] "OrgRot" [$selection[i].rotation.x,$selection[i].rotation.y,$selection[i].rotation.z]
	setUserProp $selection[i] "OrgRotW" $selection[i].rotation.w
	setUserProp $selection[i] "Orgscl" $selection[i].scale
)	
ReOrg.text = "W"
)
-----------------------------------------------------------/////////

on ApAnim pressed do (
  if (AnimListR.selection > 0)AND($selection.count >0) then (
    for obj in $selection where (getUserProp obj "FrameName") == "Skin_Mesh" do deselect obj
    if fanp3 != undefined do (   
      f = fopen fanp3 "rb" 
          if f == undefined then messageBox "export error"  
          else ( 
		  ClearListener ()
          fseek f StartAnimOffset[AnimListR.selection] #seek_set 
		   format "\nAnime: % at [%]\n" AnimListR.selected (ftell f)
		   sliderTime = 0
		   App_SA_Anim f AnimListR.selected StartAnimOffset[AnimListR.selection] sliderTime

		  ) -- else if f == undefined
		  fclose f   
          gc()

	) --if fanp3 != undefined 	  
  ) --if (AnimListR.selection > 0)AND($selection.count >0)

) --ApAnim pressed

----------------------------------------//

on loadifpR pressed do (
fanp3  = getOpenFileName caption:"Load file animation" \
                         types:"GTA animation (*.ifp)|*.ifp|"
if fanp3 != undefined do (  
    f = fopen fanp3 "rb" 
          if f == undefined then messageBox "export error" 
          else (
		  ClearListener ()
          load_IFP f
		   if (LodCheck == true) then (
		      lbl1.text = "Anim. File: " + (filenameFromPath fanp3) 
              lbl2.text = "Total Animation: " + (NumberAnim as string) 
              lbl3.text = "Internal Name: " + FileName
			  AnimListR.items = AnimName 
		      AnimListR.selection = 1
			  astart.value = 1
			  aend.value = NumberAnim
           
			  )else(
			    lbl1.text = "Not ANP3 format" 
              lbl2.text = ""
              lbl3.text = " "
			  AnimName = #()
			  AnimListR.items = AnimName 
		      astart.value = 0
			  aend.value = 0
              fanp3 = undefined
			  )
			)  
			       fclose f   
     gc()
	 if addAnim.enabled == False then (
		   
		     addAnim.enabled = true
		     RepAnim.enabled = true
		   ) --if not addAnim.enabled
   )
  )
----------------------------------------------------------///////
on saveAnimR pressed do ( 
  if (addTextAnim.text != "") AND ($selection.count >0) then (
      --sKey = Get_selectionsKey_Count 0
     if (Get_selectionsKey_Count 0) > 0 then (
	 --format "sKey=%\n" (Get_selectionsKey_Count 0) --sKey
	 for obj in $selection where (getUserProp obj "BoneID") == undefined do deselect obj
	 fanp3  = getSaveFileName caption:"export animation" \
                         types:"GTA animation (*.ifp)|*.ifp|"
     if fanp3 != undefined do (  
        f = fopen fanp3 "wb" 
          if f == undefined then messageBox "export error" 
           else (
		    ClearListener ()
			ARCname = uppercase(getFilenameFile fanp3)
		    Name_Anim = trimLeft (trimright addTextAnim.text)

			writeLong f 0x33504E41		--ANP3
			writeLong f 0 --size
			writeString f ARCname
			StEdit = 23 - ARCname.count
			for i = 1 to StEdit do ( writeByte f 0 )
     		writeLong f 1 #unsigned -- anims
			
			WriteAnimDATA f Name_Anim
			
			  size = ftell f
              toEnd = (2048 - (mod size 2048)) as integer
              for i = 1 to toEnd do writebyte f 0
              fseek f 4 #seek_set
              writelong f (size - 8) #unsigned
			  fclose f 
			  
			f = fopen fanp3 "rb" 
            if f == undefined then messageBox "export error" 
            else (
              load_IFP f
		       if (LodCheck == true) then (
		          lbl1.text = "Anim. File: " + (filenameFromPath fanp3) 
                  lbl2.text = "Total Animation: " + (NumberAnim as string) 
                  lbl3.text = "Internal Name: " + FileName
			      AnimListR.items = AnimName 
		          AnimListR.selection = 1
				  astart.value = 1
			      aend.value = NumberAnim
			    )
			 )  

			
		   )  
		  fclose f   
          gc()
		  if addAnim.enabled == False then (
		   
		     addAnim.enabled = true
		     RepAnim.enabled = true
		   ) --if not addAnim.enabled	 
       )

	 ) --if sKey > 0 
  ) --if (addTextAnim.text != "") AND ($selection.count >0)
) ---------on saveAnimR pressed  
---------------------------------------------------------------//////
--addAnim

on addAnim pressed do (
 if (addTextAnim.text != "")AND($selection.count >0) then (
    if (Get_selectionsKey_Count 0) > 0 then (
	 --format "sKey=%\n" (Get_selectionsKey_Count 0) --sKey
	 	for obj in $selection where (getUserProp obj "BoneID") == undefined do deselect obj
		   Name_Anim = trimLeft (trimright addTextAnim.text)
		   --format "Name_Anim=%\n" Name_Anim	
		   NAmecheck = false
			          for I = 1 to AnimName.count - 1 do (
					    StrAnim = AnimName[I]
						 --format "StrAnim=%\n" StrAnim
			            if uppercase (Name_Anim) == uppercase (AnimName[I]) then ( 
				        NAmecheck = true
				        exit
				        )--if
			          )--for
			--format "NAmecheck=%\n" NAmecheck		  
		   if NAmecheck == false then (
		   if fanp3 != undefined do (  
		    f = fopen fanp3 "rb+" 
		          if f == undefined then messageBox "export error" 
		          else (
				  ClearListener ()
				  fseek f 4 #seek_set
			      END_File = readlong f #unsigned
			      fseek f 32 #seek_set
			      NumberAnim = readlong f #unsigned
		          fseek f 32 #seek_set
				  writelong f (NumberAnim + 1) #unsigned
		          fseek f (END_File + 8) #seek_set
				  
					WriteAnimDATA f Name_Anim
					
					  size = ftell f
		              toEnd = (2048 - (mod size 2048)) as integer
		              for i = 1 to toEnd do writebyte f 0
		              fseek f 4 #seek_set
		              writelong f (size - 8) #unsigned
					  fclose f 
					  
					f = fopen fanp3 "rb" 
		            if f == undefined then messageBox "export error" 
		            else (
		              load_IFP f
				       if (LodCheck == true) then (
				          lbl1.text = "Anim. File: " + (filenameFromPath fanp3) 
		                  lbl2.text = "Total Animation: " + (NumberAnim as string) 
		                  lbl3.text = "Internal Name: " + FileName
					      AnimListR.items = AnimName 
				          AnimListR.selection = NumberAnim --1
						  astart.value = 1
			              aend.value = NumberAnim
					    )
					 ) 
				  
		          ) --if f == undefined  
				  fclose f   
		          gc()
		      ) --if fanp3 != undefined 
			) --NAmecheck
		) --if (Get_selectionsKey_Count 0) > 0	
  ) --(addTextAnim.text != "")AND($selection.count >0)
) --on addAnim pressed do
-----------------------------------------------------//
on RepAnim pressed do (
   if (AnimListR.selection != 0)AND($selection.count >0) then (
      if (Get_selectionsKey_Count 0) > 0 then ( 
	      for obj in $selection where (getUserProp obj "BoneID") == undefined do deselect obj
          if fanp3 != undefined do (  
		      ffanp3 = (getFilenamePath fanp3) + "ttemp.bin" 
		      ff = fopen ffanp3 "wb" 
		      f = fopen fanp3 "rb"  
		    if (f == undefined) and (ff == undefined) then ( 
			   fclose f   
			   fclose ff  
			   deleteFile ffanp3 
		       messageBox "export error"
		    )else( 
			  ClearListener ()	
		  		fseek f 4 #seek_set
		  		DataSize = readlong f #unsigned
		        fseek f 0 #seek_set
                for i = 1 to StartAnimOffset[AnimListR.selection] do writebyte ff (readByte f)
                WriteAnimDATA ff AnimName[AnimListR.selection]
				Local nRepl = AnimListR.selection
                    if AnimListR.selection != NumberAnim then ( 
						      fseek f StartAnimOffset[AnimListR.selection + 1] #seek_set 
							  for i = StartAnimOffset[AnimListR.selection + 1] to (DataSize + 7) do writebyte ff (readByte f) 
							  format "StartAnimOffset=%\n" StartAnimOffset[AnimListR.selection + 1]
					  )--end if
                  size = ftell ff 
                  toEnd = (2048 - (mod size 2048)) as integer 
                  for i = 1 to toEnd do writebyte ff 0 
                  fseek ff 4 #seek_set 
                  writelong ff (size - 8) #unsigned
                      
                fclose f   
			   fclose ff  
			   deleteFile fanp3
			   renameFile ffanp3 fanp3
			   
                   f = fopen fanp3 "rb" 
		            if f == undefined then messageBox "export error" 
		            else (
					  AnimName =#()
					  AnimListR.items = AnimName 
		              load_IFP f
				       if (LodCheck == true) then (
				          lbl1.text = "Anim. File: " + (filenameFromPath fanp3) 
		                  lbl2.text = "Total Animation: " + (NumberAnim as string) 
		                  lbl3.text = "Internal Name: " + FileName
					      AnimListR.items = AnimName 
				          AnimListR.selection = nRepl --1
						  astart.value = 1
			              aend.value = NumberAnim
					    )
					 )
			        fclose f 
					gc()
					
            ) --else if (f == undefined) and (ff == undefined)
		 ) --if fanp3 != undefined do 	
      ) --if (Get_selectionsKey_Count 0) > 0	   
   ) --if (AnimListR.selection != 0))AND($selection.count >0)
) --on RepAnim pressed do
-----------------------------------------------------//
on batAnim pressed do ( 
  if (AnimListR.selection > 0)AND($selection.count >0) then (
    for obj in $selection where (getUserProp obj "FrameName") == "Skin_Mesh" do deselect obj
    if fanp3 != undefined do (   
      f = fopen fanp3 "rb" 
          if f == undefined then messageBox "export error"  
          else ( 
		  ClearListener ()
          fseek f StartAnimOffset[AnimListR.selection] #seek_set 
		  -- format "\nAnime: % at [%]\n" AnimListR.selected (ftell f)
		   sliderTime = 0
		   for tt = astart.value to aend.value do ( 

		     App_SA_Anim f AnimListR.selected StartAnimOffset[tt] sliderTime
			 if tt != aend.value then (
                animationRange = interval 0 (animationRange.end + 1) 
				slidertime = animationRange.end 
				gc() 
			  ) --if tt	
			) --end for tt
		  ) -- else if f == undefined
		  fclose f   
          gc()
        slidertime = animationRange.start

	) --if fanp3 != undefined 	  
  ) --if (AnimListR.selection > 0)AND($selection.count >0)
) --on batAnim pressed do 
------------------------------------------//
on astart changed val do ( 
        if val < 1 then astart.value = 1
		if NumberAnim != undefined then (
	        if astart.value > NumberAnim then astart.value = NumberAnim
	        if astart.value > aend.value then aend.value = astart.value	
		) else astart.value = 0
)
    --
on aend changed val do (
        if val < 1 then aend.value = 1
		if NumberAnim != undefined then (
	        if aend.value > NumberAnim then aend.value = NumberAnim
    	    if aend.value < astart.value then astart.value = aend.value
		) else aend.value = 0
)

------------------------------------------//
) --rollout NewIFP_and_Add

rf = newRolloutFloater "GTA SA ANP3 animation" 188 525 10 30
addRollout NewIFP_and_Add rf
		  