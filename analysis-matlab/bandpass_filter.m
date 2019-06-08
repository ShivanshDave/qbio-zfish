function [y] = bandpass_filter(x,Fs,fstart,fstop)
%
%
% Dinesh Natesan

% 
highpass = designfilt('highpassiir','FilterOrder',4, ...
    'PassbandFrequency',fstart,'PassbandRipple',0.1, ...
    'SampleRate',Fs);
lowpass = designfilt('lowpassiir','FilterOrder',4, ...
    'PassbandFrequency',fstop,'PassbandRipple',0.1, ...
    'SampleRate',Fs);

x = to_column_matrix(x);    % convert to column matrix
y = nan(size(x));

for i=1:size(x,2)
    
    tx = filtfilt(highpass, x(:,i));
    y(:,i) = filtfilt(lowpass, tx);

end


end