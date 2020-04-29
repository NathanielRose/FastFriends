function slidingWindowPower = getPowerSlidingWindow(subID,block,numSecInWindow)


subFolder = [subID,'_block_',num2str(block),'/'];

% load allPower: electrode x freq x all epochs (including interpolated)
load([subFolder,subID,'_block_',num2str(block),'_power.mat'],'allPower')

dims = size(allPower);

numExtraWindows = ceil(numSecInWindow/2.5) - 1;

% calculate sliding window power
for ew=1:dims(3)-numExtraWindows 
    thisPower = mean(allPower(:,:,ew:ew+numExtraWindows),3);
    slidingWindowPower(:,:,ew) = thisPower;
end

epochNumbers = [1:size(allPower,3)];

% save 
save([subFolder,subID,'_block_',num2str(block),'_power_slidingWindow_',num2str(numSecInWindow),'.mat'],...
    'slidingWindowPower','numSecInWindow','epochNumbers');

end