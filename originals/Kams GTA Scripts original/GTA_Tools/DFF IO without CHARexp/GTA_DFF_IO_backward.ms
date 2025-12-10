if DFFinInfo == undefined then fileIn (scriptspath+"\\GTA_Tools\\gtaDFFin_Fn.mse") quiet:true
else if DFFinInfo() != 051219 then fileIn (scriptspath+"\\GTA_Tools\\gtaDFFin_Fn.mse") quiet:true
if DFFoutInfo == undefined then fileIn (scriptspath+"\\GTA_Tools\\gtaDFFout_Fn.mse") quiet:true
else if DFFoutInfo() != 051219 then fileIn (scriptspath+"\\GTA_Tools\\gtaDFFout_Fn.mse") quiet:true

if DFFinInfo() != 051219 then messagebox "You didn't have the right import function to run this script!\nTry Install it again!" title:"Import Function Error"
if DFFoutInfo() != 051219 then messagebox "You didn't have the right export function to run this script!\nTry Install it again!" title:"Export Function Error"


Global Dummysize = 0.1		--control the dummy size, change it before pressing the Import Button 
Global SPscale = 1.0
Global SAColBase = undefined


rollout aboutRoll "About" (
	group "" (
		checkbox sdtl "Show detail info." checked:false
	)
	label l1 "GTA DFF IO"
	label l2 " "
	label s1 ">> SA Char Export broken <<" align:#left
	label s2 "  - Collision Quick Hack" align:#left
	label s3 "  - Global GeoFlag only" align:#left
	label s4 "  - Materials Matching" align:#left
	label s5 "  - No Col DFF export" align:#left
	label s6 "  - rwLight try\n" align:#left
	--label s7 "  - Bones/Skin try!?" align:#left
	label s7 "  - 2nd UV Map" align:#left
	label s8 "  - export DFF lock" align:#left
	
	label l3 " " 
	label l4 "by Kam" align:#left across:2
	label l5 "19Dec05" align:#right
	label l6 "kam.lai@ntlworld.com"
	label l7 " "	
	label l8 "Dear Odie, r.i.p."
	label l9 "Pioneer GTA modder"
	label lA "30Dec1967 - 07Jun2005"	
)


rollout DFFinPara "Import DFF" (

local fname = undefined
local no_clump = #()

	Group "Multi. Clump" (
        spinner whichone "" type:#integer range:[1,1,1] align:#left fieldwidth:35 offset:[-3,3] across:2 enabled:false
        button useclump "Import" width:70 offset:[-3,0] enabled:false
	)
	group "" (
		label lbl1 "Image Type:" align:#left offset:[0,-7]
		radiobuttons textype "" labels:#("tga", "bmp","png") columns:3
		spinner ISc "Import Scale: " fieldwidth:42 range:[0,100,SPscale] align:#left
		button imp "Import DFF" width:120 height:30 align:#left
	)
	group "" (
		checkbutton autoskin "A" width:17 tooltip:"Auto Skin after import dff character" highlightcolor:yellow align:#left across:2 offset:[0,-3]
		button skinchr "Skin the Character" width:103 tooltip:"Selected model must be Skin/bones ready" align:#right offset:[-2,-3]
		progressBar skinstate color:red height:8 offset:[0,-3]
		button RenameSel "Re-Name" width:61 tooltip:"Add BoneIndex to the name of objects for easy skinnig" align:#left across:2
		button RtnameSel "Restore" width:61 tooltip:"Restore Original names to selected objects" align:#right
	)
	
	on RenameSel pressed do (
		for obj in $selection do (
			onm = getUserProp obj "BoneIndex"
			if onm != undefined then (
				if onm <10 then obj.name = "0" + onm as string + "_" + (RestoreSpace obj.name)
				else obj.name = onm as string + "_" + (RestoreSpace obj.name)
			)
		)--end for	
	)

	on RtnameSel pressed do (
		for obj in $selection do (
			onm = getUserProp obj "FrameName"
			if onm != undefined then obj.name = RestoreSpace onm
		)--end for
	)--end on RenameSel

	on skinchr pressed do (
		if (SkinData != undefined)AND($selection.count == 1) then (
			global skn = $.modifiers[1]
			if (skn != undefined)AND(classof $ == Editable_mesh) then (
				if $.numVerts != SkinData[1].count then \
					messagebox "Skin Data Not correct!" title:"Skin Error"
				else (
--New Edit(11Jul05)--**
					max modify mode
					modPanel.SetCurrentObject skn
--**
					if (skinOps.GetNumberBones skn) != SkinData[3] then (
						messagebox "Bones count in skin Modifier Not correct!" title:"Skin Error"
					)	
 					else (
						--skn
						for i = 1 to $.numVerts do (
							skinOps.SetVertexWeights skn i SkinData[1][i] SkinData[2][i]
							if (mod i 50) == 0 then skinstate.value = 100 * i/$.numVerts
						)
						skinstate.value = 0
						gc()
					)
				)
			) else messagebox "Skin modifier not found" title:"Skin Error"
		) else messagebox "Make sure you have selected the right character\nwith Skin modifier applied" title:""
	)--end on skinchr

	on Isc changed Val do (
		SPscale = Val
		try ( DFFexPara.ExSc.value = 1/Val ) catch()
	)

	on useclump pressed do (
		f = fopen fname "rb"
		if f != undefined then  (
			if whichone.value != 1 then fseek f no_clump[(whichone.value)] #seek_set
			texEx = case textype.state of (
				1: ".tga"
				2: ".bmp"
				3: ".png"
			)
			DFFin f ISc.value texEx dummysize autoskin.checked aboutRoll.sdtl.checked undefined
			fclose f
			gc()
		) else (
			format "ERROR\n"
		)
	)--end on useclump
    
	on imp pressed do (
		fname = getopenfilename caption:"Read DFF File" types:"dff File (*.dff)|*.dff|"
		if fname != undefined then (
			f = fopen fname "rb"
			if f == undefined then ( Messagebox "Can't open the file!" title:"I/O Error" )
			else (
				no_clump = checkClump f
				if no_clump == undefined then
					messagebox "This DFF is locked !\nThe author of this model do not allow you to modify it.\n\nPlease contact the author for the permission." title:"Import Failed"
				else if no_clump.count == 0 then messagebox "Not a Void DFF file!" title:"File Format Error"
				else (
					if no_clump.count == 1 then (
						texEx = case textype.state of (
							1: ".tga"
							2: ".bmp"
							3: ".png"
						)--end case
						DFFin f ISc.value texEx dummysize autoskin.checked aboutRoll.sdtl.checked (getFilenameFile fname)
						useclump.enabled = false
						whichone.enabled = false
					) else (
						fclose f
						whichone.range = [1,no_clump.count,1]
						whichone.enabled = true
						useclump.enabled = true
						txt = "This DFF has " + no_clump.count as string + " Clumps.\nPlease choose one to Import!"
						Messagebox  txt title:""
					)
				)--end if/else no_clump
			)--end if/else f
		)
		fclose f
		gc()
	)--end on imp
    
)--end rollout DFFinPara


rollout DFFexPara "Export DFF" (

	checkbutton eGTA3 "GTA3" width:40 highlightcolor:green offset:[2,0] across:3
	checkbutton eVC   "VC"   width:40 highlightcolor:green
	checkbutton eSA   "SA"   width:40 highlightcolor:green checked:true

	spinner ExSc "Export Scale: " fieldwidth:42 range:[0,100,1/SPscale] align:#left
		checkbutton MMC "MMC" width:30 align:#left highlightcolor:yellow tooltip:"use Modulate Material Color" checked:true across:4
		checkbutton TUV "UV" width:30 align:#center highlightcolor:yellow tooltip:"export Texture UV" checked:true
		checkbutton NOR "Nor" width:30 align:#center highlightcolor:yellow tooltip:"export Normal" checked:true
		checkbutton CPV "VCol" width:30 align:#right highlightcolor:yellow tooltip:"export Prelit Vertex Color"
	group "SA collision Base" (
		button colbase "Select COL3/COLL" width:120
		checkbox Vparts "Vehicle Parts" align:#left
		checkbox noCOL "Skip COL" align:#left
	) 
	group "" (
		checkbutton lockdff "lock DFF" width:120 tooltip:"The exported DFF will not be able to import back!" highlightcolor:red align:#center offset:[0,-5]
		button exp "Export DFF" width:120 height:30 tooltip:"Only selected objects will export" align:#center
		button BSexp "Bones/Skin Export" width:120 tooltip:"Select the skinned Character only" align:#center offset:[0,-3]
		checkbox AppendFile "Append export to DFF" align:#left 
	)
 
	
	on colbase pressed do (
		Cname = getopenfilename caption:"Collision Base File" types:"DFF File (*.dff)|*.dff|COL File (*.col)|*.col|"
		if Cname != undefined then (
			ctype = GetFilenameType Cname
			cb = fopen Cname "rb"
			case ctype of (
				".dff": (
					if (findCOL3 cb 0x1803FFFF) != true then ( 
						messagebox "Can't find COL3!\nMake sure to select SA vehicle dff only!" title:"NO COL3 in DFF"
						Cname = undefined
					) else colbase.text = filenameFromPath Cname
				)	
				".col": (
					rult = singleCOL cb
                    if rult == undefined then messagebox "This is not a GTA Collision file" title:"File Error" 
                    if rult == false then messagebox "This file contains more than 1 Collision file" title:"File Error"
                    if rult == true then colbase.text = filenameFromPath Cname
                    else Cname = undefined
				)	
			)
			fclose cb
		)	
		SAColBase = Cname
		if Cname == undefined then  colbase.text = "Select COL3/COLL"
	)
	
	on eGTA3 changed state do (
		if state == true then (
			eVC.checked = false
			eSA.checked = false
		) else eGTA3.checked = true
	)
	on eVC changed state do (
		if state == true then (
			eGTA3.checked = false
			eSA.checked = false
		) else eVC.checked = true
	)
	on eSA changed state do (
		if state == true then (
			eGTA3.checked = false
			eVC.checked = false
		) else eSA.checked = true
	)
	
	on BSexp pressed do (
		if $selection.count != 1 then messagebox "Select the skinned Character only!" title:"Selection Error"
		else (
			if (classof $.modifiers[1] != skin) then \
				messagebox "This object is not skinned correctly!\nSkin modifier must be on the topmost of the stack!!" title:"Skin Error"
			else (

				if eVC.checked == true then		ver = 0X0C02FFFF			--VC Version
				if eGTA3.checked == true then	ver = 0x0800FFFF			--Standard GTA3 Version
				if eSA.checked == true then		ver = 0x1803FFFF
				
				max modify mode
				bkup = $.name
				$.name = "CharExpTemp"
				global skn = $.modifiers[1]
				skn
				boneCount = skinOps.getNumberBones skn
				boneReady = true
				global bonechain = #()
				for i = 1 to boneCount do (
					tmp = skinOps.getBoneName skn i 0
					tb = "append bonechain $'" + tmp + "'"
					bonechain
					execute tb
					tt = "getUserProp $'" + tmp + "' \"BoneID\""
					if (execute tt) == undefined then (
						boneReady = false
						exit
					)
					tt = "getUserProp $'" + tmp + "' \"BoneType\""
					if (execute tt) == undefined then (
						boneReady = false
						exit
					)					
				)--end for i
				$.name = bkup
				if boneReady == false then messagebox "You didn't set   BoneIDs/BoneTypes   properly!\nEach bone must have  'BoneID' & 'BoneType'  in it's User Properities." title:"BoneID/BoneType Error"
				else (
					for i = 1 to $.numverts do (
						if skinOps.GetVertexWeightCount skn i == 0 then (boneReady = false; exit)
					)
				)
				if boneReady == false then messagebox "You didn't set   Skin/Vertices   properly!\nEach Vertex must be influence by at least 1 Bone." title:"Skin Error"
				else (
					--clearlistener()
					fname = undefined
	
					if AppendFile.checked == true then (
						Sname = getopenfilename caption:"Append DFF File" types:"dff File (*.dff)|*.dff|"
						if Sname != undefined then (
							fo = fopen Sname "rb"
							if fo != undefined then  (
								no_clump = checkClump fo

								if no_clump == undefined then (
									messagebox "This DFF is locked !\nThe author of this model do not allow you to modify it.\n\nPlease contact the author for the permission." title:"Import Failed"
									fname = unefined
								) else (

									fseek fo (no_clump[no_clump.count]+4) #seek_set
									skip = readLong fo #unsigned
									readLong fo
									skip += (ftell fo)
									fname = (getFilenamePath Sname) + "temp.dff"
									if fname != undefined then (
										f = fopen fname "wb"
										fseek fo 0 #seek_set
										for i = 1 to skip do (
											writeByte f (readByte fo #unsigned)
										)--end for i
										fclose fo	
									)--end if fname	
								)   
							)--end if fo
						)--end if Sname
					) else (
						fname = getsavefilename caption:"Export DFF File" types:"dff File (*.dff)|*.dff|"
						if fname != undefined then (
							f = fopen fname "wb"
						)
					)--end if/else AppendFile
			
					if fname != undefined then (
				
						expscale = $.scale * ExSc.value
						SkinData = CreateSkinData $
--format "1: SkinData:%\n" SkinData.count
						wCharDFFout f $ bonechain MMC.checked TUV.checked CPV.checked NOR.checked expscale SkinData ver lockdff.checked
		    	        fclose f
            
						if AppendFile.checked == true then (
							deleteFile Sname
							renameFile fname Sname
							format "\nModels appended to file:% !\n" Sname
						)else	format "\nfile:% exported!\n" fname
			
					)--end if f!=undefined
	
				)--if/else boneReady
				
			)--end check Skin modifier
		)--end check $	
	)--end on BSexp
	
	
	on ExSc changed Val do (
 		SPscale = 1/Val
		try ( DFFinPara.ISc.value = 1/Val ) catch()
	)

	on exp pressed do (
		if $selection.count != 0 then (

			--Upgradiable Parts--
			colcase = 0
			if noCOL.checked == true then colcase = 1
			if Vparts.checked == true then colcase = 2
            
		if (eSA.checked==true)AND(SAColBase==undefined)AND(colcase== 0) then messagebox "You need to supply a Collosion model for SA Export!"
		else (
		
		RootObj = checkRoot $selection
		if  RootObj != undefined then (
			----------------------
			--Scale the Root obj--
			----------------------
			bkupRootTran = RootObj.transform
			expscale = RootObj.scale * ExSc.value
			RootObj.transform = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]
		
				if eVC.checked == true then		ver = 0X0C02FFFF			--VC Version
				if eGTA3.checked == true then	ver = 0x0800FFFF			--Standard GTA3 Version
				if eSA.checked == true then		ver = 0x1803FFFF			--SA Version
				
			fname = undefined
	
			if AppendFile.checked == true then (
				Sname = getopenfilename caption:"Append DFF File" types:"dff File (*.dff)|*.dff|"
				if Sname != undefined then (
					fo = fopen Sname "rb"
					if fo != undefined then  (
						no_clump = checkClump fo
						if no_clump == undefined then (
							messagebox "This DFF is locked !\nThe author of this model do not allow you to modify it.\n\nPlease contact the author for the permission." title:"Import Failed"
							fname = unefined
						) else (
							fseek fo (no_clump[no_clump.count]+4) #seek_set
							skip = readLong fo #unsigned
							readLong fo
							skip += (ftell fo)
							fname = (getFilenamePath Sname) + "temp.dff"
							if fname != undefined then (
								f = fopen fname "wb"
								fseek fo 0 #seek_set
								for i = 1 to skip do (
									writeByte f (readByte fo #unsigned)
								)--end for i
								fclose fo	
							)--end if fname	
						)
					)--end if fo
				)--end if Sname
			) else (
				fname = getsavefilename caption:"Export DFF File" types:"dff File (*.dff)|*.dff|"
				if fname != undefined then (
					f = fopen fname "wb"
				)
			)--end if/else AppendFile
		
			if fname != undefined then (

				DFFout f $selection MMC.checked TUV.checked CPV.checked NOR.checked expscale ver SAColBase colcase lockdff.checked
    	        fclose f
            
				if AppendFile.checked == true then (
					deleteFile Sname
					renameFile fname Sname
					format "\nModels appended to file:% !\n" Sname
				)else	format "\nfile:% exported!\n" fname
			
			)--end if f!=undefined	
		
			RootObj.transform = bkupRootTran		
		
		)--end if RootObj
		
		)
		
		) else (MessageBox "Select the Objects you want to export.\n And then press 'Export DFF' button" title:"Selection Error") --end

	)--end on exp

)--end rollout DFFexPara


rollout dmyHelper "Dummies/Bones Helper" (
	spinner dmyboxsize "Size: " range:[0.00000001,100000,dummysize]
	button dmyasBox "Box" width:40 tooltip:"Show Dummies/bones as box" align:#left across:3
	button dmynLink "Link" width:40 tooltip:"Show Dummies/bones as box with Links" align:#center	
	button dmyasBone "Bone" width:40 tooltip:"Show Dummies/bones as bone" align:#right

	on dmyboxsize changed val do (
		for dmy in $selection where classof dmy == Dummy do (
			dmy.boxsize = [val,val,val]
		)	
	)

	on dmyasBox pressed do (
		for dmy in $selection where classof dmy == Dummy do (
			dmy.showLinksOnly = false
			dmy.showLinks = false
		)
		forceCompleteRedraw()
	)
	on dmynLink pressed do (
		for dmy in $selection where classof dmy == Dummy do (
			dmy.showLinksOnly = false
			dmy.showLinks = true
		)
		forceCompleteRedraw()
	)
	
	on dmyasBone pressed do (
		for dmy in $selection where classof dmy == Dummy do dmy.showLinksOnly = true
		forceCompleteRedraw()
	)
)--end rollout dmyHelper

if Kam_GTA != undefined then ( closeRolloutFloater Kam_GTA; gc() )
Kam_GTA = newRolloutFloater "GTA DFF IO 16Oct05" 175 375 10 100		
addRollout DFFinPara Kam_GTA
addRollout DFFexPara Kam_GTA rolledup:true
addRollout dmyHelper Kam_GTA rolledup:true
addRollout aboutRoll Kam_GTA rolledup:true
