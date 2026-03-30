# Public Beta 1 Checklist

This checklist tracks readiness for the first official external test release.

## Release Name

- Public Beta 1 (PB1)

## Release Scope

- Character workflow stability
- World-object workflow stability
- IFP import/export reliability
- UV animation import/export reliability
- Installation and startup reliability

## Core Validation Gates

- [ ] Clean install test on 3ds Max 2017 (`scripts` folder copy only)
- [ ] GTA Tools menu appears and all main entries open without startup errors
- [ ] Character import/export path works end-to-end in-game
- [ ] World-object import/export path works end-to-end in-game
- [ ] Character IFP import/apply/export works on known-good rigs
- [ ] World-object IFP import/export works with hierarchy-name matching
- [ ] UV animation export writes expected DFF structures and works in-game
- [ ] UV animation import reconstructs timeline behavior acceptably
- [ ] Collision/2DFX paths open and execute without hard errors

## Regression Targets (Must Re-check)

- [ ] No character skin seams from world remap path contamination
- [ ] No false "No active GTA rig found" in normal IFP_IO use
- [ ] AnimBake setup + bake path works with relative ini paths
- [ ] No missing dependent script loads from startup menu

## Packaging

- [ ] README reflects PB1 status and current installation steps
- [ ] MODIFICATIONS_SUMMARY includes PB1 milestone note
- [ ] Public docs avoid internal AI-only process notes
- [ ] Internal instruction docs remain in `.github/` only

## Known Open Items Allowed In PB1

- Character clump restoration still open
- Vehicle-specific animation behavior still partly exploratory
- UV animation edge cases may still require manual tuning

## Exit Criteria For Next Milestone

- All core validation gates pass on at least one clean environment
- No critical in-game crash regressions in character/world test assets
- Known limitations documented with clear user-facing wording
