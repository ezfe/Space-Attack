'''
Created on Nov 3, 2014

@author: claresnyder
'''
import pygame
from pygameapp import PygameApp

class SpaceAttackApp(PygameApp):
    def __init__(self, screensize = (400,400)):
        super().__init__(screensize = screensize, title="Space Attack!")
        pygame.key.set_repeat(100)
        self.setbackgroundcolor((0,0,50))
        
myapp = SpaceAttackApp()
myapp.run(100)