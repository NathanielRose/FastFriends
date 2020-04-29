%% initialize paths, subject IDs, and blocks
close all; clear


addpath(genpath('/Users/amyzou/Documents/MATLAB/eeglab2019_1'));
rmpath(genpath('/Users/amyzou/Documents/MATLAB/eeglab2019_1/plugins/')); % avoid importing eeglab's tiedrank.m

%%
dyadName ='120519';
subA = [dyadName,'_A']; subB = [dyadName,'_B']; 
block =1;

desiredCorrelationFrequencies = 1:150;

windowSize = 0; % sliding window size in seconds; 0 if N/A



%% load subA and subB and peak-normalize power

[subA_pnPower,~]=peaknormalizePower(subA,block,windowSize);
[subB_pnPower,F]=peaknormalizePower(subB,block,windowSize);

%% get correlations
% "quantified using Spearman correlation between the two partners? 
% "spectral power, computed over the entire social interaction (300 Sec)"

% " was computed over time signal of the Stockwell transform frequency
% spectrum (for each frequency bins in the range of 4-60 HZ) -- ??"

% all frequencies
[rhoFreq,pvalFreq,rhoElec,pvalElec]=calcSpearmanRho(subA_pnPower,...
    subB_pnPower,desiredCorrelationFrequencies);


% frontal = F3, F4, F7, F8, Fz, Fp1, Fp2    
frontalIdx = [3,5,15,16];%,4,9,10];
[rhoFrontal,pvalFrontal,~,~]=calcSpearmanRhoROI(subA_pnPower,...
    subB_pnPower,desiredCorrelationFrequencies,frontalIdx);

% parietal = P3,P4,Pz
parietalIdx = [1,7,19];
[rhoParietal,pvalParietal,~,~]=calcSpearmanRhoROI(subA_pnPower,...
    subB_pnPower,desiredCorrelationFrequencies,parietalIdx);

% temporal-parietal = T3,T4,T5,T6
tpIdx = [11,18,12,17];
[rhoTP,pvalTP,~,~]=calcSpearmanRhoROI(subA_pnPower,...
    subB_pnPower,desiredCorrelationFrequencies,tpIdx);

% occipital = O1,O2
occipitalIdx = [13,14];
[rhoOccipital,pvalOccipital,~,~]=calcSpearmanRhoROI(subA_pnPower,...
    subB_pnPower,desiredCorrelationFrequencies,occipitalIdx);

%% plot x = freq, y = correlation
% plot one for each block

if block == 1
f2 = figure;
sgtitle(['Dyadic Correlation Spectral Analysis, dyad=',dyadName],'FontSize',14);
set(gcf,'Position',[0 0 600 800]);
end

subplot(3,1,block);
plot(F,rhoFreq);
% plot(F,rhoFrontal); hold on;
% plot(F,rhoParietal); hold on;
% plot(F,rhoTP); hold on;
% plot(F,rhoOccipital); hold on;
xlabel('Frequency (Hz)'); 
ylabel('Spearman Correlation'); ylim([-.4 1])
title(['block ',num2str(block)]);
legend({'Frontal','Parietal','Temporal-Parietal','Occipital'});

saveas(gcf,['KinreichDyadCorrelation/',dyadName,'_ROI.png']);

%% plot scatterplot

if block == 1
f2 = figure;

sgtitle(['Dyadic Correlation Spectral Analysis (Scatterplot), dyad=',dyadName],'FontSize',14);
set(gcf,'Position',[0 0 600 800]);
end

subplot(3,1,block);
plot(F,rhoFreq); hold on;
xlabel('Frequency (Hz)'); 
ylabel('Spearman Correlation'); ylim([-.4 1])
title(['block ',num2str(block)]);

sigIdx = find(pvalFreq<0.05);
nsIdx = find(pvalFreq>=0.05);

% plot significant points
scatter(F(sigIdx),rhoFreq(sigIdx),[],'blue'); hold on;
% plot non-sig points
scatter(F(nsIdx),rhoFreq(nsIdx),[],[.5 .5 .5]); hold on;

saveas(gcf,['KinreichDyadCorrelation/',dyadName,'_Scatter.png']);
