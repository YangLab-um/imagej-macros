setBatchMode(false)

DEFAULT_PATH = "D:/Experiments/Exp_00/Processed"
DEFAULT_PATH_OUTPUT = "D:/Experiments/Exp_00_Montage"
OUTPUT_PREFIX = "Pos"

APPROX_SPATIAL_PIXELS = 100
// This defines how many spatial pixels (approximately) the output kymographs have

Dialog.create("Cropping");

Dialog.addString("Path to Stacked Image Files", DEFAULT_PATH, 36);
// This is the output path of the 00_StitchingStacking.ijm script
// The directory is supposed to contain subdirectories named Pos# (any other directories or files are not allowed)
// Each Pos# directory should have Pos#_BF, Pos#_..., ..., and Pos#.zip (zip same name as folder)
// Pos#.zip is the file created using the ROI manager and specifies the positions of every tube

Dialog.addString("Path to Output Files", DEFAULT_PATH_OUTPUT, 36);
// Use different path from the database

Dialog.addString("Channels", "Ratio , mScarlet , BF , CFP , FRET", 36);

Dialog.addNumber("Start from Pos ", 1);
Dialog.addNumber("Minimum valid length in pixel ", 1000);
// for tubes shorter than this: kymographs will have 1 px height (full spatial average) -- use this for control conditions

Dialog.show();

dataBase = Dialog.getString();
if (!endsWith(dataBase, File.separator)) {
	dataBase += File.separator;
}

outBase = Dialog.getString();

channel = split(Dialog.getString(), ",");
for (i = 0; i < channel.length; i++) {
	channel[i] = String.trim(channel[i]);
}

startPos = Dialog.getNumber();
minLength = Dialog.getNumber();

mainMin = 0;
mainMax = 0;

posDirs = getFileList(dataBase);
for (i = posDirs.length; i > 0; i--) {
	if (File.isFile(dataBase + posDirs[i - 1])) {
		posDirs = Array.deleteIndex(posDirs, i - 1);
	}
}

idx = newArray(posDirs.length);
for (i = 0; i < posDirs.length; i++) {
	name = posDirs[i].replace(OUTPUT_PREFIX, "");
	idx[i] = IJ.pad(name, 5);
}
Array.sort(idx, posDirs);

File.makeDirectory(outBase);
logName = outBase + File.separator + "log.txt";

for (ic = 0; ic < channel.length; ic++) {
	mainChannel = channel[ic];
	
	output = outBase + File.separator + mainChannel;
	File.makeDirectory(output);
	
	if (ic == 0) {
		File.append("File,PixelsAlongTube", logName);
	}
	
	for (ip = startPos - 1; ip < posDirs.length; ip++) {
		workDir = dataBase + posDirs[ip];
	
		files = getFileList(workDir);
		
		main = Array.filter(files, mainChannel);
		
		if (main.length == 1) {
			mainFile = main[0];
		} else {
			print("Data for main channel (" + mainChannel + ") not found. Skip montaging this channel at this position.");
			continue;
		}
		
		print(mainFile);
		
		prefix = replace(posDirs[ip], "/", "");
		
		roiManager("reset");
		if (File.exists(workDir + File.separator + prefix + ".zip")) {
			roiManager("open", workDir + File.separator + prefix + ".zip");
		} else {
			print(prefix + " does not exist. Skip this position.");
			continue;
		}
		
		open(workDir + mainFile);
		nTubes = roiManager("count");
		
		for (it = 0; it < nTubes; it += 2) {
			// crop each tube
			iroi_main = it;
			iroi_straight = it + 1;
			
			// mainTubeFile = replace(mainFile, OUTPUT_PREFIX + d2s(ip + 1, 0) + "_", OUTPUT_PREFIX + d2s(ip + 1, 0) + "_Tube" + d2s(it / 2 + 1, 0) + "_"); 
			mainTubeFile = replace(mainFile, prefix + "_", prefix + "_Tube" + d2s(it / 2 + 1, 0) + "_"); 
			
			// Process main channel
			selectWindow(mainFile);
			roiManager("select", iroi_main);
			run("Straighten...", "title=" + mainTubeFile + " process");
			selectWindow(mainTubeFile);
			roiManager("select", iroi_straight);
			
			run("Crop");
			
			saveAs("tiff", output + File.separator + prefix + "_Tube" + d2s(it / 2 + 1, 0) + "_" + mainChannel);
			
			run("Rotate 90 Degrees Right");
			// run("Gaussian Blur...", "sigma=2 stack");
			// Gaussian blurring will make NaN propagate
			
			w = getWidth();
			
			run("Bin...", "x=&w y=1 z=1 bin=Median");
			
			h0 = getHeight();
			pxTotal = h0;
			
			if (h0 < minLength) {
				h = floor(h0 / 10);
			} else {
				h = floor(h0 / APPROX_SPATIAL_PIXELS);
			}
			
			run("Bin...", "x=1 y=&h z=1 bin=Median");
			
			f = nSlices();
			
			run("Make Montage...", "columns=&f rows=1 scale=1");
			selectWindow("Montage");
			
			if (h0 < minLength) {
				h = getHeight();
				run("Bin...", "x=1 y=&h z=1 bin=Average");
			}
			
			saveAs("tiff", output + File.separator + prefix + "_Tube" + d2s(it / 2 + 1, 0) + "_" + mainChannel + "_Montage");
			
			if (ic == 0) {
				File.append(prefix + "_Tube" + d2s(it / 2 + 1, 0) + "," + d2s(pxTotal, 0), logName);
			}
			
			close();
	
			selectWindow(mainTubeFile);
			close();		
		}
		
		selectWindow(mainFile);
		close();
	}
}

return;
