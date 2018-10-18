
>>> python adjust_image.py path_to_video
1.choose roi dragging the mouse
2. tune parameters for image segmentation

>>>Output (to be copied inside track_zfish.py)
contr= 2.75
bright= 123
## Adaptive gaussian threshold parameters:
## see https://docs.opencv.org/3.4.0/d7/d1b/group__imgproc__misc.html#ga72b913f352e4a1b1b397736707afcde3 for an explanation
N= 611
roi = (150, 321, 969, 324)
video_path =  '/home/mattadori/research_projects/KITP/movies/exp10/f1-ds_rev-vid_2018-08-22_17-54-30.mp4'
######################################################

>>< python track_zfish.py
run the analysis con the video selected

>>>Output
It extracts
-head
-tail
-blob centroid

It writes everything to a file path_to_video.dat
-------------------------------------------------------

At this stage the analysis produces very noisy tracking of the tail point.

TO DO LIST
-adding spline to get the middle line