//
//  GameScene.swift
//  Space Attack
//
//  Created by Ezekiel Elin on 3/7/15.
//  Copyright (c) 2015 Ezekiel Elin. All rights reserved.
//

import SpriteKit
import Cocoa
enum AstronautStatus {
	case To
	case From
}

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
	case Scroller = "Scroller"
	case DeathScreen = "DeathScreen"
	case PlayerIndicator1 = "PlayerIndicator1"
	case PlayerIndicator2 = "PlayerIndicator2"
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

func percentOfMotion(timeDif: CFTimeInterval) -> Float {
	let desiredRate: CFTimeInterval = 1 / 20
	let result = Float(timeDif / desiredRate)
	return(result)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
	var lastTime: CFTimeInterval = 0
	
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
		self.background.zPosition = -1
		self.background.type = SpriteType.Background
		self.addChild(self.background)
		self.physicsWorld.contactDelegate = self
		
		self.loadNextLevel()
	}
	
	override func update(currentTime: CFTimeInterval) {
		/* Called before each frame is rendered */
		if lastTime == 0 {
			lastTime = currentTime
		}
		let timeDif = currentTime - lastTime
		lastTime = currentTime
		
		var player1Indicator: Sprite? = nil
		var player2Indicator: Sprite? = nil
		
		for child in self.children {
			if let child = child as? Sprite {
				child.update(timeDif)
				if child.type == SpriteType.PlayerIndicator1 {
					player1Indicator = child
				}
				if child.type == SpriteType.PlayerIndicator2 {
					player2Indicator = child
				}
			}
		}
		
		
		for child in self.children {
			if let player1Indicator = player1Indicator, player2Indicator = player2Indicator {
				if let player = child as? Player {
					if player.player == 1 {
						if player.position.y > self.size.height + (player.size.height / 2) {
							player1Indicator.hidden = false
							player1Indicator.position.x = player.position.x
						} else {
							player1Indicator.hidden = true
						}
					} else {
						if player.position.y > self.size.height + (player.size.height / 2) {
							player2Indicator.hidden = false
							player2Indicator.position.x = player.position.x
						} else {
							player2Indicator.hidden = true
						}
					}
				}
			} else {
				println("ERROR")
			}
		}
		updateHearts()
	}
	
	func finishGame() {
		var scene = MenuScene(size: self.size)
		let skView = self.view as SKView!
		skView.ignoresSiblingOrder = true
		scene.size = skView.bounds.size
		scene.menuType = "mainmenu_fin"
		skView.presentScene(scene)
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
			
			let deathscreen = DeathScreen(imageNamed: "deathscreen")
			deathscreen.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
			deathscreen.zPosition = 10
			deathscreen.type = SpriteType.DeathScreen
			self.addChild(deathscreen)
		}
	}
	
	func updateHearts() {
		
		for child in children {
			if let child = child as? Sprite {
				if child.type == SpriteType.Heart {
					child.removeFromParent()
				}
			}
		}
		
		var heartX = 5
		for heartNumber in 1...(currentHearts + addNextLevelHearts) {
			let heartString: String
			if heartNumber > currentHearts {
				heartString = "tempheart"
			} else {
				heartString = "heart"
			}
			let heart = Sprite(imageNamed: heartString)
			heart.type = SpriteType.Heart
			heart.anchorPoint = CGPointMake(0, 1)
			heart.position = CGPointMake(CGFloat(heartX), self.size.height - 5)
			
			heartX += Int(heart.size.width) + 5
			
			self.addChild(heart)
		}
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
			clearLevel()
			let scroller = Scroller(imageNamed: "scroller")
			scroller.type = SpriteType.Scroller
			scroller.anchorPoint = CGPointMake(0, 1)
			scroller.zPosition = 1
			scroller.position = CGPointMake(0, frame.size.height)
			scroller.velocity.dy = 3
			self.addChild(scroller)
			return
		}
		
		let player1 = Player(player: 1)
		let player2 = Player(player: 2)
		
		let player1Indicator = Sprite(imageNamed: "green-alien-offscreen")
		let player2Indicator = Sprite(imageNamed: "orange-alien-offscreen")
		
		player1.zPosition = 2
		player2.zPosition = 2
		player1Indicator.zPosition = 2
		player2Indicator.zPosition = 2
		
		player1.type = SpriteType.Player
		player2.type = SpriteType.Player
		player1Indicator.type = SpriteType.PlayerIndicator1
		player2Indicator.type = SpriteType.PlayerIndicator2
		
		player1.position = CGPointMake(CGFloat(currentLevel!["spawn"]!.dictionaryValue["player1"]!.dictionaryValue["x"]!.intValue), CGFloat(currentLevel!["spawn"]!.dictionaryValue["player1"]!.dictionaryValue["y"]!.intValue))
		player2.position = CGPointMake(CGFloat(currentLevel!["spawn"]!.dictionaryValue["player2"]!.dictionaryValue["x"]!.intValue), CGFloat(currentLevel!["spawn"]!.dictionaryValue["player2"]!.dictionaryValue["y"]!.intValue))
		player1Indicator.position = CGPointMake(0, self.size.height)
		player2Indicator.position = CGPointMake(0, self.size.height)
		
		player1Indicator.hidden = true
		player2Indicator.hidden = true
		
		player1Indicator.anchorPoint = CGPointMake(0.5, 1)
		player2Indicator.anchorPoint = CGPointMake(0.5, 1)
		
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
		self.addChild(player1Indicator)
		self.addChild(player2Indicator)
		
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
		
		let astronauts: [JSON] = currentLevel!["evil astronauts"]!.array!
		for astronaut in astronauts {
			let astronaut = astronaut.dictionaryValue
			let astroNode = EvilAstronaut(l1: CGPointMake(CGFloat(astronaut["x1"]!.intValue), CGFloat(astronaut["y1"]!.intValue)), l2: CGPointMake(CGFloat(astronaut["x2"]!.intValue), CGFloat(astronaut["y2"]!.intValue)), t: astronaut["time"]!.intValue)
			astroNode.type = SpriteType.Astronaut
			astroNode.zPosition = 0
			astroNode.position = astroNode.location1
			astroNode.position.x += astroNode.size.width / 2
			astroNode.position.y -= astroNode.size.height / 2
			
			astroNode.physicsBody = SKPhysicsBody(rectangleOfSize: astroNode.size)
			astroNode.physicsBody?.dynamic = false
			astroNode.physicsBody?.categoryBitMask = ColliderType.PowerUp.rawValue
			astroNode.physicsBody?.collisionBitMask = ColliderType.None.rawValue
			astroNode.physicsBody?.contactTestBitMask = ColliderType.Player.rawValue
			
			self.addChild(astroNode)
		}
		
		let powerups: [JSON] = currentLevel!["power ups"]!.array!
		for powerup in powerups {
			let powerup = powerup.dictionaryValue
			
			let powerupNode = PowerUp(type: powerUpType(powerup["type"]!.stringValue), amount: powerup["amount"]!.intValue, settings: powerup["settings"])
			powerupNode.type = SpriteType.PowerUp
			
			powerupNode.zPosition = 0
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
	
	func update(timeDif: CFTimeInterval) {
		if self.type == SpriteType.Unset {
			assertionFailure("Sprite type wasn't set for \(self)")
		}
		
		let percent = percentOfMotion(timeDif)
		self.position.x += self.velocity.dx * CGFloat(percent)
		self.position.y += self.velocity.dy * CGFloat(percent)
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
	
	override func update(timeDif: CFTimeInterval) {
		if self.parent == nil {
			return
		}
		
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
		
		super.update(timeDif)
	}
	
	func moveRight() {
		if self.velocity.dx < 8 {
			self.velocity.dx += 3
		}
	}
	
	func moveLeft() {
		if self.position.x > (self.size.width / 2) && self.velocity.dx > -8 {
			self.velocity.dx -= 3
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
	
	override func update(timeDif: CFTimeInterval) {
		
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
		
		//		self.position.x += self.velocity.dx
		//		self.position.y += self.velocity.dy
		
		super.update(timeDif)
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
	
	override func update(timeDif: CFTimeInterval) {
		if self.powerUpType == PowerUpType.Portal {
			self.zPosition = 0
		}
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
						println("Unable to add hearts, no action")
					}
				} else if self.powerUpType == PowerUpType.Portal {
					if let parent = self.parent, scene = parent as? GameScene {
						if let settings = self.powerUpSettings {
							player.position = CGPointMake(CGFloat(settings.dictionaryValue["destination x"]!.intValue) + CGFloat(self.size.width / 2), CGFloat(settings.dictionaryValue["destination y"]!.intValue) - CGFloat(self.size.height / 2))
							self.removeFromParent()
						} else {
							println("Unable to read settings, no action")
						}
					}
				}
			}
		}
		super.update(timeDif)
	}
}

class Scroller: Sprite {
	override func update(timeDif: CFTimeInterval) {
		if self.position.y >= 2560 {
			(self.parent! as! GameScene).finishGame()
		}
		super.update(timeDif)
	}
}

class DeathScreen: Sprite {
	var shownFor: CFTimeInterval = 0
	override func update(timeDif: CFTimeInterval) {
		shownFor += timeDif
		if shownFor > 2 {
			(self.parent! as! GameScene).loadLevel((self.parent! as! GameScene).currentLevelID)
			self.removeFromParent()
		}
		super.update(timeDif)
	}
}

class EvilAstronaut: Sprite {
	var location1: CGPoint
	var location2: CGPoint
	var time: Int
	var status = AstronautStatus.To
	
	
	init(l1: CGPoint, l2: CGPoint, t: Int) {
		self.location1 = l1
		self.location2 = l2
		self.time = t
		
		let texture = SKTexture(imageNamed: "evilastronaut")
		super.init(texture: texture, color: NSColor.clearColor(), size: texture.size())
	}
	
	
	override func update(timeDif: CFTimeInterval) {
		
		let deltaX = self.location2.x - self.location1.x
		let deltaY = self.location2.y - self.location1.y
		let thisDeltaX = CGFloat(Float(deltaX) * (Float(timeDif) / Float(time)))
		let thisDeltaY = CGFloat(Float(deltaY) * (Float(timeDif) / Float(time)))
		
		println(thisDeltaX)
		
		if self.status == AstronautStatus.To {
			self.position.x += thisDeltaX
			self.position.y += thisDeltaY
		} else if self.status == AstronautStatus.From {
			self.position.x -= thisDeltaX
			self.position.y -= thisDeltaY
		}
		
		
		if self.position.x < self.location1.x {
			self.status = AstronautStatus.To
		}
		if self.position.x > self.location2.x {
			self.status = AstronautStatus.From
		}
		
		
		let touchingBodies = self.physicsBody?.allContactedBodies()
		for body in touchingBodies! {
			if let player = body.representedObject! as? Player {
				(self.parent! as! GameScene).die()
			}
		}
		
		super.update(timeDif)
	}
}