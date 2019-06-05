% Read all videos in an experimen

% DLC-csv name
filename = 'f1-static-ds-vid_2018-08-15_17-33-07.mp4';
filepath = 'C:\Users\sdd50\work\zfish\digitized_data\EXP_3_STAT_US_DS_DLC\f1-static-ds-vid_2018-08-15_17-33-07DeepCut_resnet50_SwimmingJan25shuffle1_1030000.csv';

% Read timestamp
ts = read_timestamp('C:\Users\sdd50\work\zfish\digitized_data\stimulus-timestamp-dictionary.csv');
ind = find(find(ts.VIDEONAME==filename));
stim_start_frame = ts.STARTFRAME(ind); % 1 frame- 1 ms

% Read data and group
data = import_dlc_csv(filepath);
group_names = {'sudden-push','sudden-pull';
               'adapted-push','adapted-pull';
               'adapted-push-in-turbulent-flow','adapted-pull-in-turbulent-flow';
               'sudden-roll-right','sudden-roll-left';
               'adapted-roll-right','adapted-roll-left'};
group =  group_names(1,2);           



%{
(3)
static-us : sudden-push 
static-ds : sudden-pull	

(4)
ds_rev : adapted-push
us_rev : adapted-pull			

(10)
ds_rev : adapted-push-in-turbulent-flow
us_rev : adapted-pull-in-turbulent-flow

(5)
exp_5 CCW : sudden-roll-right
exp_5 CW  : sudden-roll-left		

(6)
exp_6 CCW : adapted-roll-right 
exp_6 CW  : adapted-roll-left

%}