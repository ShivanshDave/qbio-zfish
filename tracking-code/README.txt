// libraries install 
pip3 install numpy opencv-python tqdm scikit-image scikit-video argparse

flow :
// Make python code executable 
chmod +x track_zfish.py

// Compute Background for all videos in a batch for parallel processing
(for listing all commands -- verify and remove 'echo' to run them) output >> '/parallel-test.txt'
parallel echo ./track_zfish.py {} --do_bg >> parallel-test.txt ::: ./_local_data/exp_*/*
parallel ./track_zfish.py {} --do_bg ::: ./_local_data/exp_*/*

// go through all background and fix bad ones by swapping with other similar one from the same-fish-same-protocol trails
cp name_of_GOOD_background.bg.png name_of_BAD_background.bg.png

// Compute and save roi for all videos in the batch
parallel ./track_zfish.py {} --do_roi ::: ./_local_data/exp_*/*

// Track fish (with reading roi and background files matching to it's name)
(--no-show : To hide annotation images while tracking to aid tracking speed..)
parallel ./track_zfish.py {} --do_track --old_roi --old_bg --no-show ::: ./_local_data/exp_*/*

// DONE !! for all options 
 ./track_zfish.py --help

--- test video and annotated data ---
https://tinyurl.com/qbio-zfish-test


ToDo :
- Make req files
- Add ID to videos for easy access i.e. E2F3U1 (-D1-R1-L1)
- Add frame_num_for_time_zero for all data
- Add analysis directory


FixMe / Issues :
(1)
Traceback (most recent call last):
  File "./track_zfish.py", line 195, in <module>
    bg = get_background(args.filename, bg_T, args.old_bg_flag, args.bg_path, args.db_flag)
  File "./track_zfish.py", line 37, in get_background
    frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
cv2.error: OpenCV(3.4.4) /io/opencv/modules/imgproc/src/color.cpp:181: error: (-215:Assertion failed) !_src.empty() in function 'cvtColor'

(2)
-- Some frame-drops in digitised videos
