
%% initialize paths, subject IDs, and blocks

close all;
clear

addpath(genpath('/Users/amyzou/Documents/MATLAB/eeglab2019_1'));
rmpath(genpath('/Users/amyzou/Documents/MATLAB/eeglab2019_1/plugins/')); % avoid importing eeglab's tiedrank.m

dyadName ='120519';
subA = [dyadName,'_A']; subB = [dyadName,'_B']; 
block = 1;

windowSize = 0; % if 0 then not sliding window, else

%% create a save folder
if windowSize == 0
    saveFolder = [dyadName,'_block_',num2str(block),'_correlationFigs/'];
    extraPlotTitle = [];
else
    saveFolder = [dyadName,'_block_',num2str(block),'_correlationFigs_slidingWindow_',num2str(windowSize),'/'];
    extraPlotTitle = ['Sliding Window (',num2str(windowSize),'s)'];
end
mkdir(saveFolder);

%% peak-normalize power for subA and subB 
[subA_pnPower,~]=peaknormalizePower(subA,block,windowSize);
[subB_pnPower,F]=peaknormalizePower(subB,block,windowSize);


%% calculate power correlation for desired frequency bands
[rho,pval,corrVect]=calcSpearmanRhoBands(subA_pnPower,subB_pnPower,F);

[rows,cols,vals]=find(corrVect>0);
sigCorrs = [rows,cols,vals];

[rows,cols,vals]=find(corrVect<0);
sigCorrs = [sigCorrs;rows,cols,vals*-1];

save([dyadName,'_block_',num2str(block),'_rhoCorr'],'rho','pval','corrVect',...
                                            'sigCorrs');

%% are the significant correlations actually significant?


%% topoplot for each frequency

% get channel locations
load('chanlocsDryEEG.mat');

figure;
for fi = 1:length(allF)
    subplot(2,3,fi);
    f = allF{fi};
    topoplot(corrVect(fi,:),chanlocs);
    title(f)

    set(gcf,'Position',[0 0 1200 800])
    sgtitle(['Significant power correlation (Spearman), ',dyadName,...
        ' block ',num2str(block)]); % var dependent
    
    saveas(gcf,[saveFolder,'block_',num2str(block),'_corrTopoplot.png']);
end

%% pick one electrode and frequency band that "work"

plotPosCorrElecPerFreq(allF,corrVect,subA_meanPower,subB_meanPower,chanlocs,saveFolder,block);

%% plot scatterplot with one subj on each axis, also print pearson R on plot

plotCorrScatterplotPerFreq(rho, pval, allF, chanlocs,...
    subA_meanPower, subB_meanPower, subA, subB, saveFolder, block);
