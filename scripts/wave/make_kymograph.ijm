setBatchMode(false)

DEFAULT_PATH = "D:/Processing"
DEFAULT_PATH_OUTPUT = "D:/Experiments/Outputs"
OUTPUT_PREFIX = "Pos"

APPROX_SPATIAL_PIXELS = 100
// This defines how many spatial pixels (approximately) the output kymographs have

Dialog.create("Cropping");

Dialog.addString("Path to Stacked Image Files", DEFAULT_PATH, 36);
// This is the output path of the 00_StitchingStacking.ijm script
// The directory is supposed to contain subdirectories named Pos# (any other directories or files are not allowed)
// Each Pos# directory should have Pos#_BF, Pos#_..., ..., and Pos#.zip
// Pos#.zip is the file created using the ROI manager and specifies the positions of every tube

Dialog.addString("Path to Output Files", DEFAULT_PATH_OUTPUT, 36);
// Use different path from the database

Dialog.addString("Main Channel", "Ratio", 36);

// comma-separated min-max settings for each channel

Dialog.show();

dataBase = Dialog.getString();
if (!endsWith(dataBase, File.separator)) {
	dataBase += File.separator;
}

output = Dialog.getString();

mainChannel = Dialog.getString();

mainMin = 0;
mainMax = 0;

posDirs = getFileList(dataBase);
for (i = posDirs.length; i > 0; i--) {
	if (File.isFile(dataBase + posDirs[i - 1])) {
		posDirs = Array.deleteIndex(posDirs, i - 1);
	}
}

logName = output + File.separator + "log.txt";
File.append("File,PixelsAlongTube", logName);

for (ip = 0; ip < posDirs.length; ip++) {
	workDir = dataBase + posDirs[ip];

	files = getFileList(workDir);
	
	main = Array.filter(files, mainChannel);
	
	if (main.length == 1) {
		mainFile = main[0];
	} else {
		print("Data for main channel (" + mainChannel + ") not found.");
	}
	
	print(mainFile);
	
	open(workDir + mainFile);
	
	roiManager("reset");
	roiManager("open", workDir + File.separator + OUTPUT_PREFIX + d2s(ip + 1, 0) + ".zip");
			
	nTubes = roiManager("count");
	
	for (it = 0; it < nTubes; it += 2) {
		// crop each tube
		iroi_main = it;
		iroi_straight = it + 1;
		
		mainTubeFile = replace(mainFile, OUTPUT_PREFIX + d2s(ip + 1, 0) + "_", OUTPUT_PREFIX + d2s(ip + 1, 0) + "_Tube" + d2s(it / 2 + 1, 0) + "_"); 
		
		// Process main channel
		selectWindow(mainFile);
		roiManager("select", iroi_main);
		run("Straighten...", "title=" + mainTubeFile + " process");
		selectWindow(mainTubeFile);
		roiManager("select", iroi_straight);
		
		run("Crop");
		
		saveAs("tiff", output + File.separator + OUTPUT_PREFIX + d2s(ip + 1, 0) + "_Tube" + d2s(it / 2 + 1, 0) + "_" + mainChannel);
		
		run("Rotate 90 Degrees Right");
		// run("Gaussian Blur...", "sigma=2 stack");
		// Gaussian blurring will make NaN propagate
		
		w = getWidth();
		
		run("Bin...", "x=&w y=1 z=1 bin=Median");
		// bin=Max is used in the original scripting
		
		h = getHeight();
		pxTotal = h;
		h = floor(h / APPROX_SPATIAL_PIXELS);
		
		run("Bin...", "x=1 y=&h z=1 bin=Median");
		// bin=Average is used in the original scripting
		
		f = nSlices();
		
		run("Make Montage...", "columns=&f rows=1 scale=1");
		selectWindow("Montage");
		
		saveAs("tiff", output + File.separator + OUTPUT_PREFIX + d2s(ip + 1, 0) + "_Tube" + d2s(it / 2 + 1, 0) + "_Montage");
		File.append(OUTPUT_PREFIX + d2s(ip + 1, 0) + "_Tube" + d2s(it / 2 + 1, 0) + "_Montage.tiff," + d2s(pxTotal, 0), logName);
		
		close();

		selectWindow(mainTubeFile);
		close();		
	}
	
	selectWindow(mainFile);
	close();
}

return;
