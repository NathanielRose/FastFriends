function [rho,pval,corrVect]=calcSpearmanRhoBands(subA_pnPower,subB_pnPower,F)

allF = {'delta','theta','alpha','beta','low gamma','high gamma'};
freqBands = [1,3;4,8;9,13;14,29;30,59;60,150];
% subA_meanPower = getMeanPowerPerFrequency(subA_pnPower,allF,F);
% subB_meanPower = getMeanPowerPerFrequency(subB_pnPower,allF,F);

%% Spearman rho correlation
% correlation between electrodes across all/specified time points for each frequency

rho = NaN(6,19);
pval = NaN(6,19);
corrVect = NaN(6,19);

for fi=1:length(allF)
    thisFreqBand = freqBands(fi,:);
    subA_meanPower = squeeze(mean(subA_pnPower(:,thisFreqBand(1):thisFreqBand(end),:),2));
    subB_meanPower = squeeze(mean(subB_pnPower(:,thisFreqBand(1):thisFreqBand(end),:),2));
    [this_rho,this_pval] = corr(subA_meanPower(:,:)',...
        subB_meanPower(:,:)','type','Spearman');
    rho(fi,:) = diag(this_rho);
    pval(fi,:)=diag(this_pval);
    corrVect(fi,:) = rho(fi,:).*(pval(fi,:)<.05);
end

end