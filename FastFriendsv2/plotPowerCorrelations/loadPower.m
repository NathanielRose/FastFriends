function [powerToUse]=loadPower(subID,block,slidingWindowSize)

subBlockFolder = [subID,'_block_',num2str(block),'/'];
powerPath = ['/Users/amyzou/Documents/MATLAB/FF/calculatePower/',subBlockFolder];

if slidingWindowSize == 0
    fileName = [powerPath,subID,'_block_',num2str(block),'_power.mat'];
    load(fileName);
    powerToUse = allPower;
else
    fileName = [powerPath,subID,'_block_',num2str(block),...
        '_power_slidingWindow_',num2str(slidingWindowSize),'.mat'];
    load(fileName);
    powerToUse = slidingWindowPower;
end

end