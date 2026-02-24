# GTA Modding Tools - AI Agent Context

## Purpose
This repository restores and preserves **Kam's GTA Scripts (2005)** with selective 2018 Goldfish Edition improvements. Primary goal: fix character export regressions while adding modern features (UV animations, world object IFP).

**Target Platform**: 3ds Max 2017 (MaxScript)  
**Game**: GTA San Andreas (RenderWare engine)  
**Test Method**: MUST verify exports in-game (MaxScript success ≠ working asset)

## Key Rules
- Active code: `scripts/GTA_Tools_2026/` (edit/ship)
- References: `originals/`, `modding resources/` (cite full paths)
- Duplicate filenames across versions - always use full paths
- Test in-game before committing (visual checks + animation)

## Why this matters (short)
- The 2005 exporter logic and the 2018 Goldfish logic are different in vertex remapping and clump handling. Using the wrong exporter for skinned characters corrupts skinning and animation data.
- We keep separate, validated tool flows for characters and world objects to prevent silent corruption.

## Files and provenance (how to read this repo)
1. Active project files (what we edit and ship):
   - `scripts/GTA_Tools_2026/` — the repository's working tools and UIs.
2. Authoritative references (do not edit directly):
   - `modding resources/kams original mse files decrypted/` — Kam's 2005 originals (decrypted `.ms` copies).
   - `originals/Kams GTA Scripts 2018 Edition by Goldfish/` — Goldfish 2018 reference files.
   - `originals/Other Plugins/` — third-party helpers and examples.

When restoring behavior: add a one-line header to the changed file noting the exact originals path used (e.g. "Restored from: modding resources/kams original mse files decrypted/CharDFFexp.ms").

## Two-Tool Rule (Critical Architecture)

**Character Export** (`GTA_CHAR_IO.ms`):
- Uses 2005 `RemapByVT` (vertex-based, preserves welding)
- Loads: `CharDFFimp.ms`, `CharDFFexp.ms`, `gtaIFPio_Fn.ms`
- For: Skinned characters, skeletal animations, IFP management
- NEVER for: Props, vehicles, world objects

**World Object Export** (`GTA_DFF_IO.ms`):
- Uses 2018 `RemapByUV1/UV2` (UV-based, creates vertex splits)
- Loads: `DFFimp.ms`, `DFFexp.ms`, `gtaIFPio_Fn.ms`
- For: Props, vehicles, buildings, scenery (UV animations, object IFP)
- Runtime validation: Blocks objects with `Skin` modifier

**Why Separate Tools**: UV-based remapping breaks skinned mesh welding (visible seams). Vertex-based remapping distorts UV mapping. Different requirements → different tools.

## Practical guidance for contributors
- When making changes, always state which source you referenced by full path in the commit message and file header.
- Prefer minimal, well-documented commits that reference `originals/...` when restoring behavior.
- Do not replace active files in `scripts/GTA_Tools_2026/` with `originals/` files without an explicit restore commit and rationale.
- For character-related fixes (clump, skin export), consult `modding resources/kams original mse files decrypted/CharDFFexp.ms` first.

## Common pitfalls (short)
- "Wanted: 7 got: 8" errors are typically caused by mixing vertex-based remapping (2005) and UV-based remapping (2018). Use the appropriate exporter for the job.
- Welding, auto-centering, or auto-cleaning topology in Max can destroy intentional game topology (vertex splits for UV seams) — do not do this unless you know the consequences.

## Quick paths (examples)
- Active character exporter reference (2005): modding resources/kams original mse files decrypted/CharDFFexp.ms
- Active Goldfish-world exporter (project): scripts/GTA_Tools_2026/DFFexp.ms
- Character UI (project): scripts/GTA_Tools_2026/GTA_CHAR_IO.ms
- World-object UI (project): scripts/GTA_Tools_2026/GTA_DFF_IO.ms

## If you are restoring behavior
- Cite the exact `originals/...` or `modding resources/...` file path in the file header and PR description.
- Add a short changelog entry explaining why the restore was necessary and which in-game behavior it fixes.

---


### Integrated Workflow (Updated January 2026)
**SOLUTION**: GTA_CHAR_IO.ms now loads 2005 CharDFFexp.ms for seamless character export while keeping 2018 enhancements:
- **GTA_CHAR_IO.ms**: Character import from Kam's Original (2005) + Character export (2005 seamless) + Animation Export
- **GTA_DFF_IO.ms**: World object import/export (2018) + UV and IFP object animations

**Why Integration Works**: The 2005 CharDFFexp.ms is self-contained and uses `RemapByVT` (vertex-based remapping that preserves welding). It doesn't conflict with 2018 world object code which uses `RemapByUV1/UV2` (UV-based remapping that creates necessary vertex splits for proper UV mapping).

**Result**: Single installation workflow - no need to manually switch between 2005 and 2018 versions. GTA_CHAR_IO.ms automatically uses correct export method for characters.



Authoritative references (do not edit directly):
- `modding resources/kams original mse files decrypted/` — Kam's 2005 originals (decrypted `.ms` copies). Example: `CharDFFexp.ms`.
- `originals/Kams GTA Scripts original/` — original 2005 repo snapshot (contains `GTA_Tools/`).
- `originals/Kams GTA Scripts 2018 Edition by Goldfish/` — Goldfish 2018 reference (contains `GTA_Tools(GF)/`, readmes).
- `originals/Other Plugins/` — assorted plugin folders (examples: `dexx_gta/`, `dff/`, `GTA_Animation_XML_IO/`, etc.).


## DFF Parser (internal reference)
'research\rw-parser-ng' folder contains an internal RenderWare DFF parser written in TypeScript. This is a reference implementation to understand chunk structures and data layouts. It is NOT part of the 3ds Max toolset but can be used for offline analysis and verification of DFF files exported by the tools.

## 3DS Max 2017 Help Files
Complete offline help files for 3DS Max version 2017 can be found at: 'research\3dsmax2017\en_us\index.html'. Since 3DS Max 2017 is the main test bed for this project, these help files are a valuable resource for checking available features and avoiding MaxScript errors. Refer to this directory for authoritative documentation when developing or troubleshooting scripts.

Notes:
- If a filename appears in both `scripts/GTA_Tools_2026/` and `originals/`, treat `scripts/GTA_Tools_2026/` as the active, authoritative project file.
- Use full path references in commits and PRs (e.g. `modding resources/kams original mse files decrypted/CharDFFexp.ms`) to avoid ambiguity.


**Conclusion**: 2018 Goldfish vertex remapping changes fundamentally incompatible with skinned mesh requirements. **Original 2005 Kam's implementation handles this correctly** with seamless character exports. The working code can be studied in `originals/Kams GTA Scripts original/Decrypted mse files/`, maintaining two-version workflow: **use 2005 original logic for characters, 2018 Goldfish logic for world objects and UV/IFP animations**.

## Code Architecture

### Export Pipeline (DFFexp.ms)
1. `DFFout` - Main export for regular objects
   - Copy and prepare mesh (`tmpMsh`)
   - Build map faces (UV channels)
   - **Conditionally** call `detachBySmGr` if normals enabled
   - Call `RemapGeo` to remap vertices/UVs/colors
   - Transfer normals if needed
   - Write geometry chunks

2. `CharDFFout` - Skinned character export
   - Create skin data (`CreateSkinData`)
   - Call `RemapGeo` with2018 Goldfish version is broken, use original 2005
   - Write geometry with bone weights

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

## MaxScript Conventions

**File Loading Pattern**:
```maxscript
fileIn (scriptspath+"\\GTA_Tools_2026\\module.ms") quiet:true
global charScriptPath = getFilenamePath(getThisScriptFilename())  -- Relative paths
```

**Settings Persistence**:
```maxscript
-- Save: setINISetting iniFile "Section" "key" (value as string)
-- Load: getINISetting iniFile "Section" "key"
-- Path: scriptsPath + "GTA_Tools_2026\\settings.ini"
```

**Array Indexing**: 1-based (`for i = 1 to array.count`)

**Type Checking**:
```maxscript
if var == undefined then ...     -- Uninitialized
if var == unsupplied then ...    -- Function parameter not provided
```

**Binary I/O**: `fopen`, `fseek`, `readLong`, `writeLong`, `fclose`

**Memory Management**: Always `delete` temporary meshes/objects

**Global Scope**: Tools use many globals (`gUVpack`, `bNVC`, etc.) - check conflicts before adding new ones

**MUTEX Pattern**: Close conflicting tools before launch:
```maxscript
try (closeRolloutFloater Kam_GTA) catch ()  -- In CHAR_IO
try (closeRolloutFloater IFP_IO_GTAsa) catch ()  -- In DFF_IO
```

## Development Workflow

**Making Changes**:
1. Read existing code context (15+ years old, multiple contributors)
2. Cite source file path when restoring behavior
3. **Test in-game** before committing - MaxScript success ≠ working asset
4. Incremental targeted fixes only (no complete rewrites)

**Testing Requirements** (ANY export change):
1. Export from 3ds Max
2. Load DFF in GTA San Andreas
3. Verify visual appearance in-game
4. Test animations/deformations if applicable
5. Check for crashes/corruption

**Common Pitfalls**:
- Case sensitivity: MaxScript is case-insensitive but property names may have preferred casing
- Missing `delete` on temporary objects causes memory leaks
- Global variable conflicts between tools (use MUTEX pattern)
- Forgetting to test in-game (Max preview ≠ game rendering)

**Tool Installation**: Copy `scripts/` folder contents to `3DS_MAX_INSTALLATION/scripts/`. Startup script adds GTA Tools menu automatically.

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
- ✅ Actual bugs
- ✅ Add real features (world object IFP export)
- ✅ Maintain compatibility (don't break working code)

**What We DON'T "Fix":**
- ❌ Intentional vertex splits (correct for GPU)
- ❌ Hierarchy offsets (correct for transforms)
- ❌ Working topology (even if "messy" in Max)

**Remember**: "Cleaner" topology in 3ds Max ≠ Correct topology for game engine!

## Known Issues & Workarounds

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
- 📝 Mark as "EXPERIMENTAL"

**Recommendation**: Keep feature for modding potential, but document that it's not vanilla engine behavior.

## Useful References
- RenderWare Graphics SDK documentation (if available)
- GTA Modding Wiki: https://gtamods.com
- Original Kam's forum threads (archived)

## Questions to Ask Before Modifying
1. Does this affect skinned character exports? (Use 2005 original version)
2. Is this file encrypted (.mse)? (Cannot modify - use decrypted copies)
3. Will this change binary chunk structure? (Requires in-game testing)
4. Does this modify vertex count/order? (May break skin weights)
5. Is there a simpler workaround? (Prefer minimal changes)
6. Which originals/ file should I reference? (Cite exact path)

## File Structure & Dependencies

**Main UIs** (load subsidiary modules):
- `GTA_CHAR_IO.ms` → `CharDFFimp.ms`, `CharDFFexp.ms`, `gtaIFPio_Fn.ms`
- `GTA_DFF_IO.ms` → `DFFimp.ms`, `DFFexp.ms`, `gtaIFPio_Fn.ms`
- `GTA_Map_IO.ms` → `DFFimp.ms`, `gtaMapIO_Fn.ms`, `emt_startup.ms`
- `GTA_COL_IO.ms` → Collision import/export (standalone)
- `GTA_2DFX_IO.ms` → `ui_2dfx.ms` (2DFX effects editor)

**Startup**:
- `scripts/startup/GTAScript_Controller.ms` - Adds "GTA Tools" menu on Max launch
- Uses `macroScript` to define menu items that call `fileIn` on tools

**Settings Persistence**:
- Stored in: `scriptsPath + "GTA_Tools_2026\\settings.ini"`
- Sections: `[Import_Shared]`, `[Character_Import]`, etc.
- Keys: `mattype`, `textype`, `scale`

## Contact & Workflow
- Repository: ejp2001/kams-goldfish-bowl
- Branch: main
- Always verify changes in-game before committing
- Rollback via git if exports cause crashes
- Use full paths in commit messages (e.g., `modding resources/kams original mse files decrypted/CharDFFexp.ms`)

## Contribution History
- **2005**: Kam's original scripts - Character animations (IFP_IO_GTA.ms), DFF/COL import/export, seamless character export
- **2018**: Goldfish Edition - Vertex remapping changes (RemapByUV1/UV2, detachBySmGr), general tool enhancements, broke character export
- **December 2024 - January 2026 (E2001)**: 
  - UV animation import/export implementation (December 2024)
  - World object IFP animation export/import (January 2026)
  - Tool separation with validation (Character/Vehicle/Scenery IO)
  - 2dfx UI cleanup
  - Integration of 2005 character export for seamless skinning

---
*Last Updated: February 2, 2026*  
*Based on: Kam's GTA Scripts v1.0 (2005) + 2018 Goldfish Edition enhancements + E2001 improvements + UndefinifiedGrove source code analysis*
