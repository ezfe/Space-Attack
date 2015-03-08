//
//  GameScene.swift
//  Space Attack
//
//  Created by Ezekiel Elin on 3/7/15.
//  Copyright (c) 2015 Ezekiel Elin. All rights reserved.
//

import SpriteKit

enum Keys: String {
	case A = "a"
	case W = "w"
	case D = "d"
	case Left = ""
	case Up = ""
	case Right = ""
}

enum ColliderType: UInt32 {
	case Wall	 = 0x0000000F
	case Player	 = 0x000000F0
	case Goal	 = 0x00000F00
	case PowerUp = 0x0000F000
	case None	 = 0x00000000
}

enum SpriteType: String {
	case Player = "Player"
	case Wall = "Wall"
	case Background = "Background"
	case Goal = "Goal"
	case Astronaut = "Astronaut"
	case PowerUp = "PowerUp"
	case Unset = "Unset"
	case Heart = "Heart"
}

enum PowerUpType: String {
	case Heart = "life"
	case Jump = "jump"
	case Portal = "portal"
}

func powerUpType(pwString: String) -> PowerUpType {
	switch pwString {
		case "heart": return .Heart
		case "jump": return .Jump
		case "portal": return .Portal
		default: return .Jump
	}
}

class GameScene: SKScene, SKPhysicsContactDelegate {
	let background = Sprite(imageNamed: "levelbackground")
	
	var currentLevelID: Int = 0
	var currentLevel: [String: JSON]? = nil
	var pressedKeys = Dictionary<Keys, Bool>()
	
	var currentHearts = 3
	var addNextLevelHearts = 0
	
	override func didMoveToView(view: SKView) {
		/* Setup your scene here */
		pressedKeys[Keys.Left] = false
		pressedKeys[Keys.Up] = false
		pressedKeys[Keys.Right] = false
		
		pressedKeys[Keys.A] = false
		pressedKeys[Keys.W] = false
		pressedKeys[Keys.D] = false
		
		self.background.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
		self.background.zPosition = 0
		self.background.type = SpriteType.Background
		self.addChild(self.background)
		self.physicsWorld.contactDelegate = self
		
		self.loadNextLevel()
	}
	
	override func update(currentTime: CFTimeInterval) {
		/* Called before each frame is rendered */
		for child in self.children {
			if let child = child as? Sprite {
				child.update()
			}
		}
		updateHearts()
	}
	
	func die() {
		clearLevel()
		
		if self.currentHearts <= 1 {
			var scene = MenuScene(size: self.size)
			let skView = self.view as SKView!
			skView.ignoresSiblingOrder = true
			scene.size = skView.bounds.size
			scene.menuType = "mainmenu_died"
			skView.presentScene(scene)
		} else {
			self.currentHearts--
			self.addNextLevelHearts = 0
			loadLevel(currentLevelID)
		}
	}
	
	func updateHearts() {
		
		for child in children {
			if let child = child as? Sprite {
				if child.type == SpriteType.Heart {
					child.removeFromParent()
				}
			}
			if let child = child as? SKLabelNode {
				child.removeFromParent()
			}
		}
		
//		let heart = Sprite(imageNamed: "heart")
//		heart.type = SpriteType.Heart
//		heart.position = CGPointMake(CGFloat(heart.size.width / 2), CGFloat(self.size.height - (heart.size.height / 2)))
//		self.addChild(heart)
//
		let heartLabel = SKLabelNode(text: "\(self.currentHearts) lives (add \(self.addNextLevelHearts) when you complete this level)")
		heartLabel.fontSize = 24
		heartLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y: frame.height - (heartLabel.frame.height));
		self.addChild(heartLabel)
	}
	
	func loadNextLevel() {
		clearLevel()
		self.currentLevelID++
		loadLevel(self.currentLevelID)
		
		self.currentHearts += self.addNextLevelHearts
		self.addNextLevelHearts = 0
	}
	
	func clearLevel() {
		for child in children {
			if let child = child as? Sprite {
				if child.type != SpriteType.Background {
					child.removeFromParent()
				}
			}
		}
	}
	
	func loadLevel(level: Int) {
		println("Loading level \(level)")
		println("Currentl at \(self.currentHearts) hearts")
		
		let path = NSBundle.mainBundle().pathForResource("level\(level)", ofType: "json")
		if let path = path {
			let jsonData = NSData(contentsOfFile: path)
			currentLevel = JSON(data: jsonData!).dictionary!
		} else {
			println("No more levels")
			var scene = MenuScene(size: self.size)
			let skView = self.view as SKView!
			skView.ignoresSiblingOrder = true
			scene.size = skView.bounds.size
			scene.menuType = "mainmenu_fin"
			skView.presentScene(scene)
			return
		}
		
		let player1 = Player(player: 1)
		let player2 = Player(player: 2)
		
		player1.zPosition = 2
		player2.zPosition = 2
		
		player1.type = SpriteType.Player
		player2.type = SpriteType.Player
		
		player1.position = CGPointMake(CGFloat(currentLevel!["spawn"]!.dictionaryValue["player1"]!.dictionaryValue["x"]!.intValue), CGFloat(currentLevel!["spawn"]!.dictionaryValue["player1"]!.dictionaryValue["y"]!.intValue))
		player2.position = CGPointMake(CGFloat(currentLevel!["spawn"]!.dictionaryValue["player2"]!.dictionaryValue["x"]!.intValue), CGFloat(currentLevel!["spawn"]!.dictionaryValue["player2"]!.dictionaryValue["y"]!.intValue))
		
		player1.physicsBody = SKPhysicsBody(rectangleOfSize: player1.size)
		player1.physicsBody?.allowsRotation = false
		player1.physicsBody?.usesPreciseCollisionDetection = true
		player1.physicsBody?.categoryBitMask = ColliderType.Player.rawValue
		player1.physicsBody?.collisionBitMask = ColliderType.Wall.rawValue
		player1.physicsBody?.restitution = 0.0
		
		player2.physicsBody = SKPhysicsBody(rectangleOfSize: player2.size)
		player2.physicsBody?.allowsRotation = false
		player2.physicsBody?.usesPreciseCollisionDetection = true
		player2.physicsBody?.categoryBitMask = ColliderType.Player.rawValue
		player2.physicsBody?.collisionBitMask = ColliderType.Wall.rawValue
		player2.physicsBody?.restitution = 0.0
	
		self.addChild(player1)
		self.addChild(player2)
		
		let goal = Goal(imageNamed: "goal")
		goal.zPosition = 1
		goal.position = CGPointMake(CGFloat(currentLevel!["goal"]!.dictionaryValue["x"]!.intValue) + CGFloat(goal.size.width / 2), CGFloat(currentLevel!["goal"]!.dictionaryValue["y"]!.intValue) - CGFloat(goal.size.height / 2))
		goal.type = SpriteType.Goal
		
		goal.physicsBody = SKPhysicsBody(rectangleOfSize: goal.size)
		goal.physicsBody?.dynamic = false
		goal.physicsBody?.categoryBitMask = ColliderType.Goal.rawValue
		goal.physicsBody?.collisionBitMask = ColliderType.None.rawValue
		goal.physicsBody?.contactTestBitMask = ColliderType.Player.rawValue
		
		self.addChild(goal)
		
		let walls: [JSON] = currentLevel!["walls"]!.array!
		for wall in walls {
			let wall = wall.dictionaryValue
			let size = CGSizeMake(CGFloat(wall["width"]!.intValue), CGFloat(wall["height"]!.intValue))
			let wallNode = Wall(color: NSColor(red:0.64, green:0.8, blue:0.76, alpha:1), size: size)
			wallNode.type = SpriteType.Wall
			wallNode.zPosition = 1
			wallNode.position = CGPointMake(CGFloat(wall["x"]!.intValue) + CGFloat(wallNode.size.width / 2), CGFloat(wall["y"]!.intValue) - CGFloat(wallNode.size.height / 2))
			
			wallNode.physicsBody = SKPhysicsBody(rectangleOfSize: wallNode.size)
			wallNode.physicsBody?.dynamic = false
			
			wallNode.physicsBody?.categoryBitMask = ColliderType.Wall.rawValue
			wallNode.physicsBody?.collisionBitMask = ColliderType.Player.rawValue
			
			wallNode.physicsBody?.restitution = 0.0
			
			self.addChild(wallNode)
		}
		
		let powerups: [JSON] = currentLevel!["power ups"]!.array!
		for powerup in powerups {
			let powerup = powerup.dictionaryValue
			
			let powerupNode = PowerUp(type: powerUpType(powerup["type"]!.stringValue), amount: powerup["amount"]!.intValue, settings: powerup["settings"])
			powerupNode.type = SpriteType.PowerUp
			
			powerupNode.zPosition = 1
			powerupNode.position = CGPointMake(CGFloat(powerup["x"]!.intValue) + CGFloat(powerupNode.size.width / 2), CGFloat(powerup["y"]!.intValue) - CGFloat(powerupNode.size.height / 2))
			
			powerupNode.physicsBody = SKPhysicsBody(rectangleOfSize: goal.size)
			powerupNode.physicsBody?.dynamic = false
			powerupNode.physicsBody?.categoryBitMask = ColliderType.PowerUp.rawValue
			powerupNode.physicsBody?.collisionBitMask = ColliderType.None.rawValue
			powerupNode.physicsBody?.contactTestBitMask = ColliderType.Player.rawValue
			
			self.addChild(powerupNode)
		}
	}
	override func keyDown(theEvent: NSEvent) {
		if theEvent.characters! == Keys.Left.rawValue {
			pressedKeys[Keys.Left] = true
		} else if theEvent.characters! == Keys.Up.rawValue {
			pressedKeys[Keys.Up] = true
		} else if theEvent.characters! == Keys.Right.rawValue {
			pressedKeys[Keys.Right] = true
		} else if theEvent.characters! == Keys.A.rawValue {
			pressedKeys[Keys.A] = true
		} else if theEvent.characters! == Keys.W.rawValue {
			pressedKeys[Keys.W] = true
		} else if theEvent.characters! == Keys.D.rawValue {
			pressedKeys[Keys.D] = true
		}
		
		if theEvent.characters! == " " {
			self.loadNextLevel()
		}
	}
	
	override func keyUp(theEvent: NSEvent) {
		if theEvent.characters! == Keys.Left.rawValue {
			pressedKeys[Keys.Left] = false
		} else if theEvent.characters! == Keys.Up.rawValue {
			pressedKeys[Keys.Up] = false
		} else if theEvent.characters! == Keys.Right.rawValue {
			pressedKeys[Keys.Right] = false
		} else if theEvent.characters! == Keys.A.rawValue {
			pressedKeys[Keys.A] = false
		} else if theEvent.characters! == Keys.W.rawValue {
			pressedKeys[Keys.W] = false
		} else if theEvent.characters! == Keys.D.rawValue {
			pressedKeys[Keys.D] = false
		}
	}
}

class Sprite: SKSpriteNode {
	var type: SpriteType = SpriteType.Unset
	var velocity = CGVectorMake(0, 0)
	
	func update() {
		if self.type == SpriteType.Unset {
			assertionFailure("Sprite type wasn't set for \(self)")
		}
	}
}

class Player: Sprite {
	var player: Int
	
	var GoLeftKey: Keys
	var GoRightKey: Keys
	var JumpKey: Keys
	
	let jumpAmount: CGFloat = 9
	var jumpModifier: Float = 1
	
	init(player: Int) {
		self.player = player
		let image: String
		
		if player == 1 {
			image = "green-alien"
			self.GoLeftKey = Keys.A
			self.JumpKey = Keys.W
			self.GoRightKey = Keys.D
		} else {
			image = "orange-alien"
			self.GoLeftKey = Keys.Left
			self.JumpKey = Keys.Up
			self.GoRightKey = Keys.Right
		}
		
		let texture = SKTexture(imageNamed: image)
		super.init(texture: texture, color: NSColor.clearColor(), size: texture.size())
	}
	
	override func update() {
		if self.parent == nil {
			return
		}
		
		self.position.x += self.velocity.dx
		self.position.y += self.velocity.dy
		
		if self.physicsBody?.velocity.dy > CGFloat(475 * self.jumpModifier) {
			self.physicsBody?.velocity.dy = 0
		}
		
		if let scene = self.parent! as? GameScene {
			if scene.pressedKeys[self.GoLeftKey]! {
				self.moveLeft()
			} else if scene.pressedKeys[self.GoRightKey]! {
				self.moveRight()
			} else {
				self.velocity.dx = self.velocity.dx * 0.25
			}
			
			if scene.pressedKeys[self.JumpKey]! {
				self.jump()
			}
			
			if let level = scene.currentLevel {
				if self.position.x < (self.size.width / 2) {
					if level["wrap"]!.dictionaryValue["horizontal"]!.boolValue {
						self.position.x = scene.size.width - (self.size.width / 2)
					} else {
						self.position.x = (self.size.width / 2)
						self.velocity.dx = 0
					}
				} else if self.position.x > scene.size.width - (self.size.width / 2) {
					if level["wrap"]!.dictionaryValue["horizontal"]!.boolValue {
						self.position.x = (self.size.width / 2)
					} else {
						self.position.x = scene.size.width - (self.size.width / 2) - 1 /*prevent getting stuck on right wall*/
						self.velocity.dx = 0
					}
				}
			}
		}
		
		if self.position.y < 0 {
			(self.parent! as! GameScene).die()
		}
		
		super.update()
	}
	
	func moveRight() {
		if self.velocity.dx < 8 {
			self.velocity.dx += 1
		}
	}
	
	func moveLeft() {
		if self.position.x > (self.size.width / 2) && self.velocity.dx > -8 {
			self.velocity.dx -= 1
		}
	}
	
	func jump() {
		let touchingBodies = self.physicsBody?.allContactedBodies()
		for body in touchingBodies! {
			if let wall = body.representedObject! as? Wall {
				if wall.position.y < self.position.y {
					self.physicsBody?.applyImpulse(CGVectorMake(0.0, self.jumpAmount * CGFloat(self.jumpModifier)))
					break
				}
			}
		}
	}
}

class Wall: Sprite { }

class Goal: Sprite {
	var touchingPlayer1 = false
	var touchingPlayer2 = false
	var goalReached = false
	var player1: Player? = nil
	var player2: Player? = nil
	
	override func update() {
		
		let touchingBodies = self.physicsBody?.allContactedBodies()
		touchingPlayer1 = false
		touchingPlayer2 = false
		
		for body in touchingBodies! {
			if let player = body.representedObject! as? Player {
				if player.player == 1 {
					touchingPlayer1 = true
					player1 = player
				} else if player.player == 2 {
					touchingPlayer2 = true
					player2 = player
				}
			}
		}
		
		if touchingPlayer1 && touchingPlayer2 {
			if let player1 = player1, player2 = player2 {
				player1.removeFromParent()
				player2.removeFromParent()
				goalReached = true
			}
		}
		
		if goalReached {
			self.velocity.dy++
			if let parent = self.parent, scene = parent as? GameScene {
				if self.position.y > scene.size.height + (self.size.height / 2) {
					scene.loadNextLevel()
				}
			}
		}
		
		self.position.x += self.velocity.dx
		self.position.y += self.velocity.dy
		
		super.update()
	}
}

class PowerUp: Sprite {
	var powerUpType: PowerUpType
	var powerUpAmount: Int
	var powerUpSettings: JSON?
	
	init(type: PowerUpType, amount: Int, settings: JSON?) {
		self.powerUpType = type
		self.powerUpAmount = amount
		self.powerUpSettings = settings
		
		let texture = SKTexture(imageNamed: type.rawValue)
		super.init(texture: texture, color: NSColor.clearColor(), size: texture.size())
	}
	
	override func update() {
		let touchingBodies = self.physicsBody?.allContactedBodies()
		for body in touchingBodies! {
			if let player = body.representedObject! as? Player {
				if self.powerUpType == PowerUpType.Jump {
					player.jumpModifier = Float(self.powerUpAmount)
					self.removeFromParent()
				} else if self.powerUpType == PowerUpType.Heart {
					if let parent = self.parent, scene = parent as? GameScene {
						scene.addNextLevelHearts++
						self.removeFromParent()
					} else {
						println("Unable to add hearts, not removing")
					}
				}
			}
		}
	}
}