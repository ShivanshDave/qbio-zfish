from psychopy import visual, core, event, monitors

mywin = visual.Window([200,200],monitor="testMonitor", units="deg")
circlestim = visual.Circle(win = mywin, radius=0.1, edges=100, fillColor='black', lineColor='white')
circlestim2 = visual.Circle(win = mywin, radius=0.2, edges=100, fillColor='white', lineColor='black')
#
#nLoomFrames = 20 
#for frameN in range(nLoomFrames): # time duration of stimuli (change accordingly) 
#    circlestim.setSize(1.5/nLoomFrames, '+')   # increase the size of stimuli - (maintain size:range) 
#    circlestim.pos += (0.05, -0.01)
#    circlestim.draw()
#    mywin.flip()
#    core.wait(0.1)

while True:
    if event.getKeys(keyList=["n"]):
        break

#while True:
#    nLoomFrames = 100 
#    for frameN in range(nLoomFrames):  
#        circlestim.setSize(1.0/nLoomFrames, '+')   
#        circlestim.draw()
#        mywin.flip  
#        if event.getKeys(keyList=["n"]):
#            break
#            event.clearEvents()
#        
mywin.close()
core.quit