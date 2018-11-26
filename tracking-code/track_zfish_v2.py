import numpy as np
import cv2
from tqdm import tqdm ## pip3 install tqdm 
from skimage.morphology import skeletonize
import sys
import skvideo.io ## pip3 install scikit-video

'''
author : Matteo Adorisio (@mattadori)
@Qbio summer school KITP 2018 - Liao Zfish module
'''

def get_background(filename,T):
    
    """
    filename = path to videofile\n
    T = how often to sample a new frame to compute background
    """
    
    print('Computing background ...')
         
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
    
    cv2.imwrite(filename+'.bg.png', bg)
    
    return(bg)





if __name__ == '__main__' :

    
    
    
    
    morph_kernel = np.ones((3,3),np.uint8)
    
    videofile = sys.argv[1] # '/media/mattadori/kingston/KITP/exp4/f2_us_rev_vid_2018-08-15_22-00-24.mp4'
    
    annotated_video =  skvideo.io.FFmpegWriter(videofile+"--ANNOTATED.mp4")
    
    background_image = videofile+'.bg.png'
    
    
    outfile = open(videofile+'.dat','w')
    outfile.write("# xr,yr 'tail' --- xl,yl 'head' \n")
    outfile.write("# 1:frame 2:xl 3:yl 4:xr 5:yr\n")
    
    computeBG = True ## change to False if testing and the background has been already computed
    if computeBG: 
        bg = get_background(videofile,T=10)
    else:
        bg = cv2.imread(background_image)
        bg = cv2.cvtColor(bg, cv2.COLOR_BGR2GRAY)

    
    cap = cv2.VideoCapture(videofile)
    
    totframes = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    
    ret, frame = cap.read()

    print("Select a region of interest (use the mouse to select a rectangular region) ...")
    roi = cv2.selectROI(frame)
    bg  = bg[int(roi[1]):int(roi[1]+roi[3]), int(roi[0]):int(roi[0]+roi[2])]
    
    
    f = 0 #frame
    
    while(ret):
        f += 1 
        frame = frame[int(roi[1]):int(roi[1]+roi[3]), int(roi[0]):int(roi[0]+roi[2])]
        
        frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        fg = cv2.subtract(bg,frame_gray)
        
        _, fg = cv2.threshold(fg, 10, 255, cv2.THRESH_BINARY)
        
        
#        fg = cv2.morphologyEx(fg, cv2.MORPH_OPEN, morph_kernel)
        fg = cv2.morphologyEx(fg, cv2.MORPH_CLOSE, morph_kernel)
        
        _, contours, contours_hierarchy = cv2.findContours(fg, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
       
        mask = np.zeros(fg.shape,np.uint8)
        
        for c in contours:
            
            if cv2.contourArea(c)>2500:
                
                #skel_file = open("./skel.txt","w")
                #body_file = open("./body.txt","w")
                
                
                cv2.drawContours(mask, [c], #square brackets are needed because cv2.drawContours needs arrays of arrays as input
                                 -1, # draw all contours (only one in this case)
                                 255, #white
                                 -1) # draw contour's interior
                
                
                cv2.drawContours(frame_gray, [c], #square brackets are needed because cv2.drawContours needs arrays of arrays as input
                                 -1, # draw all contours (only one in this case)
                                 255, #white
                                 1) # draw contour's interior
                
                
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
                     
        cv2.imshow('fg', frame_gray)     
        annotated_video.writeFrame(frame_gray)
        
        ret, frame = cap.read()
        
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

        
    
    cap.release()
    cv2.destroyAllWindows()
    annotated_video.close()
    outfile.close()


