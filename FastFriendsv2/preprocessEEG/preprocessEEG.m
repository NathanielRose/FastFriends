%% EEG Preprocessing Script written for the Social EEG Project.  
% Original script: written by Anne Collins. 
% Contributors to original script: Beth Baribault, Brooke Staveland, Sarah
% Master. 
% Most recent contributor to script: Amy Zou (amyzou@berkeley.edu).

%% Import and prepare raw data for artifact rejection and ICA
% 1. Clean workspace and set paths 
clc
clear 
close all

% set paths:
homePath = '~/Desktop/Research/Berkeley/Yartsev/Fast-Friends/FastFriendsv2/preprocessEEG/'; % where the code lives
cd(homePath);

% set paths;
dataPath = '~/Desktop/Research/Berkeley/Yartsev/Fast-Friends/FastFriendsv2/eeg_data/'; % where raw data lives

% add eeglab and needed plugins
eeglabPath = '~/Desktop/Research/Berkeley/Yartsev/Fast-Friends/eeglab2019_1/';
addpath(genpath(eeglabPath)); % where eeglab lives  
capLocation=[eeglabPath,'plugins/dipfit/standard_BESA/standard-10-5-cap385.elp']; % cap info

% 2. Enter information of the subject to preprocess
% provide the subject ID, and block # if there is one (only for pilot data)

blocksAlreadyExtracted = 0;

subID = input('Enter the subject ID for the raw file to process: ','s'); % 040320_A
subFolder = [subID,'/'];

block = input(['If the raw file is specific to a block, enter the block ',... % 3
    'number (1-3). Otherwise press enter: '],'s');
if ~isempty(block)
    blocksAlreadyExtracted = 1;
    blockFolder = ['block_',block,'/'];
    mkdir([dataPath,subFolder,blockFolder]);
else
    block = '';
    blockFolder = '';
end
mkdir([dataPath,subFolder]);


% 3. Set channel-related index values

% total number of starting electrodes
numElec = 19;

% set electrode channel indices for externals and re-references
externalLoc = [16 17 20]; 
rerefLoc = [9 18]; 

% don't use A2 as reference for bad headset (temporary)
if contains(subID,'B') && ~contains(subID,'120519')
    externalLoc = [16 17 20 21]; 
    rerefLoc = 9; 
end

% set times to extract 15 minute block for 3 blocks
preOnsetTime = -5; 
blockDuration = 900; 
blocks = 1:3;

% set trigger values
triggers = {'1','5','8'}; 

% initialize EEGlab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% 4. Import raw data (.csv) format via EEGLAB -- skip for now
% EEG = pop_WearableSensing([dataPath,subID,'.csv']); 
% EEG = pop_saveset(EEG,'filename',[subID,'.set'],'filepath',[dataPath,subFolder]); 
    
% 5. Add cap locations, remove external electrodes, re-reference to A1 (and A2)

% load the imported raw data (pilot data in .set/.fdt format)
EEG = pop_loadset('filename',[subID,'.set'],'filepath',dataPath);

EEG = pop_chanedit(EEG,'lookup', capLocation); % add cap locations
EEG = pop_select(EEG, 'nochannel', externalLoc); % remove external channels
EEG = pop_reref(EEG,rerefLoc); % re-reference to A1 (and A2) 
    
% 6. Filter: high-pass above 0.1Hz and notch-filter at 60Hz and 120Hz

dims = size(EEG.data);

% high pass at 0.1Hz (for now)
FILT = pop_eegfiltnew(EEG,0.1,0);
disp('Highpass filtering at 0.1Hz complete.');

%notch filter at 60Hz and 120Hz 
d60 = designfilt('bandstopiir','FilterOrder',10, ...
               'HalfPowerFrequency1',59.5,'HalfPowerFrequency2',60.5, ...
               'DesignMethod','butter','SampleRate',EEG.srate);

d120 = designfilt('bandstopiir','FilterOrder',10, ...
               'HalfPowerFrequency1',119.5,'HalfPowerFrequency2',120.5, ...
               'DesignMethod','butter','SampleRate',EEG.srate);

FILT = filtfilt(d60,double(EEG.data'));
FILT = filtfilt(d120,double(FILT))';
disp('Notch filtering at 60 and 120 Hz complete.');

% reshape the data after filtering is done
EEG.data = reshape(FILT,dims(1),dims(2));
    
% 7. Divide the 45min dataset into three 15min datasets (for each block)
% this will get skipped for now since "raw" files are already blocked

if ~blocksAlreadyExtracted % if blocks were NOT extracted in the raw file

%     EEG = pop_loadset('filename',[subID,'_filtered.set'],'filepath',[procDataPath,subFolder]);

    % create 15min epochs around '1' triggers and save this 3-epoch dataset
    EEG = pop_epoch( EEG, '1', [preOnsetTime blockDuration]);  
    save([dataPath,subFolder,subID,'_epoched.mat'],'EEG');

    % for each block
    for b = blocks 

        % load the previously saved 3-epoch dataset
        load([dataPath,subFolder,subID,'_epoched.mat']);
        
        % extract the epoch by rejecting all other epochs
        otherBlocks = ones(1,length(blocks));
        otherBlocks(b) = 0;
        EEG = pop_rejepoch(EEG,otherBlocks,0); 

        % save this block as a dataset
        blockFolder = ['block_',num2str(b),'/'];
        subFilePath = [dataPath,subFolder,blockFolder];
        mkdir(subFilePath);
        subIDBlock = [subID,'_block_',num2str(b)];
        save([subFilePath,subIDBlock,'_epoched.mat'],'EEG');

    end
end

% 8. manually create 2s epochs for each 15 minute block

if ~blocksAlreadyExtracted 
    for b = blocks  
        subIDBlock = [subID,'_block_',num2str(b)];
        load([subFilePath,subIDBlock,'_epoched.mat']);
        createManualEpochs(EEG, subIDBlock, blockFolder);
    end
else
    subIDBlock = [subID,'_block_',num2str(block)];
    subFilePath = [dataPath,subFolder,blockFolder];
    EEG = createManualEpochs(EEG,subIDBlock,subFilePath);
    [ALLEEG,EEG,CURRENTSET] = eeg_store(ALLEEG,EEG,CURRENTSET); %adds to ALLEEG

    disp(['Epoched data saved for ',subIDBlock,'.']);

    pop_eegplot( EEG, 1, 1, 0, [], 'color','on');
end  


%% Artifact Rejection and ICA
% 9. Set-up subject and block information for artifact rejection

subID = input('Which subject are you processing? ','s');
block = input('Which block are you processing? ','s');

% if you've already cleaned a round and want to reference removed data
if exist('doAnotherRound') 
    loadOldRejected = prompt('Do you want to load the rejected data from your previous run (y/n)? ','s');
    if strcmp(loadOldRejected,'y')
        oldRejectedData = load([subFilePath,subIDBlock,'_rejected_run_',num2str(doAnotherRound),'.mat']);
    end
end

dataPath = '~/Desktop/Research/Berkeley/Yartsev/Fast-Friends/FastFriendsv2/eeg_data/'; % where data lives
subFolder = [subID,'/'];
blockFolder = ['block_',block,'/'];
subIDBlock = [subID,'_block_',block];
subFilePath = [dataPath,subFolder,blockFolder];

load([subFilePath,subIDBlock,'_epoched.mat']);
EEG = eeg_checkset(EEG);
EEG = pop_rmbase(EEG,[],[]); % removes baseline activity


pop_eegplot( EEG, 1, 1, 0, [], 'color','on');


% 10. Pre-ICA: interpolate bad channels

% Grab channel names
chanNames = getChannelNames(EEG);

% FYI 'z' and 'p' in 'Fp' only are always lowercase
toInterp={}; 
whichToInterp = input(['Enter the name of the channel you want to ',....
'interpolate. FYI p in Fp1/Fp2 are lowercase, z is always lowercase: '],'s');
while ~isempty(whichToInterp)
    toInterp = [toInterp,whichToInterp];
    whichToInterp = input(['Enter the name of another channel you want ',...
        'to interpolate, or press enter to finish: '],'s');
end

% prepare channels to interpolate
for i = 1:length(toInterp)
    ENTER_CHANNEL(i) = find(strcmp(toInterp(i),chanNames)); 
end
if isempty(toInterp)
    ENTER_CHANNEL = [];
    
end

% interpolate
EEG = interpolateBadChans(EEG,toInterp);
save([subFilePath,subIDBlock,'_rejected.mat'],'toInterp'); % save interpolated channels

% double check if this avg ref is needed if already rerefed at earlobes?
% EEG = pop_reref( EEG, []); 


% 11. Pre-ICA: reject bad epochs
pop_eegplot( EEG, 1, 1, 0, [], 'color','on');
disp(['Once you have selected epochs to reject and clicked "Update Marks" and "OK",',...
    'Press enter in the command window to continue']);
pause

% store indices of bad epochs you rejected in the GUI
toReject = find(EEG.reject.rejmanual); 

% track bad pre-ICA epochs based on their original indices
epochNumbers = 1:EEG.trials;
epochNumbers(toReject)=[]; 

EEG = rejectBadEpochs(EEG,toReject);

disp('Data cleaned and interpolated.')

% save data with rejected epochs and interpolated channels
save([subFilePath,subIDBlock,'_preICA.mat'],'EEG','epochNumbers','chanNames');
save([subFilePath,subIDBlock,'_rejected.mat'],'toReject','-append');

disp('Pre-ICA data saved.');

%% ICA

load([subFilePath,subIDBlock,'_preICA.mat'],'EEG','epochNumbers');
load([subFilePath,subIDBlock,'_rejected.mat']);

channels = 1:EEG.nbchan;
idx = ismember(channels,ENTER_CHANNEL);
channels(idx) = [];

% 12. Run ICA

tic
EEG = pop_runica(EEG, 'chanind',channels);
toc

disp('ICA finished. Saving now.')
save([subFilePath,subIDBlock,'_ICA.mat'],'EEG','epochNumbers'); 
disp('Saving finished.')

% 13. Display ICA components from previous step

load([subFilePath,subIDBlock,'_ICA.mat'],'EEG','epochNumbers'); 

disp(['Plotting components for subject ' num2str(subIDBlock)])
disp(['When you have finished selecting components for removal, ',...
    'press enter in the command window.'])

% display topoplot and component scroll
pop_selectcomps(EEG, 1:size(EEG.icaweights,1)); 
pop_eegplot(EEG,0,1,1); 

% 14. remove ICA components
pause

toICARemove=find(EEG.reject.gcompreject == 1); 
EEG = pop_subcomp(EEG,toICARemove,1); 

% re-interpolate bad channels
EEG = interpolateBadChans(EEG,toInterp);
EEG = eeg_checkset(EEG);
disp('ICA components removed.')

pop_eegplot( EEG, 1, 1, 0,[],'color','on');

save([subFilePath,subIDBlock,'_rejected.mat'],'toICARemove','-append');
save([subFilePath,subIDBlock,'_ICA_x.mat'],'EEG','epochNumbers');


%% Post-ICA artifact rejection
% 15. Look for channels with aberrant epochs

load([subFilePath,subIDBlock,'_ICA_x.mat'],'EEG','epochNumbers');

% 16. Investigate channels with aberrant epochs
plotEpochsPerChannel(EEG);

% 17. Remove bad epochs just identified
pop_eegplot( EEG, 1, 1, 0, [], 'color','on');

disp(['Once you have selected epochs to reject and clicked "Update Marks" and "OK",',...
    'Press enter in the command window to continue']);
pause

toRejectSecond = find(EEG.reject.rejmanual); 

% track bad post-ICA epochs based on their original indices and add them to all bad epochs
toRejectAll = [toReject epochNumbers(toRejectSecond)]; 


disp(['Rejecting: ' num2str(toRejectSecond)])
EEG = rejectBadEpochs(EEG,toRejectSecond);

disp(['Post-ICA cleaning save complete. Rejected epoch numbers, channels, ',...
    'and ICA components from this round are saved.']);
save([subFilePath,subIDBlock,'_rejected.mat'],'toRejectSecond','toRejectAll','-append');
save([subFilePath,'_postICA.mat']);

% 18. Indicate whether this data set needs to be recleaned
spit = input('Do you need to do another round of cleaning? y or n ', 's');

if strcmp(spit,'y')
    
    if ~exist(doAnotherRound)
        doAnotherRound = 1;
    else
        doAnotherRound = doAnotherRound + 1;
    end
    
    disp(['Start from start of Pre-ICA and do another round of cleaning for this ',...
        'subject. You can load the rejected items from this run for reference.']);
    copyfile([subFilePath,subIDBlock,'_rejected.mat'],...
             [subFilePath,subIDBlock,'_rejected_run_',num2str(doAnotherRound),'.mat'])
    

elseif strcmp(spit,'n') % if no additional round needed
    
    disp('You are ready to combine rejection info for both subjects and do a synced clean.')

end

%% Synced artifact rejection and ICA starts below
% go through the pre-ICA cleanup, except you will combine indices of
% rejected epochs between the two subjects. run this once for each subject.

% DO NOT need to interpolate each others channels or remove shared ICA components

% 19. Synced set-up subject and block information for artifact rejection. 

% define subject and block for cleaning
subID = input('Which subject are you processing? ','s');
block = input('Which block are you processing? ','s');

dataPath = '/Users/amyzou/Documents/MATLAB/FF/eeg_data/'; % where data lives
subFolder = [subID,'/'];
blockFolder = ['block_',block,'/'];
subIDBlock = [subID,'_block_',block];
subFilePath = [dataPath,subFolder,blockFolder];

% automatically get name of partner
if contains(subID,'A')
    otherSubID = [subID(1:7),'B'];
else
    otherSubID = [subID(1:7),'A'];
end

otherSubFolder = [otherSubID,'/'];
otherSubIDBlock = [otherSubID,'_block_',block]; 
otherSubFilePath = [dataPath,otherSubFolder,blockFolder,otherSubIDBlock];

load([subFilePath,subIDBlock,'_epoched.mat']);
EEG = eeg_checkset( EEG );
EEG = pop_rmbase(EEG,[],[]); % removes baseline activity

% Grab channel names
chanNames = getChannelNames(EEG);

% eeglab redraw - idk why this breaks sometimes?
pop_eegplot( EEG, 1, 1, 0, [], 'color','on');


% 20. Pre-Sync Pre-ICA: interpolate bad channels

% manually fill this in
load([subFilePath,subIDBlock,'_rejected.mat'],'toInterp');

% prepare channels to interpolate
for i = 1:length(toInterp)
    ENTER_CHANNEL(i) = find(strcmp(toInterp(i),chanNames)); 
end
if isempty(toInterp)
    ENTER_CHANNEL = [];
end

EEG = interpolateBadChans(EEG,toInterp);

% re-ref after interpolation -- double check
% EEG = pop_reref( EEG, []);

% % replot
pop_eegplot( EEG, 1, 1, 0, [], 'color','on');

% 21. Synced Pre-ICA: reject all bad epochs between partners
sub_rejected = load([subFilePath,subIDBlock,'_rejected.mat']);
otherSub_rejected = load([otherSubFilePath,'_rejected.mat']);

% find intersection of rejected epochs between subs
toRejectSynced = union(sub_rejected.toRejectAll,otherSub_rejected.toRejectAll);

% find bad pre-ICA epochs based on their original indices
EEG.originalEpochNumbers = 1:EEG.trials;
epochNumbers = 1:EEG.trials; 
epochNumbers(toRejectSynced)=[]; 

EEG=rejectBadEpochs(EEG,toRejectSynced);

save([subFilePath,subIDBlock,'_rejected.mat'],'toRejectSynced','-append'); % save bad channels
save([subFilePath,subIDBlock,'_preICA_Synced.mat'],'EEG','epochNumbers');

disp('Synced data interpolated and cleaned.')


%% 22. Post-Sync ICA

load([subFilePath,subIDBlock,'_preICA_Synced.mat'],'EEG','epochNumbers'); 

channels = 1:EEG.nbchan;
idx = ismember(channels,ENTER_CHANNEL);
channels(idx) = [];

tic
EEG = pop_runica(EEG, 'chanind',channels);
toc

disp('ICA finished. Saving now.')
save([subFilePath,subIDBlock,'_ICASynced.mat'],'EEG','epochNumbers'); %gives an error if not saving in vers 7.3?
disp('Saving finished.')

% 23. Post-sync: Display ICA components 

load([subFilePath,subIDBlock,'_ICASynced.mat'],'EEG','epochNumbers'); %gives an error if not saving in vers 7.3?

disp(['Plotting components for subject ' num2str(subIDBlock)])
disp(['When you have finished selecting components for removal, ',...
    'press enter in the command window.'])

% display topoplot and component scroll
pop_selectcomps(EEG, 1:size(EEG.icaweights,1)); 
pop_eegplot(EEG,0,1,1); 

% 24. remove ICA components
pause

toICARemovePostSync=find(EEG.reject.gcompreject == 1); 
EEG = pop_subcomp(EEG,toICARemovePostSync,1); 

% re-interpolate bad channels
EEG = interpolateBadChans(EEG,toInterp);
 
EEG = eeg_checkset(EEG);
disp('ICA components removed.');

% re-interpolate bad channels
EEG=interpolateBadChans(EEG,toInterp);
EEG=eeg_checkset(EEG);

pop_eegplot( EEG, 1, 1, 0,[],'color','on');

save([subFilePath,subIDBlock,'_rejected.mat'],'toICARemovePostSync','-append');
disp('ICA components removed.');

save([subFilePath,subIDBlock,'_final.mat'],'EEG','epochNumbers');
disp('Saved final file.');

% 25. Cleaning stats

disp('Cleaning stats for ',subIDBlock,': ')

disp(['Number of epochs rejected, note in lab notebook: ' num2str(length(toRejectSynced))]);
disp(['Percentage of epochs rejected, note in lab notebook: ' num2str(length(toRejectSynced)/epochNumbers(end)*100) '%']);

disp(['Please upload ',subIDBlock,'_rejected.mat and ',subIDBlock,'_final.mat ',...
    'to Box. You can go ahead and delete the intermediary files.']);