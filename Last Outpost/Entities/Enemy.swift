//
//  Enemy.swift
//  Last Outpost
//
//  Created by George McMullen on 8/31/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

// The different enemies in XBlaster all share the same behaviours such as how they move using
// AISteering, their health labels and how they react to being hit. This base class immplements
// these key areas which all the enemy objects can then inherit from.
class Enemy : Entity {
    enum Trace {
        case Off
        case updateEnemy
    }
    // Tracing
    var trace: Trace = .Off
    
    let healthMeterLabel = SKLabelNode(fontNamed: "Arial")
    let healthMeterText: NSString = "________"
    let scoreLabel = SKLabelNode(fontNamed: "Edit Undo Line BRK")
    let deathEmitter:SKEmitterNode = SKEmitterNode(fileNamed: "enemyDeath.sks")!
    
    var aiSteering: AISteering!
    var playableRect: CGRect!
    var dead = false
    var spawnDelay: TimeInterval = 0
    var spawnTime: TimeInterval = 0
    var lastExecutionTime: TimeInterval = 0.0
    var executionTimeGovernor: TimeInterval = 1.0/30.0  // Default 30 movements per second
    
    var spawned: Bool = false
    
    enum EnemyClass {
        case mini
        case fighter
        case boss
    }
    
    // Enemy bullet type
    enum GunType {
        case None
        case RailGun
        case StaticGun
    }
    
    var enemyClass: EnemyClass = EnemyClass.fighter
    var gunType: GunType = GunType.None
    var gunFireInterval: TimeInterval = 1.0
    private var gunLastFireTime: TimeInterval = 0.0
    var gunBurstFireNumber: Int = 1
    private var gunBurstFireCurrentNumber: Int = 0
    var gunBurstFireGovernor: TimeInterval = 1.0  // Default burst gunfire Interval
    var bulletSpeed: Double = 25.0  // Bullet speed

    
    // All the actions used for the enemies are static which means that each enemy uses a shared
    // action that is created only once in the loadSharedAssets() method. This reduces the number
    // of actions needed and removes the need to keep creating and destroying actions for each enemy
    struct SharedAssets {
        static var damageAction:SKAction!
        static var hitLeftAction:SKAction!
        static var hitRightAction:SKAction!
        static var moveBackAction:SKAction!
        static var scoreLabelAction:SKAction!
        static var onceToken = "Enemy"
    }
    
    var pewSound: SKAction = SKAction.sequence([SKAction.playSoundFileNamed(fileName: "pew.wav", atVolume: 1.0, waitForCompletion: false)])
    // Pulse colors
    let colorPulseBlue = SKAction.repeatForever(SKAction.sequence([SKAction.colorize(with: SKColor.blue, colorBlendFactor: 1, duration: 0.1), SKAction.colorize(with: SKColor.white, colorBlendFactor: 1, duration: 0.1)]))
    let colorPulseRed = SKAction.repeatForever(SKAction.sequence([SKAction.colorize(with: SKColor.red, colorBlendFactor: 1, duration: 0.1), SKAction.colorize(with: SKColor.white, colorBlendFactor: 1, duration: 0.1)]))
    var electricSound:  SKAction = SKAction.sequence([SKAction.playSoundFileNamed(fileName: "electriccurrent.wav", atVolume: 1.0, waitForCompletion: false)])
    // Pulse action
    let screenPulseAction = SKAction.repeatForever(SKAction.sequence([SKAction.fadeOut(withDuration: 1), SKAction.fadeIn(withDuration: 1)]))
    // Rotate it (spin it really fast)
    let rotateNode = SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi/1), duration: 0.1))
    // Pulse it
    let pulseNode = SKAction.repeatForever(SKAction.sequence([SKAction.fadeOut(withDuration: 0.1), SKAction.fadeIn(withDuration: 0.1)]))

    
    class func loadSharedAssets() {
        // See extension in Entity.swift
        DispatchQueue.once(token: SharedAssets.onceToken) {
            SharedAssets.damageAction = SKAction.sequence([
                SKAction.colorize(with: SKColor.red, colorBlendFactor: 1.0, duration: 0.0),
                SKAction.colorize(withColorBlendFactor: 0.0, duration: 1.0)
                ])
            
            SharedAssets.hitLeftAction = SKAction.sequence([
                SKAction.rotate(byAngle: CGFloat(-15).degreesToRadians(), duration: 0.25),
                SKAction.rotate(toAngle: CGFloat(0).degreesToRadians(), duration: 0.5)
                ])
            
            SharedAssets.hitRightAction = SKAction.sequence([
                SKAction.rotate(byAngle: CGFloat(15).degreesToRadians(), duration: 0.25),
                SKAction.rotate(toAngle: CGFloat(0).degreesToRadians(), duration: 0.5)
                ])
            
            SharedAssets.moveBackAction = SKAction.moveBy(x: 0, y: 20, duration: 0.25)
            
            SharedAssets.scoreLabelAction = SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1, duration: 0),
                    SKAction.fadeOut(withDuration: 0),
                    SKAction.fadeIn(withDuration: 0.5),
                    SKAction.moveBy(x: 0, y: 20, duration: 0.5)
                    ]),
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 40, duration: 1),
                    SKAction.fadeOut(withDuration: 1),
                    SKAction.wait(forDuration: 1.0),
                    SKAction.removeFromParent()
                    ]),
                ])
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        #if DEBUG_OFF
            print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        super.init(coder: aDecoder)
    }
    
    init(entityPosition: CGPoint, texture: SKTexture, playableRect: CGRect) {
        #if DEBUG_OFF
            print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif

        super.init(position: entityPosition, texture: texture)
        
        self.playableRect = playableRect
        
        // Set the current time as the spawn time
        spawnTime = Date().timeIntervalSince1970
        
        // Setup the label that shows how much health an enemy has
        healthMeterLabel.name = "healthMeter"
        healthMeterLabel.fontSize = 20
        healthMeterLabel.fontColor = SKColor.green
        healthMeterLabel.text = healthMeterText as String
        healthMeterLabel.position = CGPoint(x: 0, y: 30)
        addChild(healthMeterLabel)
        
        scoreLabel.fontSize = 15
        scoreLabel.color = SKColorWithRGBA(128, g: 255, b: 255, a: 255)
        scoreLabel.text = String(score)
        
        lastExecutionTime = 0.0
    }
    
    // Update method that handles the spawn delay, the 'dead' status, and the movement.
    func updateEnemy(bulletNode: SKNode, playerPosition: CGPoint) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        
        //
        let currentTime: TimeInterval = Date().timeIntervalSince1970

        // If we have a spawn delay
        // Print debug information
        // Trace information
        if(trace == .updateEnemy) {print("\tLine: \(#line)")}
        if (spawnDelay > 0) {
            // If the current time minus the spawn time is less than the spawn delay, then
            // return without doing anything
            if (currentTime - spawnTime <= spawnDelay) {
                return
            } else {
                spawned = true
            }
        }

        // If the player has been marked as dead then reposition them at the top of the screen and
        // mark them a no longer being dead
        // Trace information
        if(trace == .updateEnemy) {print("\tLine: \(#line)")}
        if (dead) {
            if (lives - 1 < 1) {
                removeFromParent()
            } else {
                dead = false
                position = CGPoint(x: CGFloat.random(min:playableRect.origin.x, max:playableRect.size.width),
                                   y: playableRect.size.height+100)
                lives = (lives > 0 ? lives - 1 : lives)
                // Set the spawn time
                spawnTime = currentTime
                spawned = false
                return
            }
        }
        
        // Initiate the last execution time
        // Trace information
        if(trace == .updateEnemy) {print("\tLine: \(#line)")}
        if (lastExecutionTime <= 0) {
            lastExecutionTime = currentTime
        }
        
        // Get the delta from the last time we executed until now
        let executionTimeDelta = currentTime - lastExecutionTime
        
        // If we've waited at least the exuection time governor, then we can move the enemy
        // Trace information
        if(trace == .updateEnemy) {print("\tLine: \(#line)")}
        if (executionTimeDelta >= executionTimeGovernor) {
            //
            // Clear the last execution time so that it resets on the next update interval
            lastExecutionTime = currentTime
            // If the enemy has reached is next waypoint then set the next waypoint to the players
            // current position. This causes the enemies to chase the player :]
            // Trace information
            if(trace == .updateEnemy) {print("\tLine: \(#line)")}
            if aiSteering.waypointReached {
                aiSteering.updateWaypoint(playerPosition)
            }

            // Steer the enemy towards the current waypoint
            // Trace information
            if(trace == .updateEnemy) {print("\tLine: \(#line)")}
            aiSteering.update(executionTimeDelta)
            
            // Update the health meter for the enemy
            // Trace information
            if(trace == .updateEnemy) {print("\tLine: \(#line)")}
            let healthBarLength = 8.0 * (health / maxHealth)
            // Trace information
            if(trace == .updateEnemy) {print("\tLine: \(#line)")}
            healthMeterLabel.text = "\(healthMeterText.substring(to: Int(healthBarLength)))"
            // Trace information
            if(trace == .updateEnemy) {print("\tLine: \(#line)")}
            healthMeterLabel.fontColor = SKColor(red: CGFloat(2 * (1 - health / maxHealth)),
                                                 green:CGFloat(2 * health / maxHealth), blue:0, alpha:1)
        }
        
        //
        // If we need to fire the bullet, then call the routine
        // Trace information
        if(trace == .updateEnemy) {print("\tLine: \(#line)")}
        if (gunType != .None) {
            fireBullet(bulletNode: bulletNode, playerPosition: playerPosition, currentTime: currentTime);
        }
    }
    
    //
    // Method to handle firing bullets from this enemy ship type
    func fireBullet(bulletNode: SKNode, playerPosition: CGPoint, currentTime: TimeInterval) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        
        //
        // If we haven't spawned or if we don't have a gun, return
        if(!spawned || gunType == .None) {
            return
        }
        
        // If we haven't fired a bullet yet, set the last fire to a random wait time based upon the interval
        if (gunLastFireTime <= 0.0) {
            gunLastFireTime = currentTime + Double.random(in: 0..<gunFireInterval)
        }
        
        // Get the delta since the last firing
        let lastFiredDelta = currentTime - gunLastFireTime
        // Set a governor so that we don't fire the gun too fast
        //
        // We fire a bullet if we have a gun burst and we've waited the minimum amount of time between bursts OR
        //   we have waited long enough to initiate a new bullet firing
        // If we've fired at least 1 burst, then make sure we wait until the governor has passed
        if (gunBurstFireCurrentNumber > 0 && lastFiredDelta <= Double(gunBurstFireGovernor)) {
            return  // We still need to wait before the next burst
        } else if (gunBurstFireCurrentNumber == 0 && lastFiredDelta < gunFireInterval) {
            return // Need to wait before we can initiate another firing
        }
            
//        print("Current Number: \(gunBurstFireCurrentNumber) Delta: \(lastFiredDelta) Governor: \(gunBurstFireGovernor)")
//        print(lastFiredDelta, (Double(gunBurstFireCurrentNumber) * Double(gunBurstFireGovernor)), lastFiredDelta <= ((Double(gunBurstFireCurrentNumber) * Double(gunBurstFireGovernor))))
        // Fire the gun
        let movement1 = CGVector(
            dx: (playerPosition.x - position.x)*10,
            dy: (playerPosition.y - position.y)*10)
        // Setup the bullet to move by a vector at a calculated speed
        let movement = SKAction.sequence([SKAction.move(by: movement1, duration: getDuration(
            pointA: playerPosition, pointB: position,
            speed: CGFloat(bulletSpeed))), SKAction.removeFromParent()])
        // Let's add a lot of special effects to this type of bullet
        // Group the actions
        switch (gunType) {
        case .RailGun:
            let bullet = EnemyBulletRailGun(entityPosition: position)
            bulletNode.addChild(bullet)
            let group = SKAction.group([movement, colorPulseRed, pewSound])
            // Execute the group
            bullet.run(group)
            break
        case .StaticGun:
            let bullet = EnemyBulletStaticGun(entityPosition: position)
            bulletNode.addChild(bullet)
            let group = SKAction.group([movement, rotateNode, pulseNode, colorPulseBlue, electricSound])
            // Execute the group
            bullet.run(group)
            if scene == nil {
                // DEBUG
                print("Enemy.swift - scene object is NIL!")
            } else {
                // Pulse the screen
                let mainScene = scene as! GameScene
                mainScene.run(SKAction.sequence([
                    SKAction.colorize(with: SKColor.darkGray, colorBlendFactor: 1.0, duration: 0.25),
                    SKAction.colorize(with: mainScene.screenBackgroundColor, colorBlendFactor: 1.0, duration: 0.25), SKAction.removeFromParent()]))
            }
            break
        default:
            return
        }
        // Add 1 to the burst fire counter
        gunBurstFireCurrentNumber += 1
        gunLastFireTime = currentTime  // Reset the time to the current time
        // If we've fired the entire burst, reset the counters
        if (gunBurstFireCurrentNumber >= gunBurstFireNumber) {
            gunBurstFireCurrentNumber = 0
        }
    }
    
    func configureCollisionBody() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        
        // More details on this method inside the PlayerShip class and more details on SpriteKit physics in
        // Chapter 9, "Beginner Physics"
        physicsBody = SKPhysicsBody(rectangleOf: frame.size)
        if physicsBody == nil {
            // DEBUG
            print("Enemy.swift:configureCollisionBody - physicsBody object is NIL! \(frame.size)")
        }
        physicsBody!.affectedByGravity = false
        physicsBody!.categoryBitMask = ColliderType.Enemy
        physicsBody!.collisionBitMask = 0
        physicsBody!.contactTestBitMask = ColliderType.Player | ColliderType.PlayerBullet
    }
    
    //
    // This method handles when this object collides with another
    override func collidedWith(_ body: SKPhysicsBody, contact: SKPhysicsContact, damage: Int = 10) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        
        // If we haven't spawned yet, don't let them hit us
        if (!spawned) {
            return
        }
        
        // When an enemy gets hit we grab the point at which the enemy was hit
        let localContactPoint:CGPoint = self.scene!.convert(contact.contactPoint, to: self)
        
        // New actions are going to be added to this enemy so remove all the current actions they have
        removeAllActions()
        
        // Depending on if the emeny was hit from above or below, we need to rotate the enemy
        // If the enemy was hit from above, reverse the rotation
        //   If the enemy was hit on the left side then run the hitLeftAction otherwise run the hitRightAction.
        //   This gives a nice impression of an actual collision
        if (localContactPoint.y < 0) {  // Hit from below
            if localContactPoint.x < 0 {
                run(SharedAssets.hitLeftAction)
            } else {
                run(SharedAssets.hitRightAction)
            }
        } else {  // Hit from above
            if localContactPoint.x < 0 {
                run(SharedAssets.hitRightAction)
            } else {
                run(SharedAssets.hitLeftAction)
            }
        }
        
        // Run the damage action so that the player has a visual queue that the enemy has been damaged
        run(SharedAssets.damageAction)
        if aiSteering.currentDirection.y < 0 {
            run(SharedAssets.moveBackAction)
        }
        
        // Reduce the enemies health by the defined damageTakenPerHit
        health -= Double(damage)
        
        // If the enemies health is now zero or less then...
        if health <= 0 {
            // ...mark them as dead
            dead = true
            
            // Increase the score for the player
            let mainScene = scene as! GameScene
            mainScene.increaseScoreBy(score)
            mainScene.increaseFundsBy(funds)
            
            // Reset the enemies health
            health = maxHealth
            
            scoreLabel.position = position
            if scoreLabel.parent == nil {
                mainScene.addChild(scoreLabel)
            }
            scoreLabel.removeAllActions()
            scoreLabel.run(SharedAssets.scoreLabelAction)
            
            deathEmitter.position = position
            if deathEmitter.parent == nil {
                deathEmitter.run(SKAction.sequence([
                    SKAction.wait(forDuration: 3.0),
                    SKAction.removeFromParent()
                    ]))
                mainScene.starfieldLayerNode.addChild(deathEmitter)
            }
            deathEmitter.isHidden = false
            deathEmitter.resetSimulation()
            mainScene.playExplodeSound()
        }
    }
    
    //
    // Set the spawn delay on this object.  We use the spawn delay to spread out the spawn rate of the enemies
    // so that we don't get 50 enemies all attacking in the first second.
    func setSpawnDelay(_ delay: TimeInterval) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        
        // If we have a positive number, set the delay
        if (delay > 0) {
            spawnDelay = delay
        }
    }
}

