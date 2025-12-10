--sa2dfx revision1
--2006 Jesse "DexX" Thoe
--v0.2f
--changelog 12/17/06
--since .2e, fixed an issue with how particle info was written. particle systems seem to work ok now. also minor UI update (disabled "create objects" stuff entirely).
--since .2d, general revision, tweaking, preparation for initial release. particle systems export supported.
--since .2c, revised 2d text info (11/06/06)
--since .2b, support for writing light info to file added.
--since .2a, particle, text info finished. disabled "Make Unique" feature (code is still present, just need to re-enable the button), finished off attribute deleting. now it only deletes SA-specific attributes.
--since .2, lighting finished, some extra (duplicate) code in 2dfx section deleted
--since .1 - everything, rewritten from scratch.

/*
global arrays to use for all images/types/systems since maxscript can't pass arguments from
one rollout to another.
*/

global fx_numimages
global fx_numpsystems
global fx_images = #()
global fx_psystems = #()
global fx_lighttypesnames = #() --names will be used in the dropdown lists
global fx_lightparam1 = #()
global fx_lightparam2 = #()
global fx_lightparam3= #()
global fx_info = 0 --print errors/messages to listener. critical errors (no objects selected..) are done via messagebox and must be displayed.
--ini-specific stuff, mainly Section names. key names will be handled on an as-needed basis
--global inifile = "scripts\\dexx_gta\\saparticle.ini"
global inifile = "saparticle.ini"
global inisetup = "particlesetup"
global initexname = "texturenames"
global inipssytems = "particlesystems"
global lighttypes = "lighttypes"
global inilastlight = "lastlight"
global inilastpsys = "lastpsys"
global inilasttext = "lasttext"
global inipath = (scriptsPath + inifile)
global lightcount
--temp filename, to avoid "undefined" errors
global effectfile = "C:\\test.sae"
--to be used
global numtextentries = 4 --number of lines of text to write to the file. used on export only.

fn fx_noobj =
(
	messagebox "No objects selected."
)

fn exportinfo =
(
	--effect types
	local effectlight = 0x00 --light info
	local effectparticle = 0x01 --particle system name
	--0x02 n/a
	local effectcard = 0x03 --for playing cards? also photo op places?
	--0x04 n/a
	--0x05 n/a
	local effect_6 = 0x06 --unknown
	local effecttext = 0x07 --2d sign text
	local effect_8 = 0x08 --used by slot machine wheels/scripted objects?
	local effect_9 = 0x09 --unknown, used alot (carter-column, stadium_sfse)
	local effectescalator = 0x0a --seems to be used only on escalators
	
	objtoexp  = #() --only objects in this array will be exported.
	
	for obj in $ do
	(
		--make sure only appropriate objects are selected, and that they have parameters to export
		if superclassof(obj) == light then
		(
			numattribs = custAttributes.count obj --count em up!
			if numattribs != 0 then --more than 0!
			(
				for a=1 to numattribs do
				(
					--check the attribute type
					custAttributes.get obj a
					attribtype = (custAttributes.getDef obj a).name
					if attribtype != undefined then --it HAS to have a name!
					(
						if attribtype == #fxdata_light then
						(
							--format "Deleted GTA Light info on %\n" obj.name
							append objtoexp obj
						)
					)--end undefined attribtype name (attributes added with paramter editor)
				)--end for
			)--end if
		)--end superclass if
		else
		if classof(obj) == Dummy then
		(
			numattribs = custAttributes.count obj --count em up!
			if numattribs != 0 then --more than 0!
			(
				for a=1 to numattribs do
				(
					--check the attribute type
					custAttributes.get obj a
					attribtype = (custAttributes.getDef obj a).name
					if attribtype != undefined then --it HAS to have a name!
					(
						if attribtype == #fxdata_particle then
						(
							--format "Deleted GTA Particle info on %\n" obj.name
							append objtoexp obj
						)
					)--end undefined attribtype name (attributes added with paramter editor)
				)--end for
			)--end if
		)--end class check
		else
		if classof(obj) == Plane then
		(
			numattribs = custAttributes.count obj --count em up!
			if numattribs != 0 then --more than 0!
			(
				for a=1 to numattribs do
				(
					--check the attribute type
					custAttributes.get obj a
					attribtype = (custAttributes.getDef obj a).name
					if attribtype != undefined then --it HAS to have a name!
					(
						if attribtype == #fxdata_text then
						(
							--format "Deleted GTA Text info on %\n" obj.name
							append objtoexp obj
						)
					)--end undefined attribtype name (attributes added with paramter editor)
				)--end if
			)--end for
		)--end class
	)--end obj loop
	
	--print objtoexp
	--print objtoexp.count
	
	--objects have been collected, time to start the export process
	effectstream=fopen effectfile "wb"
	--write file header info here
	writelong effectstream objtoexp.count
	
	for obj in objtoexp do
	(
		--print obj.name
		--determine object type, to know which info to write
		if superclassof(obj) == light then
		(
			--gather light info
			--declare data size for later use
			datsize = 0
			local tex1 = obj.sdfx_corona
			local tex2 = obj.sdfx_shad
			--determine light type
			local lightparam1
			local lightparam2
			local lightparam3
			(
				--format "Light Type: % \n" obj.sdfx_lighttype
				--do as a for loop
				--for light=1 to num light types
				for light = 1 to lightcount do
				(
					if obj.sdfx_lighttype == light then
					(
					--0 = mlampost
						lightparam1 = (getINISetting inipath lighttypes ("type" + (light as string) + "_param1")) as integer
						lightparam2 = (getINISetting inipath lighttypes ("type" + (light as string) + "_param2")) as integer
						lightparam3 = (getINISetting inipath lighttypes ("type" + (light as string) + "_param3")) as integer
					)
				)
			)
			--position
			posx = in coordsys parent obj.pos.x
			posy = in coordsys parent obj.pos.y
			posz = in coordsys parent obj.pos.z
			--colour
			lightred=obj.rgb.r
			lightgreen=obj.rgb.g
			lightblue=obj.rgb.b
			lightcolx = obj.sdfx_color4
			datsize = datsize + 4
			--draw dist, size, etc
			drawdist = obj.sdfxdrawdis
			outerrange = obj.sdfxouterrange
			lightsize = obj.sdfxsize
			innerrange = obj.sdfxinnerrange
			lightparam1 = lightparam1--light1
			lightparam2 = lightparam2 --light2
			datsize = datsize + 21
			--image1
			datsize = datsize + (tex1.count)
			padding = 13 --write 14 bytes, subtract one byte for text
			datsize = datsize + 14
			--image2
			datsize = datsize + (tex2.count)
			padding2 = 14 --write 15 bytes, subtract one byte for text
			datsize = datsize + 19
			lightparam3 = lightparam3 --light2
			datsize = datsize + 4
			
			--write light info
			writefloat effectstream posx
			writefloat effectstream posy
			writefloat effectstream posz
			writelong effectstream effectlight
			writelong effectstream datsize
			datsizepos = ftell effectstream
			--write light data
			writebyte effectstream lightred
			writebyte effectstream lightgreen
			writebyte effectstream lightblue
			writebyte effectstream lightcolx
			writefloat effectstream drawdist
			writefloat effectstream outerrange
			writefloat effectstream lightsize
			writefloat effectstream innerrange
			writelong effectstream lightparam1
			writebyte effectstream lightparam2
			writestring effectstream tex1
			for pad1=1 to padding do
			(
				writebyte effectstream 0
			)
			writestring effectstream tex2
			for pad2=1 to padding2 do
			(
				writebyte effectstream 0
			)
			writelong effectstream lightparam3
			writelong effectstream 25600
			
			format "Exported GTA light info on %\n" obj.name
		)
		else
		if classof(obj) == Dummy then
		(
			--get type info, need to determine what attributes are on dummy
			numattribs = custAttributes.count obj --count em up!
			if numattribs != 0 then --more than 0!
			(
				for a=1 to numattribs do
				(
					--check the attribute type
					custAttributes.get obj a
					attribtype = (custAttributes.getDef obj a).name
					if attribtype != undefined then --it HAS to have a name!
					(
						if attribtype == #fxdata_particle then
						(
							--append objtoexp obj
						--position
						posx = in coordsys parent obj.pos.x
						posy = in coordsys parent obj.pos.y
						posz = in coordsys parent obj.pos.z
						datsize = 0 --zero it to clear size data from last object
						--string info
						pstring = obj.sdfx_psys
						datsize = obj.sdfx_psys.count
						--datsize = datsize + pstring.count --string + terminator + garbage data is max 24 characters in length
						--garbage
						garbagesize = 24 - datsize
						--write particle info
						--write light info
						writefloat effectstream posx
						writefloat effectstream posy
						writefloat effectstream posz
						writelong effectstream effectparticle
						--writelong effectstream datsize
						writelong effectstream 24 --fixed size, don't do any more work than necessary?
						datsizepos = ftell effectstream
						writestring effectstream pstring --is also writing terminating 00
						for a=1 to (garbagesize - 1) do
						(
							writebyte effectstream 00
						)
						format "Exported GTA Particle info on %\n" obj.name
						)
					)--end undefined attribtype name (attributes added with paramter editor)
				)--end for
			)
		)
		else
		if classof(obj) == Plane then
		(
			--write text info. remember text is only 16 bytes per line! character "_" (0x5F) is used instead of " " (space, 0x20)
			--@ 16 bytes per line, 4 lines total, no more than 64 characters.
			--get all text data to a temporary array. will check each character to make sure there are no spaces (0x20)
			--and replace them if there are.
			
			local tempchar = #()
			local newchar = #()
			local finaltext
			tempchar = "" --needs to have some default value, otherwise is undefined
			newchar = "" --needs to have some default value, otherwise is undefined
			append tempchar obj.sdfx_text1
			append tempchar obj.sdfx_text2
			append tempchar obj.sdfx_text3
			append tempchar obj.sdfx_text4
			
			--correct text is necessary
			for char=0 to tempchar.count do
			(
				if tempchar[char] == " " then
				(
					--print "Space found!"
					tempchar[char] = "_"
					append newchar tempchar[char]
				)
				else
				if tempchar[char] != undefined then
				(
					--print "newchar appended"
					append newchar tempchar[char]
				)
				char = char + 1
			)
			
			--prepare final text
			finaltext = (newchar as string)
			--teh data is always 64 bytes. if they haven't entered 64 bytes of text, then append the space thats left.
			for letter=1 to (64 - finaltext.count) do
			(
				append finaltext "_"
			)
			--gather other data, position, rotation, size, etc
			pos = obj.pos
			--rot = obj.rotation as eulerangles
			rot = (quattoeuler obj.rotation order:1)
			type = effecttext
			size = 0x58 --should be fixed size
			scalex = obj.width
			scaley = obj.length			
			--write data
			writefloat effectstream obj.pos.x
			writefloat effectstream obj.pos.y
			writefloat effectstream obj.pos.z
			writelong effectstream type
			writelong effectstream size
			writefloat effectstream scalex
			writefloat effectstream scaley
			writefloat effectstream -rot.x --should be xyz?
			writefloat effectstream -rot.z
			writefloat effectstream -rot.y
			writeshort effectstream 00 --extra padding?
			writestring effectstream finaltext --write text, plus use max-appended "00" on the string
			writebyte effectstream 00 --write final null-terminator
		)
	)
	fclose effectstream
)--end exp fn

--might want to add a global function, for checking attributes types, taking index and objects as params
--end globals

rollout setupsafxsystems "Setup / Add Effects" width:156 height:520
(
	GroupBox grp6 "2dfx Attributes - Selection" pos:[4,4] width:140 height:208
	button btn_addlight "Add Light Info (Light)" pos:[8,20] width:128 height:20
	button btn_addparticle "Add Particle Info (Dummy)" pos:[8,44] width:128 height:20
	button btn_addtext "Add 2D Text (Plane)" pos:[8,68] width:128 height:20	enabled:false
	button btn_iniload "ReLoad 2dfx Ini" pos:[8,256] width:128 height:20 enabled:false
	button btn_attribdel "Delete 2dfx Data" pos:[8,232] width:128 height:20
	button btn_addesc "Add Escalator Info " pos:[8,92] width:128 height:20 enabled:false
	button btntype3 "Type 3" pos:[8,116] width:128 height:20 enabled:false
	button btntype6 "Type 6" pos:[8,140] width:128 height:20 enabled:false
	button btntype8 "Type 8" pos:[8,164] width:128 height:20 enabled:false
	button btntype9 "Type 9" pos:[8,188] width:128 height:20 enabled:false
	--setting the attribute to be unique doesnt seem to have any effect on objects which are instanced. in other words, its basically useless!
	GroupBox grp5 "Utilities" pos:[4,216] width:140 height:64
	--these features much further down the line, no point in cluttering the UI right now
	--GroupBox grp4 "Create Game Objects" pos:[4,284] width:140 height:88
	--button btn_createesc "Create Escalator" pos:[8,348] width:128 height:20 enabled:false
	--button btn21 "Create Light" pos:[8,300] width:128 height:20 enabled:false
	--button btn22 "Create Particle Sys" pos:[8,324] width:128 height:20 enabled:false
	
	fn fxadd_light =
	(
		--function to add 2dfx info, to a light (any type of light) object
		if $ != undefined then
		for obj in $ do
		(
			if superclassof(obj) == light then
			(
				--add 2dfx light info
				
				fxinfo = attributes fxdata_light
				(
					parameters main rollout:params
					(
						sdfxdrawdis type:#float ui:spn_drawdis default:100
						sdfxouterrange type:#float ui:spn_outrng default:0
						sdfxsize type:#float ui:spn_size default:0 --align:#right
						sdfxinnerrange type:#float ui:spn_inrng default:0
						sdfx_corona type:#string ui:edit_corona --default:0
						sdfx_shad type:#string ui:edit_shad --default:0
						sdfx_lighttype type:#integer ui:spn_type default:1
						sdfx_color4 type:#integer default:200 --default should be 200
					)
					
					rollout params "SA Light" width:160 height:400
					(
						spinner spn_drawdis "" pos:[88,4] width:64 height:16 range:[0,300,0]
						spinner spn_outrng "" pos:[88,64] width:64 height:16 range:[0,300,0]
						spinner spn_size "" pos:[88,24] width:64 height:16 range:[0,300,0]
						spinner spn_inrng "" pos:[88,44] width:64 height:16 range:[0,300,0]
						edittext edit_corona "" pos:[64,104] width:89 height:16 --enabled:false
						edittext edit_shad "" pos:[64,124] width:89 height:16 --enabled:false
						label lbl5 "Draw Distance" pos:[8,8] width:76 height:12
						label lbl6 "Outer Range" pos:[8,68] width:76 height:12
						label lbl7 "Size" pos:[8,27] width:76 height:12
						label lbl8 "Inner Range" pos:[8,48] width:76 height:12
						label lbl9 "Corona" pos:[8,104] width:48 height:12
						label lbl10 "Shad" pos:[8,124] width:48 height:12
						label lbl11 "Light Type" pos:[8,88] width:80 height:16
						spinner spn_type "" pos:[88,84] width:64 height:16 range:[0,300,0] type:#integer scale:1 enabled:false
					)
					
				)--end custom attribute
				
				
					custAttributes.add obj fxinfo --add the new set of data
					--obj.sdfxent = 1 --initialize attributes
					obj.sdfxdrawdis = 100.0
					obj.sdfxouterrange = 1.0
					obj.sdfxsize = 1.0
					obj.sdfxinnerrange = 1.0
					obj.sdfx_corona = "coronastar"
					obj.sdfx_shad = "shad_exp"
					obj.sdfx_lighttype = 1						
					--print any info
					format "Added GTA Light info to %\n" obj.name			
			)
			else
			format "Not a light object %\n" obj.name
		)
		else
		fx_noobj()
	)--end fxadd_light
	
	fn fxadd_particle =
	(
		--function to add 2dfx info, to a dummy (specifically) object
		if $ != undefined then
		for obj in $ do
		(
			--restrict object type to Dummy, not any type of helper obj
			if classof(obj) == Dummy then
			(
				--print obj.name
				--add 2dfx particle info				
				fxinfop = attributes fxdata_particle
				(
					parameters main rollout:params
					(
						sdfx_psys type:#string ui:edit_psys --default:0
					)--end parameters
					
					rollout params "SA Particle" width:160 height:400
					(
						edittext edit_psys "" pos:[48,4] width:109 height:16 --enabled:false
						label lbl10 "System" pos:[4,4] width:36 height:12
					)					
				)--end fxdata_particle
				(
					custAttributes.add obj fxinfop --add the new set of data
					--obj.sdfx_psys = "default"
					temppsys = getINISetting inipath inilastpsys "system" as integer
					obj.sdfx_psys = fx_psystems[temppsys] as string
					--print any info
					format "Added GTA Particle system info to %\n" obj.name
				)
				
			)--end classcheck
			else
			format "Not a dummy object %\n" obj.name
		)
		else
		fx_noobj()
	)--end fxadd_particle
	
	fn fxadd_text =
	(
		--function to add 2dfx info, to a dummy (specifically) object
		if $ != undefined then
		for obj in $ do
		(
			if classof(obj) == Plane then
			(
				print obj.name
				--add 2dfx text info
				fxinfot = attributes fxdata_text
				(
					parameters main rollout:params
					(
						sdfx_text1 type:#string ui:edit_text1
						sdfx_text2 type:#string ui:edit_text2
						sdfx_text3 type:#string ui:edit_text3
						sdfx_text4 type:#string ui:edit_text4
					)--end parameters
					
					rollout params "SA Sign Text" width:160 height:400
					(
						edittext edit_text1 "" pos:[40,20] width:109 height:16 enabled:false
						label lbl1 "Line 1" pos:[8,20] width:32 height:12
						GroupBox grp1 "Text" pos:[4,4] width:152 height:100
						edittext edit_text2 "" pos:[40,40] width:109 height:16 enabled:false
						label lbl9 "Line 2" pos:[8,40] width:32 height:12
						edittext edit_text3 "" pos:[40,60] width:109 height:16 enabled:false
						label lbl10 "Line 3" pos:[8,60] width:32 height:12
						edittext edit_text4 "" pos:[40,80] width:109 height:16 enabled:false
						label lbl11 "Line 4" pos:[8,80] width:32 height:12
					)				)--end fxdata_text
				
				(
					custAttributes.add obj fxinfot --add the new set of data
					obj.sdfx_text1 = ""
					obj.sdfx_text2 = ""
					obj.sdfx_text3 = ""
					obj.sdfx_text4 = ""
					--print any info
					format "Added GTA 2d Text info to %\n" obj.name
				)
			)			
			else
			format "Not a Plane object %\n" obj.name
		)
		else
		fx_noobj()
		
	)--end fxadd_text
	
	fn delcustattrib =
	(
		--delete all custom attributes on an object
		if $ != undefined then
		for obj in $ do
		(
			--check the attribute type. if it mtaches one of my types delete that one, and ONLY that one (preserve other attributes this way)
			if superclassof(obj) == light then
				(
					--does object have salight attributes on it?
					--code to check for existence here
						numattribs = custAttributes.count obj --count em up!
						if numattribs != 0 then --more than 0!
						(
							for a=1 to numattribs do
							(
								--check the attribute type
								custAttributes.get obj a
								attribtype = (custAttributes.getDef obj a).name
								if attribtype != undefined then --it HAS to have a name!
								(
									if attribtype == #fxdata_light then
									(
										--messagebox "light!"
										custAttributes.delete obj a
										format "Deleted GTA Light info on %\n" obj.name
									)
								)--end undefined attribtype name (attributes added with paramter editor)
							)
						)
				)
				else
				--check for other types
				if classof(obj) == Dummy then
				(
						numattribs = custAttributes.count obj --count em up!
						if numattribs != 0 then --more than 0!
						(
							for a=1 to numattribs do
							(
								--check the attribute type
								custAttributes.get obj a
								attribtype = (custAttributes.getDef obj a).name
								if attribtype != undefined then --it HAS to have a name!
								(
									if attribtype == #fxdata_particle then
									(
										custAttributes.delete obj a
										format "Deleted GTA Particle info on %\n" obj.name
									)
								)--end undefined attribtype name (attributes added with paramter editor)
							)
						)
				)
				else
				if classof(obj) == Plane then
				(
						numattribs = custAttributes.count obj --count em up!
						if numattribs != 0 then --more than 0!
						(
							for a=1 to numattribs do
							(
								--check the attribute type
								custAttributes.get obj a
								attribtype = (custAttributes.getDef obj a).name
								if attribtype != undefined then --it HAS to have a name!
								(
									if attribtype == #fxdata_text then
									(
										custAttributes.delete obj a
										format "Deleted GTA Text info on %\n" obj.name
									)
								)--end undefined attribtype name (attributes added with paramter editor)
							)
						)
				)
		)
		else
		fx_noobj()
	)--end delcustrattrib
	
	fn fxadd_escalator =
	(
		--function to add escalator
	)--end add escalator
	
	fn loadini =
	(
		--load the 2dfx info from the ini file, read ini string, to tell how many textures to be loaded
		gettexcount = getINISetting inipath inisetup "numtextures"
		getpsysount = getINISetting inipath inisetup "numparticlesys"
		numimages = gettexcount as integer
		numpsys = getpsysount as integer
		format "Number of particle textures: %\n" numimages
		format "Number of Particle systems %\n" numpsys
		
		local imgstring = "texture" --look for this string, the number will be appended automatically.
		local psysstring = "psys"
		
		--read texturename and add to array, then increment. repeat until reached limit defined above
		for texcounter=1 to numimages do
		(
			imagename = imgstring + (texcounter as string)
			texname = getINISetting inipath initexname imagename
			append fx_images texname
			format "Read particle texture %: %\n" texcounter texname
			texcounter=texcounter+1
		)
		--...and do it again, for particle systems
		for pcounter=1 to numpsys do
		(
			imagename = psysstring + (pcounter as string)
			parname = getINISetting inipath inipssytems imagename
			append fx_psystems parname
			format "Read particle system %: %\n" pcounter parname
			pcounter=pcounter+1
		)
		
	)--end loadini	
	
	on setupsafxsystems open do
	(
		--when 2dfx attributes rollout is opened...
		--clearListener()
		loadini() --load ini automatically
	)
	on btn_addlight pressed do
	(
		--add light info
		fxadd_light()
	)
	on btn_addparticle pressed do
	(
		--add particle info
		fxadd_particle()
	)
	on btn_addtext pressed do
	(
		--add 2d text section
		fxadd_text()
	)
	on btn_iniload pressed do
	(
		--reload Ini file
		loadini()
	)
	on btn_attribdel pressed do
	(
		--delete custrom attributes
		--should find a way to delete just special attribute data for that object type (ie, only delete the light 2dfx attrbiute on a light)
		delcustattrib()
	)
	on btn_addesc pressed do
	(
	--add escalator
	--will use a group of dummies, linked in a certain order
	)
	/*
	on btn_createesc pressed do
	(
	--add escalator
	--will use a group of dummies, linked in a certain order
	)
	on btn21 pressed do
	(
	--add escalator
	--will use a group of dummies, linked in a certain order
	)
	on btn22 pressed do
	(
	--add escalator
	--will use a group of dummies, linked in a certain order
	)
	*/
	on btn21 pressed do
	(
	--add type3 info
	)
	on btn22 pressed do
	(
	--add type6 info
	)
	on btn23 pressed do
	(
	--add type8 info
	)
	on btn24 pressed do
	(
	--add type9 info
	)
)


rollout setupsalight "Setup / Edit Lights" width:156 height:342
(
	GroupBox grp7 "Light Attributes" pos:[4,4] width:140 height:228
	label label_distance "Distance" pos:[8,20] width:48 height:12
	label label_otrang "Outer Range" pos:[8,80] width:68 height:12
	label label_size "Size" pos:[8,40] width:60 height:12
	label label_inrane "Inner Range" pos:[8,60] width:60 height:12
	spinner spn_outtrange "" pos:[80,80] width:61 height:16 range:[0,300,0]
	spinner spn_innrrange "" pos:[80,60] width:61 height:16 range:[0,300,0]
	spinner spn_size "" pos:[80,40] width:61 height:16 range:[0,100,0]
	spinner spn_distance "" pos:[80,20] width:61 height:16 range:[0,300,0]
	button btn1 "Apply to Light(s)" pos:[4,236] width:140 height:20
	dropdownList ddl_shad "Shad Image" pos:[8,144] width:124 height:40 items:fx_images selection:11
	dropdownList ddl_corona "Corona Image" pos:[8,100] width:124 height:40 items:fx_images selection:25
	--dropdownList ddl_shad "Shad Image" pos:[8,144] width:124 height:40 items:#("wincrack_32", "white", "waterwake", "waterclear256", "txgrassbig1", "txgrassbig0", "target256", "shad_rcbaron", "shad_ped", "shad_heli", "shad_exp", "shad_car", "shad_bike", "seabd32", "roadsignfont", "particleskid", "lunar", "lockonFire", "lockon", "lamp_shad_64", "headlight1", "headlight", "handman", "finishFlag", "coronastar", "coronaringb", "coronareflect", "coronamoon", "coronaheadlightline", "cloudmasked", "cloudhigh", "cloud1", "carfx1", "bloodpool_64") selection:11
	--dropdownList ddl_corona "Corona Image" pos:[8,100] width:124 height:40 items:#("wincrack_32", "white", "waterwake", "waterclear256", "txgrassbig1", "txgrassbig0", "target256", "shad_rcbaron", "shad_ped", "shad_heli", "shad_exp", "shad_car", "shad_bike", "seabd32", "roadsignfont", "particleskid", "lunar", "lockonFire", "lockon", "lamp_shad_64", "headlight1", "headlight", "handman", "finishFlag", "coronastar", "coronaringb", "coronareflect", "coronamoon", "coronaheadlightline", "cloudmasked", "cloudhigh", "cloud1", "carfx1", "bloodpool_64") selection:25
	dropdownList ddl_type "Light Type" pos:[8,188] width:124 height:40 enabled:true items:#("OnAtNight")
	groupBox grp5 "PreSets" pos:[4,260] width:140 height:60
	dropDownList ddl_preset "Light Presets" pos:[8,276] width:128 height:40 enabled:false items:#("Default","Streetlight Night")
	button btn_presetapply "Apply presets" pos:[4,324] width:140 height:20 enabled:false
	
	fn fx_dolightinfo =
	(
		if $ != undefined then
		(
			for obj in $ do
			(
				if superclassof(obj) == light then
				(
					--does object have salight attributes on it?
					--code to check for existence here
						numattribs = custAttributes.count obj --count em up!
						if numattribs != 0 then --more than 0!
						(
							for a=1 to numattribs do
							(
								--check the attribute type
								custAttributes.get obj a
								attribtype = (custAttributes.getDef obj a).name
								if attribtype == #fxdata_light then
								(
									--get current string names from dropdowns
									local corona = "coronastar"
									local shad = "shad_exp"
									(
										--code to get names from dropdown here
										corona = (ddl_corona.selected)
										shad = (ddl_shad.selected)
									)
									--apply the light settings
									obj.sdfxdrawdis = spn_distance.value
									obj.sdfxouterrange = spn_outtrange.value
									obj.sdfxsize = spn_size.value
									obj.sdfxinnerrange = spn_innrrange.value
									obj.sdfx_corona = corona
									obj.sdfx_shad = shad
									obj.sdfx_lighttype = ddl_type.selection
									--format "light type: % %\n" ddl_type.selection ddl_type.selected	
									--print any info
									format "Set GTA Light info on %\n" obj.name
									--will make optional, print the individual attributes that were applied to the light
									if fx_info == 1 then
									(
										format "% % set to % \n" obj.name label_distance.text spn_distance.value
										format "% % set to % \n" obj.name label_size.text spn_size.value
										format "% % set to % \n" obj.name label_inrane.text spn_innrrange.value
										format "% % set to % \n" obj.name label_otrang.text spn_outtrange.value
										--do other attributes later (after "options" are fully implmented
									)--end if fx_info
								)--end if attribname
							)--end for loop (attribs)
						)--end attribs != 0
						else --trying to edit non-existant attributes! for shame!
						(
							format "No GTA Light info on % \n" obj.name
						)
				)--end light type check
				else
				(
					format "Cannot apply light settings to non-light object %\n" obj.name
				)
			)
		)
	)
	
	on setupsalight open do
	(
		--setup variables, load data if necessary
		--load lastlight info
		spn_distance.value = (getINISetting inipath inilastlight "distance" as float)
		spn_size.value = (getINISetting inipath inilastlight "size" as float)
		spn_innrrange.value = (getINISetting inipath inilastlight "innerrange" as float)
		spn_outtrange.value = (getINISetting inipath inilastlight "outerrange" as float)
		ddl_shad.selection = (getINISetting inipath inilastlight "shad" as integer)
		ddl_corona.selection = (getINISetting inipath inilastlight "corona" as integer)
		ddl_type.selection = (getINISetting inipath inilastlight "type" as integer)
		
		--sort light types, populate arrays
		/* arrays that will be used
		global fx_lighttypesnames = #() --names will be used in the dropdown lists
		global fx_lightparam1 = #()
		global fx_lightparam2 = #()
		global fx_lightparam3= #()
		*/
		lightcount = (getINISetting inipath inisetup "numlighttypes" as integer)
		for lcount=1 to lightcount do
		(
			--print ("a word " + (lcount as string))
			entry = (getINISetting inipath lighttypes ("type" + (lcount as string) + "_name"))
			append fx_lighttypesnames (entry as string)
		)
		--add to the dropdown
		ddl_type.items = fx_lighttypesnames
	)
	
	on spn_outtrange entered do
	(
		--write value to ini file
		setINISetting inipath inilastlight "outerrange" (spn_outtrange.value as string)
	)
	
	on spn_innrrange entered do
	(
		--write value to ini file
		setINISetting inipath inilastlight "innerrange" (spn_innrrange.value as string)
	)
	
	on spn_size entered do
	(
		--write value to ini file
		setINISetting inipath inilastlight "size" (spn_size.value as string)
	)
	
	on spn_distance entered do
	(
		--write value to ini file
		setINISetting inipath inilastlight "distance" (spn_distance.value as string)
	)
	
	on btn1 pressed do
	(
		--apply light settings
		fx_dolightinfo()
	)
	
	on btn_presetapply pressed do
	(
		--apply presets
	)
	
	on ddl_shad selected sel do
	(
		--print selection
		setINISetting inipath inilastlight "shad" (sel as string)
	)
	
	on ddl_corona selected sel do
	(
		--print selection
		setINISetting inipath inilastlight "corona" (sel as string)
	)
	
	on ddl_type selected sel do
	(
		--print selection
		setINISetting inipath inilastlight "type" (sel as string)
	)
	
	on ddl_preset selected sel do
	(
		--print selection
	)
)


rollout setupsaparticle "Setup / Edit Particles" width:156 height:342
(
	GroupBox grp4 "Particles" pos:[4,4] width:140 height:84
	--dropdownList ddl_particle "Particle System" pos:[8,20] width:132 height:40 items:#("prt_blood", "prt_boatsplash", "prt_bubble", "prt_cardebris", "prt_collisionsmoke", "prt_glass", "prt_gunshell", "prt_sand", "prt_sand2", "prt_smokeII_3_expand", "prt_smoke_huge", "prt_spark", "prt_spark_2", "prt_splash", "prt_wake", "prt_watersplash", "prt_wheeldirt", "boat_prop", "camflash", "exhale", "explosion_fuel_car", "explosion_large", "explosion_medium", "explosion_molotov", "explosion_small", "explosion_tiny", "extinguisher", "fire", "fire_bike", "fire_car", "fire_large", "fire_med", "flamethrower", "gunflash", "gunsmoke", "heli_dust", "jetpack", "jetthrust", "molotov_flame", "nitro", "overheat_car", "overheat_car_electric", "riot_smoke", "spraycan", "tank_fire", "teargas", "teargasAD", "water_hydrant", "water_ripples", "water_speed", "water_splash", "water_splash_big", "water_splsh_sml", "water_swim", "cigarette_smoke", "Flame", "insects", "smoke30lit", "smoke30m", "smoke50lit", "vent", "vent2", "waterfall_end", "water_fnt_tme", "water_fountain", "tree_hit_fir", "tree_hit_palm", "blood_heli", "carwashspray", "cement", "cloudfast", "coke_puff", "coke_trail", "explosion_barrel", "explosion_crate", "explosion_door", "petrolcan", "puke", "shootlight", "smoke_flare", "wallbust", "ws_factorysmoke")
	dropdownList ddl_particle "Particle System" pos:[8,20] width:132 height:40 items:fx_psystems
	button btn_dumprtapply "Apply to Dummy(s)" pos:[8,64] width:132 height:20
	
	fn particleedit =
	(
		if $ != undefined then
		(
			for obj in $ do
			(
				if classof(obj) == Dummy then
				(
					--does object have saparticle attributes on it?
					--code to check for existence here
						numattribs = custAttributes.count obj --count em up!
						if numattribs != 0 then --more than 0!
						(
							for a=1 to numattribs do
							(
								--check the attribute type
								custAttributes.get obj a
								attribtype = (custAttributes.getDef obj a).name
								if attribtype == #fxdata_particle then
								(
									--edit particleobj
									obj.sdfx_psys = ddl_particle.selected
									format "Set % Particle System to % \n" obj.name obj.sdfx_psys
								)
							)--end for attribs
						)--end if numattribs
						else
						(
							format "No GTA Data on (%)\n" obj.name
							--print ("No GTA Data on " + obj.name)
						)
					)--end if class
					else
					(
						format "Not a helper object(%)." obj.name
					)
			)--end for
		)--end if
	)
	
	
	on setupsaparticle open do
	(
	--on open
	temppsys = getINISetting inipath inilastpsys "system" as integer
	ddl_particle.selection = temppsys
	)
	
	on ddl_particle selected sel do
	(
		--change ini setting
		setINISetting inipath inilastpsys "system" (sel as string)
	)
	
	on btn_dumprtapply pressed do
	(
		--apply particle to object
		particleedit()
	)
)

rollout setupsatext "Setup / Edit 2d Text" width:212 height:184
(
	button btn_applytext "Apply to Plane(s)" pos:[12,132] width:128 height:20
	
	edittext edt12 "" pos:[40,20] width:88 height:16
	label lbl12 "Line 1" pos:[8,20] width:32 height:12
	GroupBox grp3 "Text - 16 characters per line!" pos:[4,4] width:152 height:176
	edittext edt13 "" pos:[40,40] width:88 height:16
	label lbl13 "Line 2" pos:[8,40] width:32 height:12
	edittext edt14 "" pos:[40,60] width:88 height:16
	label lbl14 "Line 3" pos:[8,60] width:32 height:12
	edittext edt15 "" pos:[40,80] width:88 height:16
	label lbl15 "Line 4" pos:[8,80] width:32 height:12
	label lbl22 "Only 16 characters per line allowed, 4 lines total." pos:[8,100] width:144 height:28
	button btn_textkill "Destroy Plane(s) Text" pos:[12,156] width:128 height:20 toolTip:"This will clear all SA Sign test completely. The variables for the text, will become undefined."
	label txtcnt1 "%" pos:[132,20] width:20 height:12
	label txtcnt2 "%" pos:[132,40] width:20 height:12
	label txtcnt3 "%" pos:[132,60] width:20 height:12
	label txtcnt4 "%" pos:[132,80] width:20 height:12
	
	fn assigntext =
	(
		if $ != undefined then
		(
			for obj in $ do
			(
				if classof(obj) == Plane then
				(
					--does object have saparticle attributes on it?
					--code to check for existence here
						numattribs = custAttributes.count obj --count em up!
						if numattribs != 0 then --more than 0!
						(
							for a=1 to numattribs do
							(
								--check the attribute type
								custAttributes.get obj a
								attribtype = (custAttributes.getDef obj a).name
								if attribtype == #fxdata_text then
								(
									--set the text here
									obj.sdfx_text1 = edt12.text
									obj.sdfx_text2 = edt13.text
									obj.sdfx_text3 = edt14.text
									obj.sdfx_text4 = edt15.text
								)
							)--end for
						)--end if
				)--end if (classof)
			)--end for obj
		)--end if $
	)--end fn
	
	fn destroytext =
	(
		if $ != undefined then
		(
			for obj in $ do
			(
				if classof(obj) == Plane then
				(
					--does object have saparticle attributes on it?
					--code to check for existence here
						numattribs = custAttributes.count obj --count em up!
						if numattribs != 0 then --more than 0!
						(
							for a=1 to numattribs do
							(
								--check the attribute type
								custAttributes.get obj a
								attribtype = (custAttributes.getDef obj a).name
								if attribtype == #fxdata_text then
								(
									--set the text here
									obj.sdfx_text1 = ""
									obj.sdfx_text2 = ""
									obj.sdfx_text3 = ""
									obj.sdfx_text4 = ""
								)
							)--end for
						)--end if
				)--end if (classof)
			)--end for obj
		)--end if $
	)
	
	on setupsatext open do
	(
		--set any initial values
		txtcnt1.text = "0"
		txtcnt2.text = "0"
		txtcnt3.text = "0"
		txtcnt4.text = "0"
	)
	on btn_applytext pressed do
	(
		--apply text to plane
		--will need to mention specific text-related rules, such as character limit per line, and "_" used for space (only on export)
		assigntext()
	)
	on edt12 entered text do
	(
		--increment text count
		txtcnt1.text = (edt12.text.count as string)
	)
	on edt13 entered text do
	(
	--increment text count
	txtcnt2.text = (edt13.text.count as string)
	)
	on edt14 entered text do
	(
	--increment text count
	txtcnt3.text = (edt14.text.count as string)
	)
	on edt15 entered text do
	(
	--increment text count
	txtcnt4.text = (edt15.text.count as string)
	)
	on btn_textkill pressed do
	(
		--eliminate custom text
		destroytext()
	)
)


rollout setupexport "Export Effect Info" width:156 height:342
(
	button btn_export "Export Info" pos:[8,20] width:63 height:20
	groupBox grp2 "Export" pos:[4,4] width:144 height:95
	label lbl5 "Exports Effect Data to a binary file, that can be imported into a DFF using RWAnalyze." pos:[12,44] width:132 height:52
	
	on btn_export pressed do
	(
	--export info to binary file
		if $ != undefined then
		(
			--setup save file stuff
			effectfile = getSaveFileName caption:"SA Effect" types:"SA Effect(*.sae)|*.sae|All Files (*.*)|*.*|"
			if effectfile != undefined then (exportinfo())
			else
			format "No file saved\n"
		)
		else
		(--goto error function
			fx_noobj()
		)
	)
)

if (safx != undefined ) then
(
	closeRolloutFloater safx
)
safx = newrolloutfloater "SA Effects v0.2e" 170 500 10 100
addrollout setupsafxsystems safx rolledup:false
addrollout setupsalight safx rolledup:true
addrollout setupsaparticle safx rolledup:true
addrollout setupsatext safx rolledup:true
addrollout setupexport safx rolledup:true
--clearListener()