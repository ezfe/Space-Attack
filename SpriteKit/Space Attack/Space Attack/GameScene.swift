//
//  GameScene.swift
//  Space Attack
//
//  Created by Ezekiel Elin on 3/7/15.
//  Copyright (c) 2015 Ezekiel Elin. All rights reserved.
//

import SpriteKit
import Cocoa
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

enum AstronautStatus {
	case to
	case from
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
	case wall	 = 1
	case player	 = 2
	case goal	 = 3
	case powerUp = 4
	case none	 = 0
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

func powerUpType(_ pwString: String) -> PowerUpType {
	switch pwString {
	case "heart": return .Heart
	case "jump": return .Jump
	case "portal": return .Portal
	default: return .Jump
	}
}

func percentOfMotion(_ timeDif: CFTimeInterval) -> Float {
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
	
	override func didMove(to view: SKView) {
		/* Setup your scene here */
		pressedKeys[Keys.Left] = false
		pressedKeys[Keys.Up] = false
		pressedKeys[Keys.Right] = false
		
		pressedKeys[Keys.A] = false
		pressedKeys[Keys.W] = false
		pressedKeys[Keys.D] = false
		
		self.background.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
		self.background.zPosition = -1
		self.background.type = SpriteType.Background
		self.addChild(self.background)
		self.physicsWorld.contactDelegate = self
		
		self.loadNextLevel()
	}
	
	override func update(_ currentTime: TimeInterval) {
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
			if let player1Indicator = player1Indicator, let player2Indicator = player2Indicator {
				if let player = child as? Player {
					if player.player == 1 {
						if player.position.y > self.size.height + (player.size.height / 2) {
							player1Indicator.isHidden = false
							player1Indicator.position.x = player.position.x
						} else {
							player1Indicator.isHidden = true
						}
					} else {
						if player.position.y > self.size.height + (player.size.height / 2) {
							player2Indicator.isHidden = false
							player2Indicator.position.x = player.position.x
						} else {
							player2Indicator.isHidden = true
						}
					}
				}
			}
		}
		updateHearts()
	}
	
	func finishGame() {
		let scene = MenuScene(size: self.size)
		self.view?.ignoresSiblingOrder = true
		scene.size = (self.view?.bounds.size)!
		scene.menuType = "mainmenu_fin"
		self.view?.presentScene(scene)
	}
	
	func die() {
		clearLevel()
		
		if self.currentHearts <= 1 {
			let scene = MenuScene(size: self.size)
			self.view?.ignoresSiblingOrder = true
			scene.size = (self.view?.bounds.size)!
			scene.menuType = "mainmenu_died"
			self.view?.presentScene(scene)
		} else {
			self.currentHearts -= 1
			self.addNextLevelHearts = 0
			
			let deathscreen = DeathScreen(imageNamed: "deathscreen")
			deathscreen.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
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
			heart.anchorPoint = CGPoint(x: 0, y: 1)
			heart.position = CGPoint(x: CGFloat(heartX), y: self.size.height - 5)
			
			heartX += Int(heart.size.width) + 5
			
			self.addChild(heart)
		}
	}
	
	func loadNextLevel() {
		clearLevel()
		self.currentLevelID += 1
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
	
	func loadLevel(_ level: Int) {
		print("Loading level \(level)")
		print("Currentl at \(self.currentHearts) hearts")
		
		let path = Bundle.main.path(forResource: "level\(level)", ofType: "json")
		if let path = path {
			let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path))
			currentLevel = try! JSON(data: jsonData!).dictionary!
		} else {
			print("No more levels")
			clearLevel()
			let scroller = Scroller(imageNamed: "scroller")
			scroller.type = SpriteType.Scroller
			scroller.anchorPoint = CGPoint(x: 0, y: 1)
			scroller.zPosition = 1
			scroller.position = CGPoint(x: 0, y: frame.size.height)
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
		
		player1.position = CGPoint(x: CGFloat(currentLevel!["spawn"]!.dictionaryValue["player1"]!.dictionaryValue["x"]!.intValue), y: CGFloat(currentLevel!["spawn"]!.dictionaryValue["player1"]!.dictionaryValue["y"]!.intValue))
		player2.position = CGPoint(x: CGFloat(currentLevel!["spawn"]!.dictionaryValue["player2"]!.dictionaryValue["x"]!.intValue), y: CGFloat(currentLevel!["spawn"]!.dictionaryValue["player2"]!.dictionaryValue["y"]!.intValue))
		player1Indicator.position = CGPoint(x: 0, y: self.size.height)
		player2Indicator.position = CGPoint(x: 0, y: self.size.height)
		
		player1Indicator.isHidden = true
		player2Indicator.isHidden = true
		
		player1Indicator.anchorPoint = CGPoint(x: 0.5, y: 1)
		player2Indicator.anchorPoint = CGPoint(x: 0.5, y: 1)
		
		player1.physicsBody = SKPhysicsBody(rectangleOf: player1.size)
		player1.physicsBody?.allowsRotation = false
		player1.physicsBody?.usesPreciseCollisionDetection = true
		player1.physicsBody?.categoryBitMask = ColliderType.player.rawValue
		player1.physicsBody?.collisionBitMask = ColliderType.wall.rawValue
		player1.physicsBody?.restitution = 0.0
		
		player2.physicsBody = SKPhysicsBody(rectangleOf: player2.size)
		player2.physicsBody?.allowsRotation = false
		player2.physicsBody?.usesPreciseCollisionDetection = true
		player2.physicsBody?.categoryBitMask = ColliderType.player.rawValue
		player2.physicsBody?.collisionBitMask = ColliderType.wall.rawValue
		player2.physicsBody?.restitution = 0.0
		
		self.addChild(player1)
		self.addChild(player2)
		self.addChild(player1Indicator)
		self.addChild(player2Indicator)
		
		let goal = Goal(imageNamed: "goal")
		goal.zPosition = 1
		goal.position = CGPoint(x: CGFloat(currentLevel!["goal"]!.dictionaryValue["x"]!.intValue) + CGFloat(goal.size.width / 2), y: CGFloat(currentLevel!["goal"]!.dictionaryValue["y"]!.intValue) - CGFloat(goal.size.height / 2))
		goal.type = SpriteType.Goal
		
		goal.physicsBody = SKPhysicsBody(rectangleOf: goal.size)
		goal.physicsBody?.isDynamic = false
		goal.physicsBody?.categoryBitMask = ColliderType.goal.rawValue
		goal.physicsBody?.collisionBitMask = ColliderType.none.rawValue
		goal.physicsBody?.contactTestBitMask = ColliderType.player.rawValue
		
		self.addChild(goal)
		
		let walls: [JSON] = currentLevel!["walls"]!.array!
		for wall in walls {
			let wall = wall.dictionaryValue
			let size = CGSize(width: CGFloat(wall["width"]!.intValue), height: CGFloat(wall["height"]!.intValue))
			let wallNode = Wall(color: NSColor(red:0.64, green:0.8, blue:0.76, alpha:1), size: size)
			wallNode.type = SpriteType.Wall
			wallNode.zPosition = 1
			wallNode.position = CGPoint(x: CGFloat(wall["x"]!.intValue) + CGFloat(wallNode.size.width / 2), y: CGFloat(wall["y"]!.intValue) - CGFloat(wallNode.size.height / 2))
			
			wallNode.physicsBody = SKPhysicsBody(rectangleOf: wallNode.size)
			wallNode.physicsBody?.isDynamic = false
			
			wallNode.physicsBody?.categoryBitMask = ColliderType.wall.rawValue
			wallNode.physicsBody?.collisionBitMask = ColliderType.player.rawValue
			
			wallNode.physicsBody?.restitution = 0.0
			
			self.addChild(wallNode)
		}
		
		let astronauts: [JSON] = currentLevel!["evil astronauts"]!.array!
		for astronaut in astronauts {
			let astronaut = astronaut.dictionaryValue
			let astroNode = EvilAstronaut(l1: CGPoint(x: CGFloat(astronaut["x1"]!.intValue), y: CGFloat(astronaut["y1"]!.intValue)), l2: CGPoint(x: CGFloat(astronaut["x2"]!.intValue), y: CGFloat(astronaut["y2"]!.intValue)), t: astronaut["time"]!.intValue)
			astroNode.type = SpriteType.Astronaut
			astroNode.zPosition = 0
			astroNode.position = astroNode.location1
			astroNode.position.x += astroNode.size.width / 2
			astroNode.position.y -= astroNode.size.height / 2
			
			astroNode.physicsBody = SKPhysicsBody(rectangleOf: astroNode.size)
			astroNode.physicsBody?.isDynamic = false
			astroNode.physicsBody?.categoryBitMask = ColliderType.powerUp.rawValue
			astroNode.physicsBody?.collisionBitMask = ColliderType.none.rawValue
			astroNode.physicsBody?.contactTestBitMask = ColliderType.player.rawValue
			
			self.addChild(astroNode)
		}
		
		let powerups: [JSON] = currentLevel!["power ups"]!.array!
		for powerup in powerups {
			let powerup = powerup.dictionaryValue
			
			let powerupNode = PowerUp(type: powerUpType(powerup["type"]!.stringValue), amount: powerup["amount"]!.intValue, settings: powerup["settings"])
			powerupNode.type = SpriteType.PowerUp
			
			powerupNode.zPosition = 0
			powerupNode.position = CGPoint(x: CGFloat(powerup["x"]!.intValue) + CGFloat(powerupNode.size.width / 2), y: CGFloat(powerup["y"]!.intValue) - CGFloat(powerupNode.size.height / 2))
			
			powerupNode.physicsBody = SKPhysicsBody(rectangleOf: goal.size)
			powerupNode.physicsBody?.isDynamic = false
			powerupNode.physicsBody?.categoryBitMask = ColliderType.powerUp.rawValue
			powerupNode.physicsBody?.collisionBitMask = ColliderType.none.rawValue
			powerupNode.physicsBody?.contactTestBitMask = ColliderType.player.rawValue
			
			self.addChild(powerupNode)
		}
	}
	override func keyDown(with theEvent: NSEvent) {
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
	
	override func keyUp(with theEvent: NSEvent) {
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
	var velocity = CGVector(dx: 0, dy: 0)
	
	func update(_ timeDif: CFTimeInterval) {
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
		super.init(texture: texture, color: NSColor.clear, size: texture.size())
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func update(_ timeDif: CFTimeInterval) {
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
			if let wall = body.node! as? Wall {
				if wall.position.y < self.position.y {
					self.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: self.jumpAmount * CGFloat(self.jumpModifier)))
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
	
	override func update(_ timeDif: CFTimeInterval) {
		
		let touchingBodies = self.physicsBody?.allContactedBodies()
		touchingPlayer1 = false
		touchingPlayer2 = false
		
		for body in touchingBodies! {
			if let player = body.node! as? Player {
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
			if let player1 = player1, let player2 = player2 {
				player1.removeFromParent()
				player2.removeFromParent()
				goalReached = true
			}
		}
		
		if goalReached {
			self.velocity.dy += 1
			if let parent = self.parent, let scene = parent as? GameScene {
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
		super.init(texture: texture, color: NSColor.clear, size: texture.size())
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func update(_ timeDif: CFTimeInterval) {
		if self.powerUpType == PowerUpType.Portal {
			self.zPosition = 0
		}
		let touchingBodies = self.physicsBody?.allContactedBodies()
		for body in touchingBodies! {
			if let player = body.node! as? Player {
				if self.powerUpType == PowerUpType.Jump {
					player.jumpModifier = Float(self.powerUpAmount)
					self.removeFromParent()
				} else if self.powerUpType == PowerUpType.Heart {
					if let parent = self.parent, let scene = parent as? GameScene {
						scene.addNextLevelHearts += 1
						self.removeFromParent()
					} else {
						print("Unable to add hearts, no action")
					}
				} else if self.powerUpType == PowerUpType.Portal {
					if self.parent is GameScene {
						if let settings = self.powerUpSettings {
							player.position = CGPoint(x: CGFloat(settings.dictionaryValue["destination x"]!.intValue) + CGFloat(self.size.width / 2), y: CGFloat(settings.dictionaryValue["destination y"]!.intValue) - CGFloat(self.size.height / 2))
							self.removeFromParent()
						} else {
							print("Unable to read settings, no action")
						}
					}
				}
			}
		}
		super.update(timeDif)
	}
}

class Scroller: Sprite {
	override func update(_ timeDif: CFTimeInterval) {
		if self.position.y >= 2560 {
			(self.parent! as! GameScene).finishGame()
		}
		super.update(timeDif)
	}
}

class DeathScreen: Sprite {
	var shownFor: CFTimeInterval = 0
	override func update(_ timeDif: CFTimeInterval) {
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
	var status = AstronautStatus.to
	
	
	init(l1: CGPoint, l2: CGPoint, t: Int) {
		self.location1 = l1
		self.location2 = l2
		self.time = t
		
		let texture = SKTexture(imageNamed: "evilastronaut")
		super.init(texture: texture, color: NSColor.clear, size: texture.size())
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	
	override func update(_ timeDif: CFTimeInterval) {
		
		let deltaX = self.location2.x - self.location1.x
		let deltaY = self.location2.y - self.location1.y
		let thisDeltaX = CGFloat(Float(deltaX) * (Float(timeDif) / Float(time)))
		let thisDeltaY = CGFloat(Float(deltaY) * (Float(timeDif) / Float(time)))
		
		print(thisDeltaX)
		
		if self.status == AstronautStatus.to {
			self.position.x += thisDeltaX
			self.position.y += thisDeltaY
		} else if self.status == AstronautStatus.from {
			self.position.x -= thisDeltaX
			self.position.y -= thisDeltaY
		}
		
		
		if self.position.x < self.location1.x {
			self.status = AstronautStatus.to
		}
		if self.position.x > self.location2.x {
			self.status = AstronautStatus.from
		}
		
		
		let touchingBodies = self.physicsBody?.allContactedBodies()
		for body in touchingBodies! {
			if let _ = body.node! as? Player {
				(self.parent! as! GameScene).die()
			}
		}
		
		super.update(timeDif)
	}
}
