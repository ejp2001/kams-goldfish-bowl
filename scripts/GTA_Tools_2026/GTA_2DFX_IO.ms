global DFF2dfx

-- Load 2dfx UI components
try (fileIn (scriptspath+"\\GTA_Tools_2026\\ui_2dfx.ms") quiet:true) catch (format "Error loading ui_2dfx.ms: %\n" (getCurrentException()))

rollout DFF2dfxMain "2dfx Effects" width:250 (
	label info1 "GTA San Andreas 2dfx Effects" align:#center
	label info2 "Add lights, particles, and attractors" align:#center style_sunkenedge:true
	
	group "Quick Info" (
		label info3 "Select an OMNILIGHT and click a" align:#left
		label info4 "button below to configure its" align:#left
		label info5 "2dfx properties for export." align:#left
	)
	
	group "Effect Types" (
		button fx_lght "LIGHT" width:220 height:30 tooltip:"Corona lights with colors, shadows, flare (use OmniLights!)"
		button fx_prt "Particle System" width:220 height:30 tooltip:"Particle effects (smoke, fire, water, etc.)"
		button fx_sgn "Ped Attractor" width:220 height:30 tooltip:"Animation triggers for pedestrians"
	)
	
	group "Workflow" (
		label info6 "1. Create OMNILIGHT objects" align:#left
		label info7 "2. Assign 2dfx properties using buttons" align:#left
		label info8 "3. Export DFF with effects embedded" align:#left
	)
	
	on fx_lght pressed do (
		if DFF2dfx != undefined then (
			-- Call the original button handler from ui_2dfx.ms
			DFF2dfx.fx_lght.pressed()
		) else (
			messageBox "2dfx system not loaded properly. Please reload the tool." title:"Error"
		)
	)
	
	on fx_prt pressed do (
		if DFF2dfx != undefined then (
			DFF2dfx.fx_prt.pressed()
		) else (
			messageBox "2dfx system not loaded properly. Please reload the tool." title:"Error"
		)
	)
	
	on fx_sgn pressed do (
		if DFF2dfx != undefined then (
			DFF2dfx.fx_sgn.pressed()
		) else (
			messageBox "2dfx system not loaded properly. Please reload the tool." title:"Error"
		)
	)
)

-- Create and show floater
try (closeRolloutFloater twoDFX_Floater) catch ()
twoDFX_Floater = newRolloutFloater "2dfx Editor" 250 350 10 50
addRollout DFF2dfxMain twoDFX_Floater
