function expdata = plot_fish_position(exp)

% Origin in the video : top-left corner (Front-Left-Edge of tank)

% exp = load('C:\Users\sdd50\work\zfish\digitized_data\fish_data_v1.mat');
plot_dir = 'C:\Users\sdd50\work\zfish\share-june10';
plot_type = 'abs-crop';
zeroed_plot = 0;
cropped_plot = 1;

dir = fullfile(plot_dir,plot_type);
if ~isfolder(dir); mkdir(dir); end

dataset_name = {'sud_e3','adap_e4','turb_adap_e10','roll_sud_e5','roll_adap_e6'};
exp_name = {
    'push_sudden','pull_sudden'; 
    'push_adapted','pull_adapted'; 
    'push_adapted_turb','pull_adapted_turb';
    'roll_right_sudden','roll_left_sudden';
    'roll_right_adapted','roll_left_adapted'};


% Plot params
plt.nCol = 16; plt.nRow = 2;
plt.T1.X = (1:4); plt.T1.Xstat = (6:7);  plt.T2.X = (10:13);   plt.T2.Xstat = (15:16);
plt.T1.Y = (17:20); plt.T1.Ystat = (22:23);  plt.T2.Y = (26:29); plt.T2.Ystat = (31:32);

% axes for - cropped or full
if cropped_plot
    plt.ax = [-500 1500 nan nan]; 
else
    plt.ax = [-3e3 5e3  nan nan]; 
end
% axes for - zeroed or absolute position
if zeroed_plot
    plt.ax(3:4) = [-150 150]; 
else
    plt.ax(3:4) = [0 300]; 
end

plt.ytickgapX = 50; % mm
plt.ytickgapY = 50; % mm
      
expdata = struct;
expdata.plt = plt;
expdata.exp_name = exp_name;
expdata.plot_type = plot_type;
expdata.dataset_name = dataset_name;

for i=1:5
    plt.h1 = figure('Name','FishTrajectories','Units','centimeters','Position', [-2, -2, 29.7, 21]);
    
    T1 = exp_name{i,1}; % Stim Type 1
    T2 = exp_name{i,2}; % Stim Type 2

    title=['Raw data plots : ', strrep(T1,'_','-'),' vs ',strrep(T2,'_','-')];
    suptitle(title);

    data = struct;
    data = get_data_single_type(data, exp, T1, zeroed_plot);
    data = get_data_single_type(data, exp, T2, zeroed_plot);
    
    plot_single_type(plt, data, T1, plt.T1);
    plot_single_type(plt, data, T2, plt.T2);
    
    fname = sprintf('plot-%s--%s',T1,T2);
    fpath = fullfile(plot_dir,plot_type,fname);
    savefig(plt.h1,[fpath,'.fig']);
    TufteStyleC;
    orient(plt.h1,'landscape');
    set(gcf,'PaperPositionMode','auto');
    print([fpath,'.pdf'],'-painters','-dpdf','-fillpage');
    
    expdata.(dataset_name{i}) = data;
  
end

end

function data = get_data_single_type(data, exp, T, zeroed_plot)

    px2mm = 1/4.725;
    cutoff = 150; % Hz
    sr = 1e3; % FPS            
    lowpass = designfilt('lowpassiir','FilterOrder',4, ...
              'PassbandFrequency',cutoff,'PassbandRipple',0.01,'SampleRate',sr);

    data.(T).Xrho_pre  = nan(16,1);
    data.(T).Xrho_post = nan(16,1);
    data.(T).Yrho_pre  = nan(16,1);
    data.(T).Yrho_post = nan(16,1);

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
                      
            % stats - trajectory post-stimulus
            stat_range = {'post',[500,1500]};  % 0.5 to 1.5 s
            
            stFr = find(data.(T).(fish).t == 0);
            availLen = length(data.(T).(fish).t)-stFr;
            if availLen >= stat_range{2}(2)
                r = stFr + (stat_range{2}(1) : stat_range{2}(2));    
            elseif availLen >= (stat_range{2}(2)-stat_range{2}(1))
                r = stFr + (availLen-(stat_range{2}(2)-stat_range{2}(1)):availLen);
                fprintf('[%s-stim < %d ms] %s %s : %d\n',stat_range{1},stat_range{2}(2),T,fish,availLen);
                data.(T).postStimShort.(fish) = availLen;
            else
                r = stFr + (1 : availLen);
                fprintf('[%s-stim too less] %s %s : %d\n',stat_range{1},T,fish,availLen);
                data.(T).postStimShort.(fish) = availLen;
            end       

            a = data.(T).(fish).t(r);
            bx = data.(T).(fish).X(r);
            by = data.(T).(fish).Y(r);
            [data.(T).(fish).Xrho.(stat_range{1}), data.(T).(fish).Xpval.(stat_range{1})] = ...   
                corr(a,bx,'Type','Spearman');
            [data.(T).(fish).Yrho.(stat_range{1}), data.(T).(fish).Ypval.(stat_range{1})] = ...   
                corr(a,by,'Type','Spearman');
            
             % stats - trajectory pre-stimulus
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

            a = data.(T).(fish).t(r);
            bx = data.(T).(fish).X(r);
            by = data.(T).(fish).Y(r);
            [data.(T).(fish).Xrho.(stat_range{1}), data.(T).(fish).Xpval.(stat_range{1})] = ...   
                corr(a,bx,'Type','Spearman');
            [data.(T).(fish).Yrho.(stat_range{1}), data.(T).(fish).Ypval.(stat_range{1})] = ...   
                corr(a,by,'Type','Spearman');            
                    
            % Save rho in a matrix        
            data.(T).Xrho_post(4*f+t) = data.(T).(fish).Xrho.post;
            data.(T).Yrho_post(4*f+t) = data.(T).(fish).Yrho.post;
            data.(T).Xrho_pre(4*f+t)  = data.(T).(fish).Xrho.pre;
            data.(T).Yrho_pre(4*f+t)  = data.(T).(fish).Yrho.pre;
                                  
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


function plot_single_type(plt, data, T, pax)
    
    % Plot trajectories
    fish_color = [ [0, 0.4470, 0.7410];[0.8500, 0.3250, 0.0980];...
               [0.9290, 0.6940, 0.1250];[0.4940, 0.1840, 0.5560] ];
    for f=1:4
        for t=1:4
            fish = ['f',num2str(f),'t',num2str(t)];

            hUpT = subplot(plt.nRow,plt.nCol,pax.X); hold on;
            plot(data.(T).(fish).t,data.(T).(fish).X, 'Color', fish_color(f,:));
            
            hDownT = subplot(plt.nRow,plt.nCol,pax.Y); hold on;
            plot(data.(T).(fish).t,data.(T).(fish).Y, 'Color', fish_color(f,:));         
        end
    end
    
    hUpT = subplot(plt.nRow,plt.nCol,pax.X); hold on;
    axis(plt.ax);
    yticks(plt.ax(3):plt.ytickgapX:plt.ax(4));
%     yticklabels({'Front', 'center', 'Back'});
%     ylabel({'X--dir position ( mm )', '( Neg.: Up-stream, Pos.: Down-stream )'});
    ylabel({'X--dir position ( mm )', '<--- Up-stream  -Middle-  Down-stream --->'});


    hDownT = subplot(plt.nRow,plt.nCol,pax.Y); hold on;
    axis(plt.ax);
    yticks(plt.ax(3):plt.ytickgapY:plt.ax(4));
%     yticklabels({'Righ-wall', 'middle', 'Left-wall'});
%     ylabel({'Y-dir position ( mm )', '( Neg.: Righ-wall, Pos.: Left-wall )'});
    ylabel({'Y-dir position ( mm )', '<--- Left-wall -Middle- Right-wall --->'});
    xlabel({'Time (milliseconds)',strrep(T,'_','-')});
    
    linkaxes([hUpT,hDownT,],'x');
    
    
    % Plot pre-post trajectory quantification
    subplot(plt.nRow,plt.nCol,pax.Xstat);    
    CategoricalScatterplot([data.(T).Xrho_pre,data.(T).Xrho_post],'Labels',{'PreStim','PostStim'});
    
    subplot(plt.nRow,plt.nCol,pax.Ystat);
    CategoricalScatterplot([data.(T).Yrho_pre,data.(T).Yrho_post],'Labels',{'PreStim','PostStim'});

end