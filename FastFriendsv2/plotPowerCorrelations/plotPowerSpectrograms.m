%spectrograms bc fuck 


% normalized power
figure;
imagesc(1:size(pnPower,3),1:size(pnPower,2),squeeze(mean(pnPower,1))); 
colorbar();
set(gca,'YDir','normal')

keyboard
% log power
figure;
imagesc(1:size(pnPower,3),1:size(pnPower,2),squeeze(mean(log(pnPower),1))); 
set(gca,'YDir','normal')