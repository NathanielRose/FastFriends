% debug using one epoch of one electrode
figure;plot(EEG.data(12,:,1))
X=EEG.data(12,:,1);

% run FFT
Y = fft(X); % FFT-ed signal
L=length(X); % size
P2 = abs(Y/L); % 
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
Fs = 512; % sampling rate


% get single sided frequency-amplitude spectrum
f = Fs*(0:(L/2))/L; % frequency
plot(f,P1)
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')


%%
figure
for e=1:size(EEG.data,1);
    X=EEG.data(e,:,:);
    for epoch= 1:size(X,3)
        this_epoch = X(1,:,epoch);
        Y = fft(this_epoch); % FFT-ed signal
        L=length(this_epoch); % size
        P2 = abs(Y/L); % 
        P1 = P2(1:L/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        Fs = 300;
        f = Fs*(0:(L/2))/L;
        power(epoch,:,e)=P1;
    end
subplot(4,5,e)
plot(f,mean(log10(power(:,:,e))))
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')
end