function plot_fish_position(exp)

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


% Plot params
nCol = 2; nRow = 2;
up_T1 = 1; up_T2 = 2;
down_T1 = 3; down_T2 = 4;

fish_color = [ [0, 0.4470, 0.7410];[0.8500, 0.3250, 0.0980];...
               [0.9290, 0.6940, 0.1250];[0.4940, 0.1840, 0.5560] ];
           
% axes for - cropped or full
if cropped_plot; ax = [-500 1500 nan nan]; else ax = [-3e3 5e3  nan nan]; end
% axes for - zeroed or absolute position
if zeroed_plot; ax(3:4) = [-150 150]; else ax(3:4) = [0 300]; end

% LPF  
cutoff = 150; % Hz
sr = 1e3; % FPS            
lowpass = designfilt('lowpassiir','FilterOrder',4, ...
          'PassbandFrequency',cutoff,'PassbandRipple',0.01,'SampleRate',sr);
      
for i=1:5
    h1 = figure('Name','FishTrajectories','Units','centimeters','Position', [-2, -2, 29.7, 21]);
    
    T1 = exp_name{i,1}; % Stim Type 1
    T2 = exp_name{i,2}; % Stim Type 2

    title=['', strrep(T1,'_','-'),' vs ',strrep(T2,'_','-')];
    suptitle(title);

    data = struct;
    data = get_data_single_type(data, exp, T1, lowpass, zeroed_plot);
    data = get_data_single_type(data, exp, T2, lowpass, zeroed_plot);
    
    
    fname = sprintf('plot-%s--%s',expT1_name,expT2_name);
    fpath = fullfile(plot_dir,plot_type,fname);
    savefig(h1,[fpath,'.fig']);
    TufteStyleC;
    orient(h1,'landscape');
    set(gcf,'PaperPositionMode','auto');
    print([fpath,'.pdf'],'-painters','-dpdf','-fillpage');
  
end

end

function data = get_data_single_type(data, exp, T, lowpass, zeroed_plot)

    px2mm = 1/4.725;
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
            
            [data.(T).(fish).Xrho, data.(T).(fish).Xpval] = ...   
                corr(data.(T).(fish).t',data.(T).(fish).X,'Type','Spearman');
            [data.(T).(fish).Yrho, data.(T).(fish).Ypval] = ...   
                corr(data.(T).(fish).t',data.(T).(fish).Y,'Type','Spearman');
                         
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


function plot_single_type()

           hUpT1 = subplot(nRow,nCol,up_T1); hold on;
            plot(data.t,data.X, 'Color', fish_color(f,:));
            hDownT1 = subplot(nRow,nCol,down_T1); hold on;
            plot(data.t,data.Y, 'Color', fish_color(f,:));
            
            
            hUpT2 = subplot(nRow,nCol,up_T2); hold on;
            plot(data.t,data.X, 'Color', fish_color(f,:));            
            hDownT2 = subplot(nRow,nCol,down_T2); hold on;
            plot(data.t,data.Y, 'Color', fish_color(f,:));
          
            
 
    
    hUpT1 = subplot(nRow,nCol,up_T1); hold on;
    axis(ax);
    yticks(ax(3):50:ax(4));
%     yticklabels({'Front', 'center', 'Back'});
    ylabel({'X--dir position ( mm )', '( Neg.: Up-stream, Pos.: Down-stream )'});

    hUpT2 = subplot(nRow,nCol,up_T2); hold on;
    axis(ax);
    yticks(ax(3):50:ax(4));
%     yticklabels({'Front', 'center', 'Back'});

    hDownT1 = subplot(nRow,nCol,down_T1); hold on;
    axis(ax);
    yticks(ax(3):50:ax(4));
%     yticklabels({'Righ-wall', 'middle', 'Left-wall'});
    xlabel({'Time (milliseconds)',expT1_name});
    ylabel({'Y-dir position ( mm )', '( Neg.: Righ-wall, Pos.: Left-wall )'});

    hDownT2 = subplot(nRow,nCol,down_T2); hold on;
    axis(ax);
    yticks(ax(3):50:ax(4));
%     yticklabels({'Righ-wall', 'middle', 'Left-wall'});
    xlabel({'Time (milliseconds)',expT2_name});   
    
    linkaxes([hUpT1,hUpT2,hDownT1,hDownT2],'x');

end