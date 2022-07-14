/*
 * Foci Counter + EdU measurement and labeling (v0.9)
 * This macro was build upon Gert's foci counting macro based on the mean + factor * SD threshold method of Adriaan
 * This version includes the measurement of the EdU signal, allowing for the comparison of foci counts to total EdU signal in the cell.
 * EdU is measured by taking the total average EdU signal of the nucleus' area based on the DAPI signal, therefore the signal value should not be skewed by nucleus size. 
 * ------------------------------------------------------------------------------------
 * ------------------------------------------------------------------------------------
 * Original macro created by Gert van Capellen
 * Edited to include EdU measurement by Sean Holst
 */

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

// Prot1,Prot2
macroName="Batch_";
minThreshold=newArray(70,50); // Minimal threshold
maxThreshold=newArray(100,150); // Maximal threshold
factor =newArray(1.4,0.8); //factor*std voor threshold!
Nuclmin= 60; //minimal nucleus size
Nuclmax=400; //maximal nucleus size
Spotmin=newArray(0.2,0.1); //minimal spotsize
Spotmax1=newArray(30,40); //maximal spotsize before watershed
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

// Super for loop: To process the entire experiment
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


// set DAPI channel
Stack.setChannel(1);
Stack.setActiveChannels("100");
run("Gaussian Blur...", "sigma=1 slice"); 

run("Convert to Mask", "method=Huang background=Dark only black");

run("Invert","slice"); 						


// default tolerance=0.5
run("Adjustable Watershed", "tolerance=0.5 slice");

run("Set Measurements...", "area mean integrated standard stack redirect=None decimal=3");
run("Analyze Particles...", "size=Nuclmin-Nuclmax exclude include add slice");


roiManager("Remove Channel Info");


run("Clear Results");



// EdU check - loops through ROI on channel 3 and outputs the mean of each cell with 1 (positive) or 0 (negative) label
Stack.setChannel(2);
Stack.setActiveChannels("010");
run("Gaussian Blur...", "sigma=1 slice");	// blur to mitigate noise
nRoi = roiManager("Measure");
MeanEdU = newArray(nResults);
eduPos = newArray(nResults);
eduPosFoci = newArray(nResults);	
eduPosMean = newArray(nResults);
eduNegFoci = newArray(nResults); 
eduNegMean = newArray(nResults);
iPos = 0;
iNeg = 0;

for(i = 0; i < nResults; i++) {
	Stack.setChannel(2);
	roiManager("select", i);
	getStatistics(area, mean, min, max, std, histogram);
	setResult("EdUMean", i, mean);
	
	// Label EdU positive or negative based on EdU mean
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

roiManager("Remove Channel Info");
roiManager("Reset");
Stack.setChannel(1);
run("Select None"); 	// Deselects last ROI on image to prevent errors
run("Analyze Particles...", "size=Nuclmin-Nuclmax exclude include add slice");
roiManager("Remove Channel Info");
run("Clear Results");


// Prot1 spots
Stack.setChannel(3);
Stack.setActiveChannels("003");
roiManager("Measure");
AreaProt1 = newArray(nResults);
MeanProt1 = newArray(nResults);
StdProt1 = newArray(nResults);
nSpotsProt1 = newArray(nResults);
areaSpotsProt1 = newArray(nResults);
avgIntensitySpotsProt1 = newArray(nResults);
intDenSpotsProt1 =newArray(nResults);
SpotsPerAreaProt1 =newArray(nResults);


for (i=0;i<nResults;i++){
	AreaProt1[i] = getResult("Area",i);
	MeanProt1[i] = getResult("Mean",i);
	StdProt1[i] = getResult("StdDev",i);
}
run("Clear Results");
start = 0;
end = roiManager("Count");

for (i=0; i<end; i++){
	roiManager("Select", i);
	start = nResults;
	Threshold = MeanProt1[i]+factor[0]*StdProt1[i];
	if (Threshold<minThreshold[0]) Threshold=minThreshold[0]; 
	if (Threshold>maxThreshold[0]) Threshold=maxThreshold[0];
	setThreshold(Threshold,255);
	run("Analyze Particles...", "size="+Spotmin[0]+"-"+Spotmax1[0]+" show=Masks include slice");
	run("Adjustable Watershed", "tolerance=.1");
	imageCalculator("AND", "Mask of "+name,name);
	setThreshold(Threshold,255);
	run("Analyze Particles...", "size="+Spotmin[0]+"-"+Spotmax2[0]+" display include slice add");
	close();
	count = 0;
	summeanSpotsProt1 = 0;
	sumareaSpotsProt1 = 0;
	for (j=start; j<nResults; j++){
		setResult("nCel",j,i+1);
		setResult("CellID",j,(imageNr*1000)+i+1);
		count++;
		sumareaSpotsProt1 = sumareaSpotsProt1 + getResult("Area",j);
		summeanSpotsProt1 = summeanSpotsProt1 + getResult("Mean",j);
		intDenSpotsProt1[i]=intDenSpotsProt1[i]+getResult("IntDen");
		
	}

	nSpotsProt1[i] = count;
	areaSpotsProt1[i] = sumareaSpotsProt1/count;
	avgIntensitySpotsProt1[i] = summeanSpotsProt1/count;
	SpotsPerAreaProt1[i] = count/AreaProt1[i];	
}


run("Read and Write Excel","stack_results no_count_column file=["+dirF+"Results\/Prot1Spots "+File.getName(dir)+".xlsx]");
run("Duplicate...", "duplicate");
roiManager("Show All without labels");
run("From ROI Manager");
saveAs("Tiff", dir+"ResultImages/ResultProt1_"+name);
close();

run("Clear Results");
roiManager("Reset");
Stack.setChannel(1);
run("Analyze Particles...", "size=Nuclmin-Nuclmax exclude include add slice");
roiManager("Remove Channel Info");
run("Clear Results");


// Prot2 spots
Stack.setChannel(2);
roiManager("Measure");
AreaProt2 = newArray(nResults);
MeanProt2 = newArray(nResults);
StdProt2 = newArray(nResults);
nSpotsProt2 = newArray(nResults);
areaSpotsProt2 = newArray(nResults);
avgIntensitySpotsProt2 = newArray(nResults);
intDenSpotsProt2 =newArray(nResults);
SpotsPerAreaProt2 =newArray(nResults);

for (i=0;i<nResults;i++){
	AreaProt2[i] = getResult("Area",i);
	MeanProt2[i] = getResult("Mean",i);
	StdProt2[i] = getResult("StdDev",i);
}
run("Clear Results");
start =0;
end= roiManager("Count");


for (i=0; i<end; i++){
	roiManager("Select", i);
	start = nResults;
	Threshold = MeanProt2[i]+factor[1]*StdProt2[i];
	if (Threshold<minThreshold[1]) Threshold=minThreshold[1]; 
	if (Threshold>maxThreshold[1]) Threshold=maxThreshold[1];
	setThreshold(Threshold,255);
	run("Analyze Particles...", "size="+Spotmin[1]+"-"+Spotmax1[1]+" show=Masks include slice");
	run("Adjustable Watershed", "tolerance=.1");
	imageCalculator("AND", "Mask of "+name,name);
	setThreshold(Threshold,255);
	run("Analyze Particles...", "size="+Spotmin[1]+"-"+Spotmax2[1]+" display include slice add");
	close();
	count = 0;
	summeanSpotsProt2 = 0;
	sumareaSpotsProt2 = 0;
	for (j=start; j<nResults; j++){
		setResult("nCel",j,i+1);
		setResult("CellID",j,(imageNr*1000)+i+1);
		count++;
		sumareaSpotsProt2 = sumareaSpotsProt2 + getResult("Area",j);
		summeanSpotsProt2 = summeanSpotsProt2 + getResult("Mean",j);
		intDenSpotsProt2[i]=intDenSpotsProt2[i]+getResult("IntDen");
		
	}

	nSpotsProt2[i] = count;
	areaSpotsProt2[i] = sumareaSpotsProt2/count;
	avgIntensitySpotsProt2[i] = summeanSpotsProt2/count;
	SpotsPerAreaProt2[i] = count/AreaProt2[i];
	
}
run("Read and Write Excel","stack_results no_count_column file=["+dirF+"Results\/Prot2Spots "+File.getName(dir)+".xlsx]");
run("Clear Results");

for (i=0; i<end; i++){

	//DAPI
	setResult("CellID",i,(imageNr*1000)+i+1);
	setResult("nCel",i,i+1);

	//Prot1
	setResult("MeanProt1Nuclei", i, MeanProt1[i]);
	setResult("StdProt1Nuclei",i, StdProt1[i]);
	tr=MeanProt1[i]+factor[0]*StdProt1[i];
	if (tr<minThreshold[0]) tr=minThreshold[0];
	if (tr>maxThreshold[0]) tr=maxThreshold[0];
	setResult("ThresholdProt1",i, tr);
	setResult("Prot1Spots",i, nSpotsProt1[i]);
	setResult("AvgAreaProt1Spots",i, areaSpotsProt1[i]);
	setResult("AvgIntensityProt1Spots",i, avgIntensitySpotsProt1[i]);
	setResult("IntDenProt1Spots",i,intDenSpotsProt1[i]);
	setResult("Prot1SpotsPerArea",i,SpotsPerAreaProt1[i]);

	//Prot2
	setResult("MeanProt2Nuclei", i, MeanProt2[i]);
	setResult("StdProt2Nuclei",i, StdProt2[i]);
	tr=MeanProt2[i]+factor[1]*StdProt2[i];
	if (tr<minThreshold[1]) tr=minThreshold[1];
	if (tr>maxThreshold[1]) tr=maxThreshold[1];
	setResult("ThresholdProt2",i, tr);
	setResult("Prot2Spots",i, nSpotsProt2[i]);
	setResult("AvgAreaProt2Spots",i, areaSpotsProt2[i]);
	setResult("AvgIntensityProt2Spots",i, avgIntensitySpotsProt2[i]);
	setResult("IntDenProt2Spots",i,intDenSpotsProt2[i]);
	setResult("Prot2SpotsPerArea",i,SpotsPerAreaProt2[i]);

	//EdU
	Array.print(MeanEdU);
	setResult("EdUIntensity",i,MeanEdU[i]);
	setResult("EdU +/-",i,eduPos[i]);
	
}
run("Read and Write Excel","stack_results no_count_column file=["+dirF+"Results\/Nuclei "+File.getName(dir)+".xlsx]");
roiManager("Show All without labels");
run("From ROI Manager");
saveAs("Tiff", dir+"ResultImages/ResultProt2_"+name);


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
