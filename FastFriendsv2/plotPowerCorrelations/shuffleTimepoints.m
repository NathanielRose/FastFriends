clear

%% shuffle order of timepoints 10000 times

load('numEpochs.mat');

DYADS = {'120519','120519','122019','122019','122019'};
BLOCKS = [1,3,1,2,3];

numEpochs = reshape(numEpochs',[1,6]);

slidingWindowSize = 0;

% if doing sliding window, adjust numEpochs accordingly
if slidingWindowSize > 0
    numEpochs = numEpochs - ceil(slidingWindowSize/2.5) - 1;
end

%%

progressbar(0,0);

tic
for n = 1:numel(numEpochs)
    
    progressbar([],0);
    
    ne = numEpochs(n);
    
    d = DYADS{n};
    b = BLOCKS(n);
    
    subA = [d,'_A'];
    subB = [d,'_B'];       
%     keyboard

    numShuffles = 5000;
    
    % initialize structures for rho, pval, corrVects of all 1000 orders
    rhoDist = zeros(6,19,numShuffles); % bleh hardcoded values
    pvalDist = zeros(6,19,numShuffles); % bleh hardcoded values
    corrVectAll = zeros(6,19,numShuffles); % bleh hardcoded values
    
    % shuffle timepoint order 1000 times
    shuffledTimepoints = zeros(numShuffles,ne,2);
    
    subA_power = loadPower(subA,b,slidingWindowSize);
    subB_power = loadPower(subB,b,slidingWindowSize);
    
    [subA_pnPower,~]=peaknormalizePower(subA_power);
    [subB_pnPower,F]=peaknormalizePower(subB_power);
    
    foundSig = 0;
    
    for i = 1:numShuffles
        
        subA_pnPowerShuffled = subA_pnPower(:,:,randperm(ne));
        subB_pnPowerShuffled = subB_pnPower(:,:,randperm(ne));
        
        [rho,pval,corrVect]=calcSpearmanRhoCorr(subA_pnPowerShuffled,...
                                                subB_pnPowerShuffled,F);
        rhoDist(:,:,i) = rho;
        pvalDist(:,:,i) = pval;
        corrVectAll(:,:,i) = corrVect;
        
        progressbar([],i/numShuffles);
        
    end
    
    save([d,'_block_',num2str(b),'_shuffledPower'],...
            'rhoDist','pvalDist','corrVectAll');
    
    progressbar(n/6);

end
toc

% get 5 different mat files, 2 for dyad 1 (blocks 1,3) and 3 for
% dyad 2 (blocks 1,2,3). each is 1 3D matrix of doubles (1000,epochNum,2)

%% get pearson rho of 1000 shuffled power sequences 
%including non-significant rhos

% create distribution of rhos for every channel and frequency
% find the rho value at the 95% 
clear

DYADS = {'120519','120519','122019','122019','122019'};
BLOCKS = [1,3,1,2,3];


%%

for n=1:5

d = DYADS{n};
b = BLOCKS(n);

load([d,'_block_',num2str(b),'_shuffledPower']);
load([d,'_block_',num2str(b),'_rhoCorr']);

all95thRhos = NaN(6,19,2);
sig95thRhos = NaN(6,19);


% for each significant non-zero correlation
for c = 1:size(sigCorrs,1) 
    
    f = sigCorrs(c,1); % significant correlation's frequency
    e = sigCorrs(c,2); % significant correlation's electrode
    
    % create distribution of all significant/non-0
    thisCorr = squeeze(corrVectAll(f,e,:));
    thisCorr(thisCorr==0) = []; % eliminate 0 values
    ns = length(thisCorr);
    
    if sigCorrs(c,3) > 0 % pos correlation
        sig95thRhos(f,e) = prctile(thisCorr,97.5);
    elseif sigCorrs(c,3) < 1
        sig95thRhos(f,e) = prctile(thisCorr,2.5);  
    end
    
end

save([d,'_block_',num2str(b),'_shuffledPower'],...
            'sig95thRhos','ns','-append');

% for all channels and electrodes         
for f = 1:6
    for e = 1:19
        
        % create distribution of all rhos (including ns ones)
        thisCorr = rhoDist(f,e,1:1000);
        all95thRhos(f,e,:) = prctile(thisCorr,[2.5 97.5]);
        
    end
end

save([d,'_block_',num2str(b),'_shuffledPower'],...
            'all95thRhos','-append');
        
% find which frequency/electrodes abs(corr) > 95th percentile
actuallySig = zeros(6,19,2);

corrVect(corrVect==0) = NaN;

actuallySig(:,:,2) = abs(corrVect) - abs(sig95thRhos);
actuallySig(:,:,1) = logical(actuallySig(:,:,2)>0);


save([d,'_block_',num2str(b),'_shuffledPower'],...
            'actuallySig','-append');
        
end


%% plots

DYADS = {'120519','120519','122019','122019','122019'};
BLOCKS = [1,3,1,2,3];
allF = {'Delta','Theta','Alpha','Beta','Low Gamma','High Gamma'};
load('chanlocsDryEEG.mat');

n = 5; %1-5
fi = 6;
ci = 2;

d = DYADS{n};
b = BLOCKS(n);
f = allF{fi};
c = chanlocs(ci).labels;

load([d,'_block_',num2str(b),'_shuffledPower']);
load([d,'_block_',num2str(b),'_rhoCorr']);


%% plot histograms


% all 1000
figure;
histogram(rhoDist(fi,ci,1:1000));
xlabel('Spearman Rho');
ylabel('Frequency');
title([f,' Correlation at ',c,' (n=1000), ',d,' block ',num2str(b)])
saveas(gcf,[f,' Correlation at ',c,'_',d,...
    '_block_',num2str(b),'_rhoDist.png'])

keyboard

% only sigs
figure;
t = squeeze(pvalDist(fi,ci,:));
tidx = find(t<0.05);
histogram(rhoDist(fi,ci,tidx));
xlabel('Spearman Rho');
ylabel('Frequency');
title([f,' Correlation at ',c,' (n=',num2str(length(tidx)),'), ',...
    d,' block ',num2str(b)])
saveas(gcf,[f,' Correlation at ',c,'_',d,...
    '_block_',num2str(b),'_rhoDist_onlysigs.png']);

%% topoplots of actual significant things

t = reshape(actuallySig(:,:,1),[1,114]);
ti = find(t==0);

sigElecs = reshape(corrVect,[1,114]);
sigElecs(ti) = 0;
sigElecs = reshape(sigElecs,[6,19]);

figure;
for fi = 1:length(allF)
    subplot(2,3,fi);
    f = allF{fi};
    topoplot(sigElecs(fi,:),chanlocs);
    title(f)

    set(gcf,'Position',[0 0 1200 800])

end

sgtitle(['Significant power correlation (Spearman), ',d,...
    ' block ',num2str(b)]); % var dependent

saveas(gcf,[d,'_block_',num2str(b),'_actualsig_topo.png']);