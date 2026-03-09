-- GTA 2DFX Particle Editor
-- Extracted from GTAScript_Controller.ms (February 2026)
-- Assigns particle effects to Dummy objects for GTA San Andreas

-- Initialize particle effects list
global effects
if effects==undefined then
(
	effects=#("prt_blood", "prt_boatsplash", "prt_bubble", "prt_cardebris",
"prt_collisionsmoke", "prt_glass", "prt_gunshell", "prt_sand",
"prt_sand2", "prt_smokeII_3_expand", "prt_smoke_huge", "prt_spark",
"prt_spark_2", "prt_splash", "prt_wake", "prt_watersplash",
"prt_wheeldirt", "boat_prop", "camflash", "exhale", "explosion_fuel_car",
"explosion_large", "explosion_medium", "explosion_molotov", "explosion_small",
"explosion_tiny", "extinguisher", "fire", "fire_bike", "fire_car",
"fire_large", "fire_med", "flamethrower", "gunflash", "gunsmoke",
"heli_dust", "jetpack", "jetthrust", "molotov_flame", "nitro",
"overheat_car", "overheat_car_electric", "riot_smoke", "spraycan",
"tank_fire", "teargas", "teargasAD", "water_hydrant", "water_ripples",
"water_speed", "water_splash", "water_splash_big", "water_splsh_sml",
"water_swim", "cigarette_smoke", "Flame", "insects", "smoke30lit",
"smoke30m", "smoke50lit", "vent", "vent2", "waterfall_end",
"water_fnt_tme", "water_fountain", "tree_hit_fir", "tree_hit_palm",
"blood_heli", "carwashspray", "cement", "cloudfast", "coke_puff", "coke_trail", 
"explosion_barrel", "explosion_crate", "explosion_door",
"petrolcan", "puke", "shootlight", "smoke_flare", "wallbust", "ws_factorysmoke")
	global selectedEffect=undefined
)

rollout DFF2dfx_prt "Particle export" (		
	label txt1 "Particle name:" align:#left
	editText edt_prt "" width:160 height:20 align:#left
	listBox lbx2 "" items:(effects) selection:1 width:157 height:10 align:#right
	button btn_prt_set "Set to selected DUMMY" width:160 height:30 offset:[0,5]
	button btn_close_prt "Close" align:#center width:180 height:22 offset:[0,5] 	
	
	on lbx2 selected prtName do (
		edt_prt.text = lbx2.selected
	)
	
	on btn_prt_set pressed do (
		if selection.count == 0 then (
			messagebox "Select at least one Dummy object!" title:"Particle 2DFX"
		) else (
			local setCount = 0
			for dm in selection where (superclassof dm == helper and classof dm == Dummy) do (
				setUserProp dm "2dfx" "true"
				setUserProp dm "2dfx_type" "1"
				setUserProp dm "particle_name" edt_prt.text
				setCount += 1
			)
			if setCount > 0 then (
				messagebox ("Particle 2DFX set on " + setCount as string + " dummy object(s)") title:"Particle 2DFX"
			) else (
				messagebox "No Dummy objects found in selection!" title:"Particle 2DFX"
			)
		)
	)
	
	on btn_close_prt pressed do try (closeRolloutFloater DFF2dfx_prt_rol) catch ()
)

-- Launch the editor
try (closeRolloutFloater DFF2dfx_prt_rol) catch () 
DFF2dfx_prt_rol = newRolloutFloater "Particle" 200 320
addRollout DFF2dfx_prt DFF2dfx_prt_rol
