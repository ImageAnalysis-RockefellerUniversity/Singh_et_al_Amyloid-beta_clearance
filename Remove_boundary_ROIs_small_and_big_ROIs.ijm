// This macro will remove all the boundary ROIs from the ROI Manager
// as well as any ROIs with area less than a specfic value
// Input: an image and the corresponding ROIs opened in the ROI Manager
// A label image should be provided if you want to erase (fill black color) boundary-touching cells from the label image

// Author: Ved Sharma, The Rockefeller University (June 30, 2025)

/*
// Threshold values for cell area
area_threshold_min = 40; // in um
area_threshold_max = 400; // in um
*/

// Threshold values for nucleus area
area_threshold_min = 20; // in um
area_threshold_max = 200; // in um

imgWidth = getWidth(); // in pixels
imgHeight = getHeight(); // in pixels

setForegroundColor(0, 0, 0); // setting foreground color for filling black to removed ROIs
count=0;
n = roiManager("count");
for (i = n; i > 0; i--) {
    roiManager("select", i-1);
//    wait(200);
	Roi.getBounds(x, y, width, height); // all values in pixels
	getStatistics(ROIarea);
	
//	print(x, y, width, height);
	if(x <= 0 || y <= 0 || x+width+1 >= imgWidth || y+height+1 >= imgHeight || ROIarea<area_threshold_min || ROIarea>area_threshold_max) {
//		run("Fill", "slice"); // fill black color to boundary ROIs
		roiManager("delete");
		count++;
	}
}
print("ROIs removed from the image boundary: "+count);

