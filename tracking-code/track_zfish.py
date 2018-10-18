# Originally develped by Matteo Adorisio
# @Qbio summer school KITP 2018 - Liao Zfish module - 

from tqdm import tqdm
import numpy as np
import cv2
#from skimage.color import rgb2grey
#from skimage.morphology import skeletonize
import os, os.path
import sys
import skvideo.io


def nothing(x):
  pass


def roi(img,vertices):
    # blank mask:
    mask = np.zeros_like(img)

    # filling pixels inside the polygon defined by "vertices" with the fill color
    cv2.fillPoly(mask, [vertices], 255)

    # returning the image only where mask pixels are nonzero
    masked = cv2.bitwise_and(img, mask)
    
    return masked


##############################################
##############################################
##copy and paste the output of adjust_image.py
##############################################
##############################################
contr= 4.0
bright= 0
## Adaptive gaussian threshold parameters:
## see https://docs.opencv.org/3.4.0/d7/d1b/group__imgproc__misc.html#ga72b913f352e4a1b1b397736707afcde3 for an explanation
N= 613
roi = (293, 175, 943, 481)
video_path =  '/home/mattadori/research_projects/KITP/movies/exp10/sampled_video/f3-ds_rev-vid_2018-08-22_23-08-11.CUT.mp4'
######################################################


#video_path = sys.argv[1]


#video_path='/home/mattadori/research_projects/KITP/movies/exp3_projection-static-to-upstream-downstream/f1-static-ud-vid_2018-08-15_18-01-27.mp4'


if __name__ == '__main__' :
        
        
        
        filename, file_extension = os.path.splitext(video_path)
        
        output_datafile = open(filename+str('.dat'),'w+')
        output_datafile.write("## 1:frame_no 2:cx 3:cy 4:leftmost_x 5:leftmost_y 6:rightmost_x 7:rightmost_y\n")
        
        cap = cv2.VideoCapture(video_path)
        totframes = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        writer = skvideo.io.FFmpegWriter(filename+"--ANNOTATED.mp4")
        
        #erosion_kernel = np.ones((3,3),np.uint8)        
        
        
        #while(cap.isOpened()):

        print 'Processing '+filename
        for frame_no in range(int(totframes)):    

            #print filename + ' :: ' + str(float(frame_no)/float(totframes)*100) 

            ## print frame_no
            ret, frame=cap.read()

            #frame_no = cap.get(cv2.CAP_PROP_POS_FRAMES)

            #print filename, str(frame_no)+'/'+str(totframes)
            
            if ret==False:
              break

            #if frame_no == 0:
            #  roi = cv2.selectROI(frame)
            #  cv2.destroyAllWindows()

            frame = frame[int(roi[1]):int(roi[1]+roi[3]), int(roi[0]):int(roi[0]+roi[2])]
            
            frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

            #frame_gray = roi(frame_gray,vertices)
            ## parameters to adjust contrast and brightness
            mul_img = cv2.multiply(frame_gray,np.array([float(contr)]))                    # mul_img = img*alpha
            frame_gray = cv2.add(mul_img,np.array([float(bright)]))                      # new_img = img*alpha + beta
            frame_gray = cv2.GaussianBlur(frame_gray, (3,3), 5)
            frame_gray = cv2.adaptiveThreshold(frame_gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, N, 1)
            
            im2, contours, hierarchy = cv2.findContours(frame_gray, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
            filled_contours = np.zeros(frame.shape,dtype=np.uint8)
            
            for n,contour in enumerate(contours):
                
                M = cv2.moments(contour)
                h = hierarchy[0][n][3]==-1 and hierarchy[0][n][2]==-1 ## only parent contours. if true the contour doesn't have subcontours
                match_length = cv2.arcLength(contour,True) > 200 and cv2.arcLength(contour,True) < 600
                
                if h and match_length: 

                        if M['m00'] > 0:
                                
                                cx = int(M['m10']/M['m00'])
                                cy = int(M['m01']/M['m00'])
                                
                                leftmost = tuple(contour[contour[:,:,0].argmin()][0])
                                rightmost = tuple(contour[contour[:,:,0].argmax()][0])


                                output_datafile.write("%d %d %d %d %d %d %d\n" % (frame_no,cx,cy,leftmost[0],leftmost[1],rightmost[0],rightmost[1]))
                                #center of mass
                                cv2.circle(frame,(cx,cy),color=(255,255,255),radius=5,thickness=-1)
                                #head and tail
                                cv2.circle(frame,leftmost,color=(255,255,255),radius=5,thickness=-1)
                                cv2.circle(frame,rightmost,color=(255,255,255),radius=5,thickness=-1)

                                length = cv2.arcLength(contour,True)
                                #cv2.putText(frame,str(length),(cx,cy), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 0), lineType=cv2.LINE_AA)
                                
                                #cv2.drawContours(frame, contours, n, (255,255,255))
                                cv2.drawContours(filled_contours, contours, n, (255,255,255),thickness=-1) #fill contours area
                                                 
                                rect = cv2.minAreaRect(contour)
                                box = cv2.boxPoints(rect)
                                box = np.int0(box)

                                xmax_box = np.max([p[0] for p in box])
                                ymax_box = np.max([p[1] for p in box])
                                xmin_box = np.min([p[0] for p in box])
                                ymin_box = np.min([p[1] for p in box])

                                #cv2.drawContours(frame,[box],0,(0,0,255),2)

                                x,y,w,h = cv2.boundingRect(contour)

                                
            
    
                                
	               

                    
            # skel_image = skeletonize(filled_contours/255).astype(np.uint8)*255
            # nonzero_skel = np.nonzero(skel_image)
            # for p in zip(nonzero_skel[0],nonzero_skel[1]):
            #     print nframes,p[0],p[1]
            #     cv2.circle(frame,(p[1],p[0]),color=(255,255,255),radius=1,thickness=-1)
            # print ''
            # print ''
	    #print int(frame_gray.shape[1]/2.),int(frame_gray.shape[0]/2.)
            cv2.putText(frame, str(int(frame_no))+'/'+str(totframes),(50,frame_gray.shape[0]-10), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), lineType=cv2.LINE_AA)
	    
	    #stacked_images = np.concatenate((frame_gray, frame), axis=0)
	    

	    writer.writeFrame(frame) #write annotated frame to video
	    
            #cv2.imwrite('./mask_'+str(nframes)+'.png', frame)
            ## frame[ymin_box:ymax_box, xmin_box:xmax_box]

            #focus = np.zeros((800,600),dtype=np.uint8)

            
        
            #focus[zip(np.where(frame_gray[y:y+h,x:x+w])[0],np.where(frame_gray[y:y+h,x:x+w])[1])] = frame_gray[y:y+h,x:x+w]
            
                
            #cv2.imshow('frame_gray', frame)
            
            
                           
                        
            keyboard = cv2.waitKey(1) & 0xFF
        
            if keyboard==ord('q'):
              output_datafile.close()
              cap.release()
	      writer.close()
              exit()

        print 'DONE '+ filename            
        output_datafile.close()
        cap.release()
        writer.close()

    
