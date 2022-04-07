// Count number of foci
// Based on mean + factor * SD threshold method of Adriaan
//
// Gert van Cappellen
// 23/7/2018 added CellID, an individual identifier per cell
// contains imagenr*1000 + cellnr
//

// Aanpassen: Results in 1 mapje en niet MAX name maar image name

if (isOpen("Log")) { 
     selectWindow("Log"); 
     run("Close"); 
} 
run("Clear Results");
run("Close All");
if (isOpen("ROI Manager")) {
     selectWindow("ROI Manager");
     run("Close");
}

// Define variables here

macroName="Batch_";
minThreshold=newArray(70,70); // Minimal threshold
maxThreshold=newArray(100,150); // Maximal threshold
factor =newArray(1.4,0.8); //factor*std voor threshold!
Nuclmin= 60; //minimal nucleus size
Nuclmax=400; //maximal nucleus size
Spotmin=newArray(0.2,0.2); //minimal spotsize
Spotmax1=newArray(30,30); //maximal spotsize before watershed
Spotmax2=newArray(3,3); //maximal spotsize after watershed
eduThreshold=12;

print("Macro: "+macroName);
print("---------------------------------------------------------");
print("Factor *sd: ", factor[0],"; ",factor[1]);

print("Minimal threshold: ",minThreshold[0],"; ",minThreshold[1]);
print("Maximal threshold: ",maxThreshold[0],"; ",maxThreshold[1]);
print("Minimal nucleus: ",Nuclmin);
print("Maximal nucleus: ",Nuclmax);
print("Minimal Spot size: ",Spotmin[0],"; ",Spotmin[1]);
print("Maximal spot size before watershed: ",Spotmax1[0],"; ",Spotmax1[1]);
print("Maximal spot size after watershed: ",Spotmax2[0],"; ",Spotmax2[1]);

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print("Date:",dayOfMonth,"-",month+1,"-",year," Time:",hour,":",minute,"h");

dirF=getDirectory("Choose a directory"); 														// Pick file you want to process
print("Input directory: "+dirF);
print("");

FolderNames=getFileList(dirF);
Array.sort(FolderNames);

//Super for loop: To process the entire experiment
for (ll=0; ll<FolderNames.length; ll++){
	dir=dirF+FolderNames[ll];
		
	fileNames=getFileList(dir);															
	Array.sort(fileNames);
	File.makeDirectory(dirF+"\Results");
	print("---------------------------------------------------------");

// For loop for one timepoint
dir=dirF+FolderNames[ll];

print("Input directory: "+dir);
print("");

File.makeDirectory(dir+"\ResultImages");
File.makeDirectory(dir+"\Results");
fileNames=getFileList(dir);
Array.sort(fileNames);


// MAIN LOOP
imageNr=0;
for (ii=0; ii<fileNames.length; ii++){
	if(endsWith(fileNames[ii],".tif")){
		open(dir+fileNames[ii]);
		run("Select None");
		print(fileNames[ii]);
		name=getTitle();
		
imageNr++;

		

// Put your macro here
roiManager("Reset");
name = getTitle();
//rename("MAX");

Stack.setChannel(1);
run("Gaussian Blur...", "sigma=1 slice"); //TH
//setThreshold(23, 255, "Huang");
//run("Convert to Mask", "method=Default background=Dark slice");
//setAutoThreshold("Huang dark");
run("Convert to Mask", "method=Huang background=Dark only black");

run("Invert","slice"); 												//invert

//waitForUser("inverted slice");

// default tolerance=0.5
run("Adjustable Watershed", "tolerance=0.5 slice");

run("Set Measurements...", "area mean integrated standard stack redirect=None decimal=3");
run("Analyze Particles...", "size=Nuclmin-Nuclmax exclude include add slice");
//waitForUser("analyzed particles");

roiManager("Remove Channel Info");
//waitForUser("remove channel info");

run("Clear Results");
//waitForUser("clear results");

/////////////////////////////////////////////////////
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

//EdU check - loops through ROI on channel 3 and outputs the mean of each cell with + or - label
Stack.setChannel(3);
run("Gaussian Blur...", "sigma=1 slice"); 							//blur to mitigate noise
nRoi = roiManager("Measure");
MeanEdU = newArray(nResults);
eduPos = newArray(nResults);
eduPosFoci = newArray(nResults);	//test
eduPosMean = newArray(nResults);
eduNegFoci = newArray(nResults); 	//test
eduNegMean = newArray(nResults);
iPos = 0;
iNeg = 0;

for(i = 0; i < nResults; i++) {
	Stack.setChannel(3);
	roiManager("select", i);
	getStatistics(area, mean, min, max, std, histogram);
	setResult("EdUMean", i, mean);
	
	//Label EdU positive or negative based on EdU mean
	if (mean >= eduThreshold) {
		setResult("EdU", i, "1");
		eduPos[i] = getResult("EdU", i);
		eduPosFoci[iPos] = getResult("nFoci", i); 
		iPos++; 
		}
	else {
		setResult("EdU", i, "0");
		eduPos[i] = getResult("EdU", i);
		eduNegFoci[iNeg] = getResult("nFoci", i);
		iNeg++;
		}

	
MeanEdU[i] = getResult("EdUMean",i);
	}  //end loop
	


print("Pre-excel write MeanEdU:");
Array.print(MeanEdU);
print("----------------------------");
run("Read and Write Excel","stack_results no_count_column file=["+dirF+"Results\/EdUMean "+File.getName(dir)+".xlsx]");
print("Post-excel write MeanEdU:");
Array.print(MeanEdU);
print("----------------------------");
//
//run("Clear Results");
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////
roiManager("Remove Channel Info");
roiManager("Reset");
Stack.setChannel(1);
run("Select None"); 	//deselects last ROI on image itself to prevent errors
run("Analyze Particles...", "size=Nuclmin-Nuclmax exclude include add slice");
roiManager("Remove Channel Info");
run("Clear Results");

//53BP1 spots
Stack.setChannel(4);
roiManager("Measure");
Area53BP1 = newArray(nResults);
Mean53BP1 = newArray(nResults);
Std53BP1 = newArray(nResults);
nSpots53BP1 = newArray(nResults);
areaSpots53BP1 = newArray(nResults);
avgIntensitySpots53BP1 = newArray(nResults);
intDenSpots53BP1 =newArray(nResults);
SpotsPerArea53BP1 =newArray(nResults);


for (i=0;i<nResults;i++){
	Area53BP1[i] = getResult("Area",i);
	Mean53BP1[i] = getResult("Mean",i);
	Std53BP1[i] = getResult("StdDev",i);
}
run("Clear Results");
start = 0;
end = roiManager("Count");

for (i=0; i<end; i++){
	roiManager("Select", i);
	start = nResults;
	Threshold = Mean53BP1[i]+factor[0]*Std53BP1[i];
	if (Threshold<minThreshold[0]) Threshold=minThreshold[0]; 
	if (Threshold>maxThreshold[0]) Threshold=maxThreshold[0];
	setThreshold(Threshold,255);
	run("Analyze Particles...", "size="+Spotmin[0]+"-"+Spotmax1[0]+" show=Masks include slice");
	run("Grays");
	run("Adjustable Watershed", "tolerance=.1");
	imageCalculator("AND", "Mask of "+name,name);
	setThreshold(Threshold,255);
	run("Analyze Particles...", "size="+Spotmin[0]+"-"+Spotmax2[0]+" display include slice add");
	close();
	count = 0;
	summeanSpots53BP1 = 0;
	sumareaSpots53BP1 = 0;
	for (j=start; j<nResults; j++){
		setResult("nCel",j,i+1);
		setResult("CellID",j,(imageNr*1000)+i+1);
		count++;
		sumareaSpots53BP1 = sumareaSpots53BP1 + getResult("Area",j);
		summeanSpots53BP1 = summeanSpots53BP1 + getResult("Mean",j);
		intDenSpots53BP1[i]=intDenSpots53BP1[i]+getResult("IntDen");
		
	}

	nSpots53BP1[i] = count;
	areaSpots53BP1[i] = sumareaSpots53BP1/count;
	avgIntensitySpots53BP1[i] = summeanSpots53BP1/count;
	SpotsPerArea53BP1[i] = count/Area53BP1[i];	
}


run("Read and Write Excel","stack_results no_count_column file=["+dirF+"Results\/53BP1Spots "+File.getName(dir)+".xlsx]");
run("Duplicate...", "duplicate");
roiManager("Show All without labels");
run("From ROI Manager");
saveAs("Tiff", dir+"ResultImages/Result53BP1_"+name);
close();

run("Clear Results");
roiManager("Reset");
Stack.setChannel(1);
run("Analyze Particles...", "size=Nuclmin-Nuclmax exclude include add slice");
roiManager("Remove Channel Info");
run("Clear Results");



//yH2AX spots
Stack.setChannel(2);
roiManager("Measure");
AreayH2AX = newArray(nResults);
MeanyH2AX = newArray(nResults);
StdyH2AX = newArray(nResults);
nSpotsyH2AX = newArray(nResults);
areaSpotsyH2AX = newArray(nResults);
avgIntensitySpotsyH2AX = newArray(nResults);
intDenSpotsyH2AX =newArray(nResults);
SpotsPerAreayH2AX =newArray(nResults);

for (i=0;i<nResults;i++){
	AreayH2AX[i] = getResult("Area",i);
	MeanyH2AX[i] = getResult("Mean",i);
	StdyH2AX[i] = getResult("StdDev",i);
}
run("Clear Results");
start =0;
end= roiManager("Count");


for (i=0; i<end; i++){
	roiManager("Select", i);
	start = nResults;
	Threshold = MeanyH2AX[i]+factor[1]*StdyH2AX[i];
	if (Threshold<minThreshold[1]) Threshold=minThreshold[1]; 
	if (Threshold>maxThreshold[1]) Threshold=maxThreshold[1];
	setThreshold(Threshold,255);
	run("Analyze Particles...", "size="+Spotmin[1]+"-"+Spotmax1[1]+" show=Masks include slice");
	run("Grays");
	run("Adjustable Watershed", "tolerance=.1");
	imageCalculator("AND", "Mask of "+name,name);
	setThreshold(Threshold,255);
	run("Analyze Particles...", "size="+Spotmin[1]+"-"+Spotmax2[1]+" display include slice add");
	close();
	count = 0;
	summeanSpotsyH2AX = 0;
	sumareaSpotsyH2AX = 0;
	for (j=start; j<nResults; j++){
		setResult("nCel",j,i+1);
		setResult("CellID",j,(imageNr*1000)+i+1);
		count++;
		sumareaSpotsyH2AX = sumareaSpotsyH2AX + getResult("Area",j);
		summeanSpotsyH2AX = summeanSpotsyH2AX + getResult("Mean",j);
		intDenSpotsyH2AX[i]=intDenSpotsyH2AX[i]+getResult("IntDen");
		
	}

	nSpotsyH2AX[i] = count;
	areaSpotsyH2AX[i] = sumareaSpotsyH2AX/count;
	avgIntensitySpotsyH2AX[i] = summeanSpotsyH2AX/count;
	SpotsPerAreayH2AX[i] = count/AreayH2AX[i];
	
}
run("Read and Write Excel","stack_results no_count_column file=["+dirF+"Results\/yH2AXSpots "+File.getName(dir)+".xlsx]");
run("Clear Results");

for (i=0; i<end; i++){

	//DAPI
	setResult("CellID",i,(imageNr*1000)+i+1);
	setResult("nCel",i,i+1);
	setResult("AreaNuclei",i, Area53BP1[i]);

	//53BP1
	setResult("Mean53BP1Nuclei", i, Mean53BP1[i]);
	setResult("Std53BP1Nuclei",i, Std53BP1[i]);
	tr=Mean53BP1[i]+factor[0]*Std53BP1[i];
	if (tr<minThreshold[0]) tr=minThreshold[0];
	if (tr>maxThreshold[0]) tr=maxThreshold[0];
	setResult("Threshold53BP1",i, tr);
	setResult("53BP1Spots",i, nSpots53BP1[i]);
	setResult("AvgArea53BP1Spots",i, areaSpots53BP1[i]);
	setResult("AvgIntensity53BP1Spots",i, avgIntensitySpots53BP1[i]);
	setResult("IntDen53BP1Spots",i,intDenSpots53BP1[i]);
	setResult("53BP1SpotsPerArea",i,SpotsPerArea53BP1[i]);

	//yH2AX
	setResult("MeanyH2AXNuclei", i, MeanyH2AX[i]);
	setResult("StdyH2AXNuclei",i, StdyH2AX[i]);
	tr=MeanyH2AX[i]+factor[1]*StdyH2AX[i];
	if (tr<minThreshold[1]) tr=minThreshold[1];
	if (tr>maxThreshold[1]) tr=maxThreshold[1];
	setResult("ThresholdyH2AX",i, tr);
	setResult("yH2AXSpots",i, nSpotsyH2AX[i]);
	setResult("AvgAreayH2AXSpots",i, areaSpotsyH2AX[i]);
	setResult("AvgIntensityyH2AXSpots",i, avgIntensitySpotsyH2AX[i]);
	setResult("IntDenyH2AXSpots",i,intDenSpotsyH2AX[i]);
	setResult("yH2AXSpotsPerArea",i,SpotsPerAreayH2AX[i]);

	//EdU
	Array.print(MeanEdU);
	setResult("EdUIntensity",i,MeanEdU[i]);
	setResult("EdU +/-",i,eduPos[i]);
	
}
run("Read and Write Excel","stack_results no_count_column file=["+dirF+"Results\/Nuclei "+File.getName(dir)+".xlsx]");
roiManager("Show All without labels");
run("From ROI Manager");
saveAs("Tiff", dir+"ResultImages/ResultyH2AX_"+name);


		run("Close All");
		run("Clear Results");
		roiManager("Reset");

	} // END IF MAIN LOOP
}// END FOR MAIN LOOP

}// END Super For loop
// End log file and save in result images directory
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print("End: ",hour+":"+minute+":"+second);
print("---------------------------------------------------------");
print("Macro ended correctly");
selectWindow("Log");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
saveAs("Text",dirF+"Results\Log_"+macroName+"_"+dayOfMonth+"_"+month+1+"_"+year+".txt");
