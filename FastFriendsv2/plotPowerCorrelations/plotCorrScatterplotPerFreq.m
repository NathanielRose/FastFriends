%% plots correlation per electrode per freq
% plot scatterplot with one subj on each axis, also print pearson R on plot

function plotCorrScatterplotPerFreq(rho, pval, allF, chanlocs,...
    subA_meanPower, subB_meanPower, subA, subB, saveFolder, block)

rounded_rho = round(rho,3);

for fi = 1:length(allF)
    
    f=allF{fi};
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
    
    saveas(gcf,[saveFolder,'block_',num2str(block),'_',f,'_corrScatterplot.png']);

end