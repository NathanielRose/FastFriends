function chanNames = getChannelNames(EEG)

chanNames = []; % all channel names

for i = 1:EEG.nbchan %cycle through channels
    var = EEG.chanlocs(1,i).labels; % save channel names in table
    temp = compose(var);
    chanNames = [chanNames; temp];
end

end