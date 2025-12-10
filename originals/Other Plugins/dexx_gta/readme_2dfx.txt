SA Effects c0.2e
This script currently allows the creation, and export of the following data types to be used with San Andreas (and ONLY san andreas!):

Lighting Effects
Particle systems

How to create lighting effects:
1. Lighting effects can be placed on any type of Light objects (it does have to be a light though, not a dummy, or bone or any other type of object). I recommend using Omni lights, as that is the only type of light gta uses, that we can create more of. The spotlights used for vehicle headlights, and the directional light used for the sunlight, cannot be recreated externally.

2. Create an omni light, or if you already have one in your scene, proceed to the next step.

3. Link the light to the building it will be attached to. The light has to be linked to its parent object (building), because that is how the coordinate systems for lights in gta work. The coordinates for each light, are relative to their parent object.

4. To do this, press the "Select and Link" button, then left click on the light where the mouse cursor should change into 2 overlapping squares. While still holding down the left mouse button, drag the cursor over to the building geometry, wher it should draw a line between the child (light) and parent (builing) objects. let go of the button when you the cursor turns back into the "2 squares", over the parent object.

5. Now that the light is in position, and selected (select it if it's not) and linked properly, go to the "SA Effects" rollout, and expand "Setup / Add Effects" if it is not already expanded.

Click "Add Light Info" to add SA light information to this light.

once you have added the light info, go to the modify panel, of that light, and take note of the extra set of data added near the bottom of the rollout.

These are the paramters for how the light will look ingame. Although it is possible to change these parameters directly on the modify panel, it is not recommended. They should be changed via the "Setup / Edit Lights" panel, in the Sa Effects rollout. Lets open that panel.

From this panel, you can control every attribute of the light (or selection of lights, if you have more than one selected). The options should be self explanatory to the experienced gta modder. Generally speaking, you'll want to set the light type to either "mlampost" or "lampost_coast", as they are on only a tnight, and don't blink. The other light types are specialsized, and not as thoroughly tested. Press "Apply to Light9s) when you are finished setting the attributes. Light color is dervied right from the normal 3dsmax interface, nothing special.

That pretty much covers the basics of adding a light.

How to create a particle system:
A note on particles: Most of them do not play, or show up just by adding the data to the dff (some do, just not many). So if you don't see your particle system ingame, i do not have an answer yet.

Follow steps 1 to 5 for a light, but instead of creating a light, create a "Dummy" object.

Now choose "Add particle Info", with the dummy object selected.

Note the attribute on the object in the modify panel is just a string, and can be edited directly, but again, is not recommended.

Expand the "Setup / Edit Particles" panel, on the SA Effects Rollout.

Note the dropdown list contains all the possible particle systems. Choose one, and hit "Apply to Dummy(s)".

Done.

Exporting the data to a DFF model, using RWAnalyze:
First, you'll need to have exported your model already, so do that if you haven't yet.
Next, you'll need Steve M's Renderware Analyze (RWA), and you can download that here:

http://www.steve-m.com/?lang=EN&page=2&ID=21&act=details

Now install RWA.

Now, back in Max, select all the effect data you want to export (lights, particles, etc), and go to the "Export Effect info" panel on the sA Effects rollout. There's only one button, go ahead and click it. 
Save the .sae file where you want, and name it whatver you want, just be sure to remember where it is and what you called it.

Now open your dff file with rwa.

Go to the very top, where it says "Clump", right click, and choose "Collapse child sections"
Now, double click that same "Clump" section, and it should open just the main sections of the file.
Select the bottom "Geometry List" and expand it.
Within the expanded selection, expand the "Geometry" section
Within the geometry section, expand the "Extension" if possible
Now, right click on the "Extension" you just expanded, and choose "Add Section"
In the list that appears, scroll to the bottom, and choose section type "0x253F2F8", and press ok
You just created a new section of data, of type "0x253F2F8". Select it, and right click
choose "Import Section Data"
In the file browse dialog that comes up, find the .sae file you exported earlier, and import it.
Thats it, your done. save the dff without making any other changes. Import your dff to the game, and enjoy the new effects