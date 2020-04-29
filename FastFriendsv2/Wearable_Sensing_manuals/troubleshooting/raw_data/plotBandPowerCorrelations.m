
%% initialize paths, subject IDs, and blocks

addpath(genpath('/Users/amyzou/Documents/MATLAB/eeglab2019_1'));
rmpath(genpath('/Users/amyzou/Documents/MATLAB/eeglab2019_1/plugins/')); % avoid importing eeglab's tiedrank.m

subA = ''; subB = ''; block = 0;

% create a save folder
dyadNname = subA(1:end-2);
saveFolder = [dyadNname,'_correlation_figs/'];
mkdir(saveFolder);

%% load subA and subB and peak-normalize power

subA_pnPower=peaknormalizePower(subA,block);
subB_pnPower=peaknormalizePower(subB,block);


%% calculate average power for desired frequency bands

all_f = {'delta','theta','alpha','beta','low gamma','high gamma'};
subA_meanPower = averagePowerPerFrequency(subA_pnPower,all_f);
subB_meanPower = averagePowerPerFrequency(subB_pnPower,all_f);

%% Spearman rho correlation
% correlation between electrodes across all/specified time points for each frequency

for fi=1:length(all_f)
    [this_rho,this_pval] = corr(subA_meanPower(:,:,fi)',...
        subB_meanPower(:,:,fi)','type','Spearman');
    rho(fi,:) = diag(this_rho);
    pval(fi,:)=diag(this_pval);
    correlationVect(fi,:) = rho(fi,:).*(pval(fi,:)<.05);
end

%% topoplot for each frequency

% get channel locations
load('chanlocs_dry_eeg.mat');

for fi = 1:length(all_f)
    figure
    f = all_f{fi};
    topoplot(correlationVect(fi,:),chanlocs);
    title(['Significant ',f,' band power correlation topoplot (Spearman)']); % var dependent

    saveas(gcf,[saveFolder,'block_',num2str(block),'_',f,'_corr_topoplot.png']);
end
%% pick one electrode and frequency band that "work"

% for each freq, find indices of electrodes w sig pos correlations
for fi=1:length(all_f)
    
    f = all_f{fi};
    posCorrElecs = find(correlationVect(fi,:)>0); % find electrodes w significant positive correlation
    
    if posCorrElecs
        
        for ei=posCorrElecs
            
            figure
            % plot the time series overlapping
            subplot(1,2,1)
            plot(subA_meanPower(ei,:,fi))
            hold on
            plot(subB_meanPower(ei,:,fi))
            hold on
    
            % plot the time series against each other
            subplot(1,2,2)
            plot(subA_meanPower(ei,:,fi),subB_meanPower(ei,:,fi),'o')
            lsline
            
            sgtitle([f,' band power time series at electrode ',chanlocs(ei).labels,' of significant pos. correlation'])
            
            saveas(gcf,[saveFolder,'block_',num2str(block),'_',f,'_',chanlocs(ei).labels,'_time_series.png']);
        end
    end
end

% plot scatterplot with one subj on each axis, also print pearson R on plot

rounded_rho = round(rho,3);

for fi = 1:length(all_f)
    
    f=all_f{fi};
    this_pval = pval(fi,:); 
    this_rounded_rho = rounded_rho(fi,:);
    
    figure
    
    for ei=1:length(chanlocs)
        
        subplot(4,5,ei)
        
        if this_pval(ei)<.05 && this_rounded_rho(ei)>0 % if significant positive correlation
            plotColor = [.7 0 0];
        elseif this_pval(ei)<.05 && this_rounded_rho(ei)<0 % if significant negative correlation
            plotColor = [0 0 .7];
        else 
            plotColor = [.3 .3 .3];
        end
        
        plot(subA_meanPower(ei,:,fi),subB_meanPower(ei,:,fi),'o','Color',plotColor);
        lsline
        
        title([chanlocs(ei).labels,' (\rho=',num2str(this_rounded_rho(ei)),')']) % var dependent
        
        xlabel(['Subject ',num2str(subA)]) % var dependent
        ylabel(['Subject ',num2str(subB)]) % var dependent
        
        set(gca,'TickDir','out'); % more beautification
    end
    
    sgtitle([f,' band power correlation (Spearman rho)'])
    set(gcf,'Position',[0 0 1200 800])
    
    saveas(gcf,[saveFolder,'block_',num2str(block),'_',f,'_corr_scatterplot.png']);

end
