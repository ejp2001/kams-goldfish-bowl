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

### Decrypted Files Available
All `.mse` encrypted files have been decrypted and are available in:
- `originals/Kams GTA Scripts original/Decrypted mse files/` - 2005 Kam's original implementation
- `originals/Kams GTA Scripts 2018 Edition by Goldfish/Decrypted mse files/` - 2018 Goldfish modifications

The encrypted `.mse` versions remain in their original folders but are no longer needed for reference since decrypted `.ms` versions exist.

### Tool Separation (Updated January 2026)
**CRITICAL**: The repository now enforces strict separation between character and world object tools to prevent data corruption.

**Two-Tool Architecture:**

1. **GTA_CHAR_IO.ms** (Character Tools - Integrated 2005 Export)
   - **Purpose**: Skinned character models with Skin modifiers and skeletal animations ONLY
   - **Location**: `scripts/GTA_Tools_2026/GTA_CHAR_IO.ms` (renamed from GTA_IFP_IO.ms)
   - **Loads**: 
     - CharDFFimp.ms (2018 import - works fine)
     - CharDFFexp.ms (2005 original export - seamless!)
     - gtaIFPio_Fn.ms (2018 animation functions)
   - **Use For**: CJ, pedestrians, humanoid characters with bone rigs
   - **Features**: Character DFF import/export, IFP skeletal animation management, seamless skinned export
   - **Warning Labels**: "⚠ SKINNED CHARACTERS ONLY ⚠" in UI
   - **Implementation**: Loads 2005 CharDFFexp.ms from `original mse files decrypted/`
   - **NEVER**: Use for world objects, props, vehicles, static meshes

2. **GTA_DFF_IO.ms** (World Object Tools - 2026 Edition)
   - **Purpose**: Static/animated world objects WITHOUT Skin modifiers
   - **Location**: `scripts/GTA_Tools_2026/GTA_DFF_IO.ms`
   - **Loads**: DFFimp.ms, DFFexp.ms, gtaIFPio_Fn.ms, ui_2dfx.ms
   - **Use For**: Doors, gates, props, vehicles, buildings, animated world objects
   - **Features**: DFF import/export, 2dfx effects, UV animations (fixed 2024), world object IFP export (added 2026)
   - **Warning Labels**: "⚠ WORLD OBJECTS ONLY ⚠" in UI
   - **Validation**: ValidateNotCharacter() function blocks Skin modifier exports
   - **Enhanced Base**: 2018 Goldfish Edition with 2024-2026 improvements
   - **NEVER**: Use for skinned characters with Skin modifiers

**Why Separation Is Critical:**
- **2005 Kam's Original**: CharDFFexp.ms uses RemapByVT (vertex-based, preserves welding for smooth skinning)
- **2018 Goldfish Edition**: DFFexp.ms uses RemapByUV1/UV2 (UV-based, creates vertex splits that break skinning)
- **Goldfish Added**: detachBySmGr function splits vertices at smoothing groups (incompatible with Skin)
- **Result**: Using wrong tool creates visible seams on character models or corrupts animation data

**Validation System:**
```maxscript
-- In GTA_DFF_IO.ms (line ~1643)
fn ValidateNotCharacter = (
	for obj in selection do (
		for i = 1 to obj.modifiers.count do (
			if classof obj.modifiers[i] == Skin then (
				-- Show error, block export
				return false
			)
		)
	)
	return true
)
```

**UI Protection:**
- Both tools display prominent warning labels at top of rollout
- GTA_DFF_IO.ms calls ValidateNotCharacter() before SaveDFF and ExportIFP
- Error messages direct users to correct tool for their object type
- Validation prevents silent corruption from wrong tool usage

**File Dependencies:**
```
GTA_CHAR_IO.ms workflow:
  └── CharDFFimp.ms (2018 - character import)
  └── CharDFFexp.ms (2005 original - seamless export)
  └── gtaIFPio_Fn.ms (2018 - animation functions)
  └── Path: original mse files decrypted/CharDFFexp.ms

GTA_DFF_IO.ms workflow:
  └── DFFimp.ms (world object import)
  └── DFFexp.ms (world object export with UV animations)
  └── gtaIFPio_Fn.ms (world object animation export)
  └── ui_2dfx.ms (2dfx effects for lights/particles)
```

### Integrated Workflow (Updated January 2026)
**SOLUTION**: GTA_CHAR_IO.ms now loads 2005 CharDFFexp.ms for seamless character export while keeping 2018 enhancements:
- **GTA_CHAR_IO.ms**: Character import (2018) + Character export (2005 seamless) + Animations (2018 enhanced)
- **GTA_DFF_IO.ms**: World object import/export (2018 with UV animations) + World animations (2018)

**Why Integration Works**: The 2005 CharDFFexp.ms is self-contained and uses `RemapByVT` (vertex-based remapping that preserves welding). It doesn't conflict with 2018 world object code which uses `RemapByUV1/UV2` (UV-based remapping that creates necessary vertex splits for proper UV mapping).

**Result**: Single installation workflow - no need to manually switch between 2005 and 2018 versions. GTA_CHAR_IO.ms automatically uses correct export method for characters.

## File Structure
```
scripts/GTA_Tools_2026/          # Main 2018 Goldfish tools
  ├── DFFexp.ms                 # DFF model export (ACTIVE - MODIFIED)
  ├── DFFimp.ms                 # DFF model import
  ├── GTA_DFF_IO.ms            # World object UI (MODIFIED - validation added)
  ├── GTA_CHAR_IO.ms           # Character UI (RENAMED from GTA_IFP_IO.ms)
  ├── ui_2dfx.ms               # 2dfx effects UI (MODIFIED)
  ├── gtaIFPio_Fn.ms           # IFP animation functions (MODIFIED)
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

## Recent Modifications (December 2024 - January 2026)

### ✅ RESEARCH: Vertex Topology & Vehicle Animation (January 2026)
**Research**: Analyzed GTA SA source code (UndefinifiedGrove) and RenderWare format requirements  
**Findings**:
- Vertex splits at UV seams are GPU requirement (one UV per vertex index)
- RemapByUV1 creates necessary splits for proper texture mapping (CORRECT behavior)
- "Welding" or "cleaning" topology breaks intentional design
- Vehicle hydraulics use realtime physics opcodes, NOT IFP animation files
- Vehicle IFP export works technically but not used by vanilla engine (CLEO potential only)
**Documentation**: Added "Vertex Topology & UV Mapping" and "Vehicle IFP Animation" sections
**Source**: `/research` folder contains leaked source code and game data files

### ✅ ADDED: World Object IFP Animation Export/Import (January 2026)
**Feature**: Added IFP animation export/import for world objects (non-character models) via GTA_DFF_IO.ms  
**Files Modified**: `GTA_DFF_IO.ms`, `DFFimp.ms`, `gtaIFPio_Fn.ms`
- Lines 154-230 (GTA_DFF_IO.ms): ExportIFPFromRoot function with queue-based hierarchy collection, auto BoneID assignment
- Lines 455-480, 773-815 (GTA_DFF_IO.ms): Import/Export buttons with multi-animation support
- Lines 2283-2380, 2465-2500 (DFFimp.ms): ImportIFPToHierarchy with animation name matching and scanning
- Multi-animation IFP support with proper append mode and header updates
**Note**: Original Kam's 2005 version only supported character animations via IFP_IO_GTA.ms

### ✅ ADDED: Tool Separation and Validation (January 2026)
**Feature**: Renamed GTA_IFP_IO.ms → GTA_CHAR_IO.ms, added validation to prevent tool misuse  
**Files Modified**: `GTA_CHAR_IO.ms`, `GTA_DFF_IO.ms`
- GTA_CHAR_IO.ms: Added warning labels "⚠ SKINNED CHARACTERS ONLY ⚠" in rollout header
- GTA_DFF_IO.ms: Added warning labels "⚠ WORLD OBJECTS ONLY ⚠" in rollout header
- GTA_DFF_IO.ms: Created ValidateNotCharacter() function (lines ~1643-1671)
- Validation blocks Skin modifier exports, shows error directing user to 2005 original tools
- Updated rollout floater title: "GTA World Object Tools" (was "DFF IO")
**Purpose**: Prevent data corruption from using wrong tool for object type
**Note**: Formalizes architectural separation originally intended by Kam in 2005

### ✅ FIXED: UV Animation Export (December 2024)
**Issue**: UV animations not exporting correctly, objects not animating in-game  
**Cause**: Missing UV Anim PLG (0x120) chunk after Material Animation PLG (0x135)  
**Work Done**: Complete implementation of UV animation export by E2001
**Files Modified**: `DFFexp.ms`
- Lines 1906-1938: Added inline UV Anim PLG writing in `wMaterial` function
- Lines 2575-2592: UV dictionary writing before CLUMP
- Lines 2762-2766: Set atomic `hasRef` flags for UV animated objects
- Lines 94-128: Fixed `colorMap` case sensitivity (GTA_Mtl.colorMap)
**Validated**: Waterfall model with 481 and 514 key animations working in-game  
**Note**: UV animation structure may have existed in earlier versions but was incomplete/non-functional. This implementation makes it fully working.

### ✅ FIXED: 2dfx UI Cleanup (December 2024)
**Files Modified**: `ui_2dfx.ms`
- Removed redundant Slotmachine button (Type 4 sun reflection)
- Sun reflection now handled by Light tab's "Flare Type" dropdown
- Final UI: Three buttons (LIGHT, Particle, Ped Attractor)

### ❌ REMOVED: IFP Skip Position Keys Fix (January 2026)
**Issue**: Attempted to fix "Skip Position keys" checkbox - caused character skeleton collapse and twisting  
**Files Modified**: `gtaIFPio_Fn.ms` (reverted to original)
**Attempts Made**:
1. Removed conditional position key creation/deletion - broke character locomotion
2. Removed initial `SAbone.pos = [0,0,0]` - skeleton collapsed to origin
3. Added backup/restore pattern - skeleton twisted incorrectly
4. Simplified to "just apply keys from file" - skeleton twisted in knots again

**Conclusion**: Original 2018 Goldfish implementation with `in coordsys parent` block and conditional `deleteKeys` logic is correct and working. **All changes reverted** via git checkout. Position keys are conditionally created/deleted based on KeyType and noPOSkey flag as originally designed.

### ❌ ATTEMPTED: Skinned Character Seam Fix (2018 Goldfish Edition)
**Issue**: 2018 Goldfish Edition creates visible seams on skinned characters with normals enabled  
**Root Cause**: 
- **2018 Goldfish modifications** changed vertex remapping behavior that worked in 2005 original
- `RemapByUV1` function splits vertices at UV seams (correct for UV mapping)
- `detachBySmGr` splits vertices at smoothing group boundaries (when normals enabled)
- Both cause duplicate vertices that break vertex welding needed for smooth skeletal deformation
- **Original 2005 Kam's implementation does not have this problem** - character exports are seamless

**Attempts Made**:
1. Skip `detachBySmGr` for Skin modifier objects - seams remained
2. Force `RemapByVT` (no vertex splitting) for skinned meshes - game crashes due to mismatched skin data
3. Disable normals export for characters - models look cartoon-like without proper shading

**Conclusion**: 2018 Goldfish vertex remapping changes fundamentally incompatible with skinned mesh requirements. **Original 2005 Kam's implementation handles this correctly** with seamless character exports. The working code can be studied in `originals/Kams GTA Scripts original/Decrypted mse files/` but replicating the exact behavior has proven difficult. **Reverted all changes**, maintaining two-version workflow: **use 2005 original for characters, 2018 Goldfish for world objects and UV animations**.

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
   - Call `RemapGeo` with2018 Goldfish version is broken, use original 2005
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

## Vertex Topology & UV Mapping (January 2026 Research)

### Why Vertex Splits Are REQUIRED (Not a Bug!)

**Critical Understanding**: Vertex splits at UV seams are **intentional and necessary** for proper GPU rendering.

**The GPU Requirement:**
- Modern GPUs require **one UV coordinate per vertex index**
- If a 3D position needs different UVs (e.g., cube corner touching 3 faces), you MUST create multiple vertices at that position
- This is called a **UV seam** and is the **correct topology** for textured models

**Example - Cube Corner:**
```
One 3D position [1, 1, 1]
├─ Top face needs UV: (1.0, 1.0) - top-right of texture
├─ Front face needs UV: (1.0, 0.0) - bottom-right of texture
└─ Right face needs UV: (0.0, 1.0) - top-left of texture

Solution: Create 3 vertices at same position with different UVs
Result: Proper texture mapping (CORRECT!)
```

**RemapByVT vs RemapByUV1:**
```
RemapByVT (2005 Character Export):
- Maps UVs to existing vertices (no splits)
- Accepts UV stretching/errors
- Preserves vertex welding (smooth Skin deformation)
- Use for: Characters with Skin modifier

RemapByUV1 (2018 World Objects):
- Creates new vertex for each unique UV
- Proper texture mapping (no stretching)
- Breaks vertex welding (incompatible with Skin)
- Use for: World objects, props, vehicles
```

### ⚠️ WARNING: "Clean Topology" Trap

**Common Mistake**: Some tools "fix" models by welding vertices or centering to origin. This often BREAKS intentional design!

**Why "Fixes" Fail:**

**1. Welding Duplicate Vertices**
```
Problem: Tool sees multiple vertices at same position
"Fix": Weld them together (merge to single vertex)
Result: ❌ Forces them to share ONE UV coordinate
        ❌ Creates texture seams, stretching, broken materials
        ❌ What looked "clean" in Max is broken in-game
```

**Why duplicates exist:**
- Same 3D position + different UVs = REQUIRED for GPU format
- Rockstar's exporters did this correctly
- Welding destroys intentional topology

**2. Aligning to World Origin**
```
Problem: Tool sees model offset from [0,0,0]
"Fix": Center model at origin
Result: ❌ Breaks hierarchies (chassis → door → handle)
        ❌ Relative positions destroyed
        ❌ Vehicle parts no longer align
```

**Why offsets exist:**
- Hierarchies depend on relative positions
- Door at [1.5, 0.5, 0] relative to chassis is INTENTIONAL
- Centering breaks parent-child transforms

**3. "Cleaning" Smoothing Groups**
```
Problem: Tool sees "messy" smoothing group assignments
"Fix": Recalculate smoothing groups automatically
Result: ❌ May create hard edges where smooth shading intended
        ❌ May smooth edges where hard edges needed
        ❌ Visual appearance changes from original
```

### UV Animation & Vertex Splits

**Important**: UV animation works on ANY topology (split or not). The animation system just offsets existing UV coordinates over time.

**UV animation does NOT require splits** - but if your model needs proper UV mapping (textured cube, building, etc.), you already have splits whether animated or not!

**UV Animation Mechanics:**
```
Material Animation PLG (0x135): Links material to animation data
UV Animation Dictionary (0x2B): Contains keyframe data (offset, tiling)
UV Anim PLG (0x120): Runtime flags (5, 5, 0)

Game engine: Reads keyframes → Offsets UVs each frame → Works on any mesh!
```

### Explicit Normals & Smooth UV Seams

**Problem**: When two textures meet on a curved surface:
- Need vertex split for different UVs (required)
- Want unified normals for smooth shading (desired)
- GPU says: "One normal per vertex!" (conflict!)

**Theoretical Solution:**
```
1. Split vertices at UV seam (different UVs)
2. Manually unify normals (same normal on both split copies)
3. Disable smoothing groups (prevent recalculation)
4. Export with explicit normals
5. Hope game engine respects them
```

**Reality**: GTA SA engine may recalculate normals from smoothing groups, ignoring explicit normals. Results vary - test in-game!

### Tool Philosophy

**Our Approach:**
- ✅ Respect Rockstar's intentional design decisions
- ✅ Preserve topology that works in-game
- ✅ Don't "fix" what isn't broken
- ✅ Test in-game, not just in Max preview
- ✅ Document WHY things work (this file!)

**What We Fix:**
- ✅ Actual bugs (missing UV Anim PLG chunks)
- ✅ Add real features (world object IFP export)
- ✅ Maintain compatibility (don't break working code)

**What We DON'T "Fix":**
- ❌ Intentional vertex splits (correct for GPU)
- ❌ Hierarchy offsets (correct for transforms)
- ❌ Working topology (even if "messy" in Max)

**Remember**: "Cleaner" topology in 3ds Max ≠ Correct topology for game engine!

## Known Issues & Workarounds

### Skinned Character Seams (UNRESOLVED)
- **Symptom**: Visible gaps at UV seams when character animates
- **Root Cause**: 2018 Goldfish vertex splitting (RemapByUV1) incompatible with Skin modifier welding requirements
- **Workaround**: Use original Kam's 2005 version via GTA_CHAR_IO.ms (automatically loads correct exporter)
- **Why It Works**: 2005 CharDFFexp.ms uses RemapByVT (preserves vertex welding, accepts UV errors)
- **Future Fix**: Would require skin-aware vertex remapping that updates bone weights after splits

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

### Vehicle IFP Animation (January 2026 Research)

**Status**: Not used by vanilla GTA San Andreas engine

**Evidence from Source Code Analysis** (UndefinifiedGrove leaked source):
- vehicles.ide contains NO .ifp file references
- "Anims" column contains vehicle class names (truck, van, bus), NOT animation filenames
- Hydraulics use `CONTROL_CAR_HYDRAULICS` opcode (realtime physics with float values)
- Doors use `POP_CAR_DOOR` opcode (instant state change, no animation playback)
- Landing gear/rotors are hardcoded engine logic (no IFP files)
- `TASK_PLAY_ANIM` opcode only applies to characters/peds, never vehicles

**What Vehicles Actually Use:**
```
Hydraulics: CONTROL_CAR_HYDRAULICS pickup_car wheel_fl wheel_bl wheel_fr wheel_br
  - Realtime suspension control (float values per wheel)
  - NOT animation playback

Doors: POP_CAR_DOOR car_mech1_garag1 BONNET FALSE
  - Instant state change (open/closed)
  - NOT animated transition

Damage: DAMAGE_CAR_DOOR wz1_burncar1 BONNET
  - State flag (damaged/not damaged)
  - NOT animation playback
```

**GTA_DFF_IO.ms Vehicle IFP Export:**
- ✅ Technically works (exports valid IFP files)
- ❌ NOT used by vanilla game for vehicles
- ⚠️ Potential for CLEO modding (custom scripts could load/trigger)
- 📝 Mark as "EXPERIMENTAL - CLEO SCRIPTING ONLY"

**Recommendation**: Keep feature for modding potential, but document that it's not vanilla engine behavior.

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
- Repository: kams-goldfish-bowl (E2001)
- Branch: main
- User maintains two separate tool installations
- Always verify changes in-game before committing
- Rollback via git if exports cause crashes

## Contribution History
- **2005**: Kam's original scripts - Character animations (IFP_IO_GTA.ms), DFF/COL import/export, seamless character export
- **2018**: Goldfish Edition - Vertex remapping changes (RemapByUV1/UV2, detachBySmGr), general tool enhancements, broke character export
- **User (E2001)**: Created IFP_IO_GTASA.ms - Improved character animation UI based on IFP_IO_GTA.ms (easier to use, fewer file corruptions)
- **December 2024 - January 2026 (E2001)**: 
  - UV animation export implementation (December 2024)
  - World object IFP animation export/import (January 2026)
  - Tool separation with validation (Character/Vehicle/Scenery IO)
  - 2dfx UI cleanup
  - Integration of 2005 character export for seamless skinning

---
*Last Updated: January 8, 2026*  
*Based on: Kam's GTA Scripts v1.0 (2005) + 2018 Goldfish Edition enhancements + E2001 improvements + UndefinifiedGrove source code analysis*
