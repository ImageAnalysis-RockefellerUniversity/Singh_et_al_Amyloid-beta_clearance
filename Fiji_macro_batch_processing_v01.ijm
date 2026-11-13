/****************************************************************************************************
September 10, 2025

Author: Ved P. Sharma, The Rockefeller University
		E-mail: vedsharma@gmail.com
****************************************************************************************************/
// This macro selects all the regex-defined files in a folder and 
// runs processFile() function, with user's custom code
// Any new generated images are saved in user defined folder2

run("Close All");
close("Results");
close("ROI Manager");
close("Log");

folder = getDirectory("Choose a folder to process...");
//folder2 = getDirectory("Choose a folder where you want to save the processed files...");

//filePattern = "NIH3T3.*_dextran_bkgd10.tif";
//filePattern = ".*_Rab5.tif";
//filePattern = ".*.tif";
//filePattern = ".*_WC_rois_clean.zip";
filePattern = ".*_nuclei_rois_clean.zip";

fileList = getFileList(folder);
count=0;
for (j=0; j<fileList.length; j++) // loop for going through the files in a folder
	if (matches(fileList[j], filePattern)) {
		count++;
		processFile();
	}
print("No. of files processed: "+count);

function processFile() {
	currFilepath = folder+fileList[j];

// split channels and save images
	if(false) {
		run("Bio-Formats Importer", "open=&currFilepath autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		wait(200);
//		open(currFilepath);

// convert 16-bit .czi to 8-bit for use in COlocalization Threshold plugin
//		setOption("ScaleConversions", true);
//		run("8-bit");

		run("Split Channels");
		if(nImages != 4)
			exit("Error: Image should have four channels!");

		saveTitle = replace(fileList[j], ".czi", "_LC3");
		saveAs("Tiff", folder+saveTitle);
		close();

		saveTitle = replace(fileList[j], ".czi", "_Rab5");
		saveAs("Tiff", folder+saveTitle);
		close();

		saveTitle = replace(fileList[j], ".czi", "_betaPep");
		saveAs("Tiff", folder+saveTitle);
		close();

//		run("Grays");
		saveTitle = replace(fileList[j], ".czi", "_DAPI");
		saveAs("Tiff", folder+saveTitle);
		close();
	}

// Run Gaussian blur, radius=1 on DAPI images
	if(false) {
		open(currFilepath);
		run("Gaussian Blur...", "sigma=1");
		saveTitle = replace(fileList[j], ".tif", "_Gauss1");
		saveAs("Tiff", folder+saveTitle);
		close();
	}

// Delete nuclear signal from BRD2 images
	if(false) {
		if(count==1) {
			setForegroundColor(0, 0, 0);
			setBackgroundColor(255, 255, 255);
		}
		roiManager("reset");
		open(currFilepath); // open BRD2 image
		roiFilePath = replace(currFilepath, "_BRD2.tif", "_DAPI_Gauss1_rois.zip");
		roiManager("Open", roiFilePath);
		roiManager("Fill");
		run("Enhance Contrast", "saturated=0.35");

		saveTitle = replace(fileList[j], ".tif", "_noNucleus");
		saveAs("Tiff", folder+saveTitle);
		run("Close All");
	}

// Run Median filter, radius=0.5 on BRD2_noNucleus images
	if(false) {
		open(currFilepath);
		run("Median...", "radius=0.5");
		saveTitle = replace(fileList[j], ".tif", "_mdn0.5");
		saveAs("Tiff", folder+saveTitle);
		close();
	}

// Create a combined BRD2_noNucleus+mdn0.5.tif and DAPI_Gauss1 image
	if(false) {
		open(currFilepath); // This is _BRD2_noNucleus_mdn0.5.tif image
		rename("1");
		DAPIImagepath = replace(currFilepath, "_BRD2_noNucleus_mdn0.5.tif", "_DAPI_Gauss1.tif");
		open(DAPIImagepath);
		rename("2");
		run("Merge Channels...", "c1=1 c2=2 create ignore");
		saveTitle = replace(fileList[j], ".tif", "+DAPI_Gauss1");
		saveAs("Tiff", folder+saveTitle);
		run("Close All");
	}

// Subtract background
	if(false) {
		open(currFilepath);
		run("Subtract Background...", "rolling=50");
		saveTitle = replace(fileList[j], ".tif", "_bkgd");
		saveAs("Tiff", folder+saveTitle);
		close();
	}

// Threshold Rab5 image and generate mask and ROI, save mask with the ROI
	if(false) {
		roiManager("reset");
		open(currFilepath);
		setAutoThreshold("Li dark");
		run("Convert to Mask");
		run("Fill Holes");
		run("Create Selection");
		roiManager("Add");

		ROIsaveTitle = replace(fileList[j], ".tif", "_mask.roi");
		roiManager("Save", folder+ROIsaveTitle);
		
		saveTitle = replace(fileList[j], ".tif", "_mask_w_ROI");
		saveAs("Tiff", folder+saveTitle);
		run("Close All");
	}

// Run Colocalization Threshold on Rab5 and LC3 images in a folder
// Results get added to the Results window for all images in a folder
	if(false) {
		roiManager("reset");
		open(currFilepath); // This is *.Rab5.tif file
		roiFilePath = replace(currFilepath, ".tif", "_mask.roi");
		roiManager("Open", roiFilePath);
		roiManager("Select", 0);
		LC3FilePath = replace(currFilepath, "_Rab5.tif", "_LC3.tif");
		open(LC3FilePath); // This is *.LC3.tif file
		
		run("Colocalization Threshold", "use=[Channel 1] include");
		run("Close All");
	}
// Measure_betaPep_BRD2_intensities
	if(false) {
		if(count==1)
			run("Set Measurements...", "area mean integrated redirect=None decimal=2");

		roiManager("reset");
		open(currFilepath); // open betaPep_bkgd image
		roiFilePath = replace(currFilepath, "_betaPep_bkgd.tif", "_BRD2_noNucleus_mdn0.5+DAPI_Gauss1_rois_manual.zip");
		roiManager("Open", roiFilePath);
		
		roiManager("Measure");
		selectWindow("Results");
		Table.rename("Results", "betaPep");
		Table.renameColumn("Area", "Area_betaPep");
		Table.renameColumn("Mean", "Mean_betaPep");
		Table.renameColumn("IntDen", "IntDen_betaPep");
		Table.renameColumn("RawIntDen", "RawIntDen_betaPep");

		BRD2FilePath = replace(currFilepath, "_betaPep_bkgd.tif", "_BRD2_bkgd.tif");
		open(BRD2FilePath); // open BRD2_bkgd image
	
		roiManager("Measure");
		selectWindow("Results");
		Table.rename("Results", "BRD2");
		Table.renameColumn("Area", "Area_BRD2");
		Table.renameColumn("Mean", "Mean_BRD2");
		Table.renameColumn("IntDen", "IntDen_BRD2");
		Table.renameColumn("RawIntDen", "RawIntDen_BRD2");
		
		Area_BRD2 = Table.getColumn("Area_BRD2");
		Mean_BRD2 = Table.getColumn("Mean_BRD2");
		IntDen_BRD2 = Table.getColumn("IntDen_BRD2");
		RawIntDen_BRD2 = Table.getColumn("RawIntDen_BRD2");
		close("BRD2");
		
		selectWindow("betaPep");
		Table.setColumn("Area_BRD2", Area_BRD2);
		Table.setColumn("Mean_BRD2", Mean_BRD2);
		Table.setColumn("IntDen_BRD2", IntDen_BRD2);
		Table.setColumn("RawIntDen_BRD2", RawIntDen_BRD2);
		
		saveTitle = replace(fileList[j], "_bkgd.tif", ".csv");
//		saveAs("Results", folder+saveTitle)
		Table.save(folder+saveTitle);
		run("Close All");
		close("betaPep");
	}

// change channel LUTs
	if(false) {
		open(currFilepath);
		Stack.setChannel(1); run("Blue");
		Stack.setChannel(2); run("Grays");
		Stack.setChannel(3); run("Red");
		Stack.setChannel(4); run("Green");
		saveTitle = replace(fileList[j], ".czi", "");
		saveAs("Tiff", folder+saveTitle);
		close();
	}	
	
// From Z-stacks, save user-specified Z slice with all 3 channels as a .tif file
	if(false) {
		run("Bio-Formats Importer", "open=&currFilepath autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		slice_num = getNumber("Enter the Z slice number to save", 0);
		//print(slice_num);
		run("Duplicate...", "duplicate slices=&slice_num");
		saveTitle = replace(fileList[j], ".czi", "_Z"+slice_num);
		saveAs("Tiff", folder+saveTitle);
		run("Close All");
	}
	
//=============================================================================	
// Run macro "Remove_boundary_and_small_ROIs.ijm" and save the updated ROIs
	if(false) {
		open(currFilepath);
//		roiFileName = replace(fileList[j], ".tif", "_WC_rois.zip"); // Don't forget to change the threshold values in the macro below
		roiFileName = replace(fileList[j], ".tif", "_nuclei_rois.zip"); // Don't forget to change the threshold values in the macro below
		roiManager("open", folder+roiFileName);
	
		macroPath = "/mnt/bircdata07/Collaborations/Vikas_TarakhovskyLab/Scripts/Remove_boundary_ROIs_small_and_big_ROIs.ijm";
		runMacro(macroPath);
		if(roiManager("count") > 0) {
	//			saveTitle = replace(fileList[j], ".tif", "_rois_clean");
			if(roiManager("count") == 1)
				saveTitle = replace(roiFileName, ".zip", "_clean.roi");
			else
				saveTitle = replace(roiFileName, ".zip", "_clean.zip");
			roiManager("save", folder+saveTitle);
			
		}
		else
			print("After removing boundary ROI, this image has no ROI:\n"+fileList[j]);
		run("Close All");
		close("ROI Manager");
	}

//=============================================================================
// Run BIOP-JACoP plugin, save cropped ROI restults for each cell, save Results table at the end for each folder
// process only files which have the associated ROIs (_clean.zip or _clean.roi)
// Make sure to change the Results table name appropriately at the beginning of this script
	if(true) {
		roiFilePath = currFilepath;
		
		imageFileName = File.getNameWithoutExtension(fileList[j]); // remove .roi or .zip
//		imageFilePath = folder+replace(imageFileName, "_WC_rois_clean", ".tif");
		imageFilePath = folder+replace(imageFileName, "_nuclei_rois_clean", ".tif");
		open(imageFilePath);
		imageID =  getImageID();
		roiManager("open", roiFilePath);
		
		//rename ROIs
		n = roiManager("count");
		for (a = 0; a < n; a++) {
		    roiManager("select", a);
//		    roiManager("Rename", "WC_ROI_"+a+1);
		    roiManager("Rename", "nuclei_ROI_"+a+1);
		}
		roiManager("save", roiFilePath); // overwrite ROIs
		// ch2 is LC3, ch3 BRD2
		run("BIOP JACoP", "channel_a=2 channel_b=3 threshold_for_channel_a=[Costes Auto-Threshold] threshold_for_channel_b=[Costes Auto-Threshold] manual_threshold_a=0 manual_threshold_b=0 crop_rois get_pearsons get_manders get_fluorogram perform_costes_randomization_mask show_costes_plot show_costes_random_image costes_block_size=5 costes_number_of_shuffling=100");
		
		selectImage(imageID); close(); // close original image, save others
		close("ROI Manager");
		close("Log");
		
		n = nImages; // save images ending with Report
		for (a = 0; a < n; a++) {
			selectImage(1);
//			saveTitle = replace(getTitle(), " Report", "");
			saveAs("PNG", folder+getTitle());
			close();
		}
		run("Close All");
	}	
	
}

