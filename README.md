# kams-goldfish-bowl

This repo is an attempt to explore all possible fixes, improvements, and additions to *Kam's GTA Scripts for 3DS Max: 2005 original version*, *Kam's 2018 Goldfish Edition*, and *any-and-all other available MaxScript resources worth considering*. You will not find links to any of these resources in this repo. Locating them on the Internet is your problem. However; I will refer to any third-party tools whenever I think it appropriate.

My primary focus is on GTA San Andreas compatibility; although, every attempt is being made to preserve whatever GTAIII and Vice City functionality exists. I do not guarantee their continued functionality, as I have moved on from modding them (not that I ever really did).

This project makes extensive use of AI models. Most of what exists at present was created with the help of Claude Sonnet 4.5. I couldn't have done it without him! This is certain to prove an endlessly-evolving project guided primarily by AI capability and/or availability, so *expect errors.* I will attempt to address them as best I can.


## This repo contains:

* A full decrypted and unmodified archive of Kam's original .mse scripts (modding tools folder).
	
* The project itself (scripts folder).
	
* MODIFICATIONS_SUMMARY.md: AI maintained project record (a proper changelog may appear at some point).

	
Installation and usage:

* Download the repo (I assume that if you made it this far you already know the process).
	
* Copy the entire contents of the scripts folder to your "3DS_MAX_INSTALLATION/scripts" folder.
	
* Try not to hurt yourself.


## Practical Asset-Type Rules

These tools deal with file formats that look shared on paper, but behave differently in practice. The safest way to think about them is by asset type, not by extension alone.

### Character vs. Scenery vs. Vehicle

* Character, Scenery, and Vehicle assets should be treated as three separate workflows, even when they use the same `.dff` or `.ifp` container formats.

* Character models have separate export/import requirements from scenery and vehicles. If a model uses Skin, BoneID-driven character logic, or character-style hierarchy/animation handling, use Character IO.

* Scenery and Vehicle models currently share the DFF IO interface, but that does **not** mean they follow identical rules internally.

### Materials

* GTA Materials are mainly useful for Vehicles. They can be used on Characters or Scenery, but they tend to look worse in the viewport and are not reliable for everyday authoring there.

* If simplifying the toolset, GTA Materials should be considered Vehicle-editor features first.

### UV Animations

* UV animations belong primarily to the Scenery workflow.

* Vehicles may also be able to use UV animation in some cases, but that loading path is not yet well understood or documented. Treat vehicle UV animation as experimental until proven otherwise.

### Vehicle Animation Assumptions

* Vehicle animations are not yet fully mapped out in this project.

* The current working assumption is that vehicle animations are more likely to be object/hierarchy-driven than character-style IFP behavior, especially for engine parts synchronized to RPM.

* Vehicle-specific animation behavior may involve data embedded in the DFF itself, not just external IFP files.

### Embedded Collision And Shadow Data

* Embedded collision and shadow data inside a DFF is a Vehicle-only concept for GTA San Andreas.

* Vehicles are also the only asset class where collision and shadow meshes are stored in the `.dff` itself. Attempting to put embedded vehicle-style collision/shadow data in Character or Scenery DFFs can crash the game.

* Shadow Meshes are normally stored inside collision data (`.col`), not as a separate generic DFF feature.

* For vehicle export, the collision source may be either:
	* a `.col` file, or
	* a vehicle `.dff` that already contains the appended collision payload.

* If using a `.col` file as the vehicle collision source, it must contain exactly one collision model and one shadow mesh, plus however many spheres and boxes belong to that model.

* Multi-model `.col` archives are not valid as a vehicle embedded-collision source.

### IFP Archive Editing

* IFP files behave more like small animation archives than single animation files. Editing them carelessly can create corruption that is not obvious until later.

* The well-known SA IFP "EOF bug" is usually not a true end-of-file bug. It is typically caused by appending new animation data at the physical end of the file instead of the logical animation-data end stored in the header.

* For ANP3/SA IFPs, the logical append point is `fileLength + 8`, using the header's stored file length.

* If an appended animation seems to exist in the bytes but does not appear in the file properly, verify:
	* the logical file length was rewritten correctly, and
	* the animation count was updated at the correct ANP3 header offset.
	

## What's fixed:

* Character Export Producing Visible Seams In Goldfish's 2018 Edition: Restored the original mesh export method for character models only. WHY:
		* Character export (skinned models) requires vertex-based remapping (RemapByVT) to preserve vertex welding for smooth skin deformation.
		* World object export uses UV-based remapping (RemapByUV1/UV2), which splits vertices at UV seams for correct texture mapping, but this breaks skin welding and causes visible seams on characters.
		
For practical considerations, I opted to completely remove skinned character handling from the GTA_DFF_IO.ms. This has the affect of rendering GTA_DFF_IO.ms no longer useful for importing characters with skin modifiers; although you are still able to I/O the models themselves. Automatic handling of character vs. world object formats is planned for future releases.
	
* The Notorious IFP EOF (End Of File) Bug: If you don't know what I'm talking about, you're not alone! Even the AI has trouble keeping the facts straight on this one. *To the best of my knowledge* this bug has persisted up to the creation of yelmi's IFP-ANPK-TOOL (co-author: DENISka) - an adaptation of Kam's IFP_IO tool (feel free to correct me if I'm wrong). This bug adds "junk" data to the file whenever animations are edited, resulting in: ghosted animations (still identified internally, but not in header); animations not loading; "random crashes"; eventual file corruption.
	
* General Housekeeping: Moved a bunch of stuff around to make room for future enhancements (Character handling already mentioned).


## What's Added:

* Added File Management Capabilities To The IFP_IO, And Repurposed It As The Main Character IO Interface: No more external tools!

* UV Animation Export: The DFF IO will automatically export any texture animations it finds on the timeline. *Note: Timeline must be scaled to match animation before export.*  Works with multiple animations - must be the same duration to avoid skipping. 

* UV Animation Import: Animations in dff files will be automatically detected in dff file and will be added to the 3DS Max timelime on import. *Timing errors may occur if original settings are mis-matched, or after multiple I/O operations. 
	
* UV Animation Editor (WIP): Creates sprite sheet animations. Currently this usues TVanimHelper from the sa_tools scripts as its codebase. Users familiar with sa_tools plugin should need no explanation. Output is identical. As always, *Expect Bugs.*
	
* World Object Animation Import (IFP). Select the root dummy of any dummy hierarchy and import an IFP Animation file. If an animation matching the dummy hierarchy exists in the IFP file it will be added to the timeline.

* World Object Animation Export (IFP). *Not to be confused with NPC (character) IFP animations. Based on code from anim_export: sa_tools plugin. Select the root dummy of any dummy hierarchy with a timeline animation, and click any of the IFP Exporter buttons. A file dialog will open. Choose a filename and save. The animation is now ready for use in game.
	
* Bug Fixes; Script Enhancements; Error Checking (the usual stuff).
	
* Documentation (where needeed).


## What's NOT fixed: 

* Clumps: **Recent discovery:** The GTA wiki ([RpClump](https://gtamods.com/wiki/RpClump)) definition is misleading for practical modding. My original intuition was correct: clump handling (the section managing body type containers in DFFs) belongs in the Character_IO, not DFF_IO. The wiki describes clumps as *"a Struct, a Frame List, a Geometry List, a number of Atomics, optionally a number of Structs and Lights and a number of Structs and Cameras"*, but this does not reflect how clumps are actually used for character body types (Normal, Fat, Ripped) in GTA. 

**Action item:** Clump handling is currently missing from Character DFF_IO and its related files. The function will need to be fully recreated using Kam's original version as reference, then moved to Character_IO. This is now a priority for future development.

*Note: The broken clump logic in the 2018 edition (and related files) may explain the lack of full player/clothing mods. Restoring correct clump handling from Kam's original is now a top priority to avoid future confusion.*


## What was intentionally removed:

* Character Import/Export via DFF_IO.

* Compatibility with earlier versions of Kams GTA Scripts.
