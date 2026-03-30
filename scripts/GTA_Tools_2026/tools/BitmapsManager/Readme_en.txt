Max Script


Bitmaps Manager 1.0
====================================================


Compatibility: 3ds Max 2009 and higher (possibly older versions as well)

Author: Goldfish
Contact:
Goldfish-1994@yandex.ru
https://vk.com/vk.goldfish



Description:
----------------------------------------------------
This script allows you to collect all textures associated with your models into a single, selected directory.
During the texture collection process, a separate subdirectory will be created for each model, named to match the model's own name.
The script also includes an option to output text-based information regarding the textures to the Listener window (the Listener is launched by default using F11).
Additionally, this window will display important information regarding the results of the texture copying operation, reporting any errors encountered or confirming the successful completion of the task. 


Installation:
----------------------------------------------------
Place the script in any folder—for example, in ../3dmax_folder/Scripts/.
Launch the script either via the 3ds Max program menu or by dragging and dropping the script file directly into the 3ds Max viewport.


Usage:
----------------------------------------------------
Select the models you wish to process.
To output information about the textures associated with the selected models to the Listener window, click the "Print" button located within the "Print list bitmaps" section.

To collect all textures from the selected models, first specify a destination directory in the input field within the "Copy to path" section. The "to path" button will open a file explorer window, allowing you to select your desired directory.
Next, click the "Copy bitmaps to path!" button and wait for the script to finish executing. The script's execution time depends directly on the number of models and their textures.



Description of messages in the listener log:
----------------------------------------------------

The message structure when displaying textual information about a model's textures is as follows:

Model Name
----------------------------------
bitmaps:
- list of textures...
MISSING bitmaps:
- list of textures...

Under the "bitmaps:" heading, you will find a list of the textures found for the model.
Under the "MISSING bitmaps:" heading, you will find a list of textures that were not found (i.e., their file paths are invalid); typically, textures do not display on such models.
(!) Note: Some information may not be displayed within these blocks. 
- - -

The message structure when copying a model's textures is as follows:
Model Name
----------------------------------
bitmaps NOT FOUND:
- list of textures...

log: error copying bitmaps to: c:\some_folder\texture.png (maybe the bitmap already exists)
- done

Under the "bitmaps NOT FOUND:" heading, you will find a list of textures that were not found (i.e., their file paths are invalid).
The lines reading "log: error copying bitmaps to:..." display the specific paths where the script failed to copy a texture—possibly because that texture already exists at the specified location.
(!) Note: Some information may not be displayed within these blocks.




All script updates will be available on Yandex.Disk at the following link: https://yadi.sk/d/Z3PxzL663Lrojf

Thank you for using the script!