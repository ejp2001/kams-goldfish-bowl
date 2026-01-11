-- GTA DFF Binary Editor
-- Inspired by RW Analyze by Steve M. (2004)
-- 
-- Tree view visualization of RenderWare chunk hierarchy
-- Allows viewing, navigation, and basic editing of DFF structure
--
-- Created: January 8, 2026

-- Chunk type definitions (from RW_Secs.ini)
global ChunkNames = #(
	#(0x0000, "N/A Object"),
	#(0x0001, "Struct"),
	#(0x0002, "String"),
	#(0x0003, "Extension"),
	#(0x0005, "Camera"),
	#(0x0006, "Texture"),
	#(0x0007, "Material"),
	#(0x0008, "Material List"),
	#(0x0009, "Atomic Section"),
	#(0x000A, "Plane Section"),
	#(0x000B, "World"),
	#(0x000C, "Spline"),
	#(0x000D, "Matrix"),
	#(0x000E, "Frame List"),
	#(0x000F, "Geometry"),
	#(0x0010, "Clump"),
	#(0x0012, "Light"),
	#(0x0013, "Unicode String"),
	#(0x0014, "Atomic"),
	#(0x0015, "Texture Native"),
	#(0x0016, "Texture Dictionary"),
	#(0x0017, "Animation Database"),
	#(0x0018, "Image"),
	#(0x0019, "Skin Animation"),
	#(0x001A, "Geometry List"),
	#(0x001B, "Anim Animation"),
	#(0x001C, "Team"),
	#(0x001D, "Crowd"),
	#(0x001E, "Delta Morph Animation"),
	#(0x001f, "Right To Render"),
	#(0x0020, "MultiTexture Effect Native"),
	#(0x0021, "MultiTexture Effect Dictionary"),
	#(0x0022, "Team Dictionary"),
	#(0x0023, "Platform Independent Texture Dictionary"),
	#(0x0024, "Table of Contents"),
	#(0x0025, "Particle Standard Global Data"),
	#(0x0026, "AltPipe"),
	#(0x0027, "Platform Independent Peds"),
	#(0x0028, "Patch Mesh"),
	#(0x0029, "Chunk Group Start"),
	#(0x002A, "Chunk Group End"),
	#(0x002B, "UV Animation Dictionary"),
	#(0x002C, "Coll Tree"),
	-- Toolkit plugins
	#(0x0116, "Skin PLG"),
	#(0x011D, "Collision PLG"),
	#(0x011E, "HAnim PLG"),
	#(0x011F, "User Data PLG"),
	#(0x0120, "Material Effects PLG"),
	#(0x0135, "Material Animation PLG"),
	#(0x0253F2F6, "Bin Mesh PLG"),
	#(0x0253F2F8, "Native Data PLG"),
	#(0x0253F2FA, "2dfx"),
	#(0x0253F2FE, "Frame")
)

-- Get chunk name from type ID
fn GetChunkName chunkType = (
	for pair in ChunkNames where pair[1] == chunkType do return pair[2]
	return ("UNKNOWN 0x" + (bit.intAsHex chunkType))
)

-- Chunk data structure
struct ChunkInfo (
	chunkType,     -- Type ID (DWORD)
	chunkSize,     -- Data size (DWORD)
	chunkVersion,  -- RW version (DWORD)
	fileOffset,    -- Position in file
	dataOffset,    -- Start of actual data (after 12-byte header)
	depth,         -- Tree depth level
	parent,        -- Parent chunk index
	children = #() -- Child chunk indices
)

-- Global state
global DFF_EditorData = #()      -- Array of ChunkInfo structs
global DFF_EditorFile = undefined -- File handle
global DFF_EditorPath = undefined -- Current file path

-- Parse RenderWare chunk header (12 bytes)
fn ReadChunkHeader f = (
	local chunkType = readLong f #unsigned
	local chunkSize = readLong f #unsigned
	local chunkVersion = readLong f #unsigned
	#(chunkType, chunkSize, chunkVersion)
)

-- Recursively parse chunk hierarchy
fn ParseChunks f depth:0 parent:0 startPos:undefined endPos:undefined = (
	if startPos != undefined then fseek f startPos #seek_set
	if endPos == undefined then (
		-- Get file size by seeking to end
		local currentPos = ftell f
		fseek f 0 #seek_end
		endPos = ftell f
		fseek f currentPos #seek_set
	)
	
	local chunks = #()
	
	while (ftell f) < endPos do (
		local headerStart = ftell f
		local header = ReadChunkHeader f
		
		if header == undefined then exit
		
		local chunkType = header[1]
		local chunkSize = header[2]
		local chunkVersion = header[3]
		local dataStart = ftell f
		local dataEnd = dataStart + chunkSize
		
		-- Create chunk info
		local chunk = ChunkInfo \
			chunkType:chunkType \
			chunkSize:chunkSize \
			chunkVersion:chunkVersion \
			fileOffset:headerStart \
			dataOffset:dataStart \
			depth:depth \
			parent:parent
		
		append DFF_EditorData chunk
		local thisIndex = DFF_EditorData.count
		
		-- Add to parent's children
		if parent > 0 then (
			append DFF_EditorData[parent].children thisIndex
		)
		
		-- Check if this is a container chunk (has children)
		local isContainer = false
		case chunkType of (
			0x0010: isContainer = true  -- Clump
			0x000E: isContainer = true  -- Frame List
			0x001A: isContainer = true  -- Geometry List
			0x000F: isContainer = true  -- Geometry
			0x0008: isContainer = true  -- Material List
			0x0007: isContainer = true  -- Material
			0x0014: isContainer = true  -- Atomic
			0x0016: isContainer = true  -- Texture Dictionary
			0x0015: isContainer = true  -- Texture Native
			0x0003: isContainer = true  -- Extension
			0x002B: isContainer = true  -- UV Anim Dictionary
			default: isContainer = false
		)
		
		-- Recursively parse children if container
		if isContainer and chunkSize > 0 then (
			ParseChunks f depth:(depth+1) parent:thisIndex startPos:dataStart endPos:dataEnd
		) else (
			-- Skip data for non-container chunks
			fseek f dataEnd #seek_set
		)
		
		-- Safety check: don't go past expected end
		if (ftell f) > dataEnd then (
			format "WARNING: Read past chunk boundary at offset %\n" headerStart
			fseek f dataEnd #seek_set
		)
	)
)

-- Build tree view display strings
fn BuildTreeView = (
	local lines = #()
	
	for i = 1 to DFF_EditorData.count do (
		local chunk = DFF_EditorData[i]
		local indent = ""
		for d = 1 to chunk.depth do indent += "  "
		
		local name = GetChunkName chunk.chunkType
		local typeHex = bit.intAsHex chunk.chunkType
		local sizeStr = (chunk.chunkSize as string)
		local offsetStr = (chunk.fileOffset as string)
		
		-- Color indicator (simplified for listbox)
		local indicator = if chunk.children.count > 0 then "●" else "○"
		
		local line = indent + indicator + " " + name + " [" + typeHex + "] Size:" + sizeStr + " @" + offsetStr
		append lines line
	)
	
	lines
)

-- Rollout definition
rollout DFF_Editor_Rollout "DFF Binary Editor" width:800 height:600 (
	
	label lblFile "" align:#left offset:[5,5]
	
	-- Tree view (left side)
	listbox lstChunks "" height:30 width:750 align:#center offset:[0,5]
	
	-- Info panel (bottom)
	group "Selected Chunk Info" (
		label lblChunkType "Type: " align:#left
		label lblChunkSize "Size: " align:#left
		label lblChunkOffset "Offset: " align:#left
		label lblChunkVersion "Version: " align:#left
		label lblChunkChildren "Children: " align:#left
	)
	
	-- Action buttons
	button btnRefresh "Refresh View" width:120 align:#left across:5
	button btnFindChunk "Find Chunk..." width:120 align:#left
	button btnExportChunk "Export Section" width:120 align:#left
	button btnSave "Save Changes" width:120 align:#left
	button btnClose "Close File" width:120 align:#right
	
	-- Open file on rollout open
	on DFF_Editor_Rollout open do (
		if DFF_EditorPath != undefined then (
			lblFile.text = "File: " + (filenameFromPath DFF_EditorPath)
			lstChunks.items = BuildTreeView()
		) else (
			lblFile.text = "No file loaded"
		)
	)
	
	-- Update info panel when selection changes
	on lstChunks selected sel do (
		if sel > 0 and sel <= DFF_EditorData.count then (
			local chunk = DFF_EditorData[sel]
			lblChunkType.text = "Type: " + (GetChunkName chunk.chunkType) + " (0x" + (bit.intAsHex chunk.chunkType) + ")"
			lblChunkSize.text = "Size: " + (chunk.chunkSize as string) + " bytes"
			lblChunkOffset.text = "Offset: " + (chunk.fileOffset as string)
			lblChunkVersion.text = "Version: 0x" + (bit.intAsHex chunk.chunkVersion)
			lblChunkChildren.text = "Children: " + (chunk.children.count as string)
		)
	)
	
	on btnRefresh pressed do (
		if DFF_EditorPath != undefined then (
			-- Re-parse file
			DFF_EditorData = #()
			DFF_EditorFile = fopen DFF_EditorPath "rb"
			if DFF_EditorFile != undefined then (
				ParseChunks DFF_EditorFile
				fclose DFF_EditorFile
				lstChunks.items = BuildTreeView()
			)
		)
	)
	
	on btnClose pressed do (
		DFF_EditorData = #()
		DFF_EditorFile = undefined
		DFF_EditorPath = undefined
		try (closeRolloutFloater DFF_Editor_Floater) catch()
	)
	
	on btnSave pressed do (
		messageBox "Save functionality not yet implemented" title:"TODO"
	)
	
	on btnFindChunk pressed do (
		messageBox "Find functionality not yet implemented" title:"TODO"
	)
	
	on btnExportChunk pressed do (
		messageBox "Export functionality not yet implemented" title:"TODO"
	)
)

-- Main function to open DFF file
global fn OpenDFFEditor dffPath = (
	-- Reset state
	DFF_EditorData = #()
	DFF_EditorPath = dffPath
	
	-- Parse file
	local f = fopen dffPath "rb"
	if f == undefined then (
		messageBox ("Cannot open file:\n" + dffPath) title:"File Error"
		return false
	)
	
	ParseChunks f
	fclose f
	
	-- Create or update floater
	try (closeRolloutFloater DFF_Editor_Floater) catch()
	global DFF_Editor_Floater = newRolloutFloater "DFF Binary Editor" 820 640
	addRollout DFF_Editor_Rollout DFF_Editor_Floater
	
	true
)

-- Test function (comment out for production)
-- OpenDFFEditor "C:\\path\\to\\test.dff"
