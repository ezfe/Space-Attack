'''
Created on Nov 3, 2014

@author: Clare Snyder, Ezekiel Elin
'''
import pygame
from pygame.locals import *
from pygameapp import PygameApp
from actor import Actor
import json
import sys
import time
import threading

def set_timeout(func, sec):     
    t = None
    def func_wrapper():
        func()
        t.cancel()
    t = threading.Timer(sec, func_wrapper)
    t.start()

class SpaceAttackApp(PygameApp):
    # App attributes
    width = 512
    height = 512
    
    # Current window
    window = "main menu"

    # Level info
    level = {}
    levelnumber = 0

    # Background image class instance (defined later)
    backgroundImage = None
    
    # Editor variables
    editorTempData = {"x":None,"y":None}
    editorTempLevel = {"walls":[],"power ups":[],"evil astronauts":[],"goal":{"x":0,"y":0},"wrap":{"horizontal":False,"vertical":False},"spawn":{"player1":{"x":20,"y":492},"player2":{"x":492,"y":20}}}
    editorGoalSprite = None
    editorPlayer1Sprite = None
    editorPlayer2Sprite = None

    #Hearts
    defaultlives = 3
    temphearts = 0
    lives = defaultlives

    # Initializer for App
    def __init__(self):
        super().__init__(screensize = (self.width, self.height), title="Space Attack!")
        pygame.key.set_repeat(100)
        self.setbackgroundcolor((0, 0, 50))
        self.backgroundImage = Background(0, 0,512, 512, self.spritegroup)
        self.backgroundImage.setImage("images/mainmenu.png")
       
    # Handle key events for App     
    def handle_event(self, event):
        if event.type == KEYDOWN:
            # Handle Key Presses for Editor
            if self.window == "editor":
                if event.key == K_SPACE:
                    print(json.dumps(self.editorTempLevel))
                if event.key == K_x:
                    x = pygame.mouse.get_pos()[0]
                    y = pygame.mouse.get_pos()[1]
                    
                    for sprite in self.spritegroup:
                        if not isinstance(sprite, Background):
                            if sprite.x < x and (sprite.x + sprite.width) > x:
                                if sprite.y < y and (sprite.y + sprite.height) > y:
                                    for index, wall in enumerate(self.editorTempLevel["walls"]):
                                        if sprite.x == wall["x"]:
                                            del self.editorTempLevel["walls"][index]
                                            self.spritegroup.remove(sprite)

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
                        self.editorPlayer1Sprite = Player(x,y,30,24,self.spritegroup,K_d,K_a,K_w,"green")
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
                        self.editorPlayer2Sprite = Player(x,y,30,24,self.spritegroup,K_d,K_a,K_w,"orange")
                        self.editorPlayer2Sprite.doUpdate = False
                    else:
                        self.editorPlayer2Sprite.x = x
                        self.editorPlayer2Sprite.y = y

            # Handle Key Presses for Main Menu
            if self.window == "main menu":
                if event.key == K_SPACE:
                    #self.loadLevel(4)
                    #self.player.doUpdate = False
                    #self.player2.doUpdate = False
                    self.window = "editor"
                    self.backgroundImage.setImage("images/levelbackground.png")
              
        if event.type == MOUSEBUTTONUP:

            # Handle Mouse Up for Main Menu
            if self.window == "main menu":
                if event.pos[0] > 82 and event.pos[0] < 236 and event.pos[1] > 364 and event.pos[1] < 413:
                    self.window = "level"
                    self.backgroundImage.setImage("images/levelbackground.png")
                    self.loadLevel(1)
                if event.pos[0] > 276 and event.pos[0] < 430 and event.pos[1] > 364 and event.pos[1] < 413:
                    sys.exit(0)

            # Handle Mouse Up for Editor
            if self.window == "editor": #editor
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
                
                if height <15:
                    height = 5 
                self.editorTempLevel["walls"].append({"x":x,"y":y,"width":width,"height":height})
                self.wall = Wall(x,y,width,height,self.spritegroup)
                self.wall.color = (163,204,194)
                self.wall.draw()
        if event.type == MOUSEBUTTONDOWN:
            # Handle Mouse Down for Editor
            if self.window == "editor":
                self.editorTempData["x"] = event.pos[0];
                self.editorTempData["y"] = event.pos[1];
        return True

    def poll(self):
        pass
    
    def die(self):
        if not self.window == "level":
            return 
        
        self.window = "deathscreen"
        
        self.temphearts = 0
        
        if self.lives > 1:
            self.lives -= 1
            
            self.backgroundImage.setImage("images/deathscreen.png")
            self.clearLevel()
            set_timeout(self.loadSameLevel,2)
        else:
            self.lives = self.defaultlives
            self.window = "main menu"
            self.clearLevel()
            self.backgroundImage.setImage("images/mainmenu_died.png")
            return
                    
    def clearLevel(self):
        """
        Clear all sprites except background sprite
        """
        print("Cleared level")

        for sprite in self.spritegroup:
            if not isinstance(sprite, Background):
                self.spritegroup.remove(sprite)
    def loadSameLevel(self):
        """
        Reload the current level (used for deaths)
        """
        self.loadLevel(self.levelnumber)
         
    def loadNextLevel(self):
        """
        Load the next level
        """
        self.loadLevel(self.levelnumber + 1)
    
    def updateHearts(self):
        """
        Re-render the hearts
        """
        
        for sprite in self.spritegroup:
            if isinstance(sprite, Heart ):
                self.spritegroup.remove(sprite)
        
        workinghearts = self.lives + self.temphearts
        
        x = 4
        y = 4
        ycount = 1
        for life in range(0, workinghearts):
            self.heart = Heart(x, y, self.spritegroup)
            if self.lives - life <= 0:
                self.heart.setImage("images/tempheart.png")
            x += 31
            if life - (life * (ycount - 1)) > 10:
                ycount += 1
                y += 31
                x = 4
    
    def loadLevel(self, levelNumber):
        """
        Load the passed Level
        """
        print("Loading level {}".format(levelNumber))
            
        self.window = "level"
          
        # Store passed variable in App level variable
        self.levelnumber = levelNumber
        self.backgroundImage.setImage('images/levelbackground.png')
        
        # Read level file
        try:
            f = open('levels/level{}.json'.format(levelNumber),"r+")
            self.level = json.load(f)
            f.close()
        except:
            self.clearLevel()
            self.window = "main menu"
            self.backgroundImage.setImage("images/mainmenu_fin.png")
            return
    
        self.lives += self.temphearts
        self.temphearts = 0
        
        # Clear current level
        self.clearLevel()
        
        # Initialize variables

        self.updateHearts()
                    
        print(self.lives >= 1)

        self.player = Player(self.level['spawn']['player1']['x'], self.level['spawn']['player1']['y'],20,21,self.spritegroup,K_d,K_a,K_w,"green")
        self.player2 = Player(self.level['spawn']['player2']['x'], self.level['spawn']['player2']['y'],20,21,self.spritegroup,K_RIGHT,K_LEFT,K_UP,"orange")
        
        self.goal = LevelGoal(self.level['goal']['x'],self.level['goal']['y'],30,24,self.spritegroup)
        
        if "power ups" in self.level:
            for powerup in self.level['power ups']:
                if "settings" in powerup:
                    self.powerup = PowerUp(powerup['x'],powerup['y'],self.spritegroup,powerup['type'],powerup['amount'],powerup['settings'])
                else:
                    self.powerup = PowerUp(powerup['x'],powerup['y'],self.spritegroup,powerup['type'],powerup['amount'],{})
        
        if "evil astronauts" in self.level:
            for evilastronaut in self.level['evil astronauts']:
                self.evilastronaut = EvilAstronaut(evilastronaut['x1'], evilastronaut['y1'], self.spritegroup, evilastronaut['x2'], evilastronaut['y2'], evilastronaut['time'])
        
        for wall in self.level['walls']:
            self.wall = Wall(wall['x'],wall['y'],wall['width'],wall['height'],self.spritegroup)
            self.wall.color = (163,204,194)
            self.wall.draw()
            if "image" in wall:
                self.wall.setImage("images/walls/{}/{}.png".format(self.levelnumber,wall["image"]))
    
class Wall(Actor):
    """
    Class for the walls
    """
    def setImage(self, image):
        self.image = pygame.image.load(image).convert_alpha()
        self.dirty = 1
    
    def getCenterCoordinates(self):
        return (self.width/2 + self.x, self.height/2 + self.y)
        
class EvilAstronaut(Actor):
    x1, y1, x2, y2, time = None, None, None, None, None
    
    status = "none"
    
    def __init__(self, x1, y1, actor_list, x2, y2, time):
        super().__init__(x1, y1, 20, 26, actor_list)
        self.x1 = x1
        self.x2 = x2
        self.y1 = y1
        self.y2 = y2
        self.time = time
        self.status = "to"
        self.setImage("images/evilastronaut.png")
        
    def setImage(self, image):
        self.image = pygame.image.load(image).convert_alpha()
        self.dirty = 1
        
    def update(self):
        if self.status == "none":
            return
        
        deltaX = self.x2 - self.x1
        deltaY = self.y2 - self.y1
        timePercent = 1 / (20 * self.time)
        thisDeltaX = deltaX * timePercent
        thisDeltaY = deltaY * timePercent
        
        if self.status == "to":
            self.x += thisDeltaX
            self.y += thisDeltaY
        elif self.status == "from":
            self.x -= thisDeltaX
            self.y -= thisDeltaY

        if self.x < self.x1 or self.y < self.y1:
            self.status = "to"
        if self.x > self.x2 or self.y > self.y2:
            self.status = "from"
            
        if len(self.overlapping_actors(Player)) > 0:
            myapp.die()

class Background(Actor):
    """
    Class to show the background
    """
    def setImage(self, image):
        """
        Load the supplied image path as the background
        """
        self.image = pygame.image.load(image).convert()
        self.dirty = 1
        
class Heart(Actor):
    """
    Class to show the background
    """
    def __init__(self, x1, y1, actor_list):
        super().__init__(x1, y1, 32, 32, actor_list)
        self.setImage("images/heart.png")

    def setImage(self, image):
        """
        Load the supplied image path as the background
        """
        self.image = pygame.image.load(image).convert_alpha()
        self.dirty = 1
        
class PowerUp(Actor):
    """
    Class for the PowerUps
    """
    type = None
    amount = None
    used = False
    settings = {}
    def __init__(self, x, y, actor_list, type, amount, settings):
        super().__init__(x, y, 20, 20, actor_list)
        self.type = type
        self.amount = amount
        self.settings = settings
        
        self.image = pygame.image.load("images/powerups/{}.png".format(type)).convert_alpha()

    def update(self):
        # Check if allowed to update
        if self.used:
            return

        # Check overlapping Player instances
        overlappingList = self.overlapping_actors(Player)
        for thing in overlappingList:
            print("Added an effect to a player!")
            if self.type == "portal":
                thing.x = self.settings["destination x"]
                thing.y = self.settings["destination y"]
            elif self.type == "heart":
                myapp.temphearts += self.amount
                myapp.updateHearts()
            else:
                thing.effects.append({"type": self.type, "amount": self.amount, "createTime": time.time(), "durationTime": 1})
        
            self.y = -50 # Lazy deletion :D
            self.used = True # Prevent reusal

class LevelGoal(Actor):
    """
    Class for the Level Goal
    """
    goalreached = False
    yVelocity = 0
    def __init__(self, x, y, width, height, actor_list):
        super().__init__(x, y, width, height, actor_list)
        self.image = pygame.image.load("images/winstar.png").convert_alpha()
    
    def update(self):
        if len(self.overlapping_actors(Player)) == 2 and not self.goalreached:
            set_timeout(myapp.loadNextLevel,1)
            self.goalreached = True
            myapp.player.y = -50
            myapp.player2.y = -50
            myapp.player.doUpdate = False
            myapp.player2.doUpdate = False
        if self.goalreached:
            self.yVelocity -= 1
        self.y += self.yVelocity

class Player(Actor):       
    xVelocity = 0
    yVelocity = 0
    jumpAmount = 8
    jumpAmountModifier = 1
    goLeftKey = None
    goRightKey = None
    jumpKey = None
    doUpdate = True
    effects = None
    
    playerColor = None
    
    def __init__(self, x, y, width, height, actor_list, rightKey, leftKey, jumpKey, playerColor):
        super().__init__(x, y, width, height, actor_list)
        self.playerColor = playerColor
        self.setImage("images/{}-alien.png".format(self.playerColor))
        self.goRightKey = rightKey
        self.goLeftKey = leftKey
        self.jumpKey = jumpKey
        self.effects = []
    def update(self):
        # check if allowed to update
        if not self.doUpdate:
            return
        
        if abs(self.xVelocity) < 1: 
            self.xVelocity = 0
            
        print(self.xVelocity)
        print(self.x)
        
        if self.y <= 0:
            self.setImage("images/{}-alien-offscreen.png".format(self.playerColor))
        else:
            self.setImage("images/{}-alien.png".format(self.playerColor))

        # Go through effects and update them
        for effect in self.effects:
            if effect["type"] == "jump" and effect["createTime"] + effect["durationTime"] > time.time():
                if self.jumpAmountModifier < effect["amount"]:
                    self.jumpAmountModifier = effect["amount"]
        
        # Update X
        self.x = self.x + self.xVelocity
        
        # Update keypresses
        pygame.event.pump()

        # Check keys and perform actions (horizontal)
        if not self.goLeftKey == None and pygame.key.get_pressed()[self.goLeftKey]:
            self.moveLeft()
        elif not self.goRightKey == None and pygame.key.get_pressed()[self.goRightKey]:
            self.moveRight()
        else:
            # If not pressing any keys, slow down
            self.xVelocity = self.xVelocity * .25
        
        # Check keys and perform actions (vertical)
        if not self.jumpKey == None and pygame.key.get_pressed()[self.jumpKey]:
            self.jump()
        
        # Check if overlapping walls
        if len(self.overlapping_actors(Wall)) == 0:
            # If not overlapping any walls, go down
            self.yVelocity = self.yVelocity - 0.5
        else:
            if len(self.overlapping_actors(Wall)) > 1:
                print("Too many overlapping walls, physics may not work properly!")
            # If overlapping any walls, stop etc.
            wall = self.overlapping_actors(Wall)[0]
            
            wallCenterX = wall.getCenterCoordinates()[0]
            wallCenterY = wall.getCenterCoordinates()[1]
            playerCenterY = self.height/2 + self.y
            
            if playerCenterY < wallCenterY:
                if (self.y + self.height) > (wall.y + 1):
                    self.y = wall.y + 1 - self.height 
            else:
                self.y = wall.y + wall.height
                self.yVelocity = 0
            self.yVelocity = 0
         
        # Update Y   
        self.y = self.y - self.yVelocity 
        if self.yVelocity < -8:
            self.yVelocity = -12
        
        # Check if horizontal wrapping is on
        if myapp.level['wrap']['horizontal']:
            # If horizontal wrapping is on, check if wrapping should be performed
            if self.x < 0:
                # Move to right side of window
                self.x += myapp.width
            elif self.x > myapp.width:
                # Move to left side of window
                self.x -= myapp.width
        else:
            # If horizontal wrapping is off, check if corrections to position sould be applied
            if self.x < 0:
                # Make the leftside of the screen a invisible wall
                self.x = 0
                self.xVelocity = 0
            elif self.x > myapp.width:
                # Make the rightside of the screen a invisible wall
                self.x = myapp.width - 15
                self.xVelocity = 0
           
        # Check if vertical wrapping is on     
        if myapp.level['wrap']['vertical']:
            # If vertical wrapping is off, check if wrapping should be performed
            if self.y < 0:
                # Move to bottom of window
                self.y += myapp.height
            elif self.y > myapp.height:
                # Move to top of window
                self.y -= myapp.height
        else:
            if self.y < 0:
                self.y = 0

            elif self.y > myapp.height:
                #self.y = myapp.height - 15
                myapp.die()

    def setImage(self, image):
        self.image = pygame.image.load(image).convert_alpha()
        self.dirty = 1
   
    def moveRight(self):
        """
        Causes the player instance to move right
        """
        # Check if not too close to the rightside wall, and not moving too fast
        if self.x < 497 and self.xVelocity < 8:
            self.xVelocity += 1

    def moveLeft(self):
        """
        Causes the player instance to move left
        """
        # Check if not moving too fast
        if self.xVelocity > -8:
            self.xVelocity -= 1

    def jump(self):
        """
        Causes the player instance to jump
        """
        # Check if touching the ground
        if len(self.overlapping_actors(Wall)) != 0:
            # Move up 1 pixel to untouch the wall
            self.y -= 1
            
            # Set velocity appropriately
            self.yVelocity = self.jumpAmount * self.jumpAmountModifier

# Make the SpaceAttackApp instance
myapp = SpaceAttackApp()
# Run it at 20 updates per second
myapp.run(20)