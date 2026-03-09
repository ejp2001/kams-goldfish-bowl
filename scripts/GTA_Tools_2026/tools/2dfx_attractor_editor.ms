-- GTA 2DFX Ped Attractor Editor
-- Extracted from GTAScript_Controller.ms (February 2026)
-- Sets pedestrian animation triggers on Dummy objects for GTA San Andreas

rollout DFF2dfx_sgn "Ped Attractor export" (	
	label txt1 "Attractor Animation Type:" align:#left
	dropDownList pedAnimType "" items:#(
		"0 - Sit", "1 - Sit relaxed", "2 - Lean wall", "3 - Shelter",
		"4 - Talk phone", "5 - Idle", "6 - Jog", "7 - Cower"
	) width:180 height:10 align:#left
	
	group "Bounding Box" (
		label lblCorner1 "Corner 1 (min):" align:#left
		spinner corner1X "X:" range:[-1000, 1000, -1.0] type:#float width:170 align:#left
		spinner corner1Y "Y:" range:[-1000, 1000, -1.0] type:#float width:170 align:#left
		spinner corner1Z "Z:" range:[-1000, 1000, 0.0] type:#float width:170 align:#left
		
		label lblCorner2 "Corner 2 (max):" align:#left
		spinner corner2X "X:" range:[-1000, 1000, 1.0] type:#float width:170 align:#left
		spinner corner2Y "Y:" range:[-1000, 1000, 1.0] type:#float width:170 align:#left
		spinner corner2Z "Z:" range:[-1000, 1000, 2.0] type:#float width:170 align:#left
	)
	
	button btn_ped_set "Set to selected DUMMY" width:180 height:30 offset:[0,5]
	button btn_close_sgn "Close" align:#center width:180 height:22 offset:[0,5]
	
	on btn_ped_set pressed do (
		if selection.count == 0 then (
			messagebox "Select at least one Dummy object!" title:"Ped Attractor 2DFX"
		) else (
			local setCount = 0
			for dm in selection where (superclassof dm == helper and classof dm == Dummy) do (
				setUserProp dm "2dfx" "true"
				setUserProp dm "2dfx_type" "3"
				setUserProp dm "ped_anim_type" (pedAnimType.selection - 1)
				setUserProp dm "ped_corner1_x" corner1X.value
				setUserProp dm "ped_corner1_y" corner1Y.value
				setUserProp dm "ped_corner1_z" corner1Z.value
				setUserProp dm "ped_corner2_x" corner2X.value
				setUserProp dm "ped_corner2_y" corner2Y.value
				setUserProp dm "ped_corner2_z" corner2Z.value
				setCount += 1
			)
			if setCount >0 then (
				messagebox ("Ped Attractor 2DFX set on " + setCount as string + " dummy object(s)") title:"Ped Attractor 2DFX"
			) else (
				messagebox "No Dummy objects found in selection!" title:"Ped Attractor 2DFX"
			)
		)
	)
	
	on btn_close_sgn pressed do try (closeRolloutFloater DFF2dfx_sgn_rol) catch () 	
)

-- Launch the editor
try (closeRolloutFloater DFF2dfx_sgn_rol) catch () 
DFF2dfx_sgn_rol = newRolloutFloater "Ped Attractor" 220 420
addRollout DFF2dfx_sgn DFF2dfx_sgn_rol
