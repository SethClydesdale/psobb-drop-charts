# PSOBB Drop Charts
This addon provides you with a reference for items that drop from enemies on certain difficulties and for specific Section IDs. The drop chart data in this addon is for [Ephinea](https://ephinea.pioneer2.net/drop-charts/normal/), so it may not be accurate if you're playing on another server.

### Installation
1. Install the [addon plugin](https://github.com/HybridEidolon/psobbaddonplugin) for PSOBB.
2. Download this repository by clicking [**here**](https://github.com/SethClydesdale/psobb-drop-charts/archive/master.zip).
3. Drag and drop the **Drop Charts** addon into the /addons directory in your PSOBB folder.

### How to Use
This addon doesn't open automatically since it's a reference resource that you open when you need it. To open the Drop Charts :

1. Press the **\`** key to open the main addon menu.
2. Select **Drop Charts** from the menu to open the drop chart list.

After this you can select the difficulty and section id to see what item an enemy can drop. Hover over an item to see your chances of obtaining it.

### Preview
[![](https://i11.servimg.com/u/f11/18/21/41/30/pso13128.jpg)](https://i11.servimg.com/u/f11/18/21/41/30/pso13128.jpg)

### Change Log

#### v1.2.0
- Added search feature for quickly finding the item you're looking for thanks to [Paralax2062](https://github.com/SethClydesdale/psobb-drop-charts/pull/3). Type the item you're looking for then click "Selection" to search within the current difficulty and section id or "All" to search everything.

#### v1.1.1
- Updated drop chart information to reflect the recent changes made to the drop charts on Ephinea.
- Fixed empty cells causing the addon to crash when hovered. These cells were simply removed as they provided no information.
- Added a utils folder to the addon that contains utilities for updating this addon, manually. You can ignore this folder if you have no intention of doing so.

#### v1.1.0
- Added auto mode for automatic difficulty and section id selection. This mode can be toggled by clicking the "Toggle" button under the drop downs. 
- Added automatic DAR/Rare Rate calculations.

Big thank you to [Paralax2062](https://github.com/Paralax2062) for implementing this new functionality !

#### v1.0.2
- Updated drop charts to reflect the changes made in [this update](https://www.pioneer2.net/community/threads/minor-update.7791/#post-73734).

#### v1.0.1
- Adjusted table layout.
- Other minor code optimizations.

### Updating Drop Charts
If for any reason you need to update the drop chart data for this addon -- such as in the event I'm absent -- I wrote a small script that grabs and parses the data for you. Follow the steps below to update the drop charts.

1. Go to [Ephinea](https://ephinea.pioneer2.net/drop-charts/normal/) and select the desired difficulty.
2. Open your console and execute [this script](https://github.com/SethClydesdale/psobb-drop-charts/blob/master/Utils/drop-grabber.js) to copy the drop charts to your clipboard.
3. Edit the respective difficulty file (normal, hard, very hard, ultimate...), delete the contents, add "return" to the beginning of the file, and paste the copied drop chart code.
4. Save the file and the drop chart data will be updated for that difficulty.

Repeat the steps above to update the drop charts for all difficulties.

### Special Thanks to...
- [Paralax2062](https://github.com/Paralax2062) for implementing automatic Difficulty and Section ID selection, and DAR/RR calculations.
