function [rhoFreq,pvalFreq,rhoElec,pvalElec]=calcSpearmanRho(subA_pnPower,subB_pnPower,freqRange)

% subA_meanPower = getMeanPowerPerFrequency(subA_pnPower,allF,F);
% subB_meanPower = getMeanPowerPerFrequency(subB_pnPower,allF,F);

%% Spearman rho correlation
% correlation between electrodes across all/specified time points for each frequency
% 
% rho = NaN(length(freqRange),19);
% pval = NaN(length(freqRange),19);
% corrVect = NaN(length(freqRange),19);

subA_meanPower=squeeze(mean(subA_pnPower,1));
subB_meanPower=squeeze(mean(subB_pnPower,1));

% frequencies
[this_rho,this_pval] = corr(subA_meanPower',...
    subB_meanPower','type','Spearman');
rhoFreq = diag(this_rho);
pvalFreq = diag(this_pval);

% electrodes
[this_rho,this_pval] = corr(subA_meanPower(:,:)',...
    subB_meanPower(:,:)','type','Spearman');
rhoElec = diag(this_rho);
pvalElec = diag(this_pval);
% corrVect(fi,:) = rho(fi,:).*(pval(fi,:)<.05);



end