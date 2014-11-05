'''
Created on Nov 3, 2014

@author: claresnyder, ezfe
'''
import pygame
from pygame.locals import *
from pygameapp import PygameApp
from actor import Actor

class SpaceAttackApp(PygameApp):
    def __init__(self, screensize = (512,512)):
        super().__init__(screensize = screensize, title="Space Attack!")
        pygame.key.set_repeat(100)
        self.setbackgroundcolor((0,0,50))
        self.player = Player(5,5,15,15,self.spritegroup)
        self.player.color = (120,120,120)
        self.player.draw()
    def handle_event(self, event):
        if event.type == KEYDOWN:
            if event.key == K_d:
                self.player.moveRight()
            if event.key == K_a:
                self.player.moveLeft()
        return True
    def poll(self):
        pass
        
class Player(Actor):
    xVelocity = 0
    yVelocity = 0
    def update(self):
        self.x = self.x + self.xVelocity
        self.xVelocity = self.xVelocity * .95
        
        print(self.y)
        
        if self.y < 100:
            self.yVelocity = self.yVelocity - 1
        else:
            self.yVelocity = self.yVelocity * -0.80
            print(self.yVelocity)
        self.y = self.y - self.yVelocity
    def moveRight(self):
        self.xVelocity += 1
    def moveLeft(self):
        self.xVelocity -= 1

myapp = SpaceAttackApp()
myapp.run(20)
