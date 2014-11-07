'''
Created on Nov 3, 2014

@author: claresnyder, ezfe
'''
import pygame
from pygame.locals import *
from pygameapp import PygameApp
from actor import Actor

class SpaceAttackApp(PygameApp):
    width = 512
    height = 512
    def __init__(self):
        super().__init__(screensize = (self.width, self.height), title="Space Attack!")
        pygame.key.set_repeat(100)
        self.setbackgroundcolor((0,0,50))
        self.player = Player(5,5,15,15,self.spritegroup)
        self.player.color = (120,120,120)
        self.player.draw()
        self.exampleWall = Actor(5,100,400,10,self.spritegroup)
        self.exampleWall.color = (250,250,250)
        self.exampleWall.draw()
    def handle_event(self, event):
        if event.type == KEYDOWN:
            if event.key == K_d:
                self.player.moveRight()
            if event.key == K_a:
                self.player.moveLeft()
            if event.key == K_w:
                self.player.jump()
        return True
    def poll(self):
        pass
        
class Player(Actor):
    xVelocity = 0
    yVelocity = 0
    def update(self):
        self.x = self.x + self.xVelocity
        self.xVelocity = self.xVelocity * .95
        
        if len(self.overlapping_actors()) == 0:
            self.yVelocity = self.yVelocity - 0.5
        else:
            wall = self.overlapping_actors()[0]
            if (self.y + self.height) > (wall.y + 1):
                self.y = wall.y + 1 - self.height
            self.yVelocity = 0
        self.y = self.y - self.yVelocity
        
        if self.x < 0:
            self.x += myapp.width
        elif self.x > myapp.width:
            self.x -= myapp.width
        if self.y < 0:
            self.y += myapp.height
        elif self.y > myapp.height:
            self.y -= myapp.height
        
    def moveRight(self):
        self.xVelocity += 1
    def moveLeft(self):
        self.xVelocity -= 1
    def jump(self):
        if len(self.overlapping_actors()) != 0:
            self.y -= 1
            self.yVelocity = 8

myapp = SpaceAttackApp()
myapp.run(20)
