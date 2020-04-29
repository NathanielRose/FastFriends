function meanPower = getMeanPowerPerFrequency(pnPower,allF,F)

for f = allF
    
    if strcmp(f{1},'delta')
       meanPower(:,:,1) = mean(pnPower(:,find(F>=0 & F<4),:),2);
    elseif strcmp(f{1},'theta')
        meanPower(:,:,2) = mean(pnPower(:,find(F>=4 & F<9),:),2);
    elseif strcmp(f{1},'alpha')
        meanPower(:,:,3) = mean(pnPower(:,find(F>=9 & F<14),:),2);
    elseif strcmp(f{1},'beta')
        meanPower(:,:,4) = mean(pnPower(:,find(F>=14 & F<30),:),2);
    elseif strcmp(f{1},'low gamma')
        meanPower(:,:,5) = mean(pnPower(:,find(F>=30 & F<60),:),2);
    elseif strcmp(f{1},'high gamma')
        meanPower(:,:,6) = mean(pnPower(:,find(F>=60 & F<=150),:),2);
    end
    
end

end