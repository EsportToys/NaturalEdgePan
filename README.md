# NaturalEdgePan

A modern, displacement-based edge-panning instead of the legacy velocity-based behavior of 90's RTS games. 

[Download demo here.](https://github.com/EsportToys/NaturalEdgePan/releases)

https://user-images.githubusercontent.com/98432183/235227114-13128d48-fe16-4c28-af13-93ed578ad0f6.mp4


> <img src="https://upload.wikimedia.org/wikipedia/commons/6/61/The_Operations_Room_at_RAF_Fighter_Command%27s_No._10_Group_Headquarters%2C_Rudloe_Manor_%28RAF_Box%29%2C_Wiltshire%2C_showing_WAAF_plotters_and_duty_officers_at_work%2C_1943._CH11887.jpg" width="45%" />
> <img src="https://user-images.githubusercontent.com/98432183/235441910-5175e743-cd09-428b-a943-1b9abb30ca75.png" width="45%" />



## What's wrong with current systems

The way top-down camera moves at a preset rate when the cursor touches the screen/window edge is a legacy UX largely unchanged from 90's real-time-strategy games.

While some games provide menu options to adjust the panning speed/curve, it takes a lot of fiddling to find an acceptable compromise between being too slow for large displacements and too fast for fine adjustments.

This has resulted in players usually being recommended to exclusively use the minimap and hotkeys for large movements and middle-click drag scroll for small adjustments, leaving edge-panning in an awkward position being unsuited to either tasks.

Basic UX common sense tells us that frequently performed tasks should have little cognitive friction, while strongly effectful actions should require conscious intent to activate. 

Both minimap clicking and middle-click drag require a conscious action that interrupt unit control (the former needing to visually confirm where you're clicking, the latter requiring a button to activate), whereas simply moving your cursor against the edge is practically no different than generally manipulating your mouse. Yet the effectful auto-panning is assigned to the easy-to-accidentally-trigger edge, while performing the frequently needed stateful adjustment require you to interrupt your current task to click an obscure button.

This inversion of frequency-of-action vs friction-against-activation leads to unnecessary cognitive burden in the skill acquisition process -- instead of skill-differentiation via expressivity, this is just learning-segregation via clunckiness.

A frequent source of derision towards novice players of competitive RTS/MOBA games is the tendency to leave a wide space in front of the player character towards the direction of retreat, where there is little danger and such a large field of vision is unnecessary, while completely obscuring the enemy direction where the vision is most needed for the reaction margin to dodge incoming attacks:

> ###### Figure 1: poor camera positioning preventing a retreating player from seeing an otherwise evadable attack (until it is too late to react)
> ![image](https://user-images.githubusercontent.com/98432183/235234325-0ca258af-5085-4b7d-95f4-6361ed218508.png)

This behaviour is the result of the player wanting to avoid accidentally touching the window edge, which causes the camera to continuously move away in that direction.

The optimal camera positioning of leaving maximal vision on the trail of your character require much more deliberate placement of the cursor to not accidentally trigger edge-motion. 

This is why you see veteran players developing a habit of [clicking close to their controlled characters](https://youtu.be/9rTX4x7e9LE&t=378s) to maintain reactivity over direction changes -- playing the game has a pre-requisite of possessing proprioceptive control over the cursor without relying on visual confirmation.

Players who did not acquire the dexterity for cursor or camera control typically resort to the "locked camera" mode where the game automatically centers the camera on the controlled character at all times, and only occassionally unlocking it when needing to examine other parts of the game map for awareness.

This approach has a drawback of turning the act of _pointing_ (to a static target) into a task of _aiming_ (at a target that now continuously shifts with your viewpoint). Those who have the dexterity to be able to _track_ with their cursor are the ones who did not require assistance with the camera in the first place, while those who needed such help now has to deal with the even higher dexterity requirement of a constantly moving target.

## The idea

Pointing the cursor is natural, it has the least cognitive overhead (not requiring any additional conscious action, being almost directly wired to your subconscious control) and therefore should be the most frequent interaction.

Instead of having the camera be constant velocity motion, simply shift it based on how much your cursor pushed against it.

This effectively extend the total "mouseable area" from just the game window to the entire game map. In other words. your hands addresses the whole canvas, and the game window is simply the "foveal vision" of your eyes.

> ###### Figure 2: this way of edge panning basically works like war-room table stick-thingies
> <img src="https://upload.wikimedia.org/wikipedia/commons/6/61/The_Operations_Room_at_RAF_Fighter_Command%27s_No._10_Group_Headquarters%2C_Rudloe_Manor_%28RAF_Box%29%2C_Wiltshire%2C_showing_WAAF_plotters_and_duty_officers_at_work%2C_1943._CH11887.jpg" width="45%" />
> <img src="https://user-images.githubusercontent.com/98432183/235441910-5175e743-cd09-428b-a943-1b9abb30ca75.png" width="45%" />

I think the reason why no games had done this before is because the operating system do not generally report cursor motion that are clipped against a clipping zone. 

So to implement this, developers would need to use APIs that report raw device data, which has no awareness of the relative cursor position.

**However, Windows does provide you with a way to retrieve the exact cursor position at the time the event was posted**, but it seems that game frameworks such as SDL generally ignore it and prefer to set their own "coordinate mode" vs "relative mode" abstraction that feeds only either cursor-based or device-based messages but never both.

## This demo

This is a quick-and-dirty demo written in AutoIt to demonstrate a proof-of-concept of the solution described above.

If you already have AutoIt download on your system, just download and open `demo.txt` with it.

Or you can download and extract [the zipped release](https://github.com/EsportToys/NaturalEdgePan/releases), simply double-click `RunDemo.vbs` to run.

As this is a janky demo implemented via a moving background image, I set a pretty tiny game window and proportionally lowers the Windows Pointer Speed temporarily upon launch so that it feels close enough to playing a normal game (if you move your face closer towards your display).

## How to implement in your game (Windows)

0. Assuming that the cursor is clipped to the game window...
1. Subscribe to `WM_INPUT` events
2. On every `WM_INPUT` message received, call [GetMessagePos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmessagepos) and parse it to obtain the cursor position at which the event occurred.
3. Based on the starting position and the mouse delta (remember to scale it by the [Pointer Speed](https://github.com/EsportToys/MouseTray)), calculate where the cursor _would have_ landed if it were not confined to the game/display area.
4. Displace your in-world camera by the clipped amount of mouse movement (remember to scale it to your in-world units)

If you use SDL, it is not possible to implement this without using a framerate-dependent (i.e. laggy) Software Cursor, as they do not report raw device deltas which is necessary to read motion when the cursor is clipped against the window boundary.
