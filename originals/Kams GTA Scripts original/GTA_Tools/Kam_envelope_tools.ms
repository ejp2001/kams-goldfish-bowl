fn getCSval skn idx = (
	valAry = #()
	tcs = skinOps.getNumberCrossSections skn idx
	for j = 1 to tcs do (
		append valAry (skinOps.GetInnerRadius skn idx j) 
		append valAry (skinOps.GetOuterRadius skn idx j)
	)--end for j
	return valAry
)

rollout EnvTool_Roll "Envelopes Controls" (
	local blist = #()
	local skn = undefined
	local msh = undefined

	pickbutton selmesh "Pick a Skinned Char." width:150 height:30 align:#center 
	button dbinfo "Enveolpes info." width:150 align:#center enabled:false
	button setE0 "Set all Enveolpes to 0" width:150 align:#center offset:[0,-5] enabled:false
	spinner bidx "Bone#" fieldwidth:25 type:#integer align:#left offset:[0,2] across:2 enabled:false
	dropdownlist bname "" enabled:false
	label lbl "" align:#right
	group "Cross Sections" (
		spinner in1 "In " fieldwidth:45 align:#left across:2
		spinner out1 "Out " fieldwidth:45
		spinner in2 "In " fieldwidth:45 align:#left across:2
		spinner out2 "Out " fieldwidth:45
		spinner in3 "In " fieldwidth:45 align:#left across:2
		spinner out3 "Out " fieldwidth:45
		spinner in4 "In " fieldwidth:45 align:#left across:2
		spinner out4 "Out " fieldwidth:45
		spinner in5 "In " fieldwidth:45 align:#left across:2
		spinner out5 "Out " fieldwidth:45
	)
	listbox dmy "" height:6 items:#("  Little help tool designed to"," make GTA Char. skinning/"," envelope sizing more easily","","By Kam                  13Dec05","     kam.lai@ntlworld.com") enabled:false selection:0
	
	on selmesh picked obj do (
		if classof obj.modifiers[1] != skin then (
			messagebox "No Skin Modifier, or\nSkin Modifier not the topmost modifier"
			selmesh.text = "Pick a Skinned Char."
			dbinfo.enabled = false
			setE0.enabled = false
			bidx.enabled = false
			bname.enabled = false
			skn = undefined
		) else (
			select obj
			msh = obj
			max modify mode
			skn = obj.modifiers[1]
			subobjectlevel = 1
			ttb = skinops.GetNumberBones skn
			for i = 1 to ttb do append blist (skinops.GetBoneName skn i 1)
			bname.items = blist
			bidx.range = [1,ttb,1]
			dbinfo.enabled = true
			setE0.enabled = true
			bidx.enabled = true
			bname.enabled = true
			selmesh.text = obj.name + " [" + ttb as string +"]"
			lbl.text = "   no. CrossSection: " + (skinOps.getNumberCrossSections skn 1) as string
			valAry = getCSval skn 1
			if valAry.count >= 2 then (in1.value = valAry[1]; out1.value = valAry[2])
			if valAry.count >= 4 then (in2.value = valAry[3]; out2.value = valAry[4])		
			if valAry.count >= 6 then (in3.value = valAry[5]; out3.value = valAry[6])		
			if valAry.count >= 8 then (in4.value = valAry[8]; out4.value = valAry[8])
			if valAry.count >= 10 then (in5.value = valAry[9]; out5.value = valAry[10])
		)--end if/else
	)--end on selmesh

	on dbinfo pressed do (
		clearlistener()
		select msh
		max modify mode
		ttb = skinops.GetNumberBones skn
		for i = 1 to ttb do (
			tcs = skinOps.getNumberCrossSections skn i
			format "bone :%\t%\n" i (skinops.GetBoneName skn i 1)
			for j = 1 to tcs do (
				--(skinOps.SetInnerRadius skn i j 0)
				--(skinOps.SetOuterRadius skn i j 0)
				format "\tCrossSection: %\tInner: %\tOuter: %\n" j (skinOps.GetInnerRadius skn i j) (skinOps.GetOuterRadius skn i j)
			)--end for j
		)--end for i	
	)--end on dbinfo
	
	on setE0 pressed do (
		select msh
		max modify mode
		ttb = skinops.GetNumberBones skn
		for i = 1 to ttb do (
			tcs = skinOps.getNumberCrossSections skn i
			for j = 1 to tcs do (
				(skinOps.SetInnerRadius skn i j 0)
				(skinOps.SetOuterRadius skn i j 0)
			)--end for j
		)--end for i	
	)--end on dbinfo
	
	on bidx changed val do (
		select msh
		max modify mode
		subobjectlevel = 1
		bname.selection = val
		skinops.SelectBone skn val
		lbl.text = "   no. CrossSection: " + (skinOps.getNumberCrossSections skn val) as string
		valAry = getCSval skn val
		if valAry.count >= 2 then (in1.value = valAry[1]; out1.value = valAry[2])
		if valAry.count >= 4 then (in2.value = valAry[3]; out2.value = valAry[4])		
		if valAry.count >= 6 then (in3.value = valAry[5]; out3.value = valAry[6])		
		if valAry.count >= 8 then (in4.value = valAry[8]; out4.value = valAry[8])
		if valAry.count >= 10 then (in5.value = valAry[9]; out5.value = valAry[10])
	)
	on bname selected itm do (
		select msh
		max modify mode
		subobjectlevel = 1
		bidx.value = bname.selection
		skinops.SelectBone skn bname.selection
		lbl.text = "   no. CrossSection: " + (skinOps.getNumberCrossSections skn bname.selection) as string
		valAry = getCSval skn bname.selection	
		if valAry.count >= 2 then (in1.value = valAry[1]; out1.value = valAry[2])
		if valAry.count >= 4 then (in2.value = valAry[3]; out2.value = valAry[4])		
		if valAry.count >= 6 then (in3.value = valAry[5]; out3.value = valAry[6])		
		if valAry.count >= 8 then (in4.value = valAry[8]; out4.value = valAry[8])
		if valAry.count >= 10 then (in5.value = valAry[9]; out5.value = valAry[10])
	)
	
	on in1 changed val do (
		try (
			skinOps.SetInnerRadius skn bidx.value 1 val
		)catch()
	)--end on in1
	on out1 changed val do (
		try (
			skinOps.SetOuterRadius skn bidx.value 1 val
		)catch()
	)--end on out1
	on in2 changed val do (
		try (
			skinOps.SetInnerRadius skn bidx.value 2 val
		)catch()
	)--end on in2
	on out2 changed val do (
		try (
			skinOps.SetOuterRadius skn bidx.value 2 val
		)catch()
	)--end on out2
	on in3 changed val do (
		try (
			skinOps.SetInnerRadius skn bidx.value 3 val
		)catch()
	)--end on in3
	on out3 changed val do (
		try (
			skinOps.SetOuterRadius skn bidx.value 3 val
		)catch()
	)--end on out3
	on in4 changed val do (
		try (
			skinOps.SetInnerRadius skn bidx.value 4 val
		)catch()
	)--end on in4
	on out4 changed val do (
		try (
			skinOps.SetOuterRadius skn bidx.value 4 val
		)catch()
	)--end on out4
	on in5 changed val do (
		try (
			skinOps.SetInnerRadius skn bidx.value 5 val
		)catch()
	)--end on in5
	on out5 changed val do (
		try (
			skinOps.SetOuterRadius skn bidx.value 5 val
		)catch()
	)--end on out5

)--end rollout

if Kam_EnvTool != undefined then (closeRolloutFloater Kam_EnvTool; gc())
Kam_EnvTool = newRolloutFloater "Kam's Envelope Tool" 200 415 10 50
addRollout EnvTool_Roll Kam_EnvTool