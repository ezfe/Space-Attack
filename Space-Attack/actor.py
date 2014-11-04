'''
@author: Eric Dennison
'''
import pygame

class Actor(pygame.sprite.DirtySprite):

    # Initialize this actor with dimensions and the list of all actors in the game.
    def __init__(self, x, y, width, height, actor_list):
        self.actors = actor_list            # keep track of the actor list
        self.color = (0,0,0)
        self.transparent = (1,2,3)            # a transparent color
        self.image = pygame.Surface((width, height))
        self.image.set_colorkey(self.transparent)  
        self.image.fill(self.transparent)
        self.rect = self.image.get_rect(topleft=(x,y))
        self.draw()
        super().__init__(actor_list)         # call the parent class and add to the group
        
    # String representation of this actor.
    def __str__(self):
        return "{0} ({1}, {2}) {3}x{4}".format(type(self).__name__, self.x, self.y, self.width, self.height)
        
    # Returns a list of all actors that this actor overlaps (optionally, filter by actor type).
    def overlapping_actors(self, actor_type = None):
        alloverlapped = pygame.sprite.spritecollide(self, self.actors, False)
        if self in alloverlapped:
            alloverlapped.remove(self)
        return [x for x in alloverlapped if actor_type == None or isinstance(x, actor_type)]
        
    # Redraw the actor
    def draw(self):
        pygame.draw.rect(self.image, self.color, (0, 0, self.rect.width, self.rect.height))
        self.dirty = 1

    # Code that this actor will perform every frame. 
    def update(self):
        # Override this function in subclasses to perform actions every frame.
        pass
    
    # Get the height
    @property
    def height(self):
        return self.rect.height
    
    # Get the width
    @property
    def width(self):
        return self.rect.width
    
    # Get/set the x position of the topleft corner
    @property
    def x(self):
        return self.rect.x
    
    @x.setter
    def x(self, x):
        self.rect.x = x
        self.dirty = 1
    
    # Get the y position of the topleft corner
    @property
    def y(self):
        return self.rect.y
    
    @y.setter
    def y(self, y):
        self.rect.y = y
        self.dirty = 1

    # Destroy the actor.
    def destroy(self):
        self.remove(self.actors)
