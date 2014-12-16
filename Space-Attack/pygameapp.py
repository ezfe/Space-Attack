import pygame
from pygame.locals import *

class PygameApp(object):
    """
    Class that encapsulates a basic pygame application.
    """
    def __init__(self, screensize = (400,400), fullscreen = False, title = 'PygameApp Window'):
        """
        Argument to initializer is the desired screen size and/or desire for full screen
        """
        # save copies of the creation arguments
        self.screensize = screensize
        self.fullscreen = fullscreen
        self.title = title

        # create a pygame group for tracking sprites
        self.spritegroup = pygame.sprite.LayeredDirty() 
        
        self.elapsedms = 0                          # keep track of the elapsed time
        
        pygame.init()                               # every pygame app must do this
        self.clock = pygame.time.Clock()            # make a clock object to manage a frame rate
        
        # open a window different ways, depending on fullscreen setting
        if self.fullscreen:
            # find out what the current display capabilities are
            self.displayinfo = pygame.display.Info()
            self.screensize = (self.displayinfo.current_w, self.displayinfo.current_h)
            self.display = pygame.display.set_mode(self.screensize, FULLSCREEN)
        else:
            self.display = pygame.display.set_mode(self.screensize) # create a window
            pygame.display.set_caption(self.title)
        self.setbackgroundcolor(pygame.Color('black'))

    def setbackgroundcolor(self, color):
        self.backgroundcolor = color
        self.erase()

    def erase(self):
        self.display.fill(self.backgroundcolor)
        self.background = self.display.copy()       # Create a cleared background surface

    def run(self, fps = 50):
        """
        Begin display loop. Optional argument sets the frames per second desired.
        """
        self.fps = fps
        running = True
        
        # repeat the display loop
        while running:
            # get events
            for event in pygame.event.get():
                if event.type != QUIT:
                    running = self.handle_event(event)  # let the user event handler deal with it
                else:
                    running = False
            self.elapsedms += self.clock.tick(self.fps)
            # do any regular, periodic processing
            self.poll()
            self.spritegroup.update()									# call udpate functions in sprites
            self.spritegroup.clear(self.display, self.background)       # erase sprite backgrounds as needed
            pygame.display.update(self.spritegroup.draw(self.display))  # update the display
        # fell out of loop
        self.quit()

    def quit(self):
        """
        Close up and quit. Override this method as desired.
        """
        pygame.quit()


    def handle_event(self, event):
        """
        Deal with any events OTHER than QUIT, which is handled elsewhere. This method SHOULD
        be overridden in your own application.
        """
        return True                                     # default: keep running

    def poll(self):
        """
        Do any processing that should be done on each frame. This method SHOULD
        be overridden in your own application.
        """
        pass
