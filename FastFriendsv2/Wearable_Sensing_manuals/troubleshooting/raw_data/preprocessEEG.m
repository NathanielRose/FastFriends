%% clean workspace and set paths 

clc
clear all
close all

% set paths 

capLocation=('/Users/glass/Documents/MATLAB/eeglab2019_1/plugins/dipfit/standard_BESA/standard-10-5-cap385.elp'); % cap info
addpath(genpath('/Users/glass/Documents/MATLAB/eeglab2019_1')); % throws Warnings about same-name functions

homepath = ('/Users/glass/Documents/MATLAB/FF/code/'); % where the scripts are
cd(homepath);

rawdatapath = ('/Users/glass/Documents/MATLAB/FF/raw_data/'); % where the raw data lives
procdatapath =  ('/Users/glass/Documents/MATLAB/FF/processed_data/'); % where the processed data lives

subID = '021920-A'; % subject ID (format of MMDDYY-A or MMYYDD-B)

isNewSubj = 1; % are we importing this subj's data into eeglab for the first time? 

subFolder = [subID,'/'];
mkdir(procdatapath,subFolder);


[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%% set channel related index values

numElec = 19;

% set indicies for channels to remove
externalLoc = [16 17 20]; %indices of externals
rerefLoc = [9 18]; %A1 and A2 respectively, after removing externals

if strfind(subID,'B') % if this is subj B, whose headset has broken A2 
    externalLoc = [16 17 20 21]; %indices of externals + A2 bc broken
    rerefLoc = [9]; % only rerefernce with A1
end

%% Load and prepare the raw 45-minute data (only if importing the first time)

if isNewSubj
    %% load the raw .set file -- this is still done manually
    keyboard
    EEG = DSI_to_MATLAB([rawdatapath,subID,'.csv']);
    EEG = pop_loadset('filename',[subID,'.set'],'filepath',rawdatapath); 
    EEG = pop_chanedit(EEG,'lookup', capLocation) % add channel locations
    EEG = pop_select(EEG, 'nochannel', externalLoc)% remove externals X1/2/3
    EEG = pop_reref(EEG,rerefLoc)% re-reference to A1/A2 (except for the broken one)

    % save this referenced set in Subj folder
    EEG = pop_saveset(EEG,'filename',[subID,'_rereferenced.set'],'filepath',[procdatapath,subFolder]);
    disp('Rereferenced data saved.');
    pop_eegplot( EEG, 1, 1, 1);
    
    %% filter before epoching using eeglab-specific/relevant fns
    % lowpass filter below 200Hz - filtfilt or eegfilt
    % eegfilt uses filtfilt

    dims = size(EEG.data);
    % do not need to lowpass since we are already filtering at 150Hz?
    % FILT=eegfilt(EEG.data,EEG.srate,[],200); % uses 3rd-order FIR filter, should this be 10th-order instead?

    % notch filter at 60Hz and 120Hz 
    % EEG=cleanline(EEG); % use cleanline to notch filter at 60, 120 Hz
    d60 = designfilt('bandstopiir','FilterOrder',10, ...
                   'HalfPowerFrequency1',59.5,'HalfPowerFrequency2',60.5, ...
                   'DesignMethod','butter','SampleRate',EEG.srate);

    d120 = designfilt('bandstopiir','FilterOrder',10, ...
                   'HalfPowerFrequency1',119.5,'HalfPowerFrequency2',120.5, ...
                   'DesignMethod','butter','SampleRate',EEG.srate);

    FILT = filtfilt(d60,double(EEG.data'));
    FILT = filtfilt(d120,double(FILT))';
    
    % alternatively use eeglab in-house FIR filters
    

    % NOT highpassing -- for now
    % FILT=eegfilt(FILT,EEG.srate,.5,[]); % high pass filter above .5


    % after all filtering done
    EEG.data = reshape(FILT,dims(1),dims(2));
    pop_eegplot( EEG, 1, 1, 1);

    % save filtered set into subj folder
    EEG = pop_saveset(EEG,'filename',[subID,'_filtered.set'],'filepath',[procdatapath,subFolder]);
    disp('Filtered data saved.');
    
    %% extract 3 15-minute blocks from each 45 minute dataset

    triggers = {'1'}; % switch press marks start of a block
    % Extract epochs from the time series 
    EEG = pop_epoch( EEG, triggers, [-5 900]); % 5s before block start, 900s (15 min) after
    % idk how to do this part yet but 
    
    % ultimately should end up with 3 epochs (each 5s + 900s long)
     
    for b = 1:3
        subjFile = [subID,'_part_',num2str(b)];
        
        % save each individual 15 min epoch as a dataset
        save_loadset('filename',[subjFile,'_filtered.set'],'filepath',[procdatapath,subFolder]);
        
        % epoch the 15 min block into overlapping 5s epochs
        EEG = eeg_regepochs(EEG,'recurrence',2.5,'extractepochs','off') % create events at every 2.5s called 'X'
        EEG = pop_epoch(EEG,{'X'},[-2.5 2.5]) % extract epoch at 'X' from -2.5 before to 2.5 after 

        EEG = save_saveset(EEG,'filename',[subjFile,'_epoched.set'],'filepath',[procdatapath,subFolder]);
        disp(['Epoched data saved for ',subjFile]);
    end

end

%% pre-ICA cleaning set up

%declare block and load file for cleaning

block = 1; % set to 1, 2, or 3
subjFile = [subID,'_part_',block]; % files named after subj ID and the part #
EEG = pop_loadset('filename',[subjFile,'_epoched.set'],'filepath',[procdatapath,subFolder]);

subjFilePath = [procdatapath,subFolder,subjFile];

EEG = eeg_checkset( EEG );
EEG = pop_rmbase(EEG,[],[]); % removes baseline activity

% eeglab redraw - idk why this breaks sometimes?
pop_eegplot( EEG, 1, 1, 0, [], 'color','on');

% Grab channel names
chanNames = [];
for i = 1:EEG.nbchan %cycle through channels
    var = EEG.chanlocs(1,i).labels; % save channel names in table
    temp = compose(var);
    chanNames = [chanNames; temp];
end

%% interpolate bad channels

% manually fill this in
toInterp={};

% prepare channels to interpolate
df = EEG.nbchan - length(toInterp);
for i = 1:length(toInterp)
    ENTER_CHANNEL(i) = find(strcmp(toInterp(i),chanNames)); %% fix structural issues
end
if isempty(toInterp)
    ENTER_CHANNEL = [];
end

% Interpolate
badChans = [];
if ~isempty(toInterp)
    for xi=1:size(toInterp,2)
        for ei=1:EEG.nbchan
            if strmatch(EEG.chanlocs(ei).labels,toInterp{xi})
                badChans(xi)=ei;
            end
        end
    end
    EEG.data=double(EEG.data);
    EEG = pop_interp(EEG,badChans,'spherical');
end

disp(['Interpolated these channels:',toInterp]);
save([subjFilePath,'_rejected.mat'],'to_interp'); % save bad channels

% NOW re-ref after interpolation
EEG = pop_reref( EEG, []);

% % replot
pop_eegplot( EEG, 1, 1, 0, [], 'color','on');

%% reject epochs

toReject = find(EEG.reject.rejmanual); % store indices of bad epochs you rejected in the GUI

epochNumbers = [1:EEG.trials]; % track bad pre-ICA epochs based on their original indices
originalEpochNumbers = epochNumbers;
epochNumbers(toReject)=[]; % 

% Reject bad epochs
if ~isempty(toReject)
    binarized=zeros(1,EEG.trials);
    binarized(toReject)=1;
    EEG = pop_rejepoch(EEG,binarized,0);
end

save([subjFilePath,'_rejected.mat'],'toReject','-append');

%% save data with rejected epochs and interpolated channels

save([subjFilePath,'_preICA.mat'],'EEG','epochNumbers');
disp('Data cleaned and interpolated.')


%% ICA

load([subjFilePath,'_preICA.mat'],'EEG','epochNumbers'); 

if isempty(toInterp)
    ENTER_CHANNEL = [];
end

channels = [1:numElec];
idx = ismember(channels,ENTER_CHANNEL);
channels(idx) = [];

%Remove channels from list
tic
EEG = pop_runica(EEG, 'chanind',channels);
toc

disp('ICA finished. Saving now.')
save([subjFilePath,'_ICA.mat'],'EEG','epochNumbers'); %gives an error if not saving in vers 7.3?
disp('Saving finished.')

%% 4. Data reset, display the ICA components selected

clearvars -except subj_file_path channels

disp(['Cleaning subject ' num2str(subID)])

load([subjFilePath,'_ICA.mat'],'EEG','epochNumbers'); %gives an error if not saving in vers 7.3?

pop_selectcomps(EEG, 1:19); %Displays topoplots
pop_eegplot( EEG, 0, 1, 1); %Displays component scroll

%% remove ICA components

toICARemove=[]; % manually fill this in

EEG = pop_subcomp(EEG, toICARemove, 0); %Removes marked component

% Re-interpolate channels after removing bad components
if ~isempty(toInterp)
    for xi=1:size(toInterp,2)
        for ei=1:EEG.nbchan
            if strmatch(EEG.chanlocs(ei).labels,toInterp{xi});
                badChans(xi)=ei;
            end
        end
    end
    EEG.data=double(EEG.data);
    EEG = pop_interp(EEG,badChans,'spherical');
end
 
EEG = eeg_checkset( EEG );

ALLEEG=[];
% pop_eegplot( EEG, 1, 1, 1,'color','on');


EEG.toICARemove(run_num,:) = toICARemove;
save([subjFilePath,'_rejected.mat'],'toICARemove','-append');
disp('ICA components removed.')

save([subjFilePath,'_ICA_x.mat'],'EEG','epochNumbers');


%% 7. Post-ICA cleaning - plot each channel with all epochs overlaid

clearvars -except subj_file_path

load([subjFilePath,'_ICA_x.mat'],'EEG','epochNumbers');

time = EEG.times/1000;

t1 = find(time == -2.5);
t2 = find(time <2.5);t2 = t2(end);

FILT_STIMULI = EEG.data;

for electrode = 1:EEG.nbchan
    figure(3)
    clf
    subplot(2,1,1)
    plot(time(t1:t2),squeeze(FILT_STIMULI(electrode,t1:t2,:)),'k')
    subplot(2,1,2)
    plot(time(t1:t2),squeeze(mean(FILT_STIMULI(electrode,t1:t2,:),3)),'r','linewidth',2)

    title(EEG.chanlocs(electrode).labels)
    pause
end

%% 7. Identify channels with abberant ERPs and reject bad epochs
clear ENTER_CHANNEL badChans var data_table
chanNames = []; % all channel names

for i = 1:EEG.nbchan %cycle through channels
    var = EEG.chanlocs(1,i).labels; % save channel names in table
    temp = compose(var);
    chanNames = [chanNames; temp];
end

% manually set badchans here
badChans = {};

% Enter channels (can enter multiple, will evaluate one at a time)
% Make sure to scroll all the way up in command window to see ALL bad eps

for i = 1:length(badChans)
    ENTER_CHANNEL(i) = find(strcmp(badChans(i),chanNames)); %% fix structural issues
end

% %comment back in if you want to just go through every electrode (ugh)
% ENTER_CHANNEL = 1:EEG.nbchan;

k = 3; %k is the number of max and min pairs
for ii = ENTER_CHANNEL
    chan = squeeze(FILT_STIMULI(ii,t1:t2,:));
    chanMax = max(chan);
    chanMin = min(chan);
    chanSTD = std(chan);
    chanMean = mean(chan);

    [sorted,index]=sort(chanMax);
    maxes = [index(end-k+1:end)];
    maxes = fliplr(maxes);
    [sorted,index]=sort(chanMin);
    mins = [index(1:k)];
    %[maxFp1 badep1] = max(Chanmax)
    %[minFp1 badep2] = min(Chanmin)

    figure
    plot(time(t1:t2),chan,'k')
    hold on
    plot(time(t1:t2),chan(:,[maxes,mins]),'linewidth',2)
    title(chanNames(ii))

    dist_from_mean_maxes = chan(ii,maxes,:) - chanMean(maxes);
    dist_from_mean_mins = chan(ii,mins,:) - chanMean(mins);

    data_table = table;
    data_table.chan = repmat(chanNames(ii),k,1);
    data_table.Max = maxes';
    data_table.Min = mins';
    data_table.STDfromMean_Max = (dist_from_mean_maxes./chanSTD(maxes))';
    data_table.STDfromMean_Min = (dist_from_mean_mins./chanSTD(mins))';

    disp(['Epochs to take out - enter these below.  Might only want max or min. Max is first #, min is 2nd #.']);
    
    data_table
    
end

pop_eegplot( EEG, 1, 1, 0, [], 'color','on');

%% %enter bad epochs from post-ICA pass
toRejectSecond = find(EEG.reject.rejmanual); 
save([subjFilePath,'_rejected.mat'],'toRejectSecond','-append');

toRejectAll = [toReject epochNumbers(toRejectSecond)]; % track bad post-ICA epochs based on their original indices and add them to all bad epochs
save([subjFilePath,'_rejected.mat'],'toRejectAll','-append');

%% Do we need to reclean this dataset?

spit = input('Do you need to do another round of cleaning? y or n ', 's');

if strcmp(spit,'y')
    
    save([subjFilePath,'_postICA.mat']);
    disp('Post-ICA cleaning save complete. Rejected epoch numbers, channels, and ICA components from this round are saved.');
    disp('Start from the top and do another round of cleaning for this subject. You can load the rejected items from this run for reference.')

elseif strcmp(spit,'n') % if no additional round needed

    disp(['Rejecting ' num2str(toRejectSecond)])
    toRejectSecond = find(EEG.reject.rejmanual);
    
    if ~isempty(toRejectSecond)
        binarized=zeros(1,EEG.trials);
        binarized(toRejectSecond)=1;
        EEG = pop_rejepoch(EEG,binarized,0);
    end
    
    save([subjFilePath,'_solo_done.mat'],'EEG','epochNumbers');
    disp('You are ready to combine rejection info for both subjects and do a synced clean!')

end

%% add synced clean step 
% go through the pre-ICA cleanup, except you will combine indices of
% rejected epochs between the two subjects. run this once for each subject.

% load pre-removal data for this block
% load rejected items save files for both subjects
% find intersection of rejected epochs 
% do not need to interpolate each others channels or remove shared ICA components

%% save - DON'T FORGET THIS PART

spit = input('Did you do a second pass? y or n  ','s');

disp('Cleaning stats:')
if strcmp(spit,'n')
    disp(['Number of epochs rejected, note in lab notebook: ' num2str(length(toReject)+length(toRejectSecond))])
    disp(['Percentage of epochs rejected, note in lab notebook: ' num2str(((length(toReject)+length(toRejectSecond))/epochNumbers(end))*100) '%'])
elseif strcmp(spit,'y')
    disp(['Number of epochs rejected, note in lab notebook: ' num2str(length(toReject))])
    disp(['Percentage of epochs rejected, note in lab notebook: ' num2str((length(toReject)/epochNumbers(end))*100) '%'])
end
