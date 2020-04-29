%% plots time course of electrodes w/ significant pos corr for each frequency

function plotPosCorrElecPerFreq(allF,correlationVect,subA_meanPower,subB_meanPower,chanlocs,saveFolder,block)


% for each freq, find indices of electrodes w sig pos correlations
for fi=1:length(allF)
    
    f = allF{fi};
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
            
            ylabel('Averaged peak-normalized power'); xlabel('Window #')
    
            % plot the time series against each other
            subplot(1,2,2)
            plot(subA_meanPower(ei,:,fi),subB_meanPower(ei,:,fi),'o')
            lsline
            
            sgtitle([f,' band power time series at electrode ',chanlocs(ei).labels,' of significant pos. correlation'])
            
            saveas(gcf,[saveFolder,'block_',num2str(block),'_',f,'_',chanlocs(ei).labels,'_timeSeries.png']);
        end
    end
end

end