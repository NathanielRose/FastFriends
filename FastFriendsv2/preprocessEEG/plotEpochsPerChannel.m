function plotEpochsPerChannel(EEG)

time = EEG.times/1000;
t1 = find(time == -1);
t2 = find(time <1);t2 = t2(end);

chanNames = {EEG.chanlocs.labels};
badChans = {};

FILT_STIMULI = EEG.data;

for c = 1:EEG.nbchan
    figure(100)     % bring fig to front
    clf             % clear figure
    subplot(2,1,1)
    plot(time(t1:t2),squeeze(FILT_STIMULI(c,t1:t2,:)),'k')
    subplot(2,1,2)
    plot(time(t1:t2),squeeze(mean(FILT_STIMULI(c,t1:t2,:),3)),'r','linewidth',2)
    title(chanNames{c});
   
    gotInput = false;
    while ~gotInput
        checkChan=input(sprintf('Investigate %s? (y/n): ', chanNames{c}),'s');
        if ismember(checkChan,{'y','Y','yes','Yes','YES'})
            fprintf('... added %s for investigation.\n',chanNames{c});
            badChans = [badChans,chanNames{c}];
            gotInput = true;
        elseif isempty(checkChan)
            gotInput = false;
        else
            gotInput = true;
        end
    end
end

% plot aberrant epochs

if ~isempty(badChans)
    for i = 1:length(badChans)
        ENTER_CHANNEL(i) = find(strcmp(badChans(i),chanNames)); %% fix structural issues
    end
else
    disp('No channels to investigate!');
    return;
end

k = 3;

badEpochList = [];

for c = ENTER_CHANNEL
    chan = squeeze(FILT_STIMULI(c,t1:t2,:));
    chanMax = max(chan);
    chanMin = min(chan);
    chanSTD = std(chan);
    chanMean = mean(chan);

    [sorted,index]=sort(chanMax);
    maxes = [index(end-k+1:end)];
    maxes = fliplr(maxes);
    [sorted,index]=sort(chanMin);
    mins = [index(1:k)];
    
    badEpochs = unique([maxes mins]);
    badEpochList = [badEpochList, badEpochs];
    

    figure
    plot(time(t1:t2),chan,'k')
    hold on
    h=plot(time(t1:t2),chan(:,badEpochs),'linewidth',2);
    badEpochLabels = cellfun(@num2str,num2cell(badEpochs),'uni',0);
    legend(h,badEpochLabels,'location','southoutside','orientation','horizontal')
    title(chanNames(c));

    dist_from_mean_maxes = chan(c,maxes,:) - chanMean(maxes);
    dist_from_mean_mins = chan(c,mins,:) - chanMean(mins);

    data_table = table;
    data_table.chan = repmat(chanNames(c),k,1);
    data_table.Max = maxes';
    data_table.Min = mins';
    data_table.STDfromMean_Max = (dist_from_mean_maxes./chanSTD(maxes))';
    data_table.STDfromMean_Min = (dist_from_mean_mins./chanSTD(mins))';
    
    disp(['By channel, these epochs were marked for potential removal:']);
    
    data_table
    
end

disp('These epochs were most frequently identified as suspicious:');
badEpochs = unique(badEpochList)';
numCommonChannels = NaN(size(badEpochs));
for e=1:length(badEpochs)
    thisBadEpoch = badEpochs(e);
    numCommonChannels(e) = sum(badEpochList==thisBadEpoch);
end
badEpochTable = table(badEpochs,numCommonChannels);
badEpochTable = sortrows(badEpochTable,2,'descend');
disp(badEpochTable)



end