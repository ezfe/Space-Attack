'''
Created on Nov 3, 2014

@author: claresnyder, ezfe
'''
import pygame
from pygame.locals import *
from pygameapp import PygameApp
from actor import Actor
import json

class SpaceAttackApp(PygameApp):
    width = 512
    height = 512
    level = {}
    mainmenu = True
    backgroundImage = None
    
    def __init__(self):
        super().__init__(screensize = (self.width, self.height), title="Space Attack!")
        pygame.key.set_repeat(100)
        self.setbackgroundcolor((0,0,50))
        self.backgroundImage = Background(0, 0,512,512,self.spritegroup)
        self.backgroundImage.setImage("mainmenu.png")
            
    def handle_event(self, event):
        if event.type == KEYDOWN:
            if event.key == K_SPACE and self.mainmenu:
                self.mainmenu = False
                self.backgroundImage.setImage("levelbackground.png")
                self.loadLevel(1)
            if event.key == K_d:
                self.player.moveRight()
            if event.key == K_a:
                self.player.moveLeft()
            if event.key == K_w:
                self.player.jump()
            if event.key == K_RIGHT:
                self.player2.moveRight()
            if event.key == K_LEFT:
                self.player2.moveLeft()
            if event.key == K_UP:
                self.player2.jump()
        return True
    def poll(self):
        pass
    
    def loadLevel(self, levelNumber):
        f = open('levels/level{}.json'.format(levelNumber),"r+")
        self.level = json.load(f)
        f.close()
        
        self.player = Player(self.level['spawn']['player1']['x'], self.level['spawn']['player1']['y'],15,15,self.spritegroup)
        self.player.color = (120,120,120)
        self.player.draw()
        self.player2 = Player(self.level['spawn']['player2']['x'], self.level['spawn']['player2']['y'],15,15,self.spritegroup)
        self.player2.color = (120,0,120)
        self.player2.draw()
        
        self.goal = LevelGoal(230,180,50,50,self.spritegroup)
        
        for wall in self.level['walls']:
            self.wall = Wall(wall['x'],wall['y'],wall['width'],wall['height'],self.spritegroup)
            self.wall.color = (250,250,250)
            self.wall.draw()
    
class Wall(Actor):
    pass

class Background(Actor):
    def __init__(self, x, y, width, height, actor_list):
        super().__init__(x, y, width, height, actor_list)
        
    def setImage(self, image):
        self.image = pygame.image.load(image).convert()
        self.dirty = 1

class LevelGoal(Actor):
    def __init__(self, x, y, width, height, actor_list):
        super().__init__(x, y, width, height, actor_list)
        self.image = pygame.image.load("winstar.png").convert_alpha()

class Player(Actor):        
    xVelocity = 0
    yVelocity = 0
    def update(self):
        self.x = self.x + self.xVelocity
        self.xVelocity = self.xVelocity * .95
        
        if len(self.overlapping_actors(Wall)) == 0:
            self.yVelocity = self.yVelocity - 0.5
        else:
            wall = self.overlapping_actors(Wall)[0]
            wallCenterY = wall.height/2 + wall.y
            playerCenterY = self.height/2 + self.y
            if playerCenterY < wallCenterY:
                if (self.y + self.height) > (wall.y + 1):
                    self.y = wall.y + 1 - self.height 
            else:
                self.y = wall.y + wall.height
                self.yVelocity = 0
                
            self.yVelocity = 0 
        self.y = self.y - self.yVelocity 
        if self.yVelocity < -8:
            self.yVelocity = -12
        
        if myapp.level['wrap']['horizontal']:
            if self.x < 0:
                self.x += myapp.width
            elif self.x > myapp.width:
                self.x -= myapp.width
        else:
            if self.x < 0:
                self.x = 0
                self.xVelocity = 0
            elif self.x > myapp.width:
                self.x = myapp.width - 15
                self.xVelocity = 0
                
        if myapp.level['wrap']['vertical']:
            if self.y < 0:
                self.y += myapp.height
            elif self.y > myapp.height:
                self.y -= myapp.height
        else:
            if self.y < 0:
                self.y = 0
            elif self.y > myapp.height:
                self.y = myapp.height - 15
                
    def moveRight(self):
        if self.x < 497:
            self.xVelocity += 1
    def moveLeft(self):
        self.xVelocity -= 1
    def jump(self):
        if len(self.overlapping_actors(Wall)) != 0:
            self.y -= 1
            self.yVelocity = 8

myapp = SpaceAttackApp()
myapp.run(20)
