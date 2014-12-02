'''
Created on Nov 3, 2014

@author: claresnyder, ezfe
'''
import pygame
from pygame.locals import *
from pygameapp import PygameApp
from actor import Actor
import json
import sys

class SpaceAttackApp(PygameApp):
    width = 512
    height = 512
    level = {}
    levelnumber = 0
    window = "main menu"
    backgroundImage = None
    
    editorTempData = {"x":None,"y":None}
    editorTempLevel = {"walls":[],"goal":{"x":0,"y":0},"wrap":{"horizontal":False,"vertical":False},"spawn":{"player1":{"x":20,"y":492},"player2":{"x":492,"y":20}}}
    editorGoalSprite = None
    editorPlayer1Sprite = None
    editorPlayer2Sprite = None

    def __init__(self):
        super().__init__(screensize = (self.width, self.height), title="Space Attack!")
        pygame.key.set_repeat(100)
        self.setbackgroundcolor((0,0,50))
        self.backgroundImage = Background(0, 0,512,512,self.spritegroup)
        self.backgroundImage.setImage("images/mainmenu.png")
            
    def handle_event(self, event):
        if event.type == KEYDOWN:
            if self.window == "editor":
                if event.key == K_SPACE:
                    print(json.dumps(self.editorTempLevel))
                if event.key == K_g:
                    x = pygame.mouse.get_pos()[0]
                    y = pygame.mouse.get_pos()[1]
                    self.editorTempLevel["goal"]["x"] = x
                    self.editorTempLevel["goal"]["y"] = y
                    if (self.editorGoalSprite == None):
                        self.editorGoalSprite = LevelGoal(x,y,30,24,self.spritegroup)
                    else:
                        self.editorGoalSprite.x = x
                        self.editorGoalSprite.y = y
                if event.key == K_1:
                    x = pygame.mouse.get_pos()[0]
                    y = pygame.mouse.get_pos()[1]
                    self.editorTempLevel["spawn"]["player1"]["x"] = x
                    self.editorTempLevel["spawn"]["player1"]["y"] = y
                    if (self.editorPlayer1Sprite == None):
                        self.editorPlayer1Sprite = Player(x,y,30,24,self.spritegroup,K_d,K_a,K_w,"green-alien.png")
                        self.editorPlayer1Sprite.doUpdate = False
                    else:
                        self.editorPlayer1Sprite.x = x
                        self.editorPlayer1Sprite.y = y
                if event.key == K_2:
                    x = pygame.mouse.get_pos()[0]
                    y = pygame.mouse.get_pos()[1]
                    self.editorTempLevel["spawn"]["player2"]["x"] = x
                    self.editorTempLevel["spawn"]["player2"]["y"] = y
                    if (self.editorPlayer2Sprite == None):
                        self.editorPlayer2Sprite = Player(x,y,30,24,self.spritegroup,K_d,K_a,K_w,"orange-alien.png")
                        self.editorPlayer2Sprite.doUpdate = False
                    else:
                        self.editorPlayer2Sprite.x = x
                        self.editorPlayer2Sprite.y = y

            if self.window == "main menu":
                if event.key == K_SPACE:
                    self.window = "editor"
                    self.backgroundImage.setImage("images/levelbackground.png")
        if event.type == MOUSEBUTTONUP:
            if self.window == "main menu":
                if event.pos[0] > 82 and event.pos[0] < 236 and event.pos[1] > 364 and event.pos[1] < 413:
                    self.window = "level"
                    self.backgroundImage.setImage("images/levelbackground.png")
                    self.loadLevel(1)
                if event.pos[0] > 276 and event.pos[0] < 430 and event.pos[1] > 364 and event.pos[1] < 413:
                    sys.exit(0)
            elif self.window == "editor": #editor
                if (self.editorTempData["x"] < event.pos[0]):
                    x = self.editorTempData["x"]
                else:
                    x = event.pos[0]
                if (self.editorTempData["y"] < event.pos[1]):
                    y = self.editorTempData["y"]
                else:
                    y = event.pos[1]
                                        
                width = abs(event.pos[0] - self.editorTempData["x"])
                height = abs(event.pos[1] - self.editorTempData["y"])
                self.editorTempLevel["walls"].append({"x":x,"y":y,"width":width,"height":height})
                self.wall = Wall(x,y,width,height,self.spritegroup)
                self.wall.color = (250,250,250)
                self.wall.draw()
        if event.type == MOUSEBUTTONDOWN:
            if self.window == "editor": #editor
                self.editorTempData["x"] = event.pos[0];
                self.editorTempData["y"] = event.pos[1];
        return True
    def poll(self):
        pass
    
    def loadLevel(self, levelNumber):
        print("Loading level {}".format(levelNumber))
        
        self.levelnumber = levelNumber
        
        f = open('levels/level{}.json'.format(levelNumber),"r+")
        self.level = json.load(f)
        f.close()
        
        for sprite in self.spritegroup:
            if not isinstance(sprite, Background):
                self.spritegroup.remove(sprite)
        
        self.player = Player(self.level['spawn']['player1']['x'], self.level['spawn']['player1']['y'],20,21,self.spritegroup,K_d,K_a,K_w,"green-alien.png")
        self.player2 = Player(self.level['spawn']['player2']['x'], self.level['spawn']['player2']['y'],20,21,self.spritegroup,K_RIGHT,K_LEFT,K_UP,"orange-alien.png")
        
        self.goal = LevelGoal(self.level['goal']['x'],self.level['goal']['y'],30,24,self.spritegroup)
        
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
        
class PowerUp(Actor):
    type = None
    amount = None
    def __init__(self, x, y, actor_list,type,amount):
        super().__init__(x, y, 20, 20, actor_list)
        self.type = type
        self.amount = amount
        
        self.image = pygame.image.load("images/powerups/{}.png".format(type)).convert()
        self.dirty = 1

class LevelGoal(Actor):
    goalreached = False
    def __init__(self, x, y, width, height, actor_list):
        super().__init__(x, y, width, height, actor_list)
        self.image = pygame.image.load("images/winstar.png").convert_alpha()
    def update(self):
        if len(self.overlapping_actors(Player)) == 2 and not self.goalreached:
            myapp.loadLevel(myapp.levelnumber + 1)
            self.goalreached = True

class Player(Actor):        
    xVelocity = 0
    yVelocity = 0
    goLeftKey = None
    goRightKey = None
    jumpKey = None
    doUpdate = True
    def __init__(self, x, y, width, height, actor_list, rightKey, leftKey, jumpKey, image):
        super().__init__(x, y, width, height, actor_list)
        self.image = pygame.image.load("images/{}".format(image)).convert_alpha()
        self.goRightKey = rightKey
        self.goLeftKey = leftKey
        self.jumpKey = jumpKey
    def update(self):
        if not self.doUpdate:
            return
        self.x = self.x + self.xVelocity
        pygame.event.pump()
        if pygame.key.get_pressed()[self.goLeftKey]:
            self.moveLeft()
        elif pygame.key.get_pressed()[self.goRightKey]:
            self.moveRight()
        else:
            self.xVelocity = self.xVelocity * .85
        
        if pygame.key.get_pressed()[self.jumpKey]:
            self.jump()
        
        if len(self.overlapping_actors(Wall)) == 0:
            self.yVelocity = self.yVelocity - 0.5
        else:
            wall = self.overlapping_actors(Wall)[0]
            wallCenterY = wall.height/2 + wall.y
            playerCenterY = self.height/2 + self.y
            
            if (self.x + self.width) > wall.x and (self.x + self.width) <  (wall.x + 5):
                #self.x = self.width + wall.x
                #self.xVelocity = 0
                #FIX
                
                pass
            else:
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
        if self.x < 497 and self.xVelocity < 8:
            self.xVelocity += 1
    def moveLeft(self):
        if self.xVelocity > -8:
            self.xVelocity -= 1
    def jump(self):
        if len(self.overlapping_actors(Wall)) != 0:
            self.y -= 1
            self.yVelocity = 8

myapp = SpaceAttackApp()
myapp.run(20)
