exp = load('C:\Users\sdd50\work\zfish\digitized_data\fish.mat');
exp_name = {
    'push_sudden','pull_sudden'; 
    'push_adapted','pull_adapted'; 
    'push_adapted_turb','pull_adapted_turb';
    'roll_right_sudden','roll_left_sudden';
    'roll_right_adapted','roll_left_adapted'};
points = {'headX','headY','tailX','tailY', ...
          'upX','upY','downX','downY'};

%%%% Read Raw Data and populate processed data matrix
xpos = struct;
ypos = struct;
trajectory = struct;
stimstart = struct;

for i=1:5
    title=[exp_name{i,1},' vs ',exp_name{i,2}];
    figure;
    suptitle(strrep(title,'_','-'));
%     xpos.(exp_name{i,1}) = nan(4*4,4e3+7e3);
%     xpos.(exp_name{i,2}) = nan(4*4,4e3+7e3);
%     ypos.(exp_name{i,1}) = nan(4*4,4e3+7e3);
%     ypos.(exp_name{i,2}) = nan(4*4,4e3+7e3);
    
    for f=1:4
        fishID = ['f',num2str(f)];
        for t=1:4
            trialID = ['t',num2str(t)];            
            % Data 
            dataT1 = exp.(exp_name{i,1}).(fishID).(trialID).data;
            stim_startT1 = exp.(exp_name{i,1}).(fishID).(trialID).stim_start;
            t_T1 = -(stim_startT1-1):1:size(dataT1,1)-stim_startT1;
            
            dataT2 = exp.(exp_name{i,2}).(fishID).(trialID).data;
            stim_startT2 = exp.(exp_name{i,2}).(fishID).(trialID).stim_start;
            t_T2 = -(stim_startT2-1):1:size(dataT2,1)-stim_startT2;
            
            % Max -4k,7k
            
            subplot(1,2,1);
            hold on;
            plot(t_T1,dataT1.headX-dataT1.headX(stim_startT1));
            
            subplot(1,2,2);
            hold on;
            plot(t_T2,dataT2.headX-dataT2.headX(stim_startT2));

            
            
                        
            
        end       
    end
    
    
end

%%%% Plots
% only x
% only y
% trajectory - X-(front-back), Y(righ-left)
% change in trajectory (starting position zeroed)
% X velocity / acceleration 
% Y velocity / acceleration 
% Velocity / acceleration 
