'''
qbio zibra fish visual stimuls control
author = shivansh dave
'''

from psychopy import visual, core, event

class visStim:

    def __init__(self,speed,size,ori,tex):
        self.speed=speed
        self.tex=tex 
        self.size=size
        self.ori = ori
        stimH = 600
        stimW = 800
        self.mywin = visual.Window([stimW,stimH],monitor="testMonitor", units="deg", pos=(330,150))
        self.grating = visual.GratingStim(win=self.mywin, size=(100,100), mask=None, pos=[0,0], sf=self.size, ori= self.ori, tex=self.tex)
        
        '''
        for timer :
                        
            timer = core.Clock()

            timer.reset()
            time_start = timer.getTime()
            countdownTimer = core.CountdownTimer(timeout)
            and; while countdownTimer.getTime() > 0.0:

        '''

    def __del__(self):
        self.mywin.close()
        core.quit()
    
    def getClick(self,key="n",wait=0):
         while True:
             if event.getKeys(keyList=[key]):
                 return 1
             event.clearEvents()
             if wait==0:
                 return 0
             else:
                 core.wait(0.01)

    def setTimeout(self,timeout):
        timer = core.Clock()
        timer.reset()
        self.cntDwn = core.CountdownTimer(timeout)
    
    def checkTimeout(self):
        if self.cntDwn.getTime() > 0.0:
            return False
        else:
            return True

    def bars_move(self, dir, speed, timeout=0):
        if timeout > 0:
            self.setTimeout(timeout)
        while True:
            self.grating.setPhase(speed, dir)
            self.grating.draw()
            self.mywin.flip()
            if timeout == 0 :
                if self.getClick("n"):
                     break
            else:
                if self.checkTimeout():
                     break

    def white_screen(self):
        self.grating.tex = None
        self.bars_move('+',0)
        self.grating.tex = self.tex

    def steady_then_flow(self):
        def _stf_(dir):
            self.bars_move(dir,0)
            self.bars_move(dir,self.speed)
        self.white_screen()
        _stf_('+')
        _stf_('-')
        _stf_('-')
        _stf_('+')
        _stf_('-')
        _stf_('+')
        _stf_('+')
        _stf_('-')

    def flow_then_reverse(self):
        def _ftr_(dir1, dir2):
            self.bars_move(dir1,0)
            self.bars_move(dir1,self.speed)
            self.bars_move(dir2,self.speed)
        self.white_screen()
        _ftr_('+','-')
        _ftr_('-','+')
        _ftr_('-','+')
        _ftr_('+','-')
        _ftr_('-','+')
        _ftr_('+','-')
        _ftr_('+','-')
        _ftr_('-','+')

    def sensory_conflic(self, dir=1, N=3, timeout=0):
        def _ftr_(dir1, dir2):
#            self.bars_move(dir1,0)
            self.bars_move(dir1,self.speed)
            self.bars_move(dir2,self.speed)
        self.white_screen()
        if timeout > 0:
            self.setTimeout(timeout)
        for i in range(N):
            if dir==1 :
                _ftr_('+','-')
            else :
                _ftr_('-','+')
            if self.checkTimeout():
                    break

    def single_bar_move(self, dir='+', N=0, timeout=0):
        winW = 12
        winH = 15
        limit = winW/2
        speed=self.speed
        self.bar = visual.Rect(win=self.mywin, width=self.size/3, height=winH, fillColor='black', lineColor=None)
        self.bg = visual.Rect(win=self.mywin, width=winW, height=winH, fillColor='white')
        self.bar.pos=(-limit,0)
        i=N
        if timeout > 0:
            self.setTimeout(timeout)
        while True:
            if dir == '+':
                self.bar.pos += (speed,0)
                if self.bar.pos[0] > limit:
                    self.bar.pos=(-limit,0)
                    i-=1
                    if i==0:
                        i=N
                        self.getClick("n",1)
            else:
                self.bar.pos -= (speed,0)
                if self.bar.pos[0] < limit*(-1):
                    self.bar.pos=(limit,0)
                    i-=1
                    if i==0:
                        i=N
                        self.getClick("n",1)
            self.bg.draw()
            self.bar.draw()
            self.mywin.flip()
            if timeout == 0 :
                if self.getClick("n"):
                    break
            else:
                if self.checkTimeout():
                    break

    def looming_stim(self):
        circlestim = visual.Circle(win = self.mywin, edges=256,radius=1, units='deg', fillColor='white', lineColor='black')
        circlestim.draw()
        self.mywin.flip()
#        nLoomFrames = 100 
#        for frameN in range(nLoomFrames): # time duration of stimuli (change accordingly) 
#            circlestim.setSize(1.0/nLoomFrames, '+')  # increase the size of stimuli - (maintain size:range) 
#            #background.draw() 
#            circlestim.draw() 
#            self.mywin.flip() #flip is preferred to update() (equivalent but deprecated) 

    def loop_stim(self, s=1, N=0):    
        while True:
            if s==1:
                 self.single_bar_move('+',0,2)
                 self.single_bar_move('-',0,2)
            elif s==2:
                 self.bars_move('+',self.speed, 2)
                 self.bars_move('-',self.speed, 2)
            N-=1
            if N==0:
                 break


width = 1.3 #(1.3 for epson; 0.7 for LED projector)

s1 = visStim(speed=0.1,size=width,ori= 0,tex='sqr')
#s1.white_screen()
#s1.bars_move('+',0.05, 0)


# -- Experiment ------> Upstream-downstream
#s1.steady_then_flow()  #--EXP--3
#s1.flow_then_reverse() #--EXP--4
#s1.sensory_conflic(dir=1, N=16) #--EXP--GroupBehavior
#s1.single_bar_move(N=0, timeout=0) 
s1.loop_stim(N=5)

del s1


s2 = visStim(speed=0.1,size=width,ori= 90,tex='sqr')

# -- Experiment ------> Roll - CW-CCW
#s2.steady_then_flow()   #--EXP--5
#s2.flow_then_reverse() #--EXP--6

del s2

####### EXTRA #######$
'''
#f4os5 : s1 = visStim(speed=0.1,size=0.7,tex='sqr')
#f4vbs1 : s1 = visStim(speed=0.01,size=0.7,tex='sqr')
#f4vbs3 : s1 = visStim(speed=0.05,size=0.7,tex='sqr')

Screen effect on Exp3 to Exp 6 
- L -> R : Upstream (+)
- R -> L : Downstream (-)
- Upward : CW (-)
- Downward : CCW (+)

'''