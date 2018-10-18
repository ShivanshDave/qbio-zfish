from psychopy import visual, core, event, monitors

# set the window size. 
win = visual.Window([1920,1080], fullscr=False, allowGUI=False, units='deg', monitor='testMonitor')

# create starting stimulus size in degrees
circlestim = visual.Circle(win = win,  edges=256,radius=1, units='deg', fillColor='white', lineColor='white')

# create timing variables (use these at some point)
clock = core.Clock()
t= clock.getTime()
keys=event.getKeys()

# start stimulus
background.draw()
win.flip()
core.wait(120.0)

# create repeating loom every ? frames
for e in range(8): # number of epochs
    for s in range(1): # number of stimuli per epoch (change accordingly) - I alter this on a different experiment
        for frameN in range(40): # time duration of stimuli (change accordingly)
            circlestim.setSize(1, '+')  # increase the size of stimuli - (maintain size:range)
            background.draw()
            circlestim.draw()
            win.update()
        background.draw()
        core.wait(0.6) # show final circle size for 0.? seconds
        circlestim.setSize(0.5) # return circle to initial size
        win.flip()
        background.draw()
        core.wait(1.0)
        background.draw()
        if event.getKeys(keyList=["q"]):
                core.quit()
    win.flip()
    core.wait(58)
# add in key abort ........ currently does not work
core.wait(60.0)

# when experiement is completed = Close programe
win.close()
core.quit 