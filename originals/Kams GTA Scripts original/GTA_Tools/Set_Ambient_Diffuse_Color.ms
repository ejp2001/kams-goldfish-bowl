    (
    	fn SetColor mat prop col =
    	(
    		if isProperty mat prop do
    		(
    			setProperty mat prop col
    		)
    	)
    	fn ChangeMaterialColor mats col =
    	(
    		for mat in mats do
    		(
    			if classof mat == MultiSubMaterial then
    			(
    				ChangeMaterialColor mat col
    			)
    			else
    			(
    				SetColor mat #diffuseColor col
    				SetColor mat #ambientColor col
    			)
    		)
    	)
    	ChangeMaterialColor SceneMaterials white
    )

