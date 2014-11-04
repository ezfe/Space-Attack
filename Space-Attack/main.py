'''
Created on Nov 3, 2014

@author: claresnyder
'''
import pygame
from pygame.locals import *
from pygameapp import PygameApp
from actor import Actor

class SpaceAttackApp(PygameApp):
    def __init__(self, screensize = (400,400)):
        super().__init__(screensize = screensize, title="Space Attack!")
        pygame.key.set_repeat(100)
        self.setbackgroundcolor((0,0,50))
        self.player = Player(5,5,15,15,self.spritegroup)
        self.player.color = (120,120,120)
        self.player.draw()
    def handle_event(self, event):
        if event == KEYDOWN:
            if event.key == K_d:
                print("hey!")
        return True
        
class Player(Actor):
    pass
    
myapp = SpaceAttackApp()
myapp.run(20)