function plot_tail_beat(exp)

% TODO - fix axis, yticks, filter

% exp = load('C:\Users\sdd50\work\zfish\digitized_data\fish_data_v1.mat');
plot_dir = 'C:\Users\sdd50\work\zfish\plots';
plot_type = 'stim-onset-zeroed-position-cropped-trajectories';
zeroed_plot = 1;
cropped_plot = 1;

exp_name = {
    'push_sudden','pull_sudden'; 
    'push_adapted','pull_adapted'; 
    'push_adapted_turb','pull_adapted_turb';
    'roll_right_sudden','roll_left_sudden';
    'roll_right_adapted','roll_left_adapted'};
points = {'headX','headY','tailX','tailY', ...
          'upX','upY','downX','downY'};

% px2mm = 1;
px2mm = 1/4.725; % 4.725 pixels = 1 mm ;
% Max -4k,7k ; 1frame = 1ms;
      
%%%% Read Raw Data and populate processed data matrix
fish_color = [ [0, 0.4470, 0.7410];[0.8500, 0.3250, 0.0980];...
               [0.9290, 0.6940, 0.1250];[0.4940, 0.1840, 0.5560] ] ;
nCol = 2;
nRow = 2;
up_T1 = 1;
down_T1 = 3;
up_T2 = 2;
down_T2 = 4;

% select axis range
if cropped_plot
    ax = [-500 1500 nan nan]; % cropped
else
    ax = [-3e3 5e3  nan nan]; % full 
end
if zeroed_plot
    ax(3:4) = [-40 40]; % zeroed-position
else
    ax(3:4) = [0 300];  % absolute-position
end

lowpass_freq = designfilt('lowpassiir','FilterOrder',4, ...
          'PassbandFrequency',20,'PassbandRipple',0.01,'SampleRate',1e3);
lowpass_amp = designfilt('lowpassiir','FilterOrder',4, ...
          'PassbandFrequency',20,'PassbandRipple',0.01,'SampleRate',1e3);

for i=3
    
    h1 = figure('Name','FishTrajectories','Units','centimeters','Position', [-2, -2, 29.7, 21]);
    
    T1 = exp_name{i,1}; % Stim Type 1
    T2 = exp_name{i,2}; % Stim Type 2

    title=['Tail plots : ', strrep(T1,'_','-'),' vs ',strrep(T2,'_','-')];
    suptitle(title);
    
    for f=1:4
        fishID = ['f',num2str(f)];
    
        for t=1:4
            trialID = ['t',num2str(t)];            
            % Trial Data Read
            dataT1 = exp.(T1).(fishID).(trialID).data;
            stim_startT1 = exp.(T1).(fishID).(trialID).stim_start;
            t_T1 = -(stim_startT1-1):1:size(dataT1,1)-stim_startT1;
            
            dataT2 = exp.(T2).(fishID).(trialID).data;
            stim_startT2 = exp.(T2).(fishID).(trialID).stim_start;
            t_T2 = -(stim_startT2-1):1:size(dataT2,1)-stim_startT2;
            
            
            %%%%% Type 1
            data = struct;
            data.t = t_T1;
            data.P = dataT1.tailP;
            data.X = dataT1.tailX*px2mm;
            data.Y = dataT1.tailY*px2mm;
          
            data = remove_artifacts(data);
            if zeroed_plot
                data.Y = data.Y - data.Y(find(data.t==0));
            end
            
            [ppk,tppk] = findpeaks(data.Y, data.t);
            [npk,tnpk] = findpeaks(-data.Y, data.t);
            npk = -npk;
            
            Npks = min(length(ppk),length(npk));
            peak_amp = nan(Npks,1);
            peak_time = nan(Npks,1);
            peak_freq = nan(Npks,1);
            for n = 1:Npks
               peak_amp(n) = ppk(n) - npk(n);
               peak_time(n) = (tppk(n) + tnpk(n))/2;
               if n == Npks
                   continue;
               end
               peak_freq(n) = 1/(abs( tppk(n) - tnpk(n+1) ));
            end
            
            peak_freq = interp1(peak_time,peak_freq,data.t);
            peak_freq = fillmissing(peak_freq,'spline');
            peak_freq = filtfilt(lowpass_freq, peak_freq);
            
            peak_amp = interp1(peak_time,peak_amp,data.t);
            peak_amp = fillmissing(peak_amp,'spline');
            peak_amp = filtfilt(lowpass_amp, peak_amp);
                
            
            hUpT1 = subplot(nRow,nCol,up_T1); hold on;
            plot(data.t,peak_amp, 'Color', fish_color(f,:));
            hDownT1 = subplot(nRow,nCol,down_T1); hold on;
            plot(data.t,peak_freq, 'Color', fish_color(f,:));
            
            
            %%%%% Type 2
            data = struct;
            data.t = t_T2;
            data.P = dataT2.tailP;
            data.X = dataT2.tailX*px2mm;
            data.Y = dataT2.tailY*px2mm;
          
            data = remove_artifacts(data);
            if zeroed_plot
                data.Y = data.Y - data.Y(find(data.t==0));
            end
            
            [ppk,tppk] = findpeaks(data.Y, data.t);
            [npk,tnpk] = findpeaks(-data.Y, data.t);
            npk = -npk;
            
            Npks = min(length(ppk),length(npk));
            peak_amp = nan(Npks,1);
            peak_time = nan(Npks,1);
            peak_freq = nan(Npks,1);
            for n = 1:Npks
               peak_amp(n) = ppk(n) - npk(n);
               peak_time(n) = (tppk(n) + tnpk(n))/2;
               if n == Npks
                   continue;
               end
               peak_freq(n) = 1/(abs( tppk(n) - tnpk(n+1) ));
            end
            
            peak_freq = interp1(peak_time,peak_freq,data.t);
            peak_freq = fillmissing(peak_freq,'spline');
            peak_freq = filtfilt(lowpass_freq, peak_freq);
            
            peak_amp = interp1(peak_time,peak_amp,data.t);
            peak_amp = fillmissing(peak_amp,'spline');
            peak_amp = filtfilt(lowpass_amp, peak_amp);

            hUpT2 = subplot(nRow,nCol,up_T2); hold on;
            plot(data.t,peak_amp, 'Color', fish_color(f,:));            
            hDownT2 = subplot(nRow,nCol,down_T2); hold on;
            plot(data.t,peak_freq, 'Color', fish_color(f,:));
          
        end       
    end
    
    hUpT1 = subplot(nRow,nCol,up_T1); hold on;
    axis(ax);
    yticks(ax(3):10:ax(4));
%     yticklabels({'Front', 'center', 'Back'});
    ylabel('Tail beat Amplitude');

    hUpT2 = subplot(nRow,nCol,up_T2); hold on;
    axis(ax);
    yticks(ax(3):10:ax(4));
%     yticklabels({'Front', 'center', 'Back'});

    hDownT1 = subplot(nRow,nCol,down_T1); hold on;
    axis(ax);
    yticks(ax(3):10:ax(4));
%     yticklabels({'Righ-wall', 'middle', 'Left-wall'});
    xlabel({'Time (milliseconds)',expT1_name});
    ylabel('Tail beat Frequency (Hz)');

    hDownT2 = subplot(nRow,nCol,down_T2); hold on;
    axis(ax);
    yticks(ax(3):10:ax(4));
%     yticklabels({'Righ-wall', 'middle', 'Left-wall'});
    xlabel({'Time (milliseconds)',expT2_name});   
    
    linkaxes([hUpT1,hUpT2,hDownT1,hDownT2],'x');
    
    fname = sprintf('plot-%s--%s',expT1_name,expT2_name);
    fpath = fullfile(plot_dir,plot_type,fname);
    savefig(h1,[fpath,'.fig']);
    TufteStyleC;
    orient(h1,'landscape');
    set(gcf,'PaperPositionMode','auto');
    print([fpath,'.pdf'],'-painters','-dpdf','-fillpage');
  
end

end

function data = remove_artifacts(data, lowpass)
    
    % remove and interpolate points with less-confidance tracking 
    Pthres = 1; 
    rem = find(data.P < Pthres);
    data.X(rem) = nan;
    data.Y(rem) = nan;    
    data.X = fillmissing(data.X,'spline');
    data.Y = fillmissing(data.Y,'spline');  
    
    % Remove starting-ending trajectory artifact
    trim_ms = 3; 
    if trim_ms > 0
        data.P(1:trim_ms) = [];
        data.X(1:trim_ms) = [];
        data.Y(1:trim_ms) = [];
        data.t(1:trim_ms) = [];
    end
    
    data.Y = bandpass_filter(data.Y,1000,3,25);
    
    % Low-pass filter -- Remove 1kHz filimig artifact
%     if exist('lowpass','var') && ~isempty(lowpass)
%         data.X = filtfilt(lowpass, data.X);
%         data.Y = filtfilt(lowpass, data.Y);
%     end

end

function plot_single_type()

% TODO


end