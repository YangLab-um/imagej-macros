# ImageJ Macros
Repository of ImageJ scripts used in image processing by the Yang Lab at the University of Michigan

# Current scripts
- `Make_FRET_Ratio_video.ijm`: Creates AVI videos of the FRET Ratio signal for single or multiple microscope positions. FRET and CFP channels needed.
## Temperature 
- `Open_resize_straighten_images.ijm`: Create new tiff files from raw data that only contain a single tube.
- `FRET_ratio_video.ijm`: Create a video of the FRET ratio signal for a single or multiple microscope positions. FRET and CFP channels needed.
- `flip_save_avi.ijm`: Flip and save a video as an AVI file. Used after `FRET_ratio_video.ijm` to flip the video so that the temperature is increasing from left to right.
- `combine_fret_videos.ijm`: Combine all videos belonging to the same row of a temperature experiment. Save the result as a tiff.
- `make_montage.ijm`: Create a montage of the vertical average of a tube over time (kymograph).
- `combine_tube_montages.ijm`: Combine all montages belonging to the same row of a temperature experiment. Save the result as a tiff.

## GlassTubeAlignment
- `GlassTubeAlignment.py`: Perform multi-channel image alignment (multiStackReg) across all positions in a dataset where sample tubes moved during the experiment. The alignment process uses transformation information generated from the first channel in the provided channel list and applies it to all other channels. Users can specify input and output paths, a list of channels, and the range of frames to process. The script is implemented in Jython 2.7.2

#### Before alignment
![Sample Image](readme_images\GlassTubeAlignment\Before_GTA.jpg)
#### After alignment
![Sample Image2](readme_images\GlassTubeAlignment\After_GTA.jpg)


# Installation
The scripts can be run using two methods:
1. Open the script as a file in ImageJ's editor and click 'Run'
2. Copy the contents of `script` into ImageJ's `script` folder (found in ImageJ's installation directory). This method incorporates the scripts into ImageJ's `Plugins/Scripts` menu.
