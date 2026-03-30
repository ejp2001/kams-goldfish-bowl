# kams-goldfish-bowl

This repo is an attempt to explore all possible fixes, improvements, and additions to *Kam's GTA Scripts for 3DS Max: 2005 original version*, *Kam's 2018 Goldfish Edition*, and *any-and-all other available MaxScript resources worth considering*. You will not find links to any of these resources in this repo. Locating them on the Internet is your problem. However; I will refer to any third-party tools whenever I think it appropriate.

My primary focus is on GTA San Andreas compatibility; although, I make every attempt to preserve whatever GTAIII and Vice City functionality already exists.

This project makes extensive use of AI models. 


## This repo contains:

* A full decrypted and unmodified archive of Kam's original .mse scripts (modding tools folder).
	
* The project itself (scripts folder).
	
* MODIFICATIONS_SUMMARY.md: AI maintained project record (a proper changelog may appear at some point).

	
Installation and usage:

* Download the repo.
	
* Copy the entire contents of the scripts folder to your "3DS_MAX_INSTALLATION/scripts" folder.
	
* Try not to hurt yourself.


## What's fixed:

* Character Export Producing Visible Seams In Goldfish's 2018 Edition: Restored the original mesh export method for character models only. WHY:
		* Character export (skinned models) requires vertex-based remapping (RemapByVT) to preserve vertex welding for smooth skin deformation.
		* World object export uses UV-based remapping (RemapByUV1/UV2), which splits vertices at UV seams for correct texture mapping, but this breaks skin welding and causes visible seams on characters.
		
For practical considerations, I opted to completely remove skinned character handling from the GTA_DFF_IO.ms. This has the affect of rendering GTA_DFF_IO.ms no longer useful for importing characters with skin modifiers; although you are still able to I/O the models themselves. Automatic handling of character vs. world object formats is planned for future releases.
	
* The Notorious IFP EOF (End Of File) Bug: If you don't know what I'm talking about, you're not alone! Even the AI has trouble keeping the facts straight on this one. *To the best of my knowledge* this bug has persisted up to the creation of yelmi's IFP-ANPK-TOOL (co-author: DENISka) - an adaptation of Kam's IFP_IO tool (feel free to correct me if I'm wrong). This bug adds "junk" data to the file whenever animations are edited, resulting in: ghosted animations (still identified internally, but not in header); animations not loading; "random crashes"; eventual file corruption.
	
* General Housekeeping: Moved a bunch of stuff around to make room for future enhancements (Character handling already mentioned).


## What's Added:
	
* Anim Bake (Biped to Ped):   Bake any animation that can be run on 3ds Max biped to the selected GTA Character. Save animation using IFP_IO. First release - rather clumbsy - expect bugs.

* Added File Management Capabilities To The IFP_IO:   No more need for external tools! Fixes EOF bug introduced by previous versions. Utility to repair corrupt IFP files, if they are still able to be read (can regress back to last good anim in file - does not recover corrupt animations). Supports multiple characters / animations in scene. Select target rig by mesh (may be buggy).

* UV Animation Export:   The DFF IO will automatically export any texture animations it finds on the timeline. Supports multiple animations per-object - all animations must be equal duration to avoid skipping. 

* UV Animation Import:  Animations in dff files will be automatically detected in dff file and will be added to the 3DS Max timelime on import. Timing errors may develop after multiple I/O operations.
	
* UV Animation Editor:  Creates sprite sheet animations. Only slightly modified version of TVanimHelper from SA_TOOLS. Users familiar with SA_TOOLS will need no introduction. Original help files can be found in Help folder (this repo).
	
* World Object Animation Import (IFP):  Select the root dummy of any dummy hierarchy and import an IFP Animation file. If an animation matching the dummy hierarchy exists in the IFP file it will be added to the timeline.

* World Object Animation Export (IFP): *Not to be confused with Character IFP animations.* Working code evolved from MAP_ANIM_EXPORT, SA_TOOLS plugin. Select the root dummy of any dummy hierarchy with a timeline animation, and click any of the IFP Exporter buttons. A file dialog will open. Choose a filename and save. The animation is now ready for use in game.

* Bug Fixes; Script Enhancements; Error Checking (the usual stuff).
	
* Documentation (WIP).


## What's NOT fixed: 

* Clumps: **Recent discovery:** The GTA wiki ([RpClump](https://gtamods.com/wiki/RpClump)) definition is misleading for practical modding. My original intuition was correct: clump handling (the section managing body type containers in DFFs) belongs in the Character_IO, not DFF_IO. The wiki describes clumps as *"a Struct, a Frame List, a Geometry List, a number of Atomics, optionally a number of Structs and Lights and a number of Structs and Cameras"*, but this does not reflect how clumps are actually used for character body types (Normal, Fat, Ripped) in GTA. 

**Action item:** Clump handling is currently missing from Character DFF_IO and its related files. The function will need to be fully recreated using Kam's original version as reference, then moved to Character_IO. This is now a priority for future development.

*Note: The broken clump logic in the 2018 edition (and related files) may explain the lack of full player/clothing mods. Restoring correct clump handling from Kam's original is now a top priority to avoid future confusion.*


## What was intentionally removed:

* Character Import/Export via DFF_IO.

* Minor functions/utilities wherein acceptable native 3ds Max alternatives exist.

* Compatibility with earlier versions of Kams GTA Scripts.



** Many thanks to AI for making all of my dreams of not having to learn to do this myself FINALLY come true!


