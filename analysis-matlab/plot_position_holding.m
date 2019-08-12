function expdata = plot_position_holding(exp)

% Origin in the video : top-left corner (Front-Left-Edge of tank)

if ~exist('exp', 'var')
    fprintf('--reading new fish.mat--');
    exp = load('C:\Users\sdd50\work\zfish\digitized_data\fish_data_v1.mat');
end 

plot_dir = 'S:\work\zfish\plots';
plot_type = 'pos-hold';
dir = fullfile(plot_dir,plot_type);
if ~isfolder(dir); mkdir(dir); end

data = struct;
zeroed_plot = 1;    
dataset_name = {'adap_e4','turb_adap_e10'};
exp_name = {'push_adapted','pull_adapted'; 
            'push_adapted_turb','pull_adapted_turb'};
% Read data
for i=1:2   
    T1 = exp_name{i,1}; % Stim Type 1
    T2 = exp_name{i,2}; % Stim Type 2
    
    data = get_data_single_type(data, exp, T1, zeroed_plot);
    data = get_data_single_type(data, exp, T2, zeroed_plot);
    data.(dataset_name{i}) = [data.(T2).Vposhold; data.(T1).Vposhold];     
end

% Plot data
h1 = figure('Name','FishTrajectories','Units','centimeters','Position', [-2, -2, 29.7, 21]);
title=['Position holding variablities after adaptation'];
suptitle(title);
CategoricalScatterplot([data.(dataset_name{1}),data.(dataset_name{2})],'Labels',{'Laminar Flow','Turbulent Flow'});
ylabel({'Ground Speed', '(m/s)'});

% Save plot
fname = sprintf('plot-%s--%s',T1,T2);
fpath = fullfile(plot_dir,plot_type,fname);
savefig(h1,[fpath,'.fig']);
% TufteStyleC;
orient(h1,'landscape');
set(gcf,'PaperPositionMode','auto');
print([fpath,'.pdf'],'-painters','-dpdf','-fillpage');
    
end

function data = get_data_single_type(data, exp, T, zeroed_plot)

    px2mm = 1/4.725;
    cutoff = 150; % Hz
    sr = 1e3; % FPS            
    lowpass = designfilt('lowpassiir','FilterOrder',4, ...
              'PassbandFrequency',cutoff,'PassbandRipple',0.01,'SampleRate',sr);

    
    data.(T).Vposhold  = nan(16,1); %add
    
    for f=1:4
        fishID = ['f',num2str(f)];    
        
        for t=1:4
            trialID = ['t',num2str(t)];
            fish = [fishID,trialID];
            
            % Data Read
            dataT = exp.(T).(fishID).(trialID).data;
            start_frame_T = exp.(T).(fishID).(trialID).stim_start;
            data.(T).(fish).P = dataT.headP;
            data.(T).(fish).X = dataT.headX*px2mm;
            data.(T).(fish).Y = dataT.headY*px2mm;
            data.(T).(fish).t = [-(start_frame_T-1):1:size(dataT,1)-start_frame_T]';          
                        
            % Clean-up trajaectories
            data.(T).(fish) = remove_artifacts(data.(T).(fish), lowpass);
            
            if zeroed_plot
                data.(T).(fish).X = data.(T).(fish).X - data.(T).(fish).X(find(data.(T).(fish).t==0)); %#ok
                data.(T).(fish).Y = data.(T).(fish).Y - data.(T).(fish).Y(find(data.(T).(fish).t==0)); %#ok
            end                        
                      
            % stats - position holding - trajectory pre-stimulus
            stat_range = {'pre',[1000 0]};  % -1 to 0 <fixed> s 
            
            stFr = find(data.(T).(fish).t == 0);
            availLen = stFr;
            if availLen >= (stat_range{2}(1)-stat_range{2}(2))
                r = 1+stFr - stat_range{2}(1) : stFr;    
            else
                r = 1 : availLen;
                fprintf('[%s-stim too less] %s %s : %d\n',stat_range{1},T,fish,availLen);
                data.(T).preStimShort.(fish) = availLen;
            end       
            
            % velocity ( displacement / time ) - mm/s
            data.(T).(fish).('Vpre') = sum(abs(diff(data.(T).(fish).X(r))))/length(data.(T).(fish).X(r));
            data.(T).Vposhold(4*(f-1)+t) = data.(T).(fish).('Vpre');
                                  
        end       
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
    
    % Low-pass filter -- Remove 1kHz filimig artifact
    if exist('lowpass','var') && ~isempty(lowpass)
        data.X = filtfilt(lowpass, data.X);
        data.Y = filtfilt(lowpass, data.Y);
    end

end