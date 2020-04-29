This Dropbox folder contains EEG preprocessing and analysis scripts use for the Social EEG project. Actual data files will not be available here, but on Box instead. We will not be running preprocessing in the Dropbox directory. Instead, each person would copy these files into their local directory (e.g. MATLAB folder on their computer), download the raw data files from Box, and run preprocessing locally. Once preprocessing is complete, 

calculatePower: contains scripts and functions for calculating frequency band power. 

plotPowerCorrelations: contains scripts and functions for plotting frequency band power correlations between subjects in a dyad. 

preprocessEEG: contains scripts and functions for preprocessing raw EEG data. Currently the usable raw data is in .set and .fdt format. 

processed_data, raw_data: these folders is empty and will remain this way on Dropbox. You can copy these when you first set up your local directory. The raw data you download from Box will go into "raw_data", and the intermediary files you generate throughout preprocessing will be stored in processed_data. 

Wearable_Sensing_manuals: this folder contains assorted resources provided by Wearable Sensing, who makes the headsets we record from. Aside from the various resources on Google Docs, please refer to these guides if you have any questions about equipment, software, etc. 

eeglab2019_1.zip: This is the same file I sent previously in my MATLAB installation email. If you didn't do that step last time, you can use this zip instead. the unzipped folder needs to be in your MATLAB/ directory. 

Note: I have not written READMEs for the actual preprocessing/analysis scripts themselves, but they will come eventually as we progress through preprocessing together. Thanks for being patient in the meantime! If you have any questions, please contact Amy Zou (amyzou@berkeley.edu). 