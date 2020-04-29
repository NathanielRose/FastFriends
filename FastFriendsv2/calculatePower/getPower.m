
%% getPower function
% Caculates power using the Multitaper Method via pmtm(), or Wavelets and
% Convolutions. specifiedT will be removed in the future, as it will be
% dealt with properly in preprocessing.

function [power,allPower,epochNumbers]=getPower(subID,block,whichMethod,specifiedT,varargin) 
% bandpower: ne*nt*ntr array of values of  power
%     - ne: number of electrodes
%     - nt: number of time points (within trial)
%     - ntr: number of trials
% times: (1,nt) array of time points (stimulus locked -500,1000ms)
% epochnumbers: (1,ntr) array of epoch numbers for each trial


dataPath =  ('/Users/amyzou/Documents/MATLAB/FF/processed_data/cleaned/'); % where the data lives

load([dataPath,subID,'_block_',num2str(block),'_final.mat']) % load post-ICA pre-filter data

% specifiedT will be removed in the future!
% if nargin > 3

    T = specifiedT;
    voltage=EEG.data(:,:,T);
    epochNumbers = epochNumbers(T);

    if find(specifiedT < 15)
        block = 1;
    else
        block = 2;
    end

    % if we're doing sliding window

% else
% 
%     voltage = EEG.data;
%     T = size(voltage,3);

% end

dims=size(voltage);

nbchans = EEG.nbchan;
F = 1:150;

%% alternative method: do multitaper
if strcmp(whichMethod,'multitaper')

    fs = 300; % sampling rate
    nW = 4; % Time-halfbandwidth product
        
    times = round(EEG.times); 

    tic
    
%     calculate power for each individual epoch
    for e=1:dims(3) % for each epoch
        X=voltage(:,:,e)'; % voltage for this epoch
        [thisPower,F]=pmtm(X,nW,F,fs); % PSD for this epoch
        power(:,:,e) = thisPower'; % concatenate PSD for this epoch with others
    end
    
    toc 
    
   
    
%% Original method: waveletize, then do time-freq decomposition
elseif strcmp(whichMethod,'wavelet') 
    %Waveletize!

    % Setup Wavelet Params
    numcycles=4; 

    s=numcycles./(2*pi.*F); 
    t=-2:1/EEG.srate:2; % time range for wavelet window x-axis
    clear i w
    
    for fi=1:length(F) % for each frequency
        w(fi,:) = exp(2*1i*pi*F(fi).*t) .* exp(-t.^2./(2*s(fi)^2)); % get window for freq
        
        % time res: 2sigma_t *1000 for ms
        timeres(fi)=2*s(fi) * 1000; %idk
        
        % freq res: 2sigma_f
        frexres(fi)=2* (F(fi) / numcycles); %idk
    end

    %figure;plot(timeres,w')
    % Beware the edge effects from the filter -so cut down time to something reasonable
    times= round(EEG.times); 
    c1=find(round(times)==-2000); 
    c2=find(round(times)==2000);
    times = times(c1:c2); % range equal to epoch interval


    %time freq decomposition

    AllTF = [];
    for site = 1:dims(1) % for each electrode site
        site
        tic
        for fi=1:length(F) % for each frequency, get time freq decomp
            % Reshape, convolve, and reshape again
            convolved=fconv_JFC(reshape(voltage(site,:,:),1,dims(2)*dims(3)),w(fi,:)); % convolution
            resized=convolved((size(w,2)-1)/2:end-1-(size(w,2)-1)/2); %cut of 1/2 the length of the w from beg, and 1/2 from the end
            decomposed=reshape(resized,dims(2),dims(3));

            % dim: elec site x frequeny x convolution
            power(site,fi,:,:)=10*log10(abs(decomposed(c1:2:c2,:).^2));

            clear convolved resized decomposed;
        end 
        toc
    end

    times = times(1:2:end);

    power = squeeze(mean(power,2)); % power avreaged across frequencies


end

allPower = getPowerMissingEpochs(subID,block,epochNumbers,power);

% save 
subFolder = [subID,'_block_',num2str(block),'/'];
mkdir(subFolder);
save([subFolder,subID,'_block_',num2str(block),'_power.mat'],'allPower','power','F','times','epochNumbers','whichMethod','nbchans');

end