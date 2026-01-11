--15Dec05--

--fns should be hidden--
------------------------
global lightArr_
global LetsRockandRoll = true		--hidden feature--
global impHas2dfx
global imp2dfxCount
Global FrameAry = #()
Global SkinData = #()
global implightErr = false
global isIplImport = false
global cntLDffNow
global cntLDffMax

-- Ensure commonly-used globals are initialized
if (lightArr_ == undefined) then lightArr_ = #()
if (imp2dfxCount == undefined) then imp2dfxCount = 0
if (cntLDffNow == undefined) then cntLDffNow = 0
if (cntLDffMax == undefined) then cntLDffMax = 0
if (DebugMode == undefined) then DebugMode = false

/* ============================================================================
   UV ANIMATION IMPORT MODULE
   Automatically imports UV animation data from DFF and applies to materials
   ============================================================================ */

global gUVAnimDict = #()  -- Array to store UV animation data during import
global gUVAnimImportEnabled = true -- Enable/disable UV animation import
global gAppliedMaterialAnims = #()  -- Track which animations have been applied to which materials

struct UVAnimData (
	name,           -- Material name
	keyCount,       -- Number of keyframes
	startTime,      -- Start time
	endTime,        -- End time
	keyframes       -- Array of keyframe data [time, unused, u_tiling, v_tiling, unused, u_offset, v_offset, prevKey]
)

-- Read UV Animation Dictionary (0x2B) from file
fn ReadUVAnimDictionary f ver = (
	local dictData = #()
	local dictStart = ftell f - 4  -- Back up to include the chunk ID we already read
	local dictSizePos = ftell f
	local dictSize = readLong f #unsigned
	local dictVer = readLong f #unsigned
	local dictEnd = dictSizePos + dictSize + 8  -- +8 for size (4) + version (4)
	
	-- Read struct (0x01)
	local structStart = ftell f
	local structID = readLong f #unsigned
	if structID != 0x01 then (
		format "Warning: Expected struct ID 0x01, got 0x%\n" (bit.intAsHex structID)
		fseek f dictEnd #seek_set  -- Skip to end of dictionary
		return #()
	)
	
	local structSize = readLong f #unsigned
	local structVer = readLong f #unsigned
	local structEnd = structStart + 8 + structSize
	local animCount = readLong f #unsigned
	
	format "     Reading UV Animation Dictionary (% animations)\n" animCount
	
	-- Read each animation entry
	for i = 1 to animCount do (
		local entryStart = ftell f  -- Remember where this entry starts (at the chunk ID)
		local entryID = readLong f #unsigned
		if entryID != 0x1B then (
			format "Warning: Expected animation entry ID 0x1B at position %, got 0x%\n" entryStart (bit.intAsHex entryID)
			fseek f dictEnd #seek_set  -- Skip to end of dictionary
			return dictData
		)
		
		local sizePos = ftell f  -- Position where size field is
		local entrySize = readLong f #unsigned
		local afterSize = ftell f
		local entryVer = readLong f #unsigned
		-- Note: Animation entries seem to need +4 to the standard RenderWare calculation
		local entryEnd = afterSize + entrySize + 4
		
		-- Read animation header
		local flags = readLong f #unsigned
		local animType = readLong f #unsigned  -- should be 449 for UV
		local keyCount = readLong f #unsigned
		local startTime = readFloat f
		local endTime = readFloat f
		local unknown = readLong f #unsigned
		
		-- Read animation name (32 bytes, null-terminated)
		local animName = ""
		for j = 1 to 32 do (
			local ch = readByte f #unsigned
			if ch != 0 then animName += bit.intAsChar ch
		)
		
		-- Read keyframe data (32 bytes per key: 7 floats + 1 int)
		local keyframes = #()
		for k = 1 to keyCount do (
			local keyData = #()
			for j = 1 to 7 do append keyData (readFloat f)
			append keyData (readLong f)
			append keyframes keyData
		)
		
		-- Skip any remaining data in the chunk
		local posAfterKeys = ftell f
		if posAfterKeys < entryEnd then (
			for b = 1 to (entryEnd - posAfterKeys) do readByte f #unsigned
		)
		
		local uvAnim = UVAnimData name:animName keyCount:keyCount \
			startTime:startTime endTime:endTime keyframes:keyframes
		
		append dictData uvAnim
		format "       - Animation: % (% keys)\n" animName keyCount
	)
	
	-- Make sure we're at the correct position after the dictionary
	fseek f dictEnd #seek_set
	
	dictData
)

-- Read Material Animation PLG (0x135) from material extension
fn ReadMaterialAnimPLG f ver = (
	local plgStart = ftell f  -- Remember start position
	local plgSize = readLong f #unsigned
	local plgVer = readLong f #unsigned
	local plgEnd = plgStart + plgSize + 8  -- Calculate end position (+8 for size and version)
	
	-- Read struct (0x01)
	local structID = readLong f #unsigned
	if structID != 0x01 then (
		fseek f plgEnd #seek_set  -- Make sure we're at the right position even if we fail
		return undefined
	)
	
	local structSize = readLong f #unsigned
	local structVer = readLong f #unsigned
	
	local hasAnim = readLong f #unsigned
	
	-- Read animation name (32 bytes)
	local animName = ""
	for j = 1 to 32 do (
		local ch = readByte f #unsigned
		if ch != 0 then animName += bit.intAsChar ch
	)
	
	-- Ensure file pointer is at the correct position after the PLG
	fseek f plgEnd #seek_set
	
	if hasAnim == 1 then animName else undefined
)

-- Apply UV animation data to a material
fn ApplyUVAnimToMaterial mtl animData = (
	if animData == undefined then return false
	
	local bmap = undefined
	if isKindOf mtl GTA_Mtl then (
		if mtl.colormap != undefined and classof mtl.colormap == Bitmaptexture then bmap = mtl.colorMap
	) else if isKindOf mtl Standard then (
		if mtl.DiffuseMap != undefined and classof mtl.DiffuseMap == Bitmaptexture then bmap = mtl.DiffuseMap
	)
	
	if bmap == undefined then (
		format "Warning: Cannot apply UV animation to % - no bitmap texture found\n" mtl.name
		return false
	)
	
	try (
		-- Ensure controllers exist
		if bmap.coords.u_offset.controller == undefined then bmap.coords.u_offset.controller = bezier_float()
		if bmap.coords.v_offset.controller == undefined then bmap.coords.v_offset.controller = bezier_float()
		if bmap.coords.u_tiling.controller == undefined then bmap.coords.u_tiling.controller = bezier_float()
		if bmap.coords.v_tiling.controller == undefined then bmap.coords.v_tiling.controller = bezier_float()
		
		-- Clear existing keys by deleting them one by one
		while bmap.coords.u_offset.controller.keys.count > 0 do 
			deleteKey bmap.coords.u_offset.controller 1
		while bmap.coords.v_offset.controller.keys.count > 0 do 
			deleteKey bmap.coords.v_offset.controller 1
		while bmap.coords.u_tiling.controller.keys.count > 0 do 
			deleteKey bmap.coords.u_tiling.controller 1
		while bmap.coords.v_tiling.controller.keys.count > 0 do 
			deleteKey bmap.coords.v_tiling.controller 1
		
		-- Calculate animation range and deduplicate/snap keyframes
		local maxTime = 0f
		local cleanedKeyframes = #()
		local seenFrames = #{}  -- Use a bitArray for tracking seen frames
		
		for keyData in animData.keyframes do (
			-- keyData[1] is time in seconds, convert to frames
			local frameTime = (keyData[1] * frameRate)
			local snappedFrame = (floor (frameTime + 0.5)) as integer  -- Round to nearest frame
			
			-- Skip keys where tiling is 0,0 (initialization frames)
			local u_tiling = keyData[3]
			local v_tiling = keyData[4]
			if u_tiling < 0.01 and v_tiling < 0.01 then continue
			
			-- Only add first key for each frame (frame numbers start at 0, bitArray indices start at 1)
			local frameIndex = snappedFrame + 1
			-- Check if NOT already in the set (unset bits return undefined, not false)
			if seenFrames[frameIndex] != true then (
				-- Create new keyData array with snapped frame number (store as frame, not seconds)
				local newKeyData = #()
				newKeyData[1] = snappedFrame  -- Store frame number directly
				
				-- Copy all other values
				for i = 2 to keyData.count do (
					newKeyData[i] = keyData[i]
				)
				
				append cleanedKeyframes newKeyData
				seenFrames[frameIndex] = true
				
				if snappedFrame > maxTime then maxTime = snappedFrame
			)
		)
		
		format "     Reduced % keys to % keys (removed duplicates on same frames)\n" \
			animData.keyframes.count cleanedKeyframes.count
		
		-- Remove consecutive keys with identical offset values (redundant frames)
		if cleanedKeyframes.count > 1 then (
			local finalKeyframes = #()
			append finalKeyframes cleanedKeyframes[1]  -- Always keep first key
			
			for i = 2 to cleanedKeyframes.count do (
				local prevKey = cleanedKeyframes[i-1]
				local currKey = cleanedKeyframes[i]
				
				-- Compare offset values (indices 6 and 7)
				local prevU = prevKey[6]
				local prevV = prevKey[7]
				local currU = currKey[6]
				local currV = currKey[7]
				
				-- Only add if offset changed (tolerance for floating point)
				if abs(currU - prevU) > 0.001 or abs(currV - prevV) > 0.001 then (
					append finalKeyframes currKey
				)
			)
			
			if finalKeyframes.count != cleanedKeyframes.count then (
				format "     Further reduced to % keys (removed consecutive duplicates)\n" finalKeyframes.count
			)
			cleanedKeyframes = finalKeyframes
		)
		
		-- For sprite sheets: fill missing frames to ensure step behavior works
		-- Add keys on frame before each change to "hold" the previous value
		if cleanedKeyframes.count > 1 then (
			local needsFilling = false
			for i = 2 to cleanedKeyframes.count do (
				local gap = cleanedKeyframes[i][1] - cleanedKeyframes[i-1][1]
				if gap > 1 then (
					needsFilling = true
					exit
				)
			)
			
			if needsFilling then (
				local filledKeyframes = #()
				
				for i = 1 to cleanedKeyframes.count do (
					local currKey = cleanedKeyframes[i]
					local currFrame = currKey[1]
					append filledKeyframes currKey
					
					-- If there's a next key and it's more than 1 frame away, fill ALL the gap frames
					if i < cleanedKeyframes.count then (
						local nextKey = cleanedKeyframes[i+1]
						local nextFrame = nextKey[1]
						
						-- Fill every frame in the gap with the current value
						for fillFrame = (currFrame + 1) to (nextFrame - 1) do (
							local holdKey = #()
							holdKey[1] = fillFrame
							for j = 2 to currKey.count do (
								holdKey[j] = currKey[j]  -- Same values as current key
							)
							append filledKeyframes holdKey
						)
					)
				)
				
				format "     Added % hold keys (filled all gaps with keys on every frame)\n" (filledKeyframes.count - cleanedKeyframes.count)
				cleanedKeyframes = filledKeyframes
			)
		)
		
		-- Detect animation type: sprite sheet vs scrolling
		local isSpriteSheet = false
		if cleanedKeyframes.count > 1 then (
			local firstTiling_u = cleanedKeyframes[1][3]
			local firstTiling_v = cleanedKeyframes[1][4]
			local tilingConstant = true
			
			-- Check if tiling stays constant
			for keyData in cleanedKeyframes do (
				if (abs (keyData[3] - firstTiling_u) > 0.001) or (abs (keyData[4] - firstTiling_v) > 0.001) then (
					tilingConstant = false
					exit
				)
			)
			
			-- Check if offsets change in regular increments (sprite sheet pattern)
			if cleanedKeyframes.count > 2 and tilingConstant then (
				local offset1_u = cleanedKeyframes[1][6]
				local offset1_v = cleanedKeyframes[1][7]
				
				-- Find first key with different offset
				local offset2_u = offset1_u
				local offset2_v = offset1_v
				local foundDifferent = false
				
				for i = 2 to cleanedKeyframes.count do (
					offset2_u = cleanedKeyframes[i][6]
					offset2_v = cleanedKeyframes[i][7]
					if abs(offset2_u - offset1_u) > 0.001 or abs(offset2_v - offset1_v) > 0.001 then (
						foundDifferent = true
						exit
					)
				)
				
				if foundDifferent then (
					local stepSize_u = abs(offset2_u - offset1_u)
					local stepSize_v = abs(offset2_v - offset1_v)
					local stepSize = amax stepSize_u stepSize_v
					
					-- If step size is a fraction like 1/16, 1/8, etc., it's a sprite sheet
					if stepSize > 0.01 and stepSize < 0.5 then (
						local reciprocal = 1.0 / stepSize
						local nearestInt = (floor (reciprocal + 0.5)) as integer
						
						if abs(reciprocal - nearestInt) < 0.1 then (
							isSpriteSheet = true
							format "     Detected sprite sheet animation (%x% grid)\n" nearestInt nearestInt
						)
					)
				)
			)
			
			-- Fallback: constant tiling > 1 is also sprite sheet
			if not isSpriteSheet and tilingConstant and (firstTiling_u > 1.01 or firstTiling_v > 1.01) then (
				isSpriteSheet = true
				format "     Detected sprite sheet animation (tiling: %x%)\n" firstTiling_u firstTiling_v
			)
			
			if not isSpriteSheet then (
				format "     Detected scrolling/smooth UV animation\n"
			)
		)
		
		-- Set animation range if we have valid animation
		if maxTime > 0 then (
			animationRange = interval 0f maxTime
		)
		
		-- Save current default tangent types and set appropriate ones
		local savedInTangent = undefined
		local savedOutTangent = undefined
		try (
			savedInTangent = getBeforeORT() 
			savedOutTangent = getAfterORT()
			
			if isSpriteSheet then (
				-- Set step tangents for sprite sheet (holds value until next key)
				setBeforeORT #step
				setAfterORT #step
			) else (
				-- Set linear tangents for smooth scrolling
				setBeforeORT #linear
				setAfterORT #linear
			)
		) catch()
		
		-- Apply keyframes
		local keyCount = 0
		for keyData in cleanedKeyframes do (
			-- keyData[1] is frame number (already snapped)
			local frameNum = keyData[1]
			local frameTime = (frameNum as time)  -- Convert frame number directly to time
			local u_tiling = keyData[3]
			local v_tiling = keyData[4]
			local u_offset = -keyData[6]  -- Negate back
			local v_offset = keyData[7]
			
			-- Debug: print first few keys
			if keyCount < 3 then (
				format "     Key %: T=%f frame=% offset=%,% tiling=%,%\n" \
					keyCount frameTime frameNum u_offset v_offset u_tiling v_tiling
			)
			keyCount += 1
			
			-- Set keys using 'with animate on at time'
			with animate on at time frameTime (
				bmap.coords.u_offset = u_offset
				bmap.coords.v_offset = v_offset
				bmap.coords.u_tiling = u_tiling
				bmap.coords.v_tiling = v_tiling
			)
		)
		
		-- For sprite sheets, explicitly set all keys to step tangents AFTER creation
		if isSpriteSheet then (
			try (
				-- Set tangent types for all keys on all controllers
				for i = 1 to bmap.coords.u_offset.controller.keys.count do (
					bmap.coords.u_offset.controller.keys[i].inTangentType = #step
					bmap.coords.u_offset.controller.keys[i].outTangentType = #step
				)
				for i = 1 to bmap.coords.v_offset.controller.keys.count do (
					bmap.coords.v_offset.controller.keys[i].inTangentType = #step
					bmap.coords.v_offset.controller.keys[i].outTangentType = #step
				)
				for i = 1 to bmap.coords.u_tiling.controller.keys.count do (
					bmap.coords.u_tiling.controller.keys[i].inTangentType = #step
					bmap.coords.u_tiling.controller.keys[i].outTangentType = #step
				)
				for i = 1 to bmap.coords.v_tiling.controller.keys.count do (
					bmap.coords.v_tiling.controller.keys[i].inTangentType = #step
					bmap.coords.v_tiling.controller.keys[i].outTangentType = #step
				)
				format "     Applied step tangents to all keys (sprite sheet mode)\n"
			) catch (e) (
				format "     Warning: Could not set step tangents on keys: %\n" (e as string)
			)
		)
		
		-- Restore saved tangent types
		try (
			if savedInTangent != undefined then setBeforeORT savedInTangent
			if savedOutTangent != undefined then setAfterORT savedOutTangent
		) catch()
		
		-- Also apply animation to opacity/alpha map if it exists and references the same texture
		local alphaMap = undefined
		if isKindOf mtl GTA_Mtl then (
			if mtl.alphamap != undefined and classof mtl.alphamap == Bitmaptexture then alphaMap = mtl.alphamap
		) else if isKindOf mtl Standard then (
			if mtl.opacityMap != undefined and classof mtl.opacityMap == Bitmaptexture then alphaMap = mtl.opacityMap
		)
		
		if alphaMap != undefined then (
			-- Check if alpha map uses same texture file as diffuse
			local sameTex = false
			try (
				if (alphaMap.filename != undefined) and (bmap.filename != undefined) then (
					if (stricmp alphaMap.filename bmap.filename) == 0 then sameTex = true
				)
			) catch()
			
			if sameTex then (
				format "     Copying UV animation to alpha/opacity map\n"
				try (
					-- Ensure controllers exist
					if alphaMap.coords.u_offset.controller == undefined then alphaMap.coords.u_offset.controller = bezier_float()
					if alphaMap.coords.v_offset.controller == undefined then alphaMap.coords.v_offset.controller = bezier_float()
					if alphaMap.coords.u_tiling.controller == undefined then alphaMap.coords.u_tiling.controller = bezier_float()
					if alphaMap.coords.v_tiling.controller == undefined then alphaMap.coords.v_tiling.controller = bezier_float()
					
					-- Clear existing keys
					while alphaMap.coords.u_offset.controller.keys.count > 0 do deleteKey alphaMap.coords.u_offset.controller 1
					while alphaMap.coords.v_offset.controller.keys.count > 0 do deleteKey alphaMap.coords.v_offset.controller 1
					while alphaMap.coords.u_tiling.controller.keys.count > 0 do deleteKey alphaMap.coords.u_tiling.controller 1
					while alphaMap.coords.v_tiling.controller.keys.count > 0 do deleteKey alphaMap.coords.v_tiling.controller 1
					
					-- Set tangent defaults
					try (
						if isSpriteSheet then (
							setBeforeORT #step
							setAfterORT #step
						) else (
							setBeforeORT #linear
							setAfterORT #linear
						)
					) catch()
					
					-- Copy CLEANED keyframes (same as diffuse map, not original)
					for keyData in cleanedKeyframes do (
						local frameNum = keyData[1]
						local frameTime = (frameNum as time)  -- Convert frame number to time
						local u_tiling = keyData[3]
						local v_tiling = keyData[4]
						local u_offset = -keyData[6]
						local v_offset = keyData[7]
						
						with animate on at time frameTime (
							alphaMap.coords.u_offset = u_offset
							alphaMap.coords.v_offset = v_offset
							alphaMap.coords.u_tiling = u_tiling
							alphaMap.coords.v_tiling = v_tiling
						)
					)
					
					-- Set step tangents explicitly on alpha map keys too
					if isSpriteSheet then (
						try (
							for i = 1 to alphaMap.coords.u_offset.controller.keys.count do (
								alphaMap.coords.u_offset.controller.keys[i].inTangentType = #step
								alphaMap.coords.u_offset.controller.keys[i].outTangentType = #step
							)
							for i = 1 to alphaMap.coords.v_offset.controller.keys.count do (
								alphaMap.coords.v_offset.controller.keys[i].inTangentType = #step
								alphaMap.coords.v_offset.controller.keys[i].outTangentType = #step
							)
							for i = 1 to alphaMap.coords.u_tiling.controller.keys.count do (
								alphaMap.coords.u_tiling.controller.keys[i].inTangentType = #step
								alphaMap.coords.u_tiling.controller.keys[i].outTangentType = #step
							)
							for i = 1 to alphaMap.coords.v_tiling.controller.keys.count do (
								alphaMap.coords.v_tiling.controller.keys[i].inTangentType = #step
								alphaMap.coords.v_tiling.controller.keys[i].outTangentType = #step
							)
						) catch()
					)
					
					-- Restore tangent defaults
					try (
						if savedInTangent != undefined then setBeforeORT savedInTangent
						if savedOutTangent != undefined then setAfterORT savedOutTangent
					) catch()
				) catch (
					format "Warning: Failed to copy UV animation to alpha map: %\n" (getCurrentException())
				)
			)
		)
		
		format "     Applied UV animation to material: % (% keys)\n" mtl.name animData.keyCount
		return true
	) catch (
		format "Error applying UV animation to %: %\n" mtl.name (getCurrentException())
		return false
	)
)

/* ============================================================================
   END UV ANIMATION IMPORT MODULE
   ============================================================================ */


struct _2dfinfo (
	v2d_L_posX = #(),
	v2d_L_posY = #(),
	v2d_L_posZ = #(),
	v2d_L_color = #(),
	v2d_L_Dist = #(),	
	v2d_L_OutRange = #(),
	v2d_L_Size = #(),
	v2d_L_ShSize = #(),
	v2d_L_ShowMode = #(),
	v2d_L_Refl = #(),	
	v2d_L_coronaFlareType = #(),
	v2d_L_shadowColorMultiplier = #(),
	v2d_L_Flags1 = #(),
	v2d_L_CoroneName  = #(),		
	v2d_L_shadowName = #() ,
	v2d_L_shadowZDistance = #(),
	v2d_L_Flags2 = #(),
	v2d_L_DirectionX = #(),
	v2d_L_DirectionY = #(),
	v2d_L_DirectionZ = #()
)
global s_2dfinfo

fn r2DFX msh size f = (
	try(
		impHas2dfx = true
		chSize = ((size as double) - 4.0) / 100.0
		s_2dfinfo = _2dfinfo()
		fdbg = ftell f
		effect2dfxCount  = readlong f -- total 2dfx count
		_2dCountdebug = 0
		imp2dfxCount = effect2dfxCount
		
		sz = 0
		tp = 0
		_v2d_L_posX = 0.0
		_v2d_L_posY = 0.0
		_v2d_L_posZ = 0.0
		_2dfxCount = 0  -- Light count
		local particle_count = 0
		local ped_area_count = 0
		local sun_refl_count = 0
		
		for i = 1 to effect2dfxCount do (
			_v2d_L_posX = readfloat f -- x
			_v2d_L_posY = readfloat f -- y
			_v2d_L_posZ = readfloat f -- z		
			tp = readlong f -- type
			sz = readlong f -- size
			
			case tp of (
				0: (
					-- TYPE 0: LIGHT
					_2dfxCount += 1
					i2 = _2dfxCount
					s_2dfinfo.v2d_L_posX[i2] = _v2d_L_posX
					s_2dfinfo.v2d_L_posY[i2] = _v2d_L_posY
					s_2dfinfo.v2d_L_posZ[i2] = _v2d_L_posZ
					_2dCountdebug += 1
					r = readbyte f #unsigned
					g = readbyte f #unsigned
					b = readbyte f #unsigned
					a = readbyte f #unsigned
					s_2dfinfo.v2d_L_color[i2] = (color r g b)
					s_2dfinfo.v2d_L_Dist[i2] = readfloat f
					s_2dfinfo.v2d_L_OutRange[i2] = readfloat f
					s_2dfinfo.v2d_L_Size[i2] = readfloat f	
					s_2dfinfo.v2d_L_ShSize[i2] = readfloat f		
					s_2dfinfo.v2d_L_ShowMode[i2] = readbyte f #unsigned
					s_2dfinfo.v2d_L_Refl[i2] = readbyte f #unsigned		
					s_2dfinfo.v2d_L_coronaFlareType[i2] = readbyte f #unsigned	
					s_2dfinfo.v2d_L_shadowColorMultiplier[i2] = readbyte f #unsigned	
					s_2dfinfo.v2d_L_Flags1[i2] = readbyte f #unsigned		
					endtex = (ftell f) + 24
					s_2dfinfo.v2d_L_CoroneName[i2] = readstring f
					fseek f endtex #seek_set
					endtex = (ftell f) + 24	
					s_2dfinfo.v2d_L_shadowName[i2] = readstring f
					fseek f endtex #seek_set	
					s_2dfinfo.v2d_L_shadowZDistance[i2] = readbyte f #unsigned	
					s_2dfinfo.v2d_L_Flags2[i2] = readbyte f #unsigned
					
					if (chSize) == (abs (floor chSize)) then ( 
						s_2dfinfo.v2d_L_DirectionX[i2] = readbyte f #unsigned
						s_2dfinfo.v2d_L_DirectionY[i2] = readbyte f #unsigned
						s_2dfinfo.v2d_L_DirectionZ[i2] = readbyte f #unsigned
						readbyte f
						readbyte f
					) else (
						readbyte f
					)
				)
				1: (
					-- TYPE 1: PARTICLE
					particle_count += 1
					local particleType = readlong f #unsigned
					local unk1 = readlong f #unsigned
					local unk2 = readlong f #unsigned
					local unk3 = readlong f #unsigned
					local psize = readfloat f
					
					-- Create a dummy for the particle
					local dm = Dummy pos:[_v2d_L_posX, _v2d_L_posY, _v2d_L_posZ] boxsize:[0.5,0.5,0.5]
					dm.name = "2dfx_particle_" + particle_count as string
					dm.wirecolor = yellow
					setUserProp dm "2dfx" "true"
					setUserProp dm "2dfx_type" "1"
					if particleType < effects.count then (
						setUserProp dm "particle_name" effects[particleType + 1]
					) else (
						setUserProp dm "particle_name" ("unknown_" + particleType as string)
					)
					setUserProp dm "particle_size" psize
					
					format " [debug]: imported particle %: type % size %\n" particle_count particleType psize
				)
				3: (
					-- TYPE 3: PED BEHAVIOR AREA
					ped_area_count += 1
					local animType = readlong f #unsigned
					local c1x = readfloat f
					local c1y = readfloat f
					local c1z = readfloat f
					local c2x = readfloat f
					local c2y = readfloat f
					local c2z = readfloat f
					
					-- Create a dummy for the ped area
					local dm = Dummy pos:[_v2d_L_posX, _v2d_L_posY, _v2d_L_posZ] boxsize:[1.0,1.0,1.0]
					dm.name = "2dfx_pedarea_" + ped_area_count as string
					dm.wirecolor = green
					setUserProp dm "2dfx" "true"
					setUserProp dm "2dfx_type" "3"
					setUserProp dm "ped_anim_type" animType
					setUserProp dm "ped_corner1_x" c1x
					setUserProp dm "ped_corner1_y" c1y
					setUserProp dm "ped_corner1_z" c1z
					setUserProp dm "ped_corner2_x" c2x
					setUserProp dm "ped_corner2_y" c2y
					setUserProp dm "ped_corner2_z" c2z
					
					format " [debug]: imported ped attractor %: anim % bbox [%,%,%] to [%,%,%]\n" ped_area_count animType c1x c1y c1z c2x c2y c2z
				)
				4: (
					-- TYPE 4: SUN REFLECTION
					sun_refl_count += 1
					
					-- Create a dummy for the sun reflection
					local dm = Dummy pos:[_v2d_L_posX, _v2d_L_posY, _v2d_L_posZ] boxsize:[0.3,0.3,0.3]
					dm.name = "2dfx_sunrefl_" + sun_refl_count as string
					dm.wirecolor = orange
					setUserProp dm "2dfx" "true"
					setUserProp dm "2dfx_type" "4"
					
					format " [debug]: imported sun reflection % at [%,%,%]\n" sun_refl_count _v2d_L_posX _v2d_L_posY _v2d_L_posZ
				)
				default: (
					-- Unknown type, skip data
					if tp > 10 or sz > size then exit
					format " [Warning]: Unknown 2DFX type % with size %, skipping\n" tp sz
					fseek f ((ftell f)+sz) #seek_set
				)
			)
		)
	)catch (format "Error read 2dfx\n")
	if _2dCountdebug > 0 then format " [debug]: imported % 2dfx(lights)\n" _2dCountdebug
	if particle_count > 0 then format " [debug]: imported % 2dfx(particles)\n" particle_count
	if ped_area_count > 0 then format " [debug]: imported % 2dfx(ped attractors)\n" ped_area_count
	if sun_refl_count > 0 then format " [debug]: imported % 2dfx(sun reflections)\n" sun_refl_count
	imp2dfxCount = _2dCountdebug
)


fn rNVC msh f = (
	readbyte f
	readbyte f
	readbyte f
	readbyte f
	meshop.setMapSupport msh -1 true
	for i = 1 to msh.numverts do ( 
		r = (readbyte f) * 1.0 / 255.0
		g = (readbyte f) * 1.0 / 255.0
		b = (readbyte f) * 1.0 / 255.0		
		readbyte f
		meshop.setMapVert msh -1 i [r,g,b]
		--format "= % % %\n" r g b
	)
)

--A-----------------
-- General Functions
--------------------
fn Byte2char thisbyte =
(
    local charSet = " ! #$%& ()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_ abcdefghijklmnopqrstuvwxyz"
    local t = thisbyte - 31
    if (t < 1) or (t > charSet.count) then return ""
    return substring charSet t 1
)
--end fn Byte2char			--<A1>--
--
fn stripSpace str = (
	local tmp = ""
	for i = 1 to str.count do (
		if substring str i 1 == " " then tmp += "~"
		else tmp += substring str i 1
	)--end for i
	return tmp
)
--end fn stripSpace		--<A2>--
--
fn RestoreSpace str = (
	local tmp = ""
	for i = 1 to str.count do (
		if substring str i 1 == "~" then tmp += " "
		else tmp += substring str i 1
	)--end for i
	return tmp
)
--end fn RestoreSpace		--<A3>--
--
--C---------------
-- Clump Functions
------------------
struct GTA3frame ( 
	transform, parentID, unknown, name, obj, boneID		--unknown -> Coords Reference?? 0:special 3:parent 0x020003:world
)
--
fn WhichRWver f = (
    local bkup = (ftell f) 
    fseek f 0 #seek_set
    readLong f;readLong f
	bb = readShort f #unsigned
	b1 = readByte f #unsigned
	b2 = readByte f #unsigned
	format "This File is RW Version : 3.%.%.%\n" (b2/4) (b1/16) ((mod b1 8) as integer)
    fseek f bkup #seek_set
	return (b2*0x1000000 + b1*0x10000 + bb)
)
--end fn WhichRWver		--<C1>--
--
fn CheckZmodLock f = (
	Zmodlocked = false
	fseek f 0 #seek_set
	if (readLong f) != 16 then return false
	else (
		loop = true
		try (
			while loop == true do (
				fseek f ((readLong f) + 4) #seek_cur
				--mult-clump check--
				headerID = readLong f
				case headerID of (
					0xF21E: (
						skipbyte = 8 - (readlong f)
						readLong f
						s1 = readByte f
						s2 = readByte f
						cc = readLong f
						e1 = readByte f
						e2 = readByte f
						if (cc==0x1C14)OR(cc==0x1C15) then ()
						else Zmodlocked = true
						if s1 != e1 then Zmodlocked = true
						if s2 != e2 - 2 then Zmodlocked = true
						if skipbyte != 0 then Zmodlocked = true
						loop = false
					)
					default: ()
				)--end case
			)--end while
		) catch()
	)--end if/else	
	fseek f 0 #seek_set
	return Zmodlocked
)
--end fn CheckZmodLock		--<C3>--
--
fn checkClump f = (
	if LetsRockandRoll != true then 
		if  (CheckZmodLock f ) == true then return undefined

    fseek f 0 #seek_end
    dffend = ftell f
    fseek f 0 #seek_set
    
    noclump = 0
	clumpary = #()
    voidclump = true
    
    while voidclump == true do (
        if (readLong f #unsigned) == 16 then (
			append clumpary ((ftell f) - 4)
            Clump_size = readLong f #unsigned
	        readLong f
            noclump += 1        
            try (fseek f Clump_size #seek_cur) catch ( voidclump = false)
        )else (
            voidclump = false
        )--end if/else
    )--end while
	fseek f 0 #seek_set
    return clumpary
)
--end fn checkClump		--<C2>--
--
--0---------------------------
-- Functions for Bones & Skins
------------------------------
struct BoneStruct (
	boneID, boneIndex, boneType
)
--
--05Oct05 Bone created in rHAnimPLG and return bone object with BoneID in userprop
fn rHAnimPLG f string_length = (
	if (readLong f) != 256 then (
		format "Error in HAnim PLG(0x11E): %[%] skipped\n" i (ftell f)
		local skip = string_length - 4
		fseek f skip #seek_cur
		return undefined
	) else (
		FrameboneID = readLong f
		Bone_Count = readLong f #unsigned
		
		if FrameboneID == -1 then ( return undefined )
		
		--GTAbone = bone showlinks:true
		GTAbone = dummy boxsize:([0,0,0] ) wirecolor:yellow showlinks:true
		setUserProp GTAbone "BoneID" FrameboneID
        GTAbone.showLinksOnly = true
		
		if Bone_Count == 0 then return GTAbone
		else (
			readLong f;readLong f						--Unknown, always 0 36
			BoneDataAry = #()
			for j = 1 to Bone_Count do (
				BoneDataAry[j] = BoneStruct()
				BoneDataAry[j].boneID = readLong f #unsigned
				BoneDataAry[j].boneIndex = readLong f #unsigned
				BoneDataAry[j].boneType = readLong f #unsigned
			) 
			return #(GTAbone, BoneDataAry)
		)--end if/else FrameboneID
	)--end if const
)
--end fn rHAnimPLG			--<B1>--
--
--06Oct05 return vertsarray weightarray ibm specialunknown
fn rSkinPLG f data_length Vert_count ver = (

	dataEND = (ftell f) + data_length

	bvAry = #()
	bwAry = #()

	bone_count = readByte f #unsigned
	sp_count = readByte f #unsigned
	SPunknown = readByte f			--unknown??
	readByte f						--unknown??

	if DebugMode == true then format "Here:%\tdata length:%\tEnd Add:%\tvert_count:%\nBones:%\tSP:%\tunknown:%\n" here data_length dataEND Vert_count bone_count sp_count SPunknown

	if sp_count != 0 then (
		for i = 1 to sp_count do readByte f		--What is this??
	)--end if sp_count 

	for i = 1 to Vert_count do (
		vert1 = readByte f #unsigned
		vert2 = readByte f #unsigned
		vert3 = readByte f #unsigned
		vert4 = readByte f #unsigned
		bv = #((vert1 + 1))
		if vert2 != 0 then (
			append bv (vert2 + 1)
			if vert3 != 0 then (
				append bv (vert3 + 1)
				if vert4 != 0 then append bv (vert4 + 1)
			)
		)
		append bvAry bv
	)--end for i

	for j = 1 to Vert_count do (
		weight1 = readFloat f
		weight2 = readFloat f
		weight3 = readFloat f
		weight4 = readFloat f
		bw = #(weight1)
		if bvAry[j][2] != undefined then (
			append bw weight2
			if bvAry[j][3] != undefined then (
				append bw weight3
				if bvAry[j][4] != undefined then append bw weight4
			)
		)
		append bwAry bw
	)--end for j

	--Read IBM--
	if DebugMode == true then format "IBM start here(%)  bones:%\n" (ftell f) bone_count 
	global ibm = #()
	for i = 1 to bone_count do (
		if ver != 0x1803FFFF then (
			constDEAD = readLong f
			if DebugMode == true then format ": % :: " constDEAD
		)
		m1 = [(readFloat f),(readFloat f),(readFloat f)]
		u1 =  (readLong f)
		if DebugMode == true then format "%, " u1
		m2 = [(readFloat f),(readFloat f),(readFloat f)]
		u2 = (readLong f)
		if DebugMode == true then format "%, " u2
		m3 = [(readFloat f),(readFloat f),(readFloat f)]
		u3 = (readLong f)
		if DebugMode == true then format "%, " u3
		m4 = [(readFloat f),(readFloat f),(readFloat f)]
		u4 = (readLong f)
		if DebugMode == true then format "%\n" u4
		append ibm  (matrix3  m1 m2 m3 m4)
	)--end for i
	if ver == 0x1803FFFF then ( 
		if DebugMode == true then format ":: [%, %, %]\n" (readFloat f) (readFloat f) (readFloat f) 
		else ( for tt = 1 to 3 do (readFloat f)  )
	)
	if (ftell f) != dataEND then (
		format "\n>> error in reading Invert Bone Matrics :[%]<<(%)\n\n" dataEND (ftell f)
		fseek f dataEND #seek_set
	)
	return #(bvAry,bwAry,ibm,SPunknown)
)
--end fn rSkinPLG			--<B2>--
--
--1-----------------------
-- Functions for Import --
--------------------------
fn rClump f showdetail = (
	rvar = readLong f
	ercheck = false
	
	-- Check for UV Animation Dictionary (0x2B = 43) before CLUMP
	if rvar == 43 then (
		format "\t\t(!) DFF has UV Animation Dictionary!\n"
		
		if gUVAnimImportEnabled then (
			gUVAnimDict = ReadUVAnimDictionary f 0  -- version parameter not used, will be read inside
		) else (
			-- Skip the dictionary if import is disabled
			local dictSize = readLong f #unsigned
			local dictVer = readLong f #unsigned
			fseek f (dictSize - 4) #seek_cur  -- -4 because we already read dictVer
		)
		
		rvar = readLong f  -- Read next chunk ID (should be 16 for CLUMP)
	)
	
	while (rvar !=16) do (
		tmpClumpsz = readLong f #unsigned
		readLong f #unsigned
		if (tmpClumpsz == undefined) then (
			ercheck = true
			exit
		)
		fseek f tmpClumpsz #seek_cur 
		rvar = readLong f
		if rvar == 43 then format "\t\t(!) DFF has UV Animation Dictionary (unexpected position)!\n" 
	)
	if (rvar != 16 or ercheck == true)  then ( 
		local fpos = ftell f
		format "Error in Clump: Expected chunk ID 16, got % at file position %\n" rvar fpos
		exit 
	) 
	local Clumpsize = readLong f #unsigned
	if showdetail == true then (
		rVer = WhichRWver f
		format "\nClump(16) Size: %\n" Clumpsize
		format "\t->Version: %\n" rVer
		readLong f
	) else rVer = readLong f #unsigned
	if readLong f != 1 then ( format "Error in Clump Data\n"; exit )
	local Data_length = (readLong f)/4
	ver = readLong f
	object_count = readLong f
	if showdetail == true then format "\t->Object Count: %\n" object_count
	if Data_length > 1 then (
		for i = 2 to Data_length do (
			tmp = readLong f #unsigned
			if showdetail == true then format "\t->??: %\n" tmp
		)--end for i
	)
	return #(object_count,ver)
)
--end fn rClump			--<i1>--
--
fn rFrameList f Iscale showdetail = (
	if (readLong f) != 14 then ( format "Error in FrameList\n"; exit )
	tmp = (readLong f #unsigned)
	if showdetail == true then format "\tFrameList(14) Size: %\n" tmp
	readLong f		--Version
	if readLong f != 1 then ( format "Error in FrameList Data\n"; exit )
	FL_length = (readLong f #unsigned)
	readLong f		--Version
	frame_count = readLong f
	if showdetail == true then format "\t\t->Frame Count:%\n" frame_count
	frameAry = #()
	BoneDataAry = undefined
	for i = 1 to frame_count do (
		frameAry[i] = GTA3frame()
		frameAry[i].transform = matrix3 [(readFloat f),(readFloat f),(readFloat f)] [(readFloat f),(readFloat f),(readFloat f)] [(readFloat f),(readFloat f),(readFloat f)] [((readFloat f) * Iscale),((readFloat f) * Iscale),((readFloat f) * Iscale)]
		frameAry[i].parentID = (readLong f) + 1
		frameAry[i].unknown = readLong f #unsigned
	)
	for i = 1 to frame_count do (
		if readLong f != 3 then ( format "Error in FrameList Extension: %[pos: %]\n" i (ftell f); exit )
		Ext_length = readLong f
		ver = readLong f		--Version
		if Ext_length != 0 then (
            local Loop_end = (ftell f) + Ext_length
            while (ftell f) < Loop_end do (
               local header = readLong f
                string_length = readLong f
                readLong f		--Version            
                case header of (
                    39056126: (
                        tmp = ""
				        for j = 1 to string_length do (
    					    rbyte = readbyte f #unsigned
	    				    tmp += Byte2Char rbyte 
				        )
    				    frameAry[i].name = tmp
                    )
                    286: (
						if showdetail == true then format "\t\t->Bones Data(286): size: %\n" string_length
						tmp = rHAnimPLG f string_length
						if classof tmp == Array then (
							BoneDataAry = tmp[2]
                            frameAry[i].obj = tmp[1]
						) else (frameAry[i].obj = tmp)
					)
					default: (
						if showdetail == true then format "\t\t->unknown(%) size: %\n" header string_length
						fseek f string_length #seek_cur                
					)
                )--end case of
			)--end while		
		) else ( 
			if ver == 0x1803FFFF then ( 
				frameAry[i].name = "Skin_Mesh"
            )
		) --end if/else
	)--end for i

	if (BoneDataAry != undefined) then (
		for i = 1 to frameAry.count do (
			if classof frameAry[i].obj == dummy then ( --bone then (	
				tmp = for b in BoneDataAry where b.boneID == (getUserProp FrameAry[i].obj "BoneID") collect b
				if tmp.count > 0 then (
					setUserProp (frameAry[i].obj) "BoneType" tmp[1].boneType
					setUserProp (frameAry[i].obj) "BoneIndex" tmp[1].boneIndex
				)
			)--end if bone
		)--end for
	)--end BoneDataAry

	return frameAry
)
--end fn rFrameList		--<i2>--
--
--Read rwLight after Atomic--**
fn rExtra f showdetail = (
    dataleng =  readLong f
    readlong f                  --ver
    if dataleng == 4 then  frame_index = (readLong f) + 1
    else fseek f dataleng #seek_cur
    section = readLong f
    if (section == 0x12) then (
		tmp = (readLong f #unsigned)
		readLong f				--ver
		if showdetail == true then format "\tLight(18) Size: %\n" tmp    
		readLong f; readLong f; readLong f				--data(0x01),size(24),ver
		lgt = Omnilight  multiplier:0.15 
		readFloat f
		cr = (readFloat f) * 255
		cg = (readFloat f) * 255
		cb = (readFloat f) * 255
			--lgt.color = color cr cg cb
			append lightArr_ lgt
		readLong f						--fallof
		readShort f						--type
		readShort f						--light type
		readLong f						--extension(0x03)
		extleng = readLong f
		readLong f						--ver
		if extleng != 0 then fseek f extleng #seek_cur
        return #(frame_index, lgt, "light")
    ) else fseek f (4 + (readLong f)) #seek_cur
    return undefined
)
--end fn rExtra
--

-- Part 2 functions
fn rAtomic f showdetail = (
    section = readLong f
    if section == 1 then ( return rExtra f showdetail )
	if section != 20 then ( format "Error in Atomic\n";implightErr = true;  exit )
	atmsize = (readLong f #unsigned)
	if showdetail == true then format "\tAtomic(20) Size: %\n" atmsize
	readLong f		--Version
	if readLong f != 1 then ( format "Error in Atomic Data\n"; exit )
	readLong f      --Data length (should be 16)
	readLong f		--Version
    frame_index = (readLong f) + 1
    Geometry_index = (readLong f) + 1
    readLong f;readLong f       --unknown?? (5,0)
 	if (readLong f) != 3 then ( format "Error in Atomic Extension\n"; exit )
	AExt = readLong f #unsigned
	if showdetail == true then format "\t\tExtension(3) Size: %\n" AExt
	readLong f		--Version
	local AEend = (ftell f) + AExt
	while (ftell f) < AEend do (
		local header = readLong f #unsigned
		local hdsize = readLong f #unsigned
		readLong f		--Version
		case header of (	
			31:	 (
					tmp = readLong f
					if showdetail == true then format "\t\t\tRight To Render(31)??: %\n" tmp
					readLong f
					 )
			288:	 (
					tmp = readLong f
					if showdetail == true then format "\t\t\tMaterial Effect(288)??: %\n" tmp
					 )
			280:	 (
					tmp = readLong f
					if showdetail == true then format "\t\t\tParticles(280)??: %\n" tmp
					 )
			default: (
					if showdetail == true then format "\t\t\tunknown??(%) Size: %\n" header hdsize
					fseek f hdsize #seek_cur
					 )
		)--end case
	)--end while
	return #(frame_index, Geometry_index, 0, atmsize)
)
--end fn rAtomic			--<i3>--
--
fn rGeometryList f showdetail = (
	if (readLong f) != 26 then ( format "Error in GeometryList\n"; exit )
	tmp = (readLong f #unsigned)
	if showdetail == true then format "\tGeometryList(26) Size: %\n" tmp
	readLong f		--Version
	if readLong f != 1 then ( format "Error in GeometryList Data\n"; exit )
	readLong f		--Data size( should be 4 for only contain Geometry Count )
	readLong f		--Version
	geometry_count = readLong f
	if showdetail == true then format "\t\t->Geometry Count:%\n" geometry_count
	return geometry_count
)
--end fn rGeomeList		--<i4>--
--
fn rMaterialSplit thismesh file showdetail = (
	SplitType = ReadLong file
	split_count = ReadLong file
	Face_Index_count = ReadLong file
	
	if showdetail == true then format "\t\t\t\t->Split Type:%\t" SplitType 
	local faced = 0

    --Create lookup Array--
	local tary = #()
	if SplitType == 0 then (
		for i = 1 to thismesh.numfaces do ( append tary (getface thismesh i) )
    ) else (
		for i = 1 to thismesh.numfaces do ( 
			t = (getface thismesh i)
			if t.x > t.z then swap t.x t.z
			if t.y < t.x then swap t.y t.x
			if t.y > t.z then swap t.y t.z
			append tary t
		)--end for i
	)--end if/else

	for i = 1 to split_count do (
    
        case SplitType of (
        0: (    
		    IndexCount = (readlong file)/3
		    MtlID = (readlong file) + 1            
            for j = 1 to IndexCount do ( 
			    a1 = (readLong file #unsigned) + 1
			    a2 = (readLong file #unsigned) + 1
			    a3 = (readLong file #unsigned) + 1
				tpt = [a1,a2,a3]
				aaa = finditem tary tpt
				--shit zmod2 faces index changed(12Aug08)--
                if (aaa == 0)AND(LetsRockandRoll != True) then (
					delete thismesh
					if showdetail == true then clearlistener()
					messagebox "This is a Non-Standard DFF !" title:"Import Aborted"
					return undefined
                )
				if aaa == 0 then (
					tpt = [a2,a1,a3]
					aaa = finditem tary tpt
				)
				if aaa == 0 then (
					tpt = [a3,a1,a2]
					aaa = finditem tary tpt
				)
				if aaa == 0 then (
					tpt = [a1,a3,a2]
					aaa = finditem tary tpt
				)
				if aaa == 0 then (
					tpt = [a3,a2,a1]
					aaa = finditem tary tpt
				)
				if aaa == 0 then (
					tpt = [a2,a3,a1]
					aaa = finditem tary tpt
				)				
				----------------------------------
				setFaceMatID thismesh aaa MtlID
            )--end for j
        )
        1: (
				IndexCount = (readlong file) - 2
				MtlID = (readlong file) + 1            
				a1 = (readLong file  #unsigned) + 1
				a2 = (readLong file  #unsigned) + 1 
				for j = 1 to IndexCount do ( 
					a3 = (readLong file  #unsigned) + 1
					tpt = [a1,a2,a3] 
					if tpt.x > tpt.z then swap tpt.x tpt.z
					if tpt.y < tpt.x then swap tpt.y tpt.x
					if tpt.y > tpt.z then swap tpt.y tpt.z
					aaa = finditem tary tpt
					if aaa != 0 then (
						setFaceMatID thismesh aaa MtlID
						faced +=1	
					)--end if aaa
					a1 = a2
					a2 = a3
				)--end for j        
        )
        default: (
            if showdetail == true then format "Unknown Split Type: % , rwMaterialSplit Skipped\n" SplitType
            skips = readLong f #unsigned
            readlong file       --MatID
            for j = 1 to skips do readLong f            
        )
        )--end case

    )--end for i
	if showdetail == true then (
		if SplitType == 1 then format "Mesh Face:% Splited Face:%\n" thismesh.numfaces faced
		else format "\n"
	)
   return thismesh
)
--end fn ReadrwMaterialSplit	--<i5>--
--
fn rTexture f mtl texEx showdetail = (
	if (readLong f) != 6 then ( format "Error in Texture\n"; exit )
	tmp = (readLong f #unsigned)
	if showdetail == true then format "\t\t\t\t\tTexture(6) Size: %\n" tmp
	readLong f		--Version
	if readLong f != 1 then ( format "Error in Texture Data\n"; exit )
	readLong f      --Data length (should be 4 bytes for filter flag, unknown ??)
	readLong f		--Version
	TexFlag = readLong f      --filter flag, unknown??
	--diffuse texture--
	if (readLong f) != 2 then ( format "Error in Texture String1\n"; exit )
	string_length = readLong f
	readLong f		--Version
    endtex = (ftell f) + string_length
	DTex = readString f
    fseek f endtex #seek_set
	if DTex != "" then (
    
--if DebugMode == true then mtlflag[1] = true

		-- Try to construct full path using project images folder
		local texPath = DTex + texEx
		local imagesPath = (getDir #image)
		if imagesPath != undefined then (
			local fullPath = imagesPath + "\\" + DTex + texEx
			if doesFileExist fullPath then (
				texPath = fullPath
			)
		)

		if classof mtl == GTA_Mtl then (
			mtl.colormap = bitmaptexture name:DTex filename:texPath
			df = mtl.colormap
		) else (
			mtl.diffusemap = bitmaptexture name:DTex filename:texPath
			mtl.diffusemapAmount = 100
			df =   mtl.diffusemap
		)
		if TexFlag == 0x106 then df.filtering = 0
		if TexFlag == 0x10102 then df.filtering = 1
		if TexFlag == 0x10101 then df.filtering = 2
	)
	--mask texture--
	if (readLong f) != 2 then ( format "Error in Texture String2\n"; exit )
	string_length = readLong f
	readLong f		--Version
	endtex = (ftell f) + string_length
	MTex = readString f
	fseek f endtex #seek_set

	-- Only assign alpha/opacity if explicit mask texture is specified
	local maskMap = undefined
	if MTex != "" then (
		-- Try to construct full path using project images folder
		local maskPath = MTex + texEx
		local imagesPath = (getDir #image)
		if imagesPath != undefined then (
			local fullPath = imagesPath + "\\" + MTex + texEx
			if doesFileExist fullPath then (
				maskPath = fullPath
			)
		)
		
		if classof mtl == GTA_Mtl then (
			mtl.alphamap = bitmaptexture name:MTex filename:maskPath
			maskMap = mtl.alphamap
		) else (
			mtl.opacitymap = bitmaptexture name:MTex filename:maskPath
			maskMap = mtl.opacitymap
		)
		
		-- Apply filtering to mask/opacity map
		if TexFlag == 0x106 then maskMap.filtering = 0
		if TexFlag == 0x10102 then maskMap.filtering = 1
		if TexFlag == 0x10101 then maskMap.filtering = 2
		
		-- Set RGB Channel Output to "Alpha as Gray" for proper transparency
		try (
			maskMap.rgbOutput = 1  -- 0=RGB, 1=Alpha as Gray
		) catch()
	)
	-- If MTex is empty, don't assign any alpha/opacity map (viewport displays RGB normally)

	if showdetail == true then format "\t\t\t\t\t\t->Texture: %\tMask: %\n" DTex MTex
	if (readLong f) != 3 then ( format "Error in Texture Extension\n"; exit )
	TExt_length = readLong f
	readLong f		--Version 
	if TExt_length != 0 then fseek f TExt_length #seek_cur
	return mtl
)
--end rTexture				--<i6>--
--
fn rMaterial f mattype texEx showdetail = (
	if (readLong f) != 7 then ( format "Error in Material\n"; exit )
	tmp = (readLong f #unsigned)
	if showdetail == true then format "\t\t\t\tMaterial(7) Size: %\n" tmp
	readLong f		--Version
	if readLong f != 1 then ( format "Error in Material Data\n"; exit )
	M_length = (readLong f #unsigned)
	readLong f		--Version
	readLong f		--unknown?? 0
	colR = readByte f #unsigned
	colG = readByte f #unsigned
	colB = readByte f #unsigned
	colA = readByte f #unsigned
	if showdetail == true then format "\t\t\t\t\t->RGBA: %, %, %, %\n" colR colG colB colA
	readLong f		--unknown?? 1629836
	texture_count = readLong f
	
if (DebugMode == true)AND(texture_count == 0) then mtlflag[1] = true

	Gamb = readFloat f
    Gspc = readFloat f
    Gdif = readFloat f
	gtaMatFlag = true
	if (mattype == 1) and (GTA_Mtl != undefined) then (
		mtl = GTA_Mtl()
		mtl.color = color colR colG colB
		mtl.alpha = colA
		mtl.amb = Gamb
		mtl.spc = Gspc
		mtl.dif = Gdif
		mtl.specular = color 0 0 0
		if (DebugMode == true)AND(colA != 255)  then mtlflag[2] = true
	) else (
		gtaMatFlag = false
		mtl = StandardMaterial()
		mtl.glossiness = 0
		mtl.soften = 0
		mtl.Ambient = color colR colG colB 
		mtl.diffuse = color colR colG colB
		--mtl.specular = color 255 255 255
        mtl.specular = color 0 0 0
		mtl.opacity = (colA/255.0 * 100) as integer
		mtl.specular_level = Gspc *100
	)
	for i = 1 to texture_count do (
		rTexture f mtl texEx showdetail
	)
	
	-- Name material after diffuse texture if present
	if isKindOf mtl GTA_Mtl then (
		if mtl.colormap != undefined and classof mtl.colormap == Bitmaptexture then (
			mtl.name = mtl.colormap.name
		)
	) else (
		if mtl.diffusemap != undefined and classof mtl.diffusemap == Bitmaptexture then (
			mtl.name = mtl.diffusemap.name
		)
	)

	if (readLong f) != 3 then ( format "Error in Material Extension[Pos: %]\n" (ftell f); exit )
	MExt = readLong f #unsigned
	readLong f		--Version	
        
	if MExt != 0 then (
		local Loop_end = (ftell f) + MExt
        while (ftell f) < Loop_end do (
			local header = readLong f
            local tmpsize = readLong f #unsigned
			readLong f		--Version

  			case header of (
				307: (
					if (gtaMatFlag == true) then (
						MExt_end = (ftell f) + tmpsize
						impCh = true
						try mtl.matEffect catch chMfx = false	
						if impCh == true then (
							if showdetail == true then format "\t\t\t\t\tMaterial Effect(307) Size: %\n" tmpsize
							if tmpsize >= 24 then (
								try (
									typeDK = readLong f
									
									if typeDK == 49 then ( 
										mtl.matEffect = 6
										posStr  = (ftell f)
										if (readLong f) == 6 then (
											texSize = readLong f      --Data size
											readLong f		--Version
											if (readLong f) != 1 then ( format "Error in Material Effect Texture[Pos: %]\n" (ftell f); exit )
											readLong f		--Data size-->2 int (Texture Filter Mode Flags, unknown)
											readLong f		--Version
											readLong f
											if (readLong f) != 2 then ( format "Error in Material Effect String[Pos: %]\n" (ftell f); exit )
											local string_Length = readLong f #unsigned
											readLong f		--Version
											RTex = readString f
											if RTex != "" then mtl.dkpNmap = bitmaptexture name:RTex filename:(RTex+texEx)  
										) else ( fseek f MExt_end #seek_set )
										fseek f (posStr + texSize + 12) #seek_set
										mtl.dkpRAmount = readFloat f 
										if (readLong f) == 6 then (
											readLong f      --Data size
											readLong f		--Version
											if (readLong f) != 1 then ( format "Error in Material Effect Texture[Pos: %]\n" (ftell f); exit )
											readLong f		--Data size-->2 int (Texture Filter Mode Flags, unknown)
											readLong f		--Version
											readLong f
											if (readLong f) != 2 then ( format "Error in Material Effect String[Pos: %]\n" (ftell f); exit )
											local string_Length = readLong f #unsigned
											readLong f		--Version
											RTex = readString f
											if RTex != "" then mtl.dkpRmap = bitmaptexture name:RTex filename:(RTex+texEx)  
											fseek f MExt_end #seek_set 
										) else ( fseek f MExt_end #seek_set )
									)  else if typeDK == 1 then ( 
										mtl.matEffect = 6
										if (readLong f) == 6 then (
											readLong f      --Data size
											readLong f		--Version
											if (readLong f) != 1 then ( format "Error in Material Effect Texture[Pos: %]\n" (ftell f); exit )
											readLong f		--Data size-->2 int (Texture Filter Mode Flags, unknown)
											readLong f		--Version
											readLong f
											if (readLong f) != 2 then ( format "Error in Material Effect String[Pos: %]\n" (ftell f); exit )
											local string_Length = readLong f #unsigned
											readLong f		--Version
											RTex = readString f
											if RTex != "" then mtl.dkpNmap = bitmaptexture name:RTex filename:(RTex+texEx)  
										) else ( fseek f MExt_end #seek_set )
										fseek f MExt_end #seek_set
									)
								) catch ( 
									format "error read Mat Fx\n"
									fseek f MExt_end #seek_set 
								)
							) else ( fseek f MExt_end #seek_set )
						)  else ( fseek f MExt_end #seek_set )
					)
				)
				288: (
					MExt_end = (ftell f) + tmpsize
 					if showdetail == true then format "\t\t\t\t\tMaterial Effect(288) Size: %\n" tmpsize
    				if tmpsize >= 24 then (
					try (
						if DebugMode == true then mtlflag[3] = true
							ReadLong f
							type = ReadLong f
							if type == 1 then ( -- BUMP
								if (gtaMatFlag == true) then (
									chMfx = true
									impCh = false
									try mtl.matEffect catch chMfx = false	
									if (classof mtl == GTA_Mtl) and chMfx == true then impCh = true
									else if (classof mtl == standardmaterial) then impCh = true
									if impCh == true then (
										mtl.matEffect = 3
										mtl.bumpMapAmount = (Readfloat f)
										ReadLong f; ReadLong f	--unknown?? 0 1 <-this 1 act as on/off texture switch?
										if (readLong f) == 6 then (
											readLong f      --Data size
											readLong f		--Version
											if (readLong f) != 1 then ( format "Error in Material Effect Texture[Pos: %]\n" (ftell f); exit )
											readLong f		--Data size-->2 int (Texture Filter Mode Flags, unknown)
											readLong f		--Version
											readLong f
											if (readLong f) != 2 then ( format "Error in Material Effect String[Pos: %]\n" (ftell f); exit )
											local string_Length = readLong f #unsigned
											readLong f		--Version
											RTex = readString f
											if RTex != "" then mtl.bumpMap = bitmaptexture name:RTex filename:(RTex+texEx)  
											fseek f MExt_end #seek_set
										) else ( fseek f MExt_end #seek_set )
									) else ( fseek f MExt_end #seek_set )
								) else fseek f MExt_end #seek_set
							) else (
								if type == 2 then (
									if classof mtl == GTA_Mtl then (
										mtl.reflection = (Readfloat f) * 100
										try (mtl.use_RF = true) catch ()
										mtl.matEffect = 2
									) else mtl.reflectionMapAmount = (Readfloat f) * 100
									ReadLong f; ReadLong f	--unknown?? 0 1 <-this 1 act as on/off texture switch?
									if tmpsize > 24 then (
										if (readLong f) == 6 then (
											readLong f      --Data size
											readLong f		--Version
											if (readLong f) != 1 then ( format "Error in Material Effect Texture[Pos: %]\n" (ftell f); exit )
											readLong f		--Data size-->2 int (Texture Filter Mode Flags, unknown)
											readLong f		--Version
											readLong f
											if (readLong f) != 2 then ( format "Error in Material Effect String[Pos: %]\n" (ftell f); exit )
											local string_Length = readLong f #unsigned
											readLong f		--Version
											RTex = readString f
											if RTex != "" then mtl.reflectionmap = bitmaptexture name:RTex filename:(RTex+texEx)  
											fseek f MExt_end #seek_set
										) else ( fseek f MExt_end #seek_set )
									) else readlong f --should be 0 if no reflection texture map
								) else (
									if type == 4 then ( -- Dual
										chMfx = true
										impCh = false
										try mtl.matEffect catch chMfx = false	
										if (classof mtl == GTA_Mtl) and chMfx == true then impCh = true
										if impCh == true then (
											mtl.matEffect = 5
											mtl.p_srcblend = (ReadLong f)
											mtl.p_destblend = (ReadLong f)
											ReadLong f	--unknown?? 0 1 <-this 1 act as on/off texture switch?
											if (readLong f) == 6 then (
												readLong f      --Data size
												readLong f		--Version
												if (readLong f) != 1 then ( format "Error in Material Effect Texture[Pos: %]\n" (ftell f); exit )
												readLong f		--Data size-->2 int (Texture Filter Mode Flags, unknown)
												readLong f		--Version
												readLong f
												if (readLong f) != 2 then ( format "Error in Material Effect String[Pos: %]\n" (ftell f); exit )
												local string_Length = readLong f #unsigned
												readLong f		--Version
												RTex = readString f
												if RTex != "" then mtl.dualMap = bitmaptexture name:RTex filename:(RTex+texEx)  
												fseek f MExt_end #seek_set
											) else ( fseek f MExt_end #seek_set )
										) else ( fseek f MExt_end #seek_set )
									) else (fseek f MExt_end #seek_set )
								)
							)
						) catch ( 
							format "error read Mat Fx\n"
							fseek f MExt_end #seek_set 
						)
					) else ( fseek f MExt_end #seek_set )
				)
				39056124: (
						if showdetail == true then format "\t\t\t\tSA RefMat(%) Size: %\n" header tmpsize
						if (tmpsize != 24) and (gtaMatFlag == false) then (fseek f tmpsize #seek_cur)
						else (
							if DebugMode == true then mtlflag[5] = true
							sr = (readFloat f) * 255
							sg = (readFloat f) * 255
							sb = (readFloat f) * 255
							sa = (readFloat f) * 255
							bnd = readFloat f
							mtl.specular = color sr sg sb
							if classof mtl == GTA_Mtl then (
								try (mtl.use_SAS = true) catch ()
								mtl.blend = bnd
								mtl.spec_alpha = sa
							) else (
								mtl.glossiness = bnd as integer
								mtl.Soften = bnd - mtl.glossiness
							)
							readFloat f
						)
				) 
 				39056118: (
					MExt_end = (ftell f) + tmpsize
					if showdetail == true then format "\t\t\t\tSA SpecMat(%) Size: %\n" header tmpsize
					spwr = (readFloat f)*100
					slTex = readString f
					try (mtl.use_SI = true) catch ()
					if classof mtl == GTA_Mtl then mtl.spec_power = spwr
					else mtl.specular_level = spwr
					mtl.specularmap = bitmaptexture name:slTex filename:(slTex+texEx)
					fseek f MExt_end #seek_set

					if DebugMode == true then mtlflag[4] = true

				)
				309: (
					-- Material Animation PLG (0x135 = 309)
					if showdetail == true then format "\t\t\t\tMaterial Animation PLG(309) Size: %\n" tmpsize
					
					if gUVAnimImportEnabled then (
						-- tmpsize and version were already read, so rewind to read them in the function
						fseek f -8 #seek_cur  -- Go back 8 bytes (size + version)
						local animName = ReadMaterialAnimPLG f 0
						
						if animName != undefined then (
							-- Track applied animations by material:animation pairs to prevent duplicates
							local materialAnimKey = (try mtl.name catch "unknown") + "::" + animName
							
							local alreadyApplied = false
							for appliedKey in gAppliedMaterialAnims where appliedKey == materialAnimKey do (
								alreadyApplied = true
								exit
							)
							
							if alreadyApplied then (
								format "     >>> Material '%' already has animation '%' applied - skipping duplicate\n" (try mtl.name catch "unknown") animName
							) else (
								format "     >>> Material '%' references UV anim: '%'\n" (try mtl.name catch "unknown") animName
								
								-- Find matching animation data from dictionary
								local animData = undefined
								for uvAnim in gUVAnimDict where uvAnim.name == animName do (
									animData = uvAnim
									exit
								)
								
								if animData != undefined then (
									format "     >>> Applying UV animation to material\n"
									ApplyUVAnimToMaterial mtl animData
									-- Track that we've applied this animation
									append gAppliedMaterialAnims materialAnimKey
								) else (
									format "Warning: UV animation '%' referenced but not found in dictionary (dict has % entries)\n" animName gUVAnimDict.count
								)
							)
						)
					) else (
						-- Skip the PLG data if import is disabled
						fseek f tmpsize #seek_cur
					)
				)
				default: (
					if showdetail == true then format "\t\t\t\tunknown(%) Size: %\n" header tmpsize
					fseek f tmpsize #seek_cur
				)
			)--end case
		)--end while 
            
	)--end if MExt

	-- Enable material display in viewport
	mtl.showInViewport = true

	return mtl
    
)
--end fn rMaterial			--<i7>--
--
fn rMaterialList f mattype texEx showdetail = (
	if (readLong f) != 8 then ( format "Error in MaterialList\n"; exit )
	tmp = (readLong f #unsigned)
	if showdetail == true then format "\t\t\tMaterialList(8) Size: %\n" tmp
	readLong f		--Version
	if readLong f != 1 then ( format "Error in MaterialList Data\n"; exit )
	local Data_length = (readLong f)/4
	readLong f		--Version
	material_count = readLong f
	if showdetail == true then format "\t\t\t\t->Material Count:%\n" material_count
	for i = 1 to material_count do (readLong f #unsigned)
    if material_count == 1 then thismtl = rMaterial f mattype texEx showdetail
    else (
        thismtl = MultiMaterial numsubs:material_count
    	for i = 1 to material_count do (
	    	thismtl[i] = rMaterial f mattype texEx showdetail
	    )
    )--end if/else
    return thismtl
)
--end fn rMaterialList		--<i8>--
--
fn rGeometry f Iscale mattype texEx showdetail = (
	if (readLong f) != 15 then ( format "Error in Geometry\n"; exit )
	tmp = (readLong f #unsigned)
	if showdetail == true then format "\t\tGeometry(15) Size: %\n" tmp
	ver = readLong f		--Version
	if readLong f != 1 then ( format "Error in GeometryList Data\n"; exit )
	Geo_length = (readLong f #unsigned)
	readLong f		--Version
	--Info--
	GeometryFlags = readByte f #unsigned
            --byte Flag info.
            --      1   use Tri-Strip
            --      2   Position
            --      4   Texture UV
            --      8   Prelit (Vertex Colors)
            --      16  Normal
            --      32  Light
            --      64  Modulate Material Color
            --      128 Textured2 ??

    readByte f      --unknown?? always 0
	t2count = readShort f		--unknown?? for Textured2 use, no of UV map??
	face_count = readLong f #unsigned
	vert_count = readLong f #unsigned
	mt_count = readLong f #unsigned
	if showdetail == true then (
		format "\t\t\t->No. Faces: %\n" face_count 
		format "\t\t\t->No. Verts: %\n" vert_count 
		format "\t\t\t->No. Frame: %\n" mt_count
	)
	--Light--
	if (ver == 0x1003FFFF)OR(ver == 0x1803FFFF) then ()
	else (
		amb = (readFloat f)
		dif = (readFloat f)
		spe = (readFloat f)
		if showdetail == true then (
			format "\t\t\t->Ambient: %\n" amb
			format "\t\t\t->Diffuse: %\n" dif
			format "\t\t\t->Specular: %\n" spe
		)   
	)
	--===================--
	-- create empty mesh --
	--===================--
	DFFmesh=mesh numverts:vert_count numfaces:face_count


	--Vertex Colors--
	if isIplImport == false then pbUpdate()
	meshop.setMapSupport DFFmesh -2 false
	meshop.setMapSupport DFFmesh -2 true
	if ((mod GeometryFlags 16) >= 8) then (
		if showdetail == true then Format "\t\t\t<<<<<This Model has Vertex Colors!>>>>>\n"
		setNumCPVVerts DFFmesh vert_count
		buildVCFaces DFFmesh
		for i = 1 to vert_count do (
			r = readByte f #unsigned
			g = readByte f #unsigned
			b = readByte f #unsigned
			a = readByte f #unsigned
			VCol = color r g b
			setVertColor DFFmesh i VCol
			--format "%\n" a
			meshop.setMapVert DFFmesh -2 i [(a * 1.0 /255.0),(a * 1.0 /255.0),(a * 1.0 /255.0)]
		)--end for i 
	)--end Vertex Color	

	if isIplImport == false then pbUpdate()
	--UVs--
	if (t2count > 0)OR((mod GeometryFlags 8) >= 4) then (
		DFFmesh.numTVerts = vert_count
		buildTVFaces DFFmesh
		--format "UV1 Start :%\n" (ftell f)
		for i = 1 to vert_count do (
			SetTVert DFFmesh i [(readFloat f),(1 - (readFloat f)),0]
		)--end for i	
	)--end UV
	--format "UV1 End :%\nUV2 Start :%\n" ((ftell f)-1) (ftell f)	

	if isIplImport == false then pbUpdate()
	--UVs Texture2--
	if t2count > 1 then (
		meshop.setNumMaps DFFmesh 3
		meshop.setMapSupport DFFmesh 2 true
		if showdetail == true then Format "\t\t\t<<<<<UV Map2 Skipped!>>>>>\n"
		--if showdetail == true then Format "\t\t\t<<<<<use UV Map2 instead of UV1!>>>>>\n"
		for i = 1 to vert_count do (
			meshop.setMapVert DFFmesh 2 i [(readFloat f),(1 - (readFloat f)),0] 
		)--end for i
	)--end Textured2 UVs

	if isIplImport == false then pbUpdate()
	if t2count > 2 then for  jj = 3 to t2count do (
		format "UV% Start :%\n" jj (ftell f)
		for i = 1 to vert_count do ( (readFloat f);(readFloat f) )
		format "UV% End :%\n" jj ((ftell f)-1)
	)
	
	if isIplImport == false then pbUpdate()
	if t2count > 2 then for jj = 3 to t2count do (
		-- extra maps handling (no-op placeholder to preserve behaviour)
		for i = 1 to vert_count do ( (readFloat f);(readFloat f) )
	)
	
	if isIplImport == false then pbUpdate()
	--Faces--
	for i = 1 to face_count do (
		a2 = (readShort f #unsigned)  + 1.0
		a1 = (readShort f #unsigned) + 1.0
		fg = (readShort f #unsigned) 
		a3 = (readShort f #unsigned) + 1.0
		setFace DFFmesh i a1 a2 a3
		setEdgeVis DFFmesh i 1 true;setEdgeVis DFFmesh i 2 true;setEdgeVis DFFmesh i 3 true
		if ((mod GeometryFlags 8) >= 4)OR((mod GeometryFlags 256) >= 128) then ( setTVFace DFFmesh i a1 a2 a3 )
		if (mod GeometryFlags 16) >= 8 then ( setVCFace DFFmesh i a1 a2 a3 )
		if t2count == 2 then meshop.setMapFace DFFmesh 2 i [a1, a2, a3]
		meshop.setMapFace DFFmesh -2 i [a1, a2, a3]
	)--end for i

	--Bounding Sphere--
	BoundingX = (readFloat f)  * Iscale
	BoundingY = (readFloat f)  * Iscale
	BoundingZ = (readFloat f)  * Iscale
	BoundingRadius = (readFloat f)  * Iscale
	readFloat f		--PositionFlag??
	readFloat f		--NormalsFlag??

	if isIplImport == false then pbUpdate()
	--Vertices--
	for i = 1 to vert_count do (
		tx = (readFloat f)  * Iscale
		ty = (readFloat f)  * Iscale
		tz = (readFloat f)  * Iscale
		setVert DFFmesh i tx ty tz
	)--end for i		

	if isIplImport == false then pbUpdate()
	--Normals--
	if (mod GeometryFlags 32) >= 16 then (
		for i = 1 to vert_count do (
			tx = readFloat f
			ty = readFloat f
			tz = readFloat f
			setNormal DFFmesh i [tx,ty,tz]
		)--end for i
	)--end Normals

if DebugMode == true then (
	global mtlflag = #()
	if (mod GeometryFlags 256) >= 128 then bol = true else bol = false
	setUserProp DFFmesh "Textured2" bol
	if (mod GeometryFlags 128) >= 64 then bol = true else bol = false
	setUserProp DFFmesh "ModulateMaterialColor" bol
	if (mod GeometryFlags 64) >= 32 then bol = true else bol = false
	setUserProp DFFmesh "Light" bol
	if (mod GeometryFlags 32) >= 16 then bol = true else bol = false
	setUserProp DFFmesh "Normal" bol
	if (mod GeometryFlags 16) >= 8 then bol = true else bol = false
	setUserProp DFFmesh "Prelit" bol
	if (mod GeometryFlags 8) >= 4 then bol = true else bol = false
	setUserProp DFFmesh "Textured" bol
	if (mod GeometryFlags 4) >= 2 then bol = true else bol = false
	setUserProp DFFmesh "Position" bol
	if (mod GeometryFlags 2) >= 1 then bol = true else bol = false
	setUserProp DFFmesh "TriStrip" bol	
)
	if isIplImport == false then pbUpdate()
    DFFmesh.material = rMaterialList f mattype texEx showdetail

if DebugMode == true then (
	if mtlflag[1] == true then setUserProp DFFmesh "Tex" true
	if mtlflag[2] == true then setUserProp DFFmesh "Alpha" true
	if mtlflag[3] == true then setUserProp DFFmesh "Ref" true
	if mtlflag[4] == true then setUserProp DFFmesh "SI" true
	if mtlflag[5] == true then setUserProp DFFmesh "SAS" true
)

    if (readLong f) != 3 then ( format "Error in Geometry Extension[Pos: %]\n"  (ftell f); exit )
	GExt = readLong f #unsigned
    if showdetail == true then format "\t\t\tExtension(3) size: %\n" GExt
	readLong f		--Version
	hh = false
	if GExt != 0 then (
		local Loop_end = (ftell f) + GExt
        while (ftell f) < Loop_end do (
			local header = readLong f
            local string_length = readLong f #unsigned
            ver = readLong f		--Version            
            
			case header of (		
				1294: (
					if showdetail == true then format "\t\t\t\tMaterialSplit(1294) Size: %\n" string_length 
					if isIplImport == false then pbUpdate()
					tmp = rMaterialSplit DFFmesh f showdetail
					if tmp == undefined then return undefined
				)
				261: (
					if showdetail == true then format "\t\t\t\tMorph(261) Size: %\n" string_length
					fseek f string_length #seek_cur
				)
				278: (
					if showdetail == true then format "\t\t\t\tSkin(278) Size: %\n" string_length
					if isIplImport == false then pbUpdate()
					SkinData = rSkinPLG f string_length vert_count ver
				)
				39056121: (
					if isIplImport == false then pbUpdate()
					gg = (ftell f)
					rNVC DFFmesh f
					fseek f gg #seek_set
					fseek f string_length #seek_cur
				)
				39056120:(
					if isIplImport == false then pbUpdate()
					gg = (ftell f)
					r2DFX DFFmesh string_length f
					fseek f gg #seek_set
					fseek f string_length #seek_cur
				)
				default: (
					if showdetail == true then format "\t\t\t\tunknown(%) Size: %\n" header string_length
					fseek f string_length #seek_cur
				)
			)--end case
		)--end while
	)--end if GExt
	update DFFmesh
	return DFFmesh
)

--end fn rGeometry			--<i9>--
--

--M------------
--Main Import--
---------------
fn DFFin f Iscale mattype texEx Dummysize autoskin showdetail setsname = (
	imp2dfxCount = 0
	impHas2dfx = false
	gUVAnimDict = #()  -- Clear UV animation dictionary for new import
	gAppliedMaterialAnims = #()  -- Clear tracking of applied animations
	local RootObj
	local firstRootName = false
    lightArr_ = #()
	bkupadd = ftell f
	sLDffNow = ""
	sLDffMax = ""
	
    if (LetsRockandRoll != True) then (
        Zmodlocked = CheckZmodLock f
		if Zmodlocked == true then messagebox "This DFF is locked !\nThe author of this model do not allow you to modify it.\n\nPlease contact the author for the permission." title:"Import Failed"
	) else ( Zmodlocked = false )

	if Zmodlocked != true then (
    
		fseek f bkupadd #seek_set

		if showdetail == true then clearlistener()
		SkinData = undefined
		cpary = rClump f showdetail
		FrameAry = rFrameList f Iscale showdetail
		NumGeo = rGeometryList f showdetail
		
		MshAry = #()
		popPrompt()
		if cntLDffNow != 0 and cntLDffMax != 0 then (
			sLDffNow = cntLDffNow as string
			sLDffMax = cntLDffMax as string
		) else (
			sLDffNow = ""
			sLDffMax = ""
		)
		pushPrompt ("Import DFF " + "(" + sLDffNow + "/" + sLDffMax + "): " + (setsname as string) + " - read geometry...")
		for i = 1 to NumGeo do (
			if isIplImport == false then pbUpdate()
			msh = rGeometry f Iscale mattype texEx showdetail 
			if msh == undefined then (return undefined)
			
			append MshAry msh
		)
		if isIplImport == false then pbUpdate()
		popPrompt()
		if cntLDffNow != 0 and cntLDffMax != 0 then (
			sLDffNow = cntLDffNow as string
			sLDffMax = cntLDffMax as string
		) else (
			sLDffNow = ""
			sLDffMax = ""
		)
		pushPrompt ("Import DFF " + "(" + sLDffNow + "/" + sLDffMax + "): " + (setsname as string) + " - read atomic...")
		-- Replace the atomic-processing section inside DFFin with this robust version.
		while (readLong f) != 3 do (
			fseek f -4 #seek_cur
			local Idx = rAtomic f showdetail

			-- Skip undefined returns from rAtomic safely
			if Idx == undefined then (
				continue
			)

			-- Expect an array: #(frameIndex, something, ...)
			if (classof Idx == Array) and (Idx.count >= 2) then (
				local frameIdx = Idx[1] as integer
				local second = Idx[2]

				-- If second is numeric, treat it as a mesh index into MshAry
				if (classof second == Integer) or (classof second == Float) then (
					local meshIdx = (second as integer)
					if (MshAry != undefined) and (meshIdx >= 1) and (meshIdx <= MshAry.count) then (
						FrameAry[frameIdx].obj = MshAry[meshIdx]
					) else (
						format "Warning: atomic refers to invalid mesh index % (MshAry.count=%). Frame % left undefined.\n" meshIdx (if MshAry==undefined then 0 else MshAry.count) frameIdx
						FrameAry[frameIdx].obj = undefined
					)
				) else (
					-- Otherwise assume it's already a node (light/dummy/etc.) and assign directly
					FrameAry[frameIdx].obj = second
				)
			) else (
				format "Warning: unexpected return from rAtomic: %\n" Idx
			)
			-- Debug: safe ATM userprop setting
			if DebugMode == true then (
				try (
					if (Idx != undefined) and (Idx.count >= 2) then (
						local idxMesh = Idx[2]
						if ((classof idxMesh == Integer) or (classof idxMesh == Float)) then (
							local meshIdx = (idxMesh as integer)
							if (MshAry != undefined) and (meshIdx >= 1) and (meshIdx <= MshAry.count) then (
								local target = MshAry[meshIdx]
								if target != undefined then try ( setUserProp target "ATM" Idx[4] ) catch ( format "Warning: setUserProp ATM failed for MshAry[%] -> %\n" meshIdx target )
							)
						) else (
							-- idx[2] is a node
							try ( setUserProp Idx[2] "ATM" Idx[4] ) catch ( format "Warning: setUserProp ATM failed for node %\n" Idx[2] )
						)
					)
				) catch ()
			)
		)

		if showdetail == true then format "Clump END--> %\n\n" ((ftell f) + 8)
			for i = 1 to FrameAry.count do (
				if FrameAry[i].obj == undefined then 				
						FrameAry[i].obj = dummy boxsize:( [1,1,1] * Dummysize * Iscale )
				if FrameAry[i].name != undefined then (
					setUserProp FrameAry[i].obj "FrameName" (stripSpace FrameAry[i].name)
					FrameAry[i].obj.name = FrameAry[i].name
				)
			)
        
		--Here re-calculate transform form IBM--
		--> inverse(this.transform) is transform in related to world
		if (SkinData != undefined) then (
			popPrompt()
			pushPrompt ("Import DFF: " + (setsname as string) + " - read skin data...")
			FrameAry[1].obj.transform = FrameAry[1].transform
			FrameAry[1].obj.pos = FrameAry[1].obj.pos * Iscale
			RootObj = FrameAry[1].obj
			
			ibm = SkinData[3]
			--for tf in ibm do format "%\n" tf
			for i = 1 to ibm.count do (
				ibm[i].pos = ibm[i].pos * Iscale
				fms = for fm in FrameAry where (getUserProp fm.obj "BoneIndex") == (i - 1) collect fm
				if fms.count > 0 then (
					if i == 1 then (
						setUserProp fms[1].obj "SPunknown" SkinData[4]
						fms[1].obj.transform = ibm[i] * FrameAry[1].obj.transform
						--format ">>%\n" fms[1].obj.transform
					) else (
						fms[1].obj.transform = inverse(ibm[i]) * FrameAry[1].obj.transform --* FrameAry[pid].transform
						fms[1].obj.parent = FrameAry[(fms[1].parentID)].obj
						if showdetail == true then format "% -> %\n" fms[1].obj.name FrameAry[(fms[1].parentID)].obj.name
					)
				) else (
					if showdetail == true then format "Warning: No frame found for BoneIndex %\n" (i - 1)
				)
			)--end for i

			--check for max version, if < v4 then no auto skin--
			----------------------------------------------------
			mv = maxVersion()
			if mv[1] < 4000 then (
				if autoskin == true then	format "\nNo Auto Skin in Max3!!!\n\n"
				autoskin = false
			)

		) else (
			for i = 1 to FrameAry.count do (
				if (FrameAry[i].parentID == 0)OR( (SkinData != undefined)AND(FrameAry[i].parentID == 1) ) then ( 
					FrameAry[i].obj.transform = FrameAry[i].transform
					if FrameAry[i].parentID == 0 then RootObj = FrameAry[i].obj  
				) else ( 
					bkup = FrameAry[(FrameAry[i].parentID)].obj.transform
					FrameAry[(FrameAry[i].parentID)].obj.transform = (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
					--FrameAry[i].obj.transform = FrameAry[i].transform * inverse( FrameAry[(FrameAry[i].parentID)].obj.transform )
					FrameAry[i].obj.parent = FrameAry[(FrameAry[i].parentID)].obj				
					if showdetail == true then format "% -> %\n" FrameAry[i].obj.name FrameAry[(FrameAry[i].parentID)].obj.name
					FrameAry[i].obj.transform = FrameAry[i].transform
					FrameAry[(FrameAry[i].parentID)].obj.transform = bkup
				)
			)--end for i
		)

		if (autoskin == true)AND(SkinData != undefined) then (
			skn = skin()
				
			max modify mode
			select MshAry[1]
			addmodifier MshAry[1] skn
			local boneCount = 0
			for ii = 1 to ibm.count do (
				tmp = for fm in FrameAry where (getUserProp fm.obj "BoneIndex") == (ii - 1) collect fm.obj
				if tmp.count > 0 then (
					skinOps.addbone skn tmp[1] 0
					boneCount += 1

					for jj = 1 to 2 do (
						skinOps.SetInnerRadius skn boneCount jj 0
						skinOps.SetOuterRadius skn boneCount jj 0
					)
				) else (
					format "Warning: No bone found for BoneIndex % (skipping)\n" (ii - 1)
				)
			)--end for ii
			format "\nSkinning... Please Wait\n"
			for jj = 1 to $.numVerts do (
				skinOps.SetVertexWeights skn jj SkinData[1][jj] SkinData[2][jj]
			)
			format "Done!\n"	
		)--end if autoskin

		if setsname != undefined then (
			allObjs = for fm in FrameAry collect fm.obj
			selectionSets[setsname] = allObjs
		)
		
		try (
			if impHas2dfx == true and lightArr_.count > 0 then (
				for i = 1 to lightArr_.count do (	   
					newLight = lightArr_[i]
					newLight.pos.x = s_2dfinfo.v2d_L_posX[i]
					newLight.pos.y = s_2dfinfo.v2d_L_posY[i]
					newLight.pos.z = s_2dfinfo.v2d_L_posZ[i]
					
					--format "%\n" ([s_2dfinfo.v2d_L_posX[i],s_2dfinfo.v2d_L_posY[i],s_2dfinfo.v2d_L_posZ[i]])
					-- FIX: explicit cast to string for concatenation
					newLight.name = "2dfx" + (i as string)
					popPrompt()
					if cntLDffNow != 0 and cntLDffMax != 0 then (
						sLDffNow = cntLDffNow as string
						sLDffMax = cntLDffMax as string
					) else (
						sLDffNow = ""
						sLDffMax = ""
					)
					pushPrompt ("Import DFF " + "(" + sLDffNow + "/" + sLDffMax + "): " + (setsname as string) + " - read 2dfx...")
					newLight.color = s_2dfinfo.v2d_L_color[i]
					newLight.pos = [s_2dfinfo.v2d_L_posX[i],s_2dfinfo.v2d_L_posY[i],s_2dfinfo.v2d_L_posZ[i]]
					setUserProp newLight "2d_L_Dist" s_2dfinfo.v2d_L_Dist[i]
					setUserProp newLight "2d_L_OutRange" s_2dfinfo.v2d_L_OutRange[i]
					setUserProp newLight "2d_L_Size" s_2dfinfo.v2d_L_Size[i]
					setUserProp newLight "2d_L_ShSize" s_2dfinfo.v2d_L_ShSize[i]
					setUserProp newLight "2d_L_ShowMode" s_2dfinfo.v2d_L_ShowMode[i]
					setUserProp newLight "2d_L_Refl" s_2dfinfo.v2d_L_Refl[i]
					setUserProp newLight "2d_L_coronaFlareType" s_2dfinfo.v2d_L_coronaFlareType[i]
					setUserProp newLight "2d_L_shadowColorMultiplier" s_2dfinfo.v2d_L_shadowColorMultiplier[i]				
					setUserProp newLight "2d_L_Flags1" s_2dfinfo.v2d_L_Flags1[i]
					setUserProp newLight "2d_L_CoroneName" s_2dfinfo.v2d_L_CoroneName[i]
					setUserProp newLight "2d_L_shadowName" s_2dfinfo.v2d_L_shadowName[i]
					setUserProp newLight "2d_L_shadowZDistance" s_2dfinfo.v2d_L_shadowZDistance[i]
					setUserProp newLight "2d_L_Flags2" s_2dfinfo.v2d_L_Flags2[i]
					setUserProp newLight "2d_L_DirectionX" s_2dfinfo.v2d_L_DirectionX[i]
					setUserProp newLight "2d_L_DirectionY" s_2dfinfo.v2d_L_DirectionY[i]
					setUserProp newLight "2d_L_DirectionZ" s_2dfinfo.v2d_L_DirectionZ[i]
					if MshAry.count == 1 then newLight.parent = MshAry[1]						
				)
			)
		) catch (format "Error set 2dfx param\n")
		gc()
		try (if RootObj.count > 1 then firstRootName = true) catch ()
		if RootObj != undefined and firstRootName == false then RootObj.name = setsname
		popPrompt()
		if cntLDffNow != 0 and cntLDffMax != 0 then (
			sLDffNow = cntLDffNow as string
			sLDffMax = cntLDffMax as string
		) else (
			sLDffNow = ""
			sLDffMax = ""
		)
		pushPrompt ("Import DFF " + "(" + sLDffNow + "/" + sLDffMax + "): " + " Done!")
		return RootObj

	) else (
        return undefined
    )--end if/else Zmodlocked

)--end fn DFFin

format ">>> Defining IFP import functions...\n"

-- Helper function for collecting all children recursively
fn collectChildren_IFP obj = (
	local result = #()
	if obj.children.count > 0 then (
		for child in obj.children do (
			append result child
			join result (collectChildren_IFP child)
		)
	)
	result
)

-- IFP Import Functions for Hierarchy Animations
struct BoneAnimData (
	name,
	keyType,
	frameCount,
	boneID,
	frames = #()
)

-- Full patched ImportIFPToHierarchy with auto-detect divisor and safe key application.
fn ImportIFPToHierarchy rootObj fname skipPosKeys animName = (
	local f, HInfo, AnimInfo, i, startTime = 0
	
	if rootObj == undefined then (
		if selection.count >= 1 then rootObj = selection[1] 
		else (messagebox "Select a root object or pass it to ImportIFPToHierarchy" title:"Import IFP"; return false)
	)
	
	if fname == undefined then fname = getOpenFileName caption:"Import animation (.ifp)" types:"GTA animation (*.ifp)|*.ifp|"
	if fname == undefined then return false
	
	-- Default to root object name if no animation name specified
	if animName == undefined then animName = rootObj.name
	
	f = fopen fname "rb"
	if f == undefined then (messagebox "Cannot open file" title:"Import IFP"; return false)
	
	-- Read header and basic fields
	local HeaderID = readLong f
	if HeaderID != 0x33504E41 then (
		fclose f
		messagebox "This IFP file is not SA format (ANP3).\nOnly SA format hierarchy animations are supported." title:"Import IFP"
		return false
	)
	
	local fileLength = readLong f
	local Aname = readString f
	-- robust name padding handling
	local skipbyte = 23 - (if Aname != undefined then Aname.count else 0)
	if skipbyte < 0 then skipbyte = 0
	fseek f skipbyte #seek_cur
	local AnimCount = readLong f
	
	-- Scan through animations to find matching name
	local foundAnim = false
	local animIndex = 0
	for i = 1 to AnimCount do (
		local animStart = ftell f
		local currentAnimName = readString f
		if currentAnimName == undefined then (
			format "Error reading animation % name at position %\n" i (ftell f)
			fclose f
			return false
		)
		
		skipbyte = 23 - currentAnimName.count
		if skipbyte < 0 then skipbyte = 0
		fseek f skipbyte #seek_cur
		
		local BoneCount = readLong f
		local DataCount = readLong f
		
		if BoneCount == undefined or DataCount == undefined then (
			format "Error reading animation % header at position %\n" i (ftell f)
			fclose f
			return false
		)
		
		-- AnimLength calculation matches ifpAnimInfo: DataCount + (36 * BoneCount) + 4
		local animSize = DataCount + (36 * BoneCount) + 4
		
		if stricmp currentAnimName animName == 0 then (
			-- Found matching animation, seek back to start
			fseek f animStart #seek_set
			foundAnim = true
			animIndex = i
			format "Found animation % (% of %)\n" animName i AnimCount
			exit
		) else (
			-- Skip this animation's data
			fseek f animSize #seek_cur
		)
	)
	
	if not foundAnim then (
		fclose f
		messagebox ("Animation '" + animName + "' not found in IFP file.\nFile contains " + AnimCount as string + " animation(s).") title:"Import IFP"
		return false
	)
	
	-- Read animation section header (we're positioned at the correct animation)
	local RootName = readString f
	skipbyte = 23 - (if RootName != undefined then RootName.count else 0)
	if skipbyte < 0 then skipbyte = 0
	fseek f skipbyte #seek_cur
	local BoneCount = readLong f
	local DataCount = readLong f
	local unkwn = readLong f
	if unkwn != 1 then format "Warning: Unknown value: %\n" unkwn
	format "Importing animation: %\nRoot: %\nBones: %\n" Aname RootName BoneCount
	
	-- collect objects in hierarchy
	local AllObjects = #(rootObj)
	if rootObj.children.count > 0 then ( join AllObjects (collectChildren_IFP rootObj) )
	
	-- We'll read the entire animation data into memory first
	local bonesData = #()
	for i = 1 to BoneCount do (
		local Bname = readString f
		local skipb = 23 - (if Bname != undefined then Bname.count else 0)
		if skipb < 0 then skipb = 0
		fseek f skipb #seek_cur
		
		local KeyType = readLong f
		local FrameCount = readLong f
		local boneID = readLong f
		
		local rec = BoneAnimData name:Bname keyType:KeyType frameCount:FrameCount boneID:boneID frames:#()
		
		for j = 1 to FrameCount do (
			-- read rotation
			local qx = (readShort f #signed) / 4096.0
			local qy = (readShort f #signed) / 4096.0
			local qz = (readShort f #signed) / 4096.0
			local qw = (readShort f #signed) / 4096.0
			-- raw timeTicks (signed 16-bit)
			local timeTicks = readShort f #signed
			
			local frameEntry = #(qx, qy, qz, qw, timeTicks)
			if KeyType == 4 then (
				local pxs = readShort f #signed
				local pys = readShort f #signed
				local pzs = readShort f #signed
				append frameEntry (pxs/1024.0)
				append frameEntry (pys/1024.0)
				append frameEntry (pzs/1024.0)
			)
			append rec.frames frameEntry
		) -- end frame read
		
		append bonesData rec
	) -- end bones read
	
	-- Determine best divisor to convert raw timeTicks -> frames.
	-- The raw ticks in IFP files represent timeline time units
	local maxRaw = 0
	for b in bonesData do (
		for fr in b.frames do (
			if fr[5] > maxRaw then maxRaw = fr[5]
		)
	)
	if maxRaw < 0 then maxRaw = 0 -- safety
	
	-- Get current timeline settings
	local tpf = (ticksperframe as integer)
	if tpf <= 0 then tpf = 160 -- typical default (30fps)
	
	-- Calculate what the frame count would be
	local calculatedFrames = maxRaw / tpf
	format "Max ticks: %, ticksPerFrame: %, calculated frames: %\n" maxRaw tpf calculatedFrames
	
	-- The raw ticks seem to be stored at a fixed rate (160 ticks per frame for 30fps standard)
	-- regardless of the current Max session framerate
	local ifpTicksPerFrame = 160.0  -- standard IFP encoding (30fps)
	local bestFrames = maxRaw / ifpTicksPerFrame
	format "Using IFP standard: 160 ticks/frame -> % frames\n" bestFrames
	
	-- Now apply keys using chosen divisor
	local maxAnimTicks = 0
	for rec in bonesData do (
		local Bname = rec.name
		local KeyType = rec.keyType
		local FrameCount = rec.frameCount
		format "  %: % keys (type: %)\n" Bname FrameCount KeyType
		
		-- find object in hierarchy
		local obj = undefined
		for o in AllObjects where (o.name == Bname) and (superclassof o == helper) do ( obj = o; exit )
		if obj == undefined then (
			for o in AllObjects where o.name == Bname do ( obj = o; exit )
		)
		if (obj != undefined) and (superclassof obj != helper) and (obj.parent != undefined) and (superclassof obj.parent == helper) then obj = obj.parent
		
		if obj == undefined then (
			-- not in scene: skip applying keys but print diagnostics (we already printed counts)
			continue
		)
		
		for fr in rec.frames do (
			local qx = fr[1]; local qy = fr[2]; local qz = fr[3]; local qw = fr[4]
			local rawTicks = fr[5]
			-- SA IFP format: time = (rawShort / 60.0) * framerate
			-- This gives us FRAME numbers directly, not ticks
			local timeInSeconds = rawTicks / 60.0
			local frameNumber = (timeInSeconds * framerate) as integer
			if frameNumber < 0 then frameNumber = 0
			
			-- Debug first key only
			if fr == rec.frames[1] then (
				format "  First key: raw=%, seconds=%, frame=% (fps=%)\n" rawTicks timeInSeconds frameNumber framerate
			)
			
			local rot = quat qx qy qz qw
			local pos = undefined
			if KeyType == 4 then pos = [fr[6], fr[7], fr[8]]
			
			-- create key safely
			try (
				with animate on at time frameNumber (
					in coordsys parent (
						obj.rotation = rot
						-- Apply position based on KeyType and skipPosKeys flag
						if (KeyType == 4) and (not skipPosKeys) then (
							-- Animation has position data and we want to use it
							obj.pos = pos
						) else if (KeyType == 4) and skipPosKeys then (
							-- Animation has position data but we're skipping it
							-- Don't set position at all - preserve skeleton structure
						) else (
							-- KeyType 3 (rotation only) - no position data in animation
							-- Don't set position - preserve skeleton structure
						)
					)
				)
				-- set tangents to linear best-effort
				try (
					local rotCtrl = obj.rotation.controller
					local rotKeyIdx = getKeyIndex rotCtrl frameNumber
					if rotKeyIdx > 0 then (
						rotCtrl.keys[rotKeyIdx].OutTangentType = #linear
						rotCtrl.keys[rotKeyIdx].InTangentType = #linear
					)
				) catch()
				if (KeyType == 4) and (not skipPosKeys) then (
					try (
						local posCtrl = obj.position.controller
						local posKeyIdx = getKeyIndex posCtrl frameNumber
						if posKeyIdx > 0 then (
							posCtrl.keys[posKeyIdx].OutTangentType = #linear
							posCtrl.keys[posKeyIdx].InTangentType = #linear
						)
					) catch()
				)
			) catch ( format "Warning: failed to add key for % at frame %\n" obj.name frameNumber )
			
			if frameNumber > maxAnimTicks then (
				maxAnimTicks = frameNumber
				format "  >>> New max: frame=%\n" maxAnimTicks
			)
		) -- per-frame
	) -- per-bone apply
	
	-- Set final animationRange (in frames)
	local finalEnd = (if maxAnimTicks < 1 then 1 else maxAnimTicks)
	animationRange = interval 0f finalEnd
	format "Animation imported successfully! Range end: % frames\n" animationRange.end
	fclose f
	return true
) -- end fn ImportIFPToHierarchy

format ">>> ImportIFPToHierarchy function defined successfully!\n"

fn DFFinInfo = (
	format "\nDFFin SA function\n"
	format "\n"
    format " - Complete new Bones/Skin functions\n"
	format " - Second UV Map Skipped!\n"
	format " - Material Matching based on ashdexx's explanation, many thanks!\n"
	format " - new GTA Material added\n"
	format " - rwLight try (some data skipped)\n"
	format " - Non-Standard dff import disabled\n"
	format "\nby Kam\t\t15Dec05\nkam.lai@ntlworld.com\n\n"
    
    return (051215)
)