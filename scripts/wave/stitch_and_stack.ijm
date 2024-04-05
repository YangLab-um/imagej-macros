setBatchMode(false)

DEFAULT_PATH = "D:/Raw"
DEFAULT_PATH_OUTPUT = "D:/Processing"
OUTPUT_PREFIX = "Pos"

TEMPORARY_DIR = "Temporary"
PRESTITCH_MSG = "Prestitch (for visual inspection of stitching quality)"

Dialog.create("Stitching and Stacking");

Dialog.addMessage("Paths (Use Different Directory for Temporary Outputs)  ----------------------------------------------------------------------------");

Dialog.addString("Path to Raw Data", DEFAULT_PATH, 36);
Dialog.addString("Path to Output and Temporary Files", DEFAULT_PATH_OUTPUT, 36);

Dialog.addMessage("Select run mode  ------------------------------------------------------------------------------------------------------------------------------");

Dialog.addRadioButtonGroup("", newArray(PRESTITCH_MSG, "Stitch and Stack"), 2, 1, "Stitch and Stack");

Dialog.addMessage("Specify Regex Patterns for Raw Image File Names  --------------------------------------------------------------------------------");
Dialog.addString("(Each Directory) Pattern after 1-base Position Index", "-Pos_.*", 36);
Dialog.addString("(Each Image File) Pattern for BF Channel", ".*-BF_.*", 36);
Dialog.addString("(Each Image File) Comma-separated Patterns for Channel Ids", ".*-BF_.* , .*-CFP_.* , .*-FRET_.*", 36);
Dialog.addString("(Each Image File) Channel Ids for Outputs", "BF , CFP , FRET", 36);

Dialog.addMessage("Specify Numbers  ------------------------------------------------------------------------------------------------------------------------------");
Dialog.addNumber("Number of Positions (Number of tile sets)", 0);
// Position indexing must start with 1
Dialog.addNumber("Frames to be Stitched", 1);
// Frame indexing does not need to start with 0 or anything else
Dialog.addNumber("Scaling (%) of the Stacked Image", 100);
Dialog.addNumber("Rolling Ball Radius (No Subtraction If Negative)", 50);

Dialog.show();

rawBase = Dialog.getString();
if (!endsWith(rawBase, File.separator)) {
	rawBase += File.separator;
}

outBase = Dialog.getString();
if (!endsWith(outBase, File.separator)) {
	outBase += File.separator;
}

File.makeDirectory(outBase);

pattern = Dialog.getString();

bf_channel = Dialog.getString();

channel = split(Dialog.getString(), ",");
for (i = 0; i < channel.length; i++) {
	channel[i] = String.trim(channel[i]);
}

channelId = split(Dialog.getString(), ",");
for (i = 0; i < channelId.length; i++) {
	channelId[i] = String.trim(channelId[i]);
}

nPos = Dialog.getNumber();

nFrame = Dialog.getNumber();

allDirs = getFileList(rawBase);

scalePercent = Dialog.getNumber();
rollingBall = Dialog.getNumber();

runMode = Dialog.getRadioButton();
if (runMode.startsWith(PRESTITCH_MSG)) {
	flagPreStitching = true;
} else {
	flagPreStitching = false;
}

flagSkipStitching = false;
flagSkipStacking = false;

if (flagPreStitching) {
	print("Prestitching option is on. Only the first frame will be analyzed");
	// TileConfiguration.txt file created for each position by prestitching will be used in the full stitching process
	
	nFrame = 1;
	
	flagSkipStitching = true;
	flagSkipStacking = true;
	
	// stitch the first frame of bright field images

	for (ip = 0; ip < nPos; ip++) {
		posList = Array.filter(allDirs, "(" + d2s(ip + 1, 0) + pattern + ")");
		
		gridNum = posList.length;
	
		saveDir = outBase + OUTPUT_PREFIX + d2s(ip + 1, 0) + "/";
		if (!File.isDirectory(saveDir)) {
			File.makeDirectory(saveDir);
		}
		
		tempFiles = newArray();
		
		for (ig = 0; ig < posList.length; ig++) {
			// get the first image at each grid and make its temporary copy
			allFiles = getFileList(rawBase + posList[ig]);
			f = Array.filter(allFiles, "(" + bf_channel + ")");
			Array.sort(f);
			
			tempFile = rawBase + ".temp_grid_" + d2s(ig + 1, 0) + ".tif";
			tempFiles = Array.concat(tempFiles, newArray(tempFile));
			
			File.copy(rawBase + posList[ig] + f[0], tempFile);
		}
		
		run("Grid/Collection stitching", "type=[Grid: row-by-row] order=[Left & Down] grid_size_x=" + d2s(gridNum, 0) + " grid_size_y=1 tile_overlap=30 first_file_index_i=1 directory=" + rawBase + " file_names=.temp_grid_{i}.tif output_textfile_name=TileConfiguration.txt fusion_method=[Max. Intensity] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap display_fusion computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
		// You might see some band in the stitched images which are artifacts. Adjust the parameters for stitching to get proper results
		// Fusion method Max. Intensity may give better result than Linear Blending. In BF images, the centers of tiles tend to be brighter than the periphery, which is thought to be the reason for having stripes in the stitched image. Max. Intensity option can alleviate this problem.
		
		rawScale = saveDir + "Pos" + d2s(ip + 1, 0) + "_BF";
		saveAs("tiff", rawScale);
		tempFiles = Array.concat(tempFiles, newArray(rawScale));
		
		close();
		
		File.openSequence(saveDir, " filter=BF scale=" + d2s(scalePercent, 0));
		
		saveAs("tiff", saveDir + "Pos" + d2s(ip + 1, 0) + "_BF");
		
		close();
		
		File.rename(rawBase + "TileConfiguration.txt", saveDir + "TileConfiguration.old.txt");
		File.rename(rawBase + "TileConfiguration.registered.txt", saveDir + "TileConfiguration.txt");
		// are there other relevant metadata files?
		
		File.delete(rawScale);
			
		for (i = 0; i < tempFiles.length; i++) {
			if (File.exists(tempFiles[i])) {
				File.delete(tempFiles[i]);
			}
		}
	}
}

if (!flagSkipStitching) {
	// Stitching can be skipped if you want to use existing data
	
	// Stitch entire data
	// Requires prestitched data and tile configuration files
	
	for (ip = 0; ip < nPos; ip++) {
		posList = Array.filter(allDirs, "(" + d2s(ip + 1, 0) + pattern + ")");
		
		gridNum = posList.length;
	
		saveDir = outBase + OUTPUT_PREFIX + d2s(ip + 1, 0) + "/";
		stitchedDir = saveDir + File.separator + TEMPORARY_DIR + File.separator;
		if (!File.isDirectory(stitchedDir)) {
			File.makeDirectory(stitchedDir);
		}
		
		for (ic = 0; ic < channel.length; ic++) {
			for (ifs = 0; ifs < nFrame; ifs++) {
				tempFiles = newArray();
			
				for (ig = 0; ig < posList.length; ig++) {
					allFiles = getFileList(rawBase + posList[ig]);
					f = Array.filter(allFiles, "(" + channel[ic] + ")");
					Array.sort(f);
					// this is not efficient
					
					tempFile = rawBase + ".temp_grid_" + d2s(ig + 1, 0) + ".tif";
					tempFiles = Array.concat(tempFiles, newArray(tempFile));
					
					File.copy(rawBase + posList[ig] + f[ifs], tempFile);
				}
				
				File.copy(saveDir + "TileConfiguration.txt", rawBase + "TileConfiguration.txt");
				// Reference tile configuration file created during the prestitching process
				
				tempFiles = Array.concat(tempFiles, newArray(rawBase + "TileConfiguration.txt"));
				
				run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by TileConfiguration] directory=" + rawBase + " layout_file=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
				// Use Linear Blending for non-BF images
				
				saveAs("tiff", stitchedDir + channelId[ic] + IJ.pad(ifs, 8));
				close();
				
				for (i = 0; i < tempFiles.length; i++) {
					if (File.exists(tempFiles[i])) {
						File.delete(tempFiles[i]);
					}
				}
			}
		}
	}
	print("Stitching is done");
} else {
	print("Stiching is skipped");
}

if (!flagSkipStacking) {
	for (ip = 0; ip < nPos; ip++) {
		flag_numerator = 0;
		flag_denominator = 0;
		
		saveDir = outBase + OUTPUT_PREFIX + d2s(ip + 1, 0) + File.separator;
		
		for (ic = 0; ic < channelId.length; ic++) {
			File.openSequence(
				saveDir + TEMPORARY_DIR + File.separator,
				" filter=" + channelId[ic] + " scale=" + d2s(scalePercent, 0)
			);
			// Open sequences of stitched files
			
			window_name = "Pos" + d2s(ip + 1, 0) + "_" + channelId[ic];
			rename(window_name);
			
			if (rollingBall >= 0) {
				run("Subtract Background...", "rolling=" + d2s(rollingBall, 0) + " stack");
				// This may produces NaNs and Infs. Adjust min-max range accordingly to see proper results
			}
			
			// FRET ratio defined here -- by default, FRET ratio is defined to be FRET channel intensity / CFP channel intensity
			// >>> FRET ratio definition
			if (matches(channelId[ic], ".*FRET.*")) {
				ratio_numerator = window_name;
				flag_numerator = 1;
			}
			if (matches(channelId[ic], ".*CFP.*")) {
				ratio_denominator = window_name;
				flag_denominator = 1;
			}
			// <<< FRET ratio definition
			
			saveAs("tiff", saveDir + window_name);
		}
		if (flag_numerator == 1 && flag_denominator == 1) {
			run("Misc...", "divide=NaN run");
			// division by zero will be mapped to NaN
			
			imageCalculator("Divide create 32-bit stack", ratio_numerator + ".tif", ratio_denominator + ".tif");
			// Do we need 32-bit results?
			
			saveAs("tiff", saveDir + "Pos" + d2s(ip + 1, 0) + "_Ratio");
		}
	}
	
	print("Stacking is done.");
} else {
	print("Stacking is skipped.");
}

print("Done.");

// You may want to delete all temporary files

return;
