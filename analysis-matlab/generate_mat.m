% mat file for exp 3-4-5-6-10

% Read folders
% folders = uigetdir(pwd,'Experiments folders dir');
folders = 'C:\Users\sdd50\work\zfish\digitized_data';

% files = dir(folders);
% subdir = files([files.isdir]);
% subdir(1:2) = [];
% names = subdir.name;

exp_dir = {
    'EXP_3_STAT_US_DS_DLC'; 
    'EXP_4_US_DS_REV_DLC'; 
    'EXP_10_TURB_FLOW_REV_DLC';
    'EXP_5_STAT_CW_CCW_DLC';
    'EXP_6_CW_CCW_REV_DLC'};
exp_typ = {
    'static-us','static-ds'; 
    'ds_rev','us_rev'; 
    'ds_rev','us_rev';
    'CCW','CW';
    'CCW','CW'};
exp_name = {
    'push_sudden','pull_sudden'; 
    'push_adapted','pull_adapted'; 
    'push_adapted_turb','pull_adapted_turb';
    'roll_right_sudden','roll_left_sudden';
    'roll_right_adapted','roll_left_adapted'};

ts = read_timestamp('C:\Users\sdd50\work\zfish\digitized_data\stimulus-timestamp-dictionary.csv');

for i=1:length(exp_dir)
    data_dir = fullfile(folders,exp_dir{i});
    csv_files = dir(fullfile(data_dir,'*.csv'));
    all_files = {csv_files.name};

    trial_count_typ1 = [0 0 0 0];
    trial_count_typ2 = [0 0 0 0];
    
    for f=1:length(all_files)
      
        fishID = all_files{f}(1:2);
        fishNum = str2num(fishID(end));       

        if contains(all_files{f},exp_typ(i,1))
            typeStim = exp_name{i,1};
            trial_count_typ1(fishNum) = trial_count_typ1(fishNum) + 1;
            trialNum = trial_count_typ1(fishNum);
            trialID = ['t',num2str(trialNum)];

        elseif contains(all_files{f},exp_typ(i,2))
            typeStim = exp_name{i,2};
            trial_count_typ2(fishNum) = trial_count_typ2(fishNum) + 1;
            trialNum = trial_count_typ2(fishNum);
            trialID = ['t',num2str(trialNum)];

        else
            warning('Type unknown');
            fprintf('%s\n',all_files{f});
            typeStim = 'other';
            fishID = ['exp',num2str(i)];
            trialID = all_files{f}(1:end-50);
            trialID = strrep(trialID,'-','_');

        end

        % Read/save timestamp
        ind = find( ts.VIDEONAME==[all_files{f}(1:end-50),'.mp4'] );
        stimStart = ts.STARTFRAME(ind);
        exp.(typeStim).(fishID).(trialID).stim_start = stimStart;

        % Read/Store data
        data = import_dlc_csv(fullfile(data_dir,all_files{f}));
        exp.(typeStim).(fishID).(trialID).data = data;         
             
    end
 
end

% Save mat
save( fullfile( folders, 'fish.mat'), '-struct', 'exp', '-v7.3')