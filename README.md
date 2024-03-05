# ImageJ Macros
Repository of ImageJ scripts used in image processing by the Yang Lab at the University of Michigan

# Current scripts
- `Make_FRET_Ratio_video.ijm`: Creates AVI videos of the FRET Ratio signal for single or multiple microscope positions. FRET and CFP channels needed.
## Temperature 
- `Open_resize_straighten_images.ijm`: Create new tiff files from raw data that only contain a single tube.
- `FRET_ratio_video.ijm`: Create a video of the FRET ratio signal for a single or multiple microscope positions. FRET and CFP channels needed.
- `flip_save_avi.ijm`: Flip and save a video as an AVI file. Used after `FRET_ratio_video.ijm` to flip the video so that the temperature is increasing from left to right.

# Installation
The scripts can be run using two methods:
1. Open the script as a file in ImageJ's editor and click 'Run'
2. Copy the contents of `script` into ImageJ's `script` folder (found in ImageJ's installation directory). This method incorporates the scripts into ImageJ's `Plugins/Scripts` menu.
