if DFFinInfo == undefined then fileIn (scriptspath+"\\GTA_Tools\\gtaDFFin_Fn.mse") quiet:true 
else if DFFinInfo() < 050825 then fileIn (scriptspath+"\\GTA_Tools\\gtaDFFin_Fn.mse") quiet:true
if DFFinInfo() < 050825 then messagebox "You didn't have the right import function to run this script!\nTry Install it again!" title:"Import Function Error" 
if MapIOInfo == undefined then fileIn (scriptspath+"\\GTA_Tools\\gtaMapIO_Fn.mse") quiet:true
else if MapIOInfo() != 051010 then fileIn (scriptspath+"\\GTA_Tools\\gtaMapIO_Fn.mse") quiet:true
if MapIOInfo() != 051010 then messagebox "You didn't have the right import function to run this script!\nTry Install it again!" title:"Import Function Error" 


interiors = #(
"Outside (standard)",
"Ocean View Hotel in Washington Beach",
"Tommy Vercetti Estate on Starfish Island",
"Bank in Little Havana",
"Mall in Vice Point",
"Pole Position Club in Washington Beach",
"Lawyers in Washington Beach",
"Robina's Cafe in Little Havana",
"Concert hall of Love Fist in Downtown",
"Record studios of Love Fist in Downtown   ",
"Ammu Nation Rifle Range in Downtown",
"Bar of the bikers in Downtown",
"House of the old woman in Little Haiti",
"Printworks in Little Haiti",
"Stadium hall 1 in Downtown",
"Stadium hall 2 in Downtown",
"Stadium hall 3 in Downtown",
"Malibu Club in Vice Point" )


Global dffpath = undefined
Global VDary = #()
Global obj = undefined
if fxID == undefined then Global fxID = 0.99991

--IO Main--
--=======--
rollout IORoll "IO Control" (
	button dpbtn "DFF Path" width:60 tooltip:"Select DFF Path" align:#left offset:[0,-2] across:2
	edittext dptxt "" width:190 align:#right text:""
	on dpbtn pressed do (
		dffpath = getSavePath caption:"DFF Path"
		if dffpath != undefined then dptxt.text = dffpath
		else dptxt.text = ""
	)--end on dpbtn
	
    checkbutton G3ctr "GTA3" width:80 tooltip:"Select Import/Export as GTA3 format" checked:false highlightcolor:green align:#center across:3
    checkbutton VCctr "VC" width:80 tooltip:"Select Import/Export as VC format" checked:false highlightcolor:green align:#center
    checkbutton SActr "SA" width:80 tooltip:"Select Import/Export as SA format" checked:true highlightcolor:green align:#center
	on G3ctr changed state do (
		if state == false then G3ctr.checked = true
		else (
			VCctr.checked = false
			SActr.checked = false
		)	
	)
	on VCctr changed state do (
		if state == false then VCctr.checked = true
		else (
			SActr.checked = false
			G3ctr.checked = false
		)	
	)
	on SActr changed state do (
		if state == false then SActr.checked = true
		else (
			VCctr.checked = false
			G3ctr.checked = false
		)	
	)
	
	group "IPL Info." (
		button ipldmp "Get IPL Info." width:246 --align:#left across:3
		label lbl1 "" align:#left
		label lbl2 "" align:#left across:2
		label lbl3 "" align:#right
		button dmpiplary "List DFF" width:123 align:#left tooltip:"Listout All Needed DFF in IPL" enabled:false across:2 
		button ckmissDFF "Check Missing DFF" width:123 align:#left enabled:false tooltip:"Check missing DFF from directory"
	)
	on ipldmp pressed do (
		iplname = getOpenFileName caption:"Open GTA IPL File" types:"IPL File (*.ipl)|*.ipl|"
		if (iplname != undefined) then (
			iplary = dumpDFF iplname
			lbl1.text = "File :   " + (filenameFromPath iplname)
			lbl2.text = "Total objects :   " + iplary[1] as string
			global DFFary = iplary[2]
			lbl3.text = "Total DFF needed :  " + DFFary.count as string
			dmpiplary.enabled = true
			ckmissDFF.enabled = true
		)--end if	
	)--end on ipldmp
	on dmpiplary pressed do (
		clearlistener()
		for n in DFFary do format "%.dff\n" n	
	)--end on dmpiplary 
	on ckmissDFF pressed do (
		if dptxt.text != "" then (
			tmp = getFiles ( dptxt.text + "\\*.dff" )
			flist = for d in tmp collect (getFilenameFile d)
			clearlistener()
			format "Missing DFF:\n\n"
			for n in DFFary do
				if finditem flist n == 0 then format "%.dff\n" n
			format "\nDONE!!\n"
		) else  ( messagebox "Select the DFF Path first!\n" title:"Not ready to Check" )
	)--end on ckmissDFF	
	
	group "Import" (
		label lblipl "Texture:" align:#left across:4
		radiobuttons textype "" labels:#("tga", "bmp") columns:2
		checkbutton fximp "2dfx" width:45 highlightcolor:yellow tooltip:"Read 2dfx when import .ide   (SLOW!!!)" offset:[15,-2]
		spinner fxsize "" fieldwidth:45 range:[0,10000,1] align:#right
		button impipl "IPL" width:82 across:3 
		button ideIn "IDE" width:82  
		button zonIn "ZON" width:82
	)
	on impipl pressed do (
		if dptxt.text != "" then (
			dffpath = dptxt.text
			iplname = getOpenFileName caption:"Open GTA IPL File" types:"IPL File (*.ipl)|*.ipl|"
			if (iplname != undefined) then (
				if G3ctr.checked == true then verNo = 1
				if VCctr.checked == true then verNo = 2	
				if SActr.checked == true then verNo = 3
				clearlistener()		
				ReadIPL iplname dffpath verNo textype.state
				format "\nAll Done!!\n\n"
				max tool zoomextents
			)
		) else ( messagebox "Select the DFF Path first!\n" title:"Not ready to import" )
	)--end on impipl
	on zonIn pressed do (
		ZONname = getOpenFileName caption:"Open GTA ZON File" types:"ZON File (*.zon)|*.zon|"
			if (ZONname != undefined) then (
				ReadZon ZONname 
			)	
	)--end zonIn
	on ideIn pressed do (
		idename = getOpenFileName caption:"Open GTA IDE File" types:"IDE File (*.ide)|*.ide|"
			if (idename != undefined) then (
				if G3ctr.checked == true then verNo = 1
				if VCctr.checked == true then verNo = 2	
				if SActr.checked == true then verNo = 3
				clearlistener()		
				ReadIDE idename VerNo fximp.checked fxsize.value
				format "\nAll Done!!\n\n"
				max tool zoomextents
			)
	)--end on impipl
 --=================================================--
	button txdlist "TXD List" width:123  across:2
	button txdcheck "TXD Check" width:123
	on txdlist pressed do (
		CheckTXD dptxt.text false
	)--end on txdlist
	on txdcheck pressed do (
		if dptxt.text != "" then (
			CheckTXD dptxt.text true
		) else  ( messagebox "Select the TXD Path first!\n" title:"Not ready to Check" )
	)--end on txdcheck		
 --=================================================--
	group "Export (Selected Only)" (
		button expipl "IPL" width:82 across:3 --align:#left offset:[-19,0]
		button expide "IDE" width:82 --align:#right offset:[0,0]
		button expzon "ZON" width:82 --align:#right
	)
	on expzon pressed do (
		if $selection.count > 0 then (
			if G3ctr.checked == true then verNo = 1
			if VCctr.checked == true then verNo = 2	
			if SActr.checked == true then verNo = 3

			format "<!--"
			format "\n"	
			f = "" as StringStream
			format "#ZON file generated from Kam's GTA Map IO\n" to:f
			f = WriteZon f $selection verNo
			clearListener()
			format "%\n" ( f as string )		
			format "#"			
		)--end if
	)--end on expzon
	
	on expipl pressed do (
		if $selection.count > 0 then (
			if G3ctr.checked == true then verNo = 1
			if VCctr.checked == true then verNo = 2	
			if SActr.checked == true then verNo = 3

			format "<!--"
			format "\n"

			f = "" as StringStream
			format "#IPL file generated from Kam's GTA Map IO\ninst\n"		to:f
 			f = WriteInst f $selection verNo
			if f != undefined then (
				format "end\ncull\n"								to:f
				WriteCull f $selection verNo
				if verNo != 1 then format "end\npath\nend\n"		to:f
				
				if verNo == 3 then (
					format "grge\n"									to:f
					WriteGrge f $selection
					format "end\nenex\n"							to:f
					WriteEnex f $selection
					format "end\npick\n"							to:f
					WritePick f $selection
					format "end\ncars\n"							to:f
					WriteCars f $selection
					format "end\n"									to:f
				)else format "pick\nend\n"							to:f
				if verNo == 3 then (
					format "jump\n"									to:f
					WriteJump f $selection
					format "end\ntcyc\nend\n"						to:f
					format "auzo\n"									to:f
					WriteAuzo f $selection
					format "end\nmult\nend\n"						to:f
				)
				clearListener()
				format "%\n" ( f as string )		
				format "#"
			)
		)
	)--end on expipl

	on expide pressed do (
		if $selection.count > 0 then (
			if G3ctr.checked == true then verNo = 1
			if VCctr.checked == true then verNo = 2	
			if SActr.checked == true then verNo = 3
			
			format "<!--"
			format "\n"
			f = "" as StringStream
			format "#IDE file generated from Kam's GTA Map IO\n"		to:f
 			f = WriteIDE f $selection verNo
			if f != undefined then (
				clearListener()
				format "%\n" ( f as string )		
				format "#"
			)
		)
	)--end on expide



	
)--end rollout IORoll

--obj Properities--
--===============--
rollout MapRoll "Objects Properities" (
		label lbl1 "Object :  " 	align:#left across:2
		spinner intID "Interior:#" fieldwidth:30 type:#integer align:#right
		
		button getProp "Get" width:123 align:#left across:2
		button setProp "Set" width:123 align:#right --offset:[-8,0]

		spinner idsp "ID : " fieldwidth:45 type:#integer range:[0,99999,5000] align:#left across:3
		button seltxd "Txd" width:35 height:17 align:#left tooltip:"Texture of the object" offset:[7,0]
		edittext txdtext "" fieldwidth:120 align:#right
		button seltxdp "Txdp" width:35 height:17 align:#left tooltip:"Texture Parent for txd" across:4
		edittext txdpant "" fieldwidth:85 align:#right
		button mapanim "Anim" width:35 height:17 align:#left tooltip:"ifp for Animated Objects" offset:[2,0] --across:2
		edittext lblanim "" fieldwidth:85 align:#right offset:[2,0]
    
		label hassub "" align:#left across:2 
		spinner farview "View Distance : " fieldwidth:45 range:[0,3000,300] align:#right type:#integer
		button setsubVD "Set sub-obj View Distance" width:246 enabled:false

		group "Render Effect" (
			checkbox eff1 "Wet Surface (Rain)" across:2	--1
			checkbox eff2 "tobj Night Flag" 		--2
			checkbox eff3 "No Cull behind Alpha" across:2		--4
			checkbox eff4 "!No Cull behind Alpha" across:3			--8
			checkbox eff5 "tobj Day Flag" 	across:2		--16
			checkbox eff6 "** Is Interior"		--32
			checkbox eff7 "Disable Shadow Cull" across:2	--64
			checkbox eff8 "No Surface from Cull"			--128
			checkbox eff9 "Disable DrawDistance" across:2			--256
			checkbox effA "**Breakable with Crack" --across:2			--512
			checkbox effB "**Breakable" --offset:[-41,0]			--1024
			Label FlagInfo1 "   ! disables texture to black when placed in exterior" align:#left
			Label FlagINfo2	"  ** object must be defined in object.dat" align:#left
		)		
	group "Time Object" (
		checkbox usetime "" align:#left across:3
		spinner timeOn "Time On : " type:#integer range:[0,24,0] fieldwidth:45 align:#left offset:[-55,0] enabled:false
		spinner timeOff "Time Off : " type:#integer range:[0,24,0] fieldwidth:45 align:#right enabled:false
	)

	on seltxd pressed do (
		stxd = getOpenFileName caption:"Select Texture TXD File" types:"TXD File (*.txd)|*.txd|"
		if (stxd != undefined) then txdtext.text = filenamefrompath stxd
		else txdtext.text = ""
	)		
	on seltxdp pressed do (
		stxp = getOpenFileName caption:"Select Texture Parent TXD File" types:"TXD File (*.txd)|*.txd|"
		if (stxp != undefined) then txdpant.text = filenamefrompath stxp
		else txdpant.text = ""
	)
	on mapanim pressed do (
		mifp = getOpenFileName caption:"Select Map Animation IFP File" types:"IFP File (*.ifp)|*.ifp|"
		if (mifp != undefined) then lblanim.text = filenamefrompath mifp
		else lblanim.text = ""
	)

	group "VC Interiors" (    
		--label lbl2 "VC : " align:#left offset:[0,3] across:2
		dropdownlist intlist "" width:250 items:interiors align:#right offset:[2,0]
	)

	on setsubVD pressed do (
		SB = totalsubobj obj 
		createVDary obj SB
	)
	on usetime changed state do (
		if state == true then (
			timeOn.enabled = true
			timeOff.enabled = true
		) else (
			timeOn.enabled = false
			timeOff.enabled = false		
		)
	)--end on usetime 
	on intID changed val do (
		if val < 18 then intlist.selection = val + 1
				 else intlist.selection = 1
	)
	on intlist selected sel do (
		intID.value = intlist.selection - 1	
	)

	
	on setProp pressed do (
		if $selection.count != 1 then messagebox "Select a single object only!" Title:"Please select again"
		else (
			obj = $
			while obj.parent != undefined do obj = obj.parent
			select obj
			lbl1.text = obj.name
		----------------------------------
		--Set up Buffer for all same obj--
		----------------------------------
			upb = ""

			upb += "ID=" + idsp.value as string + "\n"
			if txdtext.text.count > 0 then (
				ttt = findstring txdtext.text ".txd"
				if ttt != undefined then txdtext.text = substring txdtext.text 1 (txdtext.text.count-4)
				upb += "TXD=" + txdtext.text + "\n"
			)
			if txdpant.text.count > 0 then (
				ttt = findstring txdpant.text ".txd"
				if ttt != undefined then txdpant.text = substring txdpant.text 1 (txdpant.text.count-4)
				upb += "TXDP=" + txdpant.text + "\n"
			)
			if lblanim.text.count > 0 then (
				ttt = findstring lblanim.text ".ifp"
				if ttt != undefined then lblanim.text = substring lblanim.text 1 (lblanim.text.count-4)
				upb += "Anim=" + lblanim.text + "\n"
			)
			SB = totalsubobj obj
			upb += "SubObj=" + SB as string + "\n"
			if SB == 1 then upb += "View=" + farview.value as string + "\n"
			else (
				if VDary.count > 0 then (
					for i = 1 to SB do 
						upb += "View" + i as string + "=" + VDary[i] as string + "\n"
				) else 
					for i = 1 to SB do upb += "View" + i as string + "=300\n"				
			)--end if/else SB

			rendeff = 0
			if eff1.checked == true then rendeff += 1
			if eff2.checked == true then rendeff += 2
			if eff3.checked == true then rendeff += 4
			if eff4.checked == true then rendeff += 8
			if eff5.checked == true then rendeff += 16
			if eff6.checked == true then rendeff += 32
			if eff7.checked == true then rendeff += 64
			if eff8.checked == true then rendeff += 128
			if eff9.checked == true then rendeff += 256
			if effA.checked == true then rendeff += 512
			if effB.checked == true then rendeff += 1025
			upb += "RenderEffect=" + rendeff as string + "\n"
			
			if usetime.checked == true then (
				upb += "TimeOn=" + timeOn.value as string + "\n"
				upb += "TimeOff=" + timeOff.value as string + "\n"
			) 

			upb += "Interior=" + intID.value as string + "\n"
			
		----------------------------------		
			intAry = for o in geometry where o.name == lbl1.text collect o
			for o in intAry do setUserPropBuffer o upb
		)--end if/else
	)--end on setProp

	on getProp pressed do (
		if $selection.count != 1 then messagebox "Select a single object only!" Title:"Please select again"
		else (
			obj = $
			while obj.parent != undefined do obj = obj.parent
			ID = getUserProp obj "ID"
			if ID == undefined then (
				messagebox "No ID in this object" title:"Warning"
				idsp.value = 9999
			) else 			idsp.value = ID

			txd = getUserProp obj "TXD"
			if txd != undefined then txdtext.text = txd
			else txdtext.text = ""
			txdp = getUserProp obj "TXDP"
			if txdp != undefined then txdpant.text = txdp
			else txdpant.text = ""

			SB = totalsubobj obj
			if SB > 1 then (
				farview.enabled = false
				setsubVD.enabled = true
				hassub.text = "*Sub-Obj: " + SB as string

				notset = false
				txt = ""
				for j = 1 to SB do (
					txt += "tmp = getUserProp obj \"View" + j as string + "\"\n"
				    txt += "if tmp == undefined then notset = true\n" 
					txt += "else VDary[" + j as string + "] = tmp\n" 
				)
				execute txt
				if notset == true then VDary = #()

			) else (
				VDary = #()
				farview.enabled = true
				setsubVD.enabled = false
				hassub.text = ""
				try (farview.value = getUserProp obj "View") catch (farview.value = 300)
			)	
				
			rendeff = getUserProp obj "RenderEffect"
			if rendeff != undefined then (
				if rendeff >= 1024 then (rendeff -= 1024; effB.checked = true ) else effB.checked = false 
				if rendeff >= 512 then ( rendeff -= 512; effA.checked = true ) else effA.checked = false 
				if rendeff >= 256 then ( rendeff -= 256; eff9.checked = true ) else eff9.checked = false 
				if rendeff >= 128 then ( rendeff -= 128; eff8.checked = true ) else eff8.checked = false 
				if rendeff >= 64 then (  rendeff -= 64;  eff7.checked = true ) else eff7.checked = false 
				if rendeff >= 32 then (  rendeff -= 32;  eff6.checked = true ) else eff6.checked = false 
				if rendeff >= 16 then (  rendeff -= 16;  eff5.checked = true ) else eff5.checked = false 
				if rendeff >= 8 then (   rendeff -= 8;   eff4.checked = true ) else eff4.checked = false 
				if rendeff >= 4 then (   rendeff -= 4;   eff3.checked = true ) else eff3.checked = false 
				if rendeff >= 2 then (   rendeff -= 2;   eff2.checked = true ) else eff2.checked = false 
				if rendeff >= 1 then ( eff1.checked = true ) else eff1.checked = false 
			) else (
				eff1.checked = false; eff2.checked = false
				eff3.checked = false; eff4.checked = false
				eff5.checked = false; eff6.checked = false
				eff7.checked = false; eff8.checked = false
				eff9.checked = false; effA.checked = false
				effB.checked = false
			)--end if rendeff
				
			ton = getUserProp obj "TimeOn"
			toff = getUserProp obj "TimeOff"
			if (ton != undefined) AND (toff != undefined) then (
				usetime.checked = true
				timeOn.enabled = true;  timeOn.value = ton
				timeOff.enabled = true; timeOff.value = toff				
			) else (
				usetime.checked = false
				timeOn.enabled = false
				timeOff.enabled = false
			)
			mifp = getUserProp obj "Anim"
			if mifp != undefined then lblanim.text = mifp
			else lblanim.text = ""

			Intr = getUserProp obj "Interior"
			if Intr != undefined then (
				 intID.value = intr
				 if intr < 18 then intlist.selection = intr + 1
				 else intlist.selection = 1
			) else (
				intID.value = 0
				intlist.selection = 1
			)
			
			select obj
			lbl1.text = "Object :  " + obj.name
		)
	)--end on getProp	
)--end rollout MapRoll


--ZONE--
--====--
rollout ZONRoll "Zone Properities" (
	label lblz "Zone : " 	align:#left
	button getzone "Get" width:123 align:#left across:2
	button setzone "Set" width:123 align:#right
	radiobuttons ztype "" labels:#("Normal","Navig","Info","Map") columns:4 --align:#right
	group "Island : (GTA3)" (
		radiobuttons island "" labels:#("Portland","Staunton","Shoreside") columns:3 --align:#right
	)	
	on getzone pressed do (
		if $selection.count != 1 then messagebox "Select a single object only!" Title:"Please select again"
		else (
			if (classof $ == Box)AND(getUserProp $ "Zone" == true) then (
				type = getUserProp $ "Type"
				IID = getUserProp $ "IslandID"
				if type != undefined then ztype.state = type + 1
				if IID != undefined then island.state = IID
				lblz.text = "Zone : " + $.name
			) else (
				messageBox "Not a ZONE, or\nNo ZONE data in this object." title:"ZONE Warning"
				lblz.text = "Zone : "
			)
		)--end if/else selection
	)--end on getzone

	on setzone pressed do (
		if $selection.count != 1 then messagebox "Select a single object only!" Title:"Please select again"
		else (
			if (classof $ == Box) then (
				lblz.text = "Zone : " + $.name
				setUserProp $ "Zone" true
				setUserProp $ "Type" (ztype.state - 1)
				setUserProp $ "IslandID" island.state
				$.wirecolor = color 255 255 0
				lblz.text = "Zone : " + $.name
			) else messageBox "Use Box primitive as ZONE" title:"ZONE Warning"
		)--end if/else
	)--end on setzone

	
)--end rollout ZONRoll


--2dfx--
--====--
Rollout Roll2dfx "2dfx" (
	label fxname "" align:#left across:2
	spinner Unkn "Unknown:" fieldwidth:45 range:[0,99999,200] type:#integer align:#right
	group "Lights" (
		spinner spVD "ViewDistance:" fieldwidth:45 range:[0,9999,300] type:#integer align:#right across:2
		spinner spLS "Lamp Size:" fieldwidth:45 range:[0,9999,1] type:#integer align:#right 
		spinner spOutR "Outter Radius:" range:[0,999,10] type:#integer fieldwidth:45 align:#right across:2
		spinner spInR  "Inner Radius:"  range:[0,999,5] type:#integer fieldwidth:45 align:#right
		spinner spCS  "Corona Size:"  range:[0,999,40] type:#integer fieldwidth:45 align:#right across:2
		spinner spRf  "Reflection:"  range:[0,999,0] type:#integer fieldwidth:45 align:#right
		spinner spLF  "Lens Flare:"  range:[0,999,0] type:#integer fieldwidth:45 align:#right across:2
		spinner spDust  "Dust:"  range:[0,999,0] type:#integer fieldwidth:45 align:#right
		colorpicker lgtcolor "" align:#left across:2
		dropdownlist dlcontrol width:200 items:#("light day/night", "light night", \
"flicker day/night", "flicker night", "blink 1 sec, day/night", "blink 1 sec, night", \
"blink 2 sec, day/night", "blink 2 sec, night", "light day", "blink 3 sec, night", \
"blink 3 sec, day/night", "random flicker at night (streetlamps)", "unknown") align:#right
	)
	group "Particles" (
		colorpicker parcolor "" align:#left across:3
		dropdownlist dlpar width:118 items:#("white steam medium", "white steam small", "white steam big", "Fire", "black smoke", "water spray up", "water fall down") align:#right
		spinner spPsize  "Size:"  range:[0,9999,0] fieldwidth:45 align:#right offset:[0,3]
		spinner spukn1  "Unknown:"  range:[-999,999,0] fieldwidth:45 align:#Left across:3
		spinner spukn2  "-"  range:[-999,999,0] fieldwidth:45 align:#right offset:[12,0]
		spinner spukn3  "-"  range:[-999,999,0] fieldwidth:45 align:#right --across:2
	)
	group "Ped Area" (
		colorpicker pedcolor "" align:#left across:2
        dropdownlist pedanim "" width:200 items:#("Automat (handle with object)","Seatplace","Busstop","Display Window","Unknown") align:#right
		spinner spdir1x  "Direction 1:"  range:[-999,999,0] fieldwidth:45 align:#Left across:3
		spinner spdir1y  "-"  range:[-999,999,0] fieldwidth:45 align:#right offset:[12,0]
		spinner spdir1z  "-"  range:[-999,999,0] fieldwidth:45 align:#right --across:2
		spinner spdir2x  "Direction 2:"  range:[-999,999,0] fieldwidth:45 align:#Left across:3
		spinner spdir2y  "-"  range:[-999,999,0] fieldwidth:45 align:#right offset:[12,0]
		spinner spdir2z  "-"  range:[-999,999,0] fieldwidth:45 align:#right --across:2
	)
	group "Sun Flares" (
		colorpicker sfcolor "" align:#left 
	)
	button getfx "Get" width:122 align:#left across:2
	button updatefx "Update" width:123 align:#right
	
	on updatefx pressed do (
		if superclassof obj == shape then (
			--check if new 2dfx--
			if (subString obj.name 1 5) != "2dfx_" then (
				createfx obj fxID
				fxID -= 0.0001
			)
			update2dfx obj Roll2dfx
		)
	)--end on updatefx 
	
	on getfx pressed do (
		if $selection.count > 1 then messagebox "Select a single shape only!" Title:"Please select again"	
		else
		if superclassof $ != shape then messagebox "Not a 2dfx!" Title:"Selection Error"
		else
		if ($.parent == undefined) then messagebox "Link the 2dfx to a mesh(ID ready) first!" Title:"ID Problem"
		else (	
			obj = $.parent
			while obj.parent != undefined do obj = obj.parent
			if getUserProp obj "ID" == undefined then (
				txt = "No ID in " + obj.name + "\nPlease Set it in Object Properties first!"
				messagebox txt title:"ID Problem"
			) else (
				ss = select2dfx $ Roll2dfx
				if ss == undefined then messagebox "Unknown 2dfx!!" title:"Selection Error"
				else 
				if ss == false then fxname.text = "**" + $.name
				else (
					fxname.text = $.name
					Unkn.value = getUserProp $ "unkn1"
				)
				obj = $
			)
		)
	)--end on getfx

)--end Rollout Roll2dfx



--About--
--=====--
rollout aboutRoll "About" (
	label l1 "GTA Mapping Tools v0.5b"
	label l2 ""
	label l3 "Support:" align:#left
	label l4 "   - IPL Import/export" align:#left
	label l4a "         . insts, cull (all Version)" align:#left
	label l4b "         . grge, enex, pick, jump, cars, auzo (SA only)" align:#left
	label l5 "   - ZON Import/export(GTA3/VC)" align:#left	
	label l6 "   - IDE Import/export" align:#left
	label l6a "         . objs, tobj (all Version)" align:#left
	label l6b "         . 2dfx (GTA3/VC, not sure in SA)" align:#left
	label l6c "         . anim, txdp (SA only)" align:#left
	label lA ""	
	label lB "by Kam  10Oct05" 
	label lC "kam.lai@ntlworld.com"
) 

rollout mapobjRoll "Map Objects Creation" (
	button creGrge "Grge" width:45 across:5
	button crePick "Pick" width:45 
	button creCars "Cars" width:45 
	button creEnex "Enex" width:45 
	button creAuzo "Auzo" width:45
	button creJump "Jump" width:45 across:5
	button creCull "Cull" width:45
	button dmy1 "" width:45 enabled:false
	button dmy2 "" width:45 enabled:false
	button dmy3 "" width:45 enabled:false
	on creGrge pressed do (
		nob = GTAgrge()
		select nob
	)
	on crePick pressed do (
		nob = GTApick()
		select nob
	)
	on creCars pressed do (
		nob = GTAcars()
		select nob
	)
	on creEnex pressed do (
		nob = NewEnex 1 1 [0,0,0] [0,2,0]
		select nob
	)
	on creAuzo pressed do (
		nob = GTAauzo()
		select nob
	)
	on creCull pressed do (
		nob = GTAcull xray:on
		select nob
	)
    on creJump pressed do (
		jmp = GTAland showlinks:true		
		jst = GTAjump pos:[1,-1,0] showlinks:true
		jst.parent = jmp
		jst.name = jmp.name + ".start"
		jcm = GTAjcam pos:[-1,-1,1] target:jmp 
		jcm.name = jmp.name + ".camera"
		jd = dummy boxsize:[1,1,1]
		jd.name = jmp.name + ".dummy"
		jcm.parent = jd
		jmp.parent = jd
		select jd
	)
)

rollout disproll "Display Helper" (
	button mapshow "Show Texture" width:120 tooltip:"Display texture on selected objects" align:#center across:2
	button maphide "Hide Texture" width:120 tooltip:"Hide texture on selected objects" align:#center

	on mapshow pressed do (
		if $selection.count > 0 then (
			freeSceneBitmaps()
			objary = $selection
			for obj in objary where obj.material != undefined do (
				if classof obj.material == Multimaterial then (
					for i = 1 to obj.material.count do (
						try (
							showTextureMap obj.material[i] obj.material[i].colormap on
						) catch (
							try (showTextureMap obj.material[i] obj.material[i].diffusemap on ) catch ()
						)
					)
				) else (
					try (
						showTextureMap obj.material obj.material.colormap on
					) catch (
						try (showTextureMap obj.material obj.material.diffusemap on ) catch ()
					)
				)
			)--end for obj	
		)--end if
	)--end on mapshow
	
		on maphide pressed do (
		if $selection.count > 0 then (
			objary = $selection
			for obj in objary where obj.material != undefined do (
				if classof obj.material == Multimaterial then (
					for i = 1 to obj.material.count do (
						try (
							showTextureMap obj.material[i] obj.material[i].colormap off
						) catch (
							try (showTextureMap obj.material[i] obj.material[i].diffusemap off ) catch ()
						)
					)
				) else (
					try (
						showTextureMap obj.material obj.material.colormap off
					) catch (
						try (showTextureMap obj.material obj.material.diffusemap off ) catch ()
					)
				)
			)--end for obj	
		)--end if
	)--end on mapshow
)

if Kam_GTAMAP != undefined then (closeRolloutFloater Kam_GTAMAP; gc() )
Kam_GTAMAP = newRolloutFloater "GTA Mapping Tools v0.5b" 300 500 10 60		
addRollout IORoll Kam_GTAMAP	rolledup:true
addRollout MapRoll Kam_GTAMAP 	--rolledup:true
addRollout Roll2dfx Kam_GTAMAP  rolledup:true
addRollout ZONRoll Kam_GTAMAP 	rolledup:true
addRollout mapobjRoll Kam_GTAMAP 	rolledup:true
addRollout disproll Kam_GTAMAP 	rolledup:true
addRollout aboutRoll Kam_GTAMAP	rolledup:true