 
 :::::::::::::: KAM's GTA Scripts (2018) ::::::::::::::
--------------------------------------------------------------------------------------
modified by Goldfish  
---------------------------------------------------------------------------------------
https://vk.com/topic-99725313_37821803

Updated and improved version of KAM's skipts.
Based on the original Kam's scripts.
This script was tested in 3ds max 2009 and 2012 and 2017.

Complete with the script there is a fixed and updated GTA Material


Download the latest version of the script
https://yadi.sk/d/DQMt4tMM3TTV5e
or
https://drive.google.com/drive/folders/1hjKlZzNjxilEBfDGrSIN2iJF-1xSwVxU?usp=sharing


Changes and updates:


>>>>>>>>>>>>>> [DFF IO] <<<<<<<<<<<<<<<


What was added:
  (17.05.2020)
- checkbox 'Mesh Fix', necessary if polygons are mixed after exporting the model

  (20.11.2019)
 - material selection when importing DFF (GTAMat or Standart)
 
  (28.10.2019)
  - choice of material before you import the DFF (GTAMat or standard)
  
  (17.03.2018)
 - mass import and export DFF's
 - import / export Night prelite
 - import / export Vertex Alpha
 - import / export UV2 channel
 - import / export 2dfx (only light sources)
 - optional interface for configuring 2dfx
 - additional locking dff (new)


  (23.03.2018)
 - import / export Bump maps
 - import / export Dual maps
 - import / export Normal Map and Reflection (Adaptation for Normal map Plugin from DK)
 - auto-save the interface settings DFF IO after each change


What's been fixed:
  (31.05.2020)
 - saving settings in the DFF IO script interface
 
  (17.05.2020)
 - 2DFX setup interface
 - export of materials
 - minor fixes and updates to the script code
 
  (20.11.2019)
 - import of multiclamp models (with clump UV Anim section)
 - other minor code fixes and improvements
 
  (28.10.2019)
 - import 2dfx (fixed a critical bug)
 - import map IO texture extension 
 - UPDATED map IO script and improved its compatibility with the latest version of the DFF importer
 - updated script interface
 - other minor code fixes and improvements

   (01.09.2019)
 - MAP IO
 
   (17.03.2018)
 - exporting a hierarchy of models
 - export of normals
 - import of color from light sources 2dfx

   (23.03.2018)
 - export models of characters
 - importing a model hierarchy
 - general script code repair


Additionally:
  (31.05.2020)
 - additional tools have been added to the GTA Tools menu (for a list of all available tools in the KAM script, click here https://vk.com/page-99725313_54168827 )
 
  (17.05.2020)
 - added the script 'Vehicle Scale Helper' in the GTA Tools menu (script for changing the scale of transport)
 - Added a script 'Object Explode' in the GTA Tools menu (script for dividing the landscape into even parts)
 
  (20.11.2019)
 - added checking the dimensions of the model before exporting to the script of mass export of collisions in CST(export_steve_col_script.ms)
 
 - added more warnings and tips when exporting
 - added export log ( F11 listener)
 - updated and improved script interface
 - added optional UV2 coordinate compression
 - added additional tools to work with the model
 - added progress-bar and fixed script freezes
 - added default settings for exporting prelite
 - added menu GTA tools scripts in the top menu bar 3ds max


Additional utilities:

 - Prelit Tools
         the script for mass configuration prelite

 - Fix models pivot
         script for mass alignment of the pivot position of the model to integer coordinates before exporting the mapping

 - Align pivot to center
         script for mass equalization of pivot in the center

 - Col Export (mass)
         script for mass export of col (cst)

		 
>>>>>>>>>>>>>> [Map IO] <<<<<<<<<<<<<<<

What was added:
  (20.11.2019)
 - added mass IPL import
 - added import of map models with any (custom) texture extension
 - added the ability to select model material when importing
 - added binary ipl import (when importing, you must specify the path to gta.dat of your mod / game)
 - added the ability to select IPL sections for import (you need to put a checkmark in front of the desired section)
 - added the ability to fake map import (instead of map models, planes will be created)
 - added button to launch EMAPTool script of the ice version, designed for easy export of map mapping to IPL / IDE
 - added a detailed log when importing a map
 - added progress bar when importing map
 - added statistics of loaded map mapping
 - the script code has been improved, now it is more likely that the script will not crash due to an error, but will issue warnings in the log (F11) and continue its work
 - added more warnings and tips to help identify most of the errors on the part of the user
 - EMAPTool officially became part of the KAM script and is located in the '/ scripts / GTA_Tools (GF) /' folder (it is recommended to check for an update of this script in the VK office of the script author group)
 

 What's been fixed:
   (17.05.2020)
  - [EMAPTool] added more decimal places to model coordinates when exporting to IPL
  
   (10.12.2019)
 - fix and update EMAPTool
 
   (20.11.2019)
 - improved and redesigned script interface
 - improved and revised map import code
 - fixed import of multi-clamp models (with clump UV Anim section)
 - fixed the problem when import was stopped due to incorrect IPL / mapping
 - IPL import with comments has been fixed (all comments in Cyrillic should be at the beginning of the file BEFORE the INST section!)


[COL IO]  - not changed
[IFP IO]  - not changed


Authors

============

- 19.12.05 -
Kam, Odie, Pioneer

Official post on the forum: http://gtaforums.com/topic/218318-rel-kams-maxscript-going-over-quick-update/



-17.03.2018 -

Goldfish - Goldfish-1994@yandex.ru

Updating the script: 31.05.2020 (v 0.3.7)

For questions and suggestions, write here (support): https://vk.com/topic-99725313_37821803


