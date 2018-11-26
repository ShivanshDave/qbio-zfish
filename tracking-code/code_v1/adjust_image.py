# Originally develped by Matteo Adorisio
# @Qbio summer school KITP 2018 - Liao Zfish module - 

import sys
import cv2
import numpy as np
import pylab as pl
from roi.roipoly import roipoly 

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



if __name__ == '__main__' :


        filename = sys.argv[1] #<<<<<<<<<<<<<<<<<< video file
        
        cap = cv2.VideoCapture(filename)
        print cap
        ret, frame0 = cap.read()
        print ret
        frame0 = cv2.cvtColor(frame0,cv2.COLOR_BGR2GRAY)

        roi = cv2.selectROI(frame0)
        cv2.destroyAllWindows()
        
        ### test: code to choose irregular ROI
        #pl.imshow(frame0, interpolation='nearest', cmap="Greys")
        #pl.colorbar()
        #pl.title("left click: line segment,  right click: close region")

        ##let user draw ROI
        #ROI = roipoly(roicolor='r') #let user draw first ROI

        
        #vertices=np.array([[np.int32(x), np.int32(y)] for x,y in zip(ROI.allxpoints,ROI.allypoints)])

        #rame0 = roi(frame0,vertices)
        #nonzero = np.asarray(np.where(frame0>0))
        
        
        #cv2.imshow('roi',frame0)
        #cv2.waitKey()
        

        
        #roi = cv2.selectROI(frame0)
        cv2.destroyAllWindows()
        
        totframes = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        cv2.namedWindow("bc",cv2.WINDOW_NORMAL)
        cv2.resizeWindow("bc",800,600)

        cv2.createTrackbar("f","bc",1,totframes-1,nothing)
        cv2.createTrackbar("contr","bc",1,50,nothing)
        cv2.createTrackbar("bright","bc",0,255,nothing)
        #cv2.createTrackbar("C","bc",2,255,nothing)
        cv2.createTrackbar("N","bc",21,1555,nothing)
        #cv2.createTrackbar("thr","bc",0,255,nothing)
        
        f = 1
        while (True):

                cap.set(cv2.CAP_PROP_POS_FRAMES, f)
                ret, frame = cap.read()

                
                #frame_no = cap.get(cv2.CAP_PROP_POS_FRAMES)
                #print frame_no
                
                    

                frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY) 
                frame = frame[int(roi[1]):int(roi[1]+roi[3]), int(roi[0]):int(roi[0]+roi[2])]
                       
                #frame = roi(frame,vertices)
                
                #cap.set(cv2.CAP_PROP_POS_FRAMES, f)
                f = cv2.getTrackbarPos("f","bc")
                contr = cv2.getTrackbarPos("contr","bc")
                contr = contr*0.25
                bright = cv2.getTrackbarPos("bright","bc")
                #thr = cv2.getTrackbarPos("thr","bc")
                #C = cv2.getTrackbarPos("C","bc")
                N = cv2.getTrackbarPos("N","bc")
                if N % 2 == 0: N = N + 1
                
                
                mul_img = cv2.multiply(frame,np.array([float(contr)]))                    
                frame_adj = cv2.add(mul_img,np.array([float(bright)]))
                frame_adj = cv2.GaussianBlur(frame_adj, (3,3), 5)
                #frame_adj = cv2.equalizeHist(frame_adj)
                frame_adj = cv2.adaptiveThreshold(frame_adj, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, N, 1)
#                _,frame_adj = cv2.threshold(frame_adj,thr,255,cv2.THRESH_BINARY_INV)

                cv2.imshow("bc",frame_adj)

                k = cv2.waitKey(1) & 0xFF
                if k == ord('q'):
                    
                    print '######################################################'
                    print '## copy and paste the lines below into track_zfish: ##'
                    print '## -------------------------------------------------##'
                    #print 'roi=',roi
                    print 'contr=', contr
                    print 'bright=',  bright
                    print '## Adaptive gaussian threshold parameters:'
                    print '## see https://docs.opencv.org/3.4.0/d7/d1b/group__imgproc__misc.html#ga72b913f352e4a1b1b397736707afcde3 for an explanation'
                    print 'N=',  N
                    #print 'C=',  C
                    print 'roi =',roi
                    print 'video_path = ', "'" + filename + "'"
                    #print '## -------------------------------------------------##'
                    #print '## ROI vertices'
                    #print 'vertices =', vertices
                    print '######################################################'
                    break
                
        cv2.destroyAllWindows()
