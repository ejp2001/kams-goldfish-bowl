Example "RUNNING SMOKE" using max script UV anim helper  and  UV anim export


1. Drawing "comics" texture (pic 0)

2. Have screen model. We have set UV coords for animated texture like this (pic 1). Export DFF

3. Run script TV anim helper. Set U count and V count. (pic 2à) in my case its 4 and 6 frames...
   after that SELECT MATERIAL and choose material with texture for animation...(pic 2á)

4. Command line. By default "1..<Number of frames in texture>, time = 1.0"
   its mean - frames from 1 to <Number of frames in texture> will be played in 1 sec.

5. OK, press GO.. It creates animation for texture

6. Now run script UV anim export.. select material with just animated texture.
   Select DFF created in (2)... In dropdown list choose texture will be animated..
   (in my case its running_smoke) (pic 3, 4)
   OK, press Append animation... DFF will save in same path with name "temp_<DFF name>.dff"


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
You can control you animation by command line (CL), for example

  24..1,1..5,time=3 ; time=2; 1,2,4,6..24,time = 1.5

As you see CL contains blocks, broken by ";".. in example :
1 block - frames from 24 ïto 1 and from 1 to 5 will be played at 3 sec
2 block - pause 2 sec (!!! dont use 1st block for pause)
3 block - i think its clear

You can use any blocks in CL.