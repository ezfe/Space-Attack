//
//  GameScene.swift
//  Space Attack
//
//  Created by Ezekiel Elin on 3/7/15.
//  Copyright (c) 2015 Ezekiel Elin. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
	
	var menuType = "mainmenu"
	
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
		let mainMenu = SKSpriteNode(imageNamed: menuType)
		mainMenu.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
		self.addChild(mainMenu)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        
        let location = theEvent.locationInNode(self)

		println(location.x)
		println(location.y)
		
		if location.x > 82 && location.x < 236 && location.y < 148 && location.y > 100 {
			var scene = GameScene(size: self.size)
			let skView = self.view as SKView!
			skView.ignoresSiblingOrder = true
			scene.size = skView.bounds.size
			skView.presentScene(scene)
		} else if location.x > 276 && location.x < 430 && location.y < 148 && location.y > 100 {
			NSApplication.sharedApplication().terminate(self)
		}
	}
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
		
    }
}
