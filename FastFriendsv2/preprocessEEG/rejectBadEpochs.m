function EEG=rejectBadEpochs(EEG,toReject)

% Reject bad epochs
if ~isempty(toReject)
    binarized=zeros(1,EEG.trials);
    binarized(toReject)=1;
    EEG = pop_rejepoch(EEG,binarized,0);
end

end