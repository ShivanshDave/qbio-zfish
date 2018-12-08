#!/usr/bin/python3

import numpy as np
import cv2
from tqdm import tqdm 
from skimage.morphology import skeletonize 
import sys
import skvideo.io 
import argparse

'''
author : Matteo Adorisio (@mattadori) and Shivansh (@dave-shivansh)
@Qbio summer school KITP 2018 - Liao Zfish module
'''

def get_background(filename,T,old_bg,bg_path,debug):
    
    background_image = filename+'.bg.png'
    if old_bg or bg_path :
        if bg_path :
            background_image = bg_path
        bg = cv2.imread(background_image)
        bg = cv2.cvtColor(bg, cv2.COLOR_BGR2GRAY)            
    else :
        if debug:
            print('Computing background - ',background_image)
         
        cap = cv2.VideoCapture(filename)    
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        nf = 0
        imgs = []
        for f in tqdm(range(total_frames)):
            ret, frame = cap.read()
            nf += 1       
            if nf % T == 0: 
                frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
                imgs.append(frame_gray)

        bg = np.median(np.asarray(imgs),axis=0).astype(np.uint8)
        cv2.imwrite(background_image, bg)
    if debug:
        print('Background used - ',background_image)
    return(bg)

def get_roi(filename,old_roi,roi_path,debug):

    roi_name = filename+'.roi'
    if old_roi or roi_path :
        if roi_path :
            roi_name = roi_path
        roi_file = open(roi_name,'r')
        roi = roi_file.readline()
        roi = [int(s) for s in roi.split() if s.isdigit()]
    else :
        if debug:
            print('Setting ROI - ',roi_name)
        
        cap = cv2.VideoCapture(filename) 
        ret, frame = cap.read()
        cap.release()

        roi = cv2.selectROI(frame)
        cv2.destroyAllWindows()         
        
        roi_file = open(roi_name,'w')
        roi_file.write("{} {} {} {}".format(int(roi[0]),int(roi[1]),int(roi[2]),int(roi[3])))
    roi_file.close()
    if debug:
        print('ROI - ',roi, roi_name)
    return(roi)

def track_fish(videofile,bg,roi,no_show,debug):
    if debug:
        print("Starting fish tracking...")
        

    bg  = bg[int(roi[1]):int(roi[1]+roi[3]), int(roi[0]):int(roi[0]+roi[2])]

    annotated_video =  skvideo.io.FFmpegWriter(videofile+"--ANNOTATED.mp4")
    outfile = open(videofile+'.dat','w')
    outfile.write("# xr,yr 'tail' --- xl,yl 'head' \n")
    outfile.write("# 1:frame 2:xl 3:yl 4:xr 5:yr\n")

    cap = cv2.VideoCapture(videofile)
    totframes = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    ret, frame = cap.read()

    if debug:    
        print("Tracking fish - ",videofile, no_show)

    f = 0 #frame   
    while(ret):
        f += 1 
        frame = frame[int(roi[1]):int(roi[1]+roi[3]), int(roi[0]):int(roi[0]+roi[2])]        
        frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        fg = cv2.subtract(bg,frame_gray)       
        _, fg = cv2.threshold(fg, 10, 255, cv2.THRESH_BINARY)
        morph_kernel = np.ones((3,3),np.uint8)
        fg = cv2.morphologyEx(fg, cv2.MORPH_CLOSE, morph_kernel) # _OPEN        
        _, contours, contours_hierarchy = cv2.findContours(fg, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)       
        mask = np.zeros(fg.shape,np.uint8)
        
        for c in contours:
            
            if cv2.contourArea(c)>2500:
                #skel_file = open("./skel.txt","w")
                #body_file = open("./body.txt","w")
                
                #square brackets for cv2.drawContours needs arrays of arrays as input
                cv2.drawContours(mask, [c],
                                 -1, # draw all contours (only one in this case)
                                 255, #white
                                 -1) # draw contour's interior
                
                cv2.drawContours(frame_gray, [c],
                                 -1, 
                                 255,
                                 1)
                                
                pixelpoints = np.transpose(np.nonzero(mask))

                #for p in pixelpoints:
                #    body_file.write("{} {}\n".format(p[0],p[1]))

                #M = cv2.moments(c)
                #cx = int(M["m10"] / M["m00"])
                #cy = int(M["m01"] / M["m00"])
                                
                leftmost = c[c[:,:,0].argmin()][0]
                cv2.circle(frame_gray,tuple(leftmost), 4, (255,0,0), -1) 
                rightmost = c[c[:,:,0].argmax()][0]
                cv2.circle(frame_gray,tuple(rightmost), 4, (255,0,0), -1)                 
                
                outfile.write("{} {} {} {} {}\n".format(f,leftmost[0],leftmost[1],rightmost[0],rightmost[1]))
                                
                skel = skeletonize(np.asarray(mask/255,dtype=np.uint8)).astype(np.uint8)
                #skel = thin(np.asarray(mask/255,dtype=np.uint8),max_iter=10).astype(np.uint8)
                pixelskel = np.transpose(np.nonzero(skel))

                #leftmost = pixelskel[pixelskel[:,1].argmin(),:]
                #rightmost = pixelskel[pixelskel[:,1].argmax(),:]
                                
                #pixelskel = np.append(pixelskel,[np.asarray([leftmost[1],leftmost[0]])],axis=0) # add leftmost
                
                for p in pixelskel:
                    cv2.circle(frame_gray,(p[1],p[0]), 1, (255,0,0), -1)
                    #skel_file.write("{} {}\n".format(p[0],p[1]))
                                    
                #body_file.flush()
                #skel_file.flush()
                #body_file.close()
                #skel_file.close()                
                
        cv2.putText(frame_gray, str(int(f))+'/'+str(totframes),(50,frame_gray.shape[0]-10), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), lineType=cv2.LINE_AA)
        
             
        annotated_video.writeFrame(frame_gray)
        
        ret, frame = cap.read()
        
        if not no_show :             
            cv2.imshow('fg', frame_gray)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
   
    cap.release()
    cv2.destroyAllWindows()
    annotated_video.close()
    outfile.close()


if __name__ == '__main__' :
    
    parser = argparse.ArgumentParser(description='Fish tracking')

    parser.add_argument("filename", help='Video file name')
    parser.add_argument("--do_track", dest='track_flag', action='store_true', help="Track fish")

    parser.add_argument("--do_roi", dest='roi_flag', action='store_true', help="Compute and save roi")
    parser.add_argument("--old_roi", dest='old_roi_flag', action='store_true', help="Use precomputed roi")
    parser.add_argument("--roi_path", default=None, help="Give custom roi path")

    parser.add_argument("--do_bg", dest='bg_flag', action='store_true', help="Compute background")
    parser.add_argument("--old_bg", dest='old_bg_flag', action='store_true', help="Use precomputed background")
    parser.add_argument("--bg_path", default=None, help="Give custom background")

    parser.add_argument("--debug", dest='db_flag', action='store_true', help="Debug")
    parser.add_argument("--no-show", dest='no_show_flag', action='store_true', help="Hide annotation (faster)")
    
    args = parser.parse_args()
    bg_T = 10 # Select 1:bg_T files for bg compute
    
    if args.bg_flag or args.track_flag :
        bg = get_background(args.filename, bg_T, args.old_bg_flag, args.bg_path, args.db_flag)

    if args.roi_flag or args.track_flag  :
        roi = get_roi(args.filename,args.old_roi_flag, args.roi_path, args.db_flag)
    
    if args.track_flag :
        track_fish(args.filename,bg,roi,args.no_show_flag,args.db_flag)

    exit()

