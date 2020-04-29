function [rhoFreq,pvalFreq,rhoElec,pvalElec]=calcSpearmanRhoROI(subA_pnPower,subB_pnPower,freqRange,roiIdx)

% subA_meanPower = getMeanPowerPerFrequency(subA_pnPower,allF,F);
% subB_meanPower = getMeanPowerPerFrequency(subB_pnPower,allF,F);

%% Spearman rho correlation
% correlation between electrodes across all/specified time points for each frequency
% 
% rho = NaN(length(freqRange),19);
% pval = NaN(length(freqRange),19);
% corrVect = NaN(length(freqRange),19);

subA_meanPower = squeeze(mean(subA_pnPower(roiIdx,:,:),3));
subB_meanPower = squeeze(mean(subB_pnPower(roiIdx,:,:),3));

subA_temp = subA_meanPower(1,:);
subB_temp = subB_meanPower(1,:);

[this_rho,this_pval]=corr(subA_temp',subB_temp','type','Spearman');


% frequencies
[this_rho,this_pval] = corr(subA_meanPower,...
    subB_meanPower,'type','Spearman');
rhoFreq = diag(this_rho);
pvalFreq = diag(this_pval);

% electrodes
[this_rho,this_pval] = corr(subA_meanPower(:,:)',...
    subB_meanPower(:,:)','type','Spearman');
rhoElec = diag(this_rho);
pvalElec = diag(this_pval);
% corrVect(fi,:) = rho(fi,:).*(pval(fi,:)<.05);



end