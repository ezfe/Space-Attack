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
	
    override func didMove(to view: SKView) {
        /* Setup your scene here */
		let mainMenu = SKSpriteNode(imageNamed: menuType)
		mainMenu.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
		self.addChild(mainMenu)
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        
        let location = theEvent.location(in: self)

		print(location.x)
		print(location.y)
		
		if location.x > 82 && location.x < 236 && location.y < 148 && location.y > 100 {
			let scene = GameScene(size: self.size)
			self.view?.ignoresSiblingOrder = true
			scene.size = (self.view?.bounds.size)!
			self.view?.presentScene(scene)
		} else if location.x > 276 && location.x < 430 && location.y < 148 && location.y > 100 {
			NSApplication.shared.terminate(self)
		}
	}
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
		
    }
}
