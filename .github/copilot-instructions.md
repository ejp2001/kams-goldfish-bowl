# GTA Modding Tools - AI Agent Context

## Project Overview
This repository contains **Kam's GTA Scripts** (2018 Goldfish Edition) - MaxScript tools for 3ds Max that import/export GTA San Andreas game assets in RenderWare format (DFF models, IFP animations, COL collision, IPL/IDE map data).

## Language & Environment
- **MaxScript** - proprietary scripting language for Autodesk 3ds Max
- Not JavaScript/Python - syntax similarities but different runtime
- Case-insensitive language with unique array/collection syntax
- Functions use `fn functionName param1 param2 = ()` syntax
- No semicolons required, parentheses for grouping/precedence

## Critical Constraints

### Encrypted Files - DO NOT MODIFY
Some `.mse` files are **encrypted/compiled** and cannot be edited:
- `CharDFFimp.mse`
- `CharDFFexp.mse` 
- `gtaDFFout_Fn.mse`
- `GTA_COL_IO.mse`

These show as binary/garbage when opened. The original Kam's version uses these for skinned character exports.

### Two-Version Workflow
**IMPORTANT**: User maintains two separate installations:
1. **Original Kam's GTA Scripts** (`originals/Kams GTA Scripts original/`) - Used ONLY for skinned character exports (no seams)
2. **2018 Goldfish Edition** (`scripts/GTA_Tools(GF)/`) - Used for everything else (has UV animations, enhanced features)

**Why**: The 2018 Goldfish version's vertex remapping system (`RemapByUV1/UV2/VT`) splits vertices at UV seams, causing visible geometric gaps in skinned character models during skeletal deformation. The original uses encrypted implementation that handles this differently. Attempts to fix this in 2018 version have caused crashes.

**DO NOT** attempt to consolidate to single version without extensive testing and understanding of encrypted .mse implementation.

## File Structure
```
scripts/GTA_Tools(GF)/          # Main 2018 Goldfish tools
  ├── DFFexp.ms                 # DFF model export (ACTIVE - MODIFIED)
  ├── DFFimp.ms                 # DFF model import
  ├── GTA_DFF_IO.ms            # Main UI and file operations
  ├── ui_2dfx.ms               # 2dfx effects UI (MODIFIED)
  ├── gtaIFPio_Fn.ms           # IFP animation functions (MODIFIED)
  ├── IFP_IO_GTASA.ms          # SA animation UI
  ├── IFP_IO_GTA.ms            # GTA3/VC animation UI
  ├── GTA_Map_IO.ms            # IPL/IDE map import/export
  ├── CharDFFexp.ms            # OLD character export (not loaded)
  └── *.mse                    # Encrypted files (READ-ONLY)

originals/                      # Reference versions
  ├── Kams GTA Scripts original/  # Working version for characters
  └── Other Plugins/              # 2018 base comparison
```

## Game Format Details

### RenderWare DFF (3D Models)
Binary chunk-based format:
- Each chunk: `[ChunkID (4 bytes)][Size (4 bytes)][Version (4 bytes)][Data...]`
- GTA SA Version: `0x1803FFFF`
- Nested hierarchy: CLUMP → FrameList, GeometryList → Geometry → Material

**Key Chunks**:
- `0x0010` - CLUMP (root container)
- `0x000E` - FrameList (bone/object hierarchy)
- `0x001A` - GeometryList (mesh data container)
- `0x000F` - Geometry (vertices, faces, UVs, normals)
- `0x0007` - Material (textures, colors, properties)
- `0x0116` - Skin PLG (bone weights for characters)
- `0x0135` - Material Animation PLG (links to UV anim dictionary)
- `0x0120` - UV Anim PLG (runtime flags for UV animation)
- `0x002B` - UV Animation Dictionary (keyframe data)
- `0x253F2FA` - 2dfx effects (lights, particles, attractors)

### IFP (Animations)
- GTA3/VC: Simple rotation-only keyframes
- GTA SA: Rotation + translation, compressed quaternions
- KeyType 3: Rotation only (4 values per key)
- KeyType 4: Rotation + Position (7 values per key)

### 2dfx Effects (in DFF files)
- Type 0x00: Light (corona, shadow, flags)
- Type 0x01: Particle system
- Type 0x03: Ped attractor (animation triggers)
- Type 0x04: Sun reflection (REMOVED - now handled by Type 0x00 Flare Type)

## Recent Modifications (December 2024)

### ✅ FIXED: UV Animation Export
**Issue**: UV animations stopped exporting, objects not animating in-game  
**Cause**: Missing UV Anim PLG (0x120) chunk after Material Animation PLG (0x135)  
**Files Modified**: `DFFexp.ms`
- Lines 1906-1938: Added inline UV Anim PLG writing in `wMaterial` function
- Lines 2575-2592: UV dictionary writing before CLUMP
- Lines 2762-2766: Set atomic `hasRef` flags for UV animated objects
- Lines 94-128: Fixed `colorMap` case sensitivity (GTA_Mtl.colorMap)

**Validated**: Waterfall model with 481 and 514 key animations working in-game

### ✅ FIXED: 2dfx UI Cleanup
**Files Modified**: `ui_2dfx.ms`
- Removed redundant Slotmachine button (Type 4 sun reflection)
- Sun reflection now handled by Light tab's "Flare Type" dropdown
- Final UI: Three buttons (LIGHT, Particle, Ped Attractor)

### ✅ FIXED: IFP Skip Position Keys
**Issue**: "Skip Position keys" checkbox not working reliably  
**Cause**: Flawed architecture - created position keys then attempted unreliable post-facto deletion  
**Files Modified**: `gtaIFPio_Fn.ms` (lines 280-320)
- Rewrote SA animation handling in `ApplyAnim` function
- Removed backup position logic that created keys then deleted
- New preventative conditional logic - keys never created when `noPOSkey=true`
- Applies to all three IFP UI files (GTA3/VC/SA)

### ❌ ATTEMPTED: Skinned Character Seam Fix
**Issue**: 2018 Goldfish creates visible seams on skinned characters with normals enabled  
**Root Cause**: 
- `RemapByUV1` function splits vertices at UV seams (correct for UV mapping)
- `detachBySmGr` splits vertices at smoothing group boundaries (when normals enabled)
- Both cause duplicate vertices that break vertex welding needed for smooth skeletal deformation

**Attempts Made**:
1. Skip `detachBySmGr` for Skin modifier objects - seams remained
2. Force `RemapByVT` (no vertex splitting) for skinned meshes - game crashes due to mismatched skin data
3. Disable normals export for characters - models look cartoon-like without proper shading

**Conclusion**: Vertex remapping system fundamentally incompatible with skinned mesh requirements. Original Kam's encrypted implementation handles this correctly but cannot be inspected or modified. **Reverted all changes**, maintaining two-version workflow.

## Code Architecture

### Export Pipeline (DFFexp.ms)
1. `DFFout` - Main export for regular objects
   - Copy and prepare mesh (`tmpMsh`)
   - Build map faces (UV channels)
   - **Conditionally** call `detachBySmGr` if normals enabled
   - Call `RemapGeo` to remap vertices/UVs/colors
   - Transfer normals if needed
   - Write geometry chunks

2. `wCharDFFout` - Skinned character export
   - Create skin data (`CreateSkinData`)
   - Call `RemapGeo` with skin data
   - Write geometry with bone weights
   - **DO NOT MODIFY** - use original Kam's version for characters

3. `RemapGeo` - Vertex/UV remapping dispatcher
   - Compares vertex count vs UV1 count vs UV2 count
   - Calls `RemapByVT`, `RemapByUV1`, or `RemapByUV2` based on highest count
   - Returns remapped mesh + skin data

4. `RemapByUV1` - UV-based remapping (creates vertex splits)
   - Creates new vertex for each unique UV coordinate
   - **Critical for proper UV mapping** but **breaks skinned mesh welding**
   - Remaps skin bone indices and weights to new vertex layout

5. `RemapByVT` - Vertex-based remapping (no splits)
   - Maps UVs/colors to existing vertices
   - Preserves vertex welding but **doesn't remap skin data properly**

### Import Pipeline (DFFimp.ms)
- Reads chunk hierarchy
- Builds Max objects from geometry
- Applies materials and textures
- Creates Skin modifier with bone weights

### Animation (gtaIFPio_Fn.ms)
- `ApplyAnim` - Main function to apply IFP keyframes to Max objects
- Handles framerate conversion (30fps → Max fps)
- Bone matching by name or "BoneID" user property
- Conditional position key creation based on `noPOSkey` flag

## Development Guidelines

### Making Changes
1. **Read existing code context** - These scripts are 15+ years old with multiple contributors
2. **Test in-game** - MaxScript errors don't mean game crashes, only in-game testing validates
3. **Backup before modifying** - User maintains working versions for critical workflows
4. **Avoid "complete rewrites"** - Incremental targeted fixes only
5. **Respect encrypted files** - Never attempt to modify .mse files

### Common Pitfalls
- **Case sensitivity**: MaxScript is case-insensitive but property names may have preferred casing
- **Array indexing**: 1-based, not 0-based (`for i = 1 to array.count`)
- **Undefined vs unsupplied**: Check `if var == undefined` and `if var == unsupplied`
- **File I/O**: Binary operations use `fopen`, `fseek`, `readLong`, `writeLong`, etc.
- **Memory management**: Always `delete` temporary meshes/objects
- **Global variables**: Many globals used (`gUVpack`, `gMeshFix`, `bNVC`, etc.) - be careful with scope

### Testing Requirements
Any export changes require:
1. Export from 3ds Max
2. Load DFF in GTA San Andreas
3. Verify visual appearance in-game
4. Test animations/deformations if applicable
5. Check for crashes/corruption

MaxScript "success" ≠ working game asset. The game engine is the final validator.

## Known Issues & Workarounds

### Skinned Character Seams (UNRESOLVED)
- **Symptom**: Visible gaps at UV seams when character animates
- **Workaround**: Use original Kam's version for all skinned character exports
- **Future Fix**: Would require reverse-engineering encrypted CharDFFexp.mse implementation or complete rewrite of remapping system with skin-aware vertex welding

### UV Animation Requirements
- Must have Material Animation PLG (0x135) with 48-byte structure
- Must have UV Anim PLG (0x120) with 12-byte structure (flags: 5, 5, 0)
- Dictionary chunk (0x2B) must precede CLUMP in file structure
- Atomic objects must have `hasRef=true` flag set

### IFP Animation Bone Matching
- Matches by exact bone name first
- Falls back to "BoneID" user property
- Case-sensitive name matching
- Missing bones skip animation (no error)

## Useful References
- RenderWare Graphics SDK documentation (if available)
- GTA Modding Wiki: https://gtamods.com
- Original Kam's forum threads (archived)
- MaxScript reference: https://help.autodesk.com/view/MAXDEV/2023/ENU/

## Questions to Ask Before Modifying
1. Does this affect skinned character exports? (Use original version instead)
2. Is this file encrypted (.mse)? (Cannot modify)
3. Will this change binary chunk structure? (Requires in-game testing)
4. Does this modify vertex count/order? (May break skin weights)
5. Is there a simpler workaround? (Prefer minimal changes)

## Contact & Workflow
- Repository: kams-goldfish-bowl (ejp2001)
- Branch: main
- User maintains two separate tool installations
- Always verify changes in-game before committing
- Rollback via git if exports cause crashes

---
*Last Updated: December 2024*  
*Based on: Kam's GTA Scripts v1.0 (2005) + 2018 Goldfish Edition enhancements*
