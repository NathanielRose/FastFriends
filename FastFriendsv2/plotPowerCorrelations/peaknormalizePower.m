%% peaknormalizePower
%
% Helper function for plotBandPowerCorrelations_FF. Loads
% bandpower_multitaper.m file for the specified subject and part number. 
% Peak normalizes power of each frequency and electrode channel by dividing 
% the power across epochs by the peak power of that frequency and electrode.

function [pnPower,F]=peaknormalizePower(subID,block,slidingWindowSize)

powerToUse = loadPower(subID,block,slidingWindowSize);

F = 1:150;

% interpolate power at 60Hz and 120Hz
powerToUse(:,60,:) = (powerToUse(:,59,:) + powerToUse(:,61,:))/2;
powerToUse(:,120,:) = (powerToUse(:,119,:) + powerToUse(:,121,:))/2;

% pnPower = NaN * ones(size(powerToUse)); % initialize 

pnPower = powerToUse./max(powerToUse,[],[1,3]);


end