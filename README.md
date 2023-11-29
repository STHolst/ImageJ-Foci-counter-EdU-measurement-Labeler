# Foci Counter w/ EdU signal measurement & labeling
- This ImageJ macro uses the 'mean + factor * SD' method established in *Royen et al. 2007, JCB* to count the foci of two channels in individual nuclei, and labels each cell EdU+ or EdU-, based on the mean EdU signal per nucleus. 

- This an edited version of the foci counting macro created by Gert van Cappellen, of the Erasmus MC's Optical Imaging Center (OIC), and has been published with his permission.

# How to use
### 1. Open the macro in ImageJ and edit the variables as needed
* Optimization of the settings below is essential to gain reliable data from your images. The default settings should be considered nothing more than a placeholder, or a starting point for optimization.
</br>

* **minThreshold & maxThreshold** determines the baseline for the minimum and maximum intensity to be detected as a focus
* **maxThreshold** determines the baseline for the maximum intensity to be detcted as a focus
* **factor** determines the factor in the 'mean + factor * SD' equation
* **Nuclmin & Nuclmax** determine the minimum and maximum nucleus size to be segmented
* **Spotmin** determines the minimum focus size to be detected and segmented
* **Spotmax1 & Spotmax2** determinue the maximum focus size before and after watershedding respectively.

### 2. Select the directory of the images you want to process
* This macro uses a 'superloop' to repeat the macro over several folders - this means you need to select the folder 'above' the folder that contains your images
* i.e. if your data is structured like this: "*/data/**experiment1**/condition1/image1.TIF*" you need to select the "***experiment1***" folder as your directory, rather than "*condition1*", because the macro will search for images, within folders of the selected directory, rather than searching for images directly within the selected directory. 
* This allows you to run the macro on several conditions structured in separate folders.
* Only .TIF files are supported.

### 3. Run the macro
* Depending on the number of images and cells to process, this may take a while. Do not use your keyboard while the macro runs, as any keyboard input can be interpreted by Fiji/ImageJ and might disturb the process.

### 4. Examine the results and optimize the settings if necessary.
* The data will be exported to the Results folder in your selected directory. <br> (i.e. "*/data/experiment1/**Results***")
* The result images are exported to ResultImages folder in the subfolders of your selected directory </br> (i.e. "*/data/experiment1/condition1/**ResultImages***") 
* Examine the images in ***ResultImages*** and see if the macro detection is accurate. It's advised to take a sample and do a foci count by eye, and compare this to the macro's results.
