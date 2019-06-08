function plot_from_mat(exp)

% exp = load('C:\Users\sdd50\work\zfish\digitized_data\fish_data_v1.mat');
plot_dir = 'C:\Users\sdd50\work\zfish\plots';
plot_type = 'stim-onset-zeroed-position-cropped-trajectories';

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

% ax = [-3e3 5e3 -650*px2mm 650*px2mm];
% ax = [-500 1500 -650*px2mm 650*px2mm];
ax = [-500 1500 -150 150];

% LPF  
cutoff = 150; % Hz
sr = 1e3; % FPS            
lowpass = designfilt('lowpassiir','FilterOrder',4, ...
          'PassbandFrequency',cutoff,'PassbandRipple',0.01,'SampleRate',sr);

for i=1:5
    h1 = figure('Name','FishTrajectories','Units','centimeters','Position', [-2, -2, 29.7, 21]);
    
    expT1_name = strrep(exp_name{i,1},'_','-');
    expT2_name = strrep(exp_name{i,2},'_','-');
   
    title=[expT1_name,' vs ',expT2_name];
    suptitle(title);

    for f=1:4
        fishID = ['f',num2str(f)];
    
        for t=1:4
            trialID = ['t',num2str(t)];            
            % Trial Data Read
            dataT1 = exp.(exp_name{i,1}).(fishID).(trialID).data;
            stim_startT1 = exp.(exp_name{i,1}).(fishID).(trialID).stim_start;
            t_T1 = -(stim_startT1-1):1:size(dataT1,1)-stim_startT1;
            
            dataT2 = exp.(exp_name{i,2}).(fishID).(trialID).data;
            stim_startT2 = exp.(exp_name{i,2}).(fishID).(trialID).stim_start;
            t_T2 = -(stim_startT2-1):1:size(dataT2,1)-stim_startT2;
            
                      
            data = struct;
            data.t = t_T1;
            data.P = dataT1.headP;
            data.X = dataT1.headX*px2mm;
            data.Y = dataT1.headY*px2mm;
          
            data = remove_artifacts(data, lowpass);
            data.X = data.X - data.X(find(data.t==0));
            data.Y = data.Y - data.Y(find(data.t==0));
                        
            hUpT1 = subplot(nRow,nCol,up_T1); hold on;
            plot(data.t,data.X, 'Color', fish_color(f,:));
            hDownT1 = subplot(nRow,nCol,down_T1); hold on;
            plot(data.t,data.Y, 'Color', fish_color(f,:));
            
            
            data.t = t_T2;
            data.P = dataT2.headP;
            data.X = dataT2.headX*px2mm;
            data.Y = dataT2.headY*px2mm;            
            
            data = remove_artifacts(data, lowpass);
            data.X = data.X - data.X(find(data.t==0));
            data.Y = data.Y - data.Y(find(data.t==0));
            
            hUpT2 = subplot(nRow,nCol,up_T2); hold on;
            plot(data.t,data.X, 'Color', fish_color(f,:));            
            hDownT2 = subplot(nRow,nCol,down_T2); hold on;
            plot(data.t,data.Y, 'Color', fish_color(f,:));
          
        end       
    end
    
    hUpT1 = subplot(nRow,nCol,up_T1); hold on;
    axis(ax);
    yticks(-150:50:150);
%     yticklabels({'Front', 'center', 'Back'});
    ylabel({'X--dir position ( mm )', '( Neg.: Up-stream, Pos.: Down-stream )'});

    hUpT2 = subplot(nRow,nCol,up_T2); hold on;
    axis(ax);
    yticks(-150:50:150);
%     yticklabels({'Front', 'center', 'Back'});

    hDownT1 = subplot(nRow,nCol,down_T1); hold on;
    axis(ax);
    yticks(-150:50:150);
%     yticklabels({'Righ-wall', 'middle', 'Left-wall'});
    xlabel({'Time (milliseconds)',expT1_name});
    ylabel({'Y-dir position ( mm )', '( Neg.: Righ-wall, Pos.: Left-wall )'});

    hDownT2 = subplot(nRow,nCol,down_T2); hold on;
    axis(ax);
    yticks(-150:50:150);
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
    
    % Low-pass filter -- Remove 1kHz filimig artifact
    if exist('lowpass','var') && ~isempty(lowpass)
        data.X = filtfilt(lowpass, data.X);
        data.Y = filtfilt(lowpass, data.Y);
    end

end

function plot_an_exp_type()

% TODO


end

%%%% Plots
% only x
% only y
% trajectory - X-(front-back), Y(righ-left)
% change in trajectory (starting position zeroed)
% X velocity / acceleration 
% Y velocity / acceleration 
% Velocity / acceleration 
