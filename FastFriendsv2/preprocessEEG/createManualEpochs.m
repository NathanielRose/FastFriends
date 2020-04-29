function EEG = createManualEpochs(EEG,fileName,folderName)

    % insert triggers called 'X' at every 2 seconds, and extract epoch from 
    % 1 second before and 1 second after
    EEG = eeg_regepochs(EEG,'recurrence',1,'extractepochs','off'); 
    EEG = pop_epoch(EEG,{'X'},[-1 1]); 
    disp('2s epochs (w/ 1s overlap) created.');
    
%     EEG = pop_saveset(EEG,'filename',[fileName,'_epoched.set'],'filepath',folderName);
    save([folderName,fileName,'_epoched.mat']);
    
end