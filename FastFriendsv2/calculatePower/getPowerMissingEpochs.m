%% getAllPower.m
% Calculate power for missing epochs by interpolating power of its
% immediate neighbors. 

function allPower = getPowerMissingEpochs(subID,block,remainingEpochNumbers,remainingEpochPower)

    nbchans = 19;
    F = 1:150;
    
    % this is a hack; should keep originalEpochNumbers from preproc 
    originalEpochNumbers = 1:remainingEpochNumbers(end); 
    
    % build new allpower matrix (#electrodes x freq x originalEpochNums)
    % some epochs will still be missing from the end. big bummer
    allPower = NaN * ones(nbchans,length(F),remainingEpochNumbers(end)); 
    
    % populate allpower matrix with existingEpochPower
    for re=1:length(remainingEpochNumbers)

        allPower(:,:,remainingEpochNumbers(re)) = remainingEpochPower(:,:,re);
    end
    % get list of missing epochs -- actual epoch value
    missingEpochs = setdiff(originalEpochNumbers,remainingEpochNumbers);
    
    % for each missing epoch
    for me=missingEpochs
        
        if me < remainingEpochNumbers(1) % if earliest epochs are missing
            
            allPower(:,:,me) = allPower(:,:,remainingEpochNumbers(1));
            
        elseif me > remainingEpochNumbers(end) % if lastest epochs are missing -- not a case rn
            
            allPower(:,:,me) = allPower(:,:,remainingEpochNumbers(end));
        else
            
            leftNeighbor = remainingEpochNumbers(max(find(remainingEpochNumbers<me))); % largest smaller neighbor
            rightNeighbor = remainingEpochNumbers(min(find(remainingEpochNumbers>me))); % smallest larger neighbor
            powerToAvg(:,:,1) = allPower(:,:,leftNeighbor);
            powerToAvg(:,:,2) = allPower(:,:,rightNeighbor);
            allPower(:,:,me) = mean(powerToAvg,3);
        end 
        
    end
    
    if min(remainingEpochNumbers) > 15
        allPower = allPower(:,:,min(remainingEpochNumbers):end);
    end
    
%     save([subID,'_block_',num2str(block),'_power.mat'],'allPower','-append');
    
end