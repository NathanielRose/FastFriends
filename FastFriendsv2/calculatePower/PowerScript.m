
%% set up
clear all;

% for first subject in dyad
subID = '122019_A';
block = 1;


%% get non-sliding window power

% % for 2nd dyad
TFirstHalf= 1:193; 
TSecondHalf = 194:391; 

[power,allPower,epochNumbers]=getPower(subID,block,'multitaper',TSecondHalf);

%% do sliding window analysis
% for first subject in dyad
subID = '122019_B';
block = 3;


% dyad 1 block 1 - end = 775
% dyad 1 block 3 - end = 897
% dyad 2 block 3- 210
numSecInWindow = [20 60 120 ];


for n = numSecInWindow
    getPowerSlidingWindow(subID,block,n);
end

