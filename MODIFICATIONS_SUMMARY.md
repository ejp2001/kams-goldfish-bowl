# Modifications Summary - GTA Tools 2026

This document tracks major project-level modifications and milestones for the active toolset.

## Scope

- Active codebase: scripts/GTA_Tools_2026
- Baselines: Kam 2005 originals + 2018 Goldfish edition
- Focus: GTA San Andreas compatibility with preserved legacy support where practical

## Sources And Integration Model

- Kam original 2005 logic is preserved for character-critical paths.
- Goldfish 2018 logic is preserved for world-object workflows and modernized UI/tooling.
- Community scripts are integrated selectively when they improve practical workflows.

## Chronological Changelog

## December 2024

### UV Animation System (Major)

- Added full UV animation export support in DFF pipeline:
  - UV Animation Dictionary chunk writing
  - Material Animation PLG linkage
  - UV Anim PLG runtime flags
- Added UV animation import support:
  - dictionary parsing
  - keyframe reconstruction in Max
  - practical handling for scrolling and sprite-like patterns
- Added keyframe optimization path to reduce redundant imported keys.

### 2DFX UI And Import Cleanup

- Reworked 2DFX UI to remove dead/unused controls and improve clarity.
- Consolidated practical effect workflows (lights, particles, ped attractors).
- Extended import handling for non-light effect types with better parameter retention.

### Transparency And Editing Workflow

- Converted/maintained decrypted .ms sources for maintainability and debugging transparency.

## January 2026

### World Object IFP Workflow In Main DFF UI (Major)

- Added world-object animation import/export controls directly into GTA_DFF_IO.
- Added hierarchy-based export path and append-to-existing IFP workflow.
- Improved multi-animation handling behavior for import and matching.

### Character/World Animation Separation (Architecture)

- Separated animation function files per consumer to prevent logic cross-contamination:
  - gtaCharIFPio_Fn.ms for character workflows
  - gtaDFFIFPio_Fn.ms for world-object workflows

### Character Pipeline Stability

- Reinforced character-safe behavior around BoneID-centric matching and skeleton-preserving import assumptions.
- Kept character export aligned with 2005-compatible logic where required.

## March 2026

### AnimBake Workflow (Major)

- Added/refined dedicated motion-capture-to-GTA bake workflow in GTA_AnimBake.ms:
  - Setup rig stage
  - Source animation load stage
  - Bake stage to BoneID-driven GTA hierarchy
- Added canonical mapping/critical-bone validation behavior for safer bake runs.

### AnimBake Configuration Normalization

- Standardized GTA_AnimBake.ini to two-path config entries:
  - FigureFile
  - CharacterDFF
- Added runtime path resolution while preserving relative-path persistence in config.

### New Rig Analysis Utilities

- Added GTA_Skeleton_Dump.ms for scene hierarchy/BoneID diagnostics.
- Added GTA_BipGTA_BuildSpec.ms for documenting and reusing BipGTA target rig build policy.

### IFP_IO Active Rig Detection Hardening

- Improved active rig root resolution in GTA_IFP_IO when multiple candidate roots exist.
- Selection handling now evaluates all selected nodes before fallback logic.
- Added stronger root-picking heuristics for BoneID-rooted scenes.

### Release Milestone Start

- Project officially marked as **Public Beta 1 (PB1)**.
- Focus shifted from broad feature expansion to stability, regression checks, and in-game validation pass coverage.
- Practical PB1 gate tracking lives in [PUBLIC_BETA_1_CHECKLIST.md](PUBLIC_BETA_1_CHECKLIST.md).

## Current Architecture Rules (Operational)

- Character export/import and world-object export/import remain intentionally separated.
- Character workflows must preserve Skin/BoneID-safe behavior.
- World-object workflows can use UV-splitting/remap paths that are unsafe for skinned characters.

## Known High-Priority Open Work

- Character clump handling restoration remains open and high priority.
- Any exporter behavior change still requires in-game validation before considered complete.

## Validation Policy

For export-impacting changes, expected validation sequence remains:

1. Export from 3ds Max
2. Load in GTA SA
3. Check visual correctness
4. Check animation/deformation behavior
5. Confirm no crash/corruption regressions

## Document Status

- Last refreshed: March 30, 2026
- Intent: concise project changelog and architecture summary
