//
//  GameScene.swift
//  Last Outpost
//
//  Created by George McMullen on 8/28/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

// The update method uses the GameState to work out what should be done during each update loop
enum GameState {
    case splashScreen  // Sitting on the splash screen
    case gameRunning   // Game is currently running
    case gameOver      // Game has ended
    case waveComplete  // Wave completed
    case readyToStartWave  // Ready to start the wave
    case transitioning  // Transition player to the starting position
}

// Center gun type
enum PlayerCenterLaserCannonState {
    case railGun
    case particleLaser
    case protonLaser
}

// Forward wing gun type
enum PlayerWingLaserCannonState {
    case none
    case railGun
    case particleLaser
    case protonLaser
}

// Tail gun type
enum PlayerTailLaserCannonState {
    case none
    case railGun
    case particleLaser
    case protonLaser
}

// THe difficulty enum is used to set the timing interval for the enemies.  The larger the number,
// the slower the enemies are.
enum GameDifficulty: Double {
    case easy = 1.25
    case normal = 1.0
    case hard = 0.8
    case extreme = 0.3
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    let startingWave: Int = 1 // Used for setting a starting level if you want to debug it
    let bonusWaveInterval: Int = 10 // The bonus wave interval (i.e. bonus every 'n' waves)
    let weaponUpgradeInterval: Int = 5  // Improve weapons every 'n' levels
    // We can use this to increase/decrease the player difficulty. The smaller the number, the faster
    // the screen should do updates for the enemies.  We use the value from this enum to multiply
    // against objects during game play.
    var programDifficulty: GameDifficulty = .normal
    
    // Screen nodes:
    let playerLayerNode = SKNode()  // Contains the player ship images and effects
    let hudLayerNode = SKNode()  // Contains the score, health, press any key messages
    let playerBulletLayerNode = SKNode()  // Contains the player's bullets
    let enemyBulletLayerNode = SKNode()  // Contains the enemies bullets
    var enemyLayerNode = SKNode()  // Contains the enemy ship images and effects
    let starfieldLayerNode = SKNode()  // Contains the starfield particles (background)
    
    var playableRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0) // Defined playable area of the screen (screen size)
    let screenBackgroundColor = SKColor.black
    let hudHeight: CGFloat = 90  // Total height of the HUD (subtracted from the play area size)
    var musicVolume: Float = 0.5
    var specialEffectsVolume: Float = 1.0
    var laserVolume: Float = 0.5  // Laser volume
    
    var gameState = GameState.splashScreen  // Current game state
    
    // The execution time and governor variables are used to control the speed of the objects
    // during the game.  These variables allow us to try and standarize on a set speed indepenent
    // of the processor CPU speed.  We limit the movement of an enemy, for instance, to 30 mps (movements
    // per second).
    var lastEnemyExecutionTime: TimeInterval = 0.0
    let enemyExecutionGovernor: TimeInterval = 1.0 / 30.0  // 30 mps
    var playerBulletExecutionTime: TimeInterval = 0.0
    let playerBulletsPerSecond: Float = 4.0
    var playerBulletFireRateInterval: TimeInterval = 0.0
    var enemyBulletExecutionTime: TimeInterval = 0.0
    let enemyBulletsPerSecond: Float = 4.0
    var enemyBulletFireRateInterval: TimeInterval = 0.0
    var transitionStartExecutionTime: TimeInterval = 0.0
    var transitionLastExecutionTime: TimeInterval = 0.0
    let transitionExecutionRate: TimeInterval = 0.025  // Speed to transition the player back to the starting spot
    let transitionExecutionSpeed: Int = 5 // Number of pixels to move
    let transitionMiminumTime: TimeInterval = 5.0  // Minimum amout of time we want to wait before starting next level
    let enemyBulletSpeed: Double = 25.0  // Bullet speed
    
    // Text labels.  Make sure you have the font loaded in the code if you add unusual fonts here.
    // Edit Undo Link BRK = edunline.ttf
    let gameOverLabel = SKLabelNode(fontNamed: "Edit Undo Line BRK")
    let playerHealthLabel = SKLabelNode(fontNamed: "Arial")
    let scoreLabel = SKLabelNode(fontNamed: "Edit Undo Line BRK")
    let tapScreenLabel = SKLabelNode(fontNamed: "Edit Undo Line BRK")
    let levelLabel = SKLabelNode(fontNamed: "Edit Undo Line BRK")
    let waveLabel = SKLabelNode(fontNamed: "Arial")
    let fundsLabel = SKLabelNode(fontNamed: "Arial")
    let healthBarString: NSString = "===================="
   
    var score = 0
    var funds = 0  // Amount of money earned by the player to purchase upgrades
    var wave = 0  // Current wave

    // Variables used for the bonus mode:
    var bonusStartTime: TimeInterval = 0
    var bonusTimeRemaining: Int = 0
    var lastBonusTimeRemaining: Int = 0
    var bonusMode = false
    var endBonusMode = false
    var bonusTimeMaxRegenerationPercent = 0.5
    var bonusTime: Int = 30
    let countdownLabel = SKLabelNode(fontNamed: "Edit Undo Line BRK")

    // Enemy Definitions:
    //   Scouts
    var enemyScoutsLevelFirstAppear: Int = 1
    var enemyScoutsStartingNumber: Int = 5
    var enemyScoutsStartingHPs: Double = 5.0
    var enemyScoutsHPStrengthMultiplier: Double = 0.05
    var enemyScoutsLevelsToAddAdditional: Int = 1
    var enemyScoutsMaximumNumber: Int = 10
    var enemyScoutsLevelGainAdditionalLives: Int = 10
    var enemyScoutsMaximumNumberOfAdditioinalLives: Int = 2
    var enemyScoutSpawnDelay: Double = 4.0
    var enemyScoutsSpawnMinimum: Double = 0.0

    //   Swarmers
    var enemySwarmersLevelFirstAppear: Int = 5
    var enemySwarmersStartingNumber: Int = 3
    var enemySwarmersStartingHPs: Double = 3.0
    var enemySwarmersHPStrengthMultiplier: Double = 0.05
    var enemySwarmersLevelsToAddAdditional: Int = 5
    var enemySwarmersMaximumNumber: Int = 20
    var enemySwarmersLevelGainAdditionalLives: Int = 1
    var enemySwarmersMaximumNumberOfAdditioinalLives: Int = 0
    var enemySwarmersSpawnDelay: Double = 5.0
    var enemySwarmersSpawnMinimum: Double = 0.5

    //   Fighters
    var enemyFightersLevelFirstAppear: Int = 9
    var enemyFightersStartingNumber: Int = 2
    var enemyFightersStartingHPs: Double = 7.0
    var enemyFightersHPStrengthMultiplier: Double = 0.05
    var enemyFightersLevelsToAddAdditional: Int = 5
    var enemyFightersMaximumNumber: Int = 10
    var enemyFightersLevelGainAdditionalLives: Int = 20
    var enemyFightersMaximumNumberOfAdditioinalLives: Int = 2
    var enemyFightersSpawnDelay: Double = 4.0
    var enemyFightersSpawnMinimum: Double = 4.0

    //   Boss Fighter
    var enemyBossFightersLevelFirstAppear: Int = 19
    var enemyBossFightersStartingNumber: Int = 1
    var enemyBossFightersStartingHPs: Double = 25.0
    var enemyBossFightersHPStrengthMultiplier: Double = 0.1
    var enemyBossFightersLevelInterval: Int = 10
    var enemyBossFightersLevelsToAddAdditional: Int = 10
    var enemyBossFightersMaximumNumber: Int = 5
    var enemyBossFightersLevelGainAdditionalLives: Int = 20
    var enemyBossFightersMaximumNumberOfAdditioinalLives: Int = 1
    var enemyBossFightersSpawnDelay: Double = 5.0
    var enemyBossFightersSpawnMinimum: Double = 5.0
    
    //   Boss Bombers
    var enemyBossBombersLevelFirstAppear: Int = 39
    var enemyBossBombersStartingNumber: Int = 1
    var enemyBossBombersStartingHPs: Double = 50.0
    var enemyBossBombersHPStrengthMultiplier: Double = 0.1
    var enemyBossBombersLevelsToAddAdditional: Int = 20
    var enemyBossBombersMaximumNumber: Int = 4
    var enemyBossBombersLevelGainAdditionalLives: Int = 20
    var enemyBossBombersMaximumNumberOfAdditioinalLives: Int = 1
    var enemyBossBombersSpawnDelay: Double = 5.0
    var enemyBossBombersSpawnMinimum: Double = 10.0
    
    var laserSound: SKAction = SKAction.sequence([SKAction.playSoundFileNamed("laser.wav", waitForCompletion: false), SKAction.removeFromParent()])
    var pewSound: SKAction = SKAction.sequence([SKAction.playSoundFileNamed(fileName: "pew.wav", atVolume: 1.0, waitForCompletion: false)])
    var explodeSound:  SKAction = SKAction.sequence([SKAction.playSoundFileNamed(fileName: "explode.wav",  atVolume: 0.8, waitForCompletion: false), SKAction.removeFromParent()])
    var levelCompleteSound:  SKAction = SKAction.sequence([SKAction.playSoundFileNamed(fileName: "levelcomplete.mp3", atVolume: 1.0, waitForCompletion: false), SKAction.removeFromParent()])
    var gameOverSound:  SKAction = SKAction.sequence([SKAction.playSoundFileNamed(fileName: "gameover.mp3", atVolume: 1.0, waitForCompletion: false), SKAction.removeFromParent()])
    var electricSound:  SKAction = SKAction.sequence([SKAction.playSoundFileNamed(fileName: "electriccurrent.wav", atVolume: 1.0, waitForCompletion: false)])
    
    // Pulse action
    let screenPulseAction = SKAction.repeatForever(SKAction.sequence([SKAction.fadeOut(withDuration: 1), SKAction.fadeIn(withDuration: 1)]))
    // Rotate it (spin it really fast)
    let rotateNode = SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi/1), duration: 0.1))
    // Pulse it
    let pulseNode = SKAction.repeatForever(SKAction.sequence([SKAction.fadeOut(withDuration: 0.1), SKAction.fadeIn(withDuration: 0.1)]))
    // Pulse colors
    let colorPulseBlue = SKAction.repeatForever(SKAction.sequence([SKAction.colorize(with: SKColor.blue, colorBlendFactor: 1, duration: 0.1), SKAction.colorize(with: SKColor.white, colorBlendFactor: 1, duration: 0.1)]))
    let colorPulseRed = SKAction.repeatForever(SKAction.sequence([SKAction.colorize(with: SKColor.red, colorBlendFactor: 1, duration: 0.1), SKAction.colorize(with: SKColor.white, colorBlendFactor: 1, duration: 0.1)]))
    
    // Player ship
    var playerShip: PlayerShip!
    var playerShipCenterCannon: PlayerCenterLaserCannonState = .railGun
    var playerShipWingCannons: PlayerWingLaserCannonState = .none
    var playerShipTailCannons: PlayerTailLaserCannonState = .none
    
    var deltaPoint = CGPoint.zero
    var previousTouchLocation = CGPoint.zero
    
    // Initilization method
    override init(size: CGSize) {
        super.init(size: size)
        
        // Calculate playable margin.  Put a boarder of 20 pixels on each side
        playableRect = CGRect(x: 20, y: 20, width: size.width-40, height: size.height - hudHeight-40)
        playerBulletFireRateInterval = TimeInterval(1.0 / playerBulletsPerSecond)
        enemyBulletFireRateInterval = TimeInterval(1.0 / enemyBulletsPerSecond)

        // Setup the initial game state
        gameState = .gameOver
        // Setup the starting screen
        setupSceneLayers()
        setUpUI()
        setupEntities()
        
        SKTAudio.sharedInstance().playBackgroundMusic("bgmusic.mp3", 0.0)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
    }
    
    //
    // TouchBegan
    // Notes:  This method is called when the user touches the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch (gameState) {
        case .gameOver:
            startGame()
            break
        case .gameRunning:
            break
        case .splashScreen:
            startGame()
            break
        case .readyToStartWave:
            startNextWave()
            break
        case .waveComplete:
            break
        case .transitioning:
            transitionPlayer()
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = (touches as NSSet).anyObject() as! UITouch
        let currentPoint = touch.location(in: self)
        previousTouchLocation = touch.previousLocation(in: self)
        deltaPoint = currentPoint - previousTouchLocation
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        deltaPoint = CGPoint.zero
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        deltaPoint = CGPoint.zero
    }
    
    //
    // The update method is used to control the game play and scenes.  A governor is used to control
    // the pace of the game during game play with the exception of the player movement.  Players are
    // allowed to move as quick as they can so that we try and minimize the finger moving quicker than
    // the player sprite.
    override func update(_ delta: TimeInterval) {
        let currentTime = Date().timeIntervalSince1970
        
        // Get the new player ship location
        var newPoint:CGPoint = playerShip.position + deltaPoint
        
        // BONUS MODE:
        // If we are in bonus mode, and we don't have a bonusStartTime, get the current time
        if bonusMode && bonusStartTime == 0 {
            bonusStartTime = delta
            lastBonusTimeRemaining = bonusTime
        }
        if bonusStartTime > 0 {
            bonusTimeRemaining = bonusTime - Int(delta - bonusStartTime)
            if bonusTimeRemaining < 0 {
                bonusTimeRemaining = 0
            }
            // Add the health regeneration for the number of seconds that we
            // stayed alive since the last check
            let healthPerTick: Double = ((playerShip.maxHealth*bonusTimeMaxRegenerationPercent)/Double(bonusTime))
            // Calcuate the amount of health to regenerate
            playerShip.health += Double(lastBonusTimeRemaining - bonusTimeRemaining)*healthPerTick
            
            if (playerShip.health > playerShip.maxHealth) {
                playerShip.health = playerShip.maxHealth
            }
            lastBonusTimeRemaining = bonusTimeRemaining
        }


        var executeEnemyMovement: Bool = true
        var playerBulletExecutionTimeElapsed: Bool = true
        var enemyBulletExecutionTimeElapsed: Bool = true
        
        // Initiate the last execution time
        if (lastEnemyExecutionTime == 0) {
            lastEnemyExecutionTime = currentTime
        }
        // Initiate the last player bullet execution time
        if (playerBulletExecutionTime == 0) {
            playerBulletExecutionTime = currentTime
        }
        // Initiate the last player bullet execution time
        if (enemyBulletExecutionTime == 0) {
            enemyBulletExecutionTime = currentTime
        }
        // Get the delta from the last time we executed until now
        let enemyExecutionTimeDelta = currentTime - lastEnemyExecutionTime
        // Get the delta from the last time we executed until now
        let playerBulletExecutionTimeDelta = currentTime - playerBulletExecutionTime
        // Get the delta from the last time we executed until now
        let enemyBulletExecutionTimeDelta = currentTime - enemyBulletExecutionTime
        
        // Check to see if we've waited long enough to do our processing.  We multiple this
        // raw value by the difficulty setting value to increase the time or decease it
        if (enemyExecutionTimeDelta < (enemyExecutionGovernor * programDifficulty.rawValue)) {
            //
            //  Nope, don't move the enemies yet
            executeEnemyMovement = false
        } else {
            //
            // Yes we've waited long enough, store the new execution time
            lastEnemyExecutionTime = currentTime
        }
        // Check to see if we've waited long enough to do our processing.  We multiple this
        // raw value by the difficulty setting value to increase the time or decease it
        if (playerBulletExecutionTimeDelta < (playerBulletFireRateInterval)) {
            //
            //  Nope, don't move the enemies yet
            playerBulletExecutionTimeElapsed = false
        } else {
            //
            // Yes we've waited long enough, store the new execution time
            playerBulletExecutionTime = currentTime
        }
        // Check to see if we've waited long enough to do our processing.  We multiple this
        // raw value by the difficulty setting value to increase the time or decease it
        if (enemyBulletExecutionTimeDelta < (enemyBulletFireRateInterval)) {
            //
            //  Nope, don't move the enemies yet
            enemyBulletExecutionTimeElapsed = false
        } else {
            //
            // Yes we've waited long enough, store the new execution time
            enemyBulletExecutionTime = currentTime
        }
        
        //
        // Do processes that are being governored (like moving the enemy ships, bullets, etc.)
        
        switch gameState {
        case (.splashScreen):
            break
        case .readyToStartWave:
            // If we don't have a levelLabel, then we just changed to this games status
            if (levelLabel.parent == nil) {
                levelLabel.text = "WAVE \(wave+1)"
                if ((wave+1)%bonusWaveInterval == 0) {
                    levelLabel.text = "WAVE \(wave+1): BONUS WAVE"
                }
                levelLabel.removeAllActions()
                hudLayerNode.addChild(tapScreenLabel)
                hudLayerNode.addChild(levelLabel)
                tapScreenLabel.run(screenPulseAction)
                levelLabel.run(screenPulseAction)
            }
            break
        case (.gameRunning):
            // Move the player's ship
            _ = newPoint.x.clamp(playableRect.minX, playableRect.maxX)
            _ = newPoint.y.clamp(playableRect.minY,playableRect.maxY)

            playerShip.position = newPoint
            deltaPoint = CGPoint.zero

            if (bonusMode && endBonusMode) {
                endBonusMode = false
                bonusTimeRemaining = 0
            }
            
            if (bonusMode) {
                if (countdownLabel.parent == nil) {
                    hudLayerNode.addChild(countdownLabel)
                }
                countdownLabel.text = "\(bonusTimeRemaining)"
                countdownLabel.fontSize = bonusTimeRemaining > 10 ? CGFloat(36) : CGFloat(144)
                countdownLabel.fontColor = SKColor(red: CGFloat(drand48()),
                                                   green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
                if (bonusTimeRemaining == 0) {
                    gameState = .waveComplete
                    // Remove enemies from wave
                    for node in enemyLayerNode.children {
                        node.removeFromParent()
                    }
                }
            }

            //
            // If the player bullet execution time has elapsed, then fire the bullets
            if (playerBulletExecutionTimeElapsed) {
                firePlayerBullets()  // Fire a new set of player bullets
                playerBulletExecutionTime = 0
            }

            //
            // If the enemy execution time has elapsed, then move the enemies
            if (executeEnemyMovement) {
                // Loop through all enemy nodes and run their update method.
                // This causes them to update their position based on their currentWaypoint and position
                var nodeCounter = 0
                for node in enemyLayerNode.children {
                    nodeCounter += 1
                    let enemy = node as! Enemy
                    // Update the enemy and let the AI know how long the wait has been
                    enemy.update(enemyExecutionTimeDelta) // Update the enemy
                }
                // If all of the enemies are gone, wave is complete
                if (nodeCounter == 0) {
                    gameState = .waveComplete
                }
                // Yes we've waited long enough, store the new execution time
                lastEnemyExecutionTime = 0
            }
            //
            // If the enemy bullet execution time has elapsed, then fire the bullets
            if (enemyBulletExecutionTimeElapsed) {
                fireEnemyBullets()  // Fire a new set of player bullets
                enemyBulletExecutionTime = 0
            }

            // Update the players health label to be the right length based on the players health and also
            // update the color so that the closer to 0 it gets the more red it becomes
            playerHealthLabel.fontColor = SKColor(red: CGFloat(2.0 * (1 - playerShip.health / 100)),
                                                  green: CGFloat(2.0 * playerShip.health / 100),
                                                  blue: 0,
                                                  alpha: 1)
            
            // Calculate the length of the players health bar.
            let healthBarLength = Double(healthBarString.length) * playerShip.health / 100.0
            playerHealthLabel.text = healthBarString.substring(to: Int(healthBarLength))
            waveLabel.text = "Wave: \(wave)"
            
            // If the player health reaches 0 then change the game state.
            if playerShip.health <= 0 {
                gameState = .gameOver
                playGameOver() // Play the game over music
            }
            break
        case (.waveComplete):
            // Clear out the last execution times
            lastEnemyExecutionTime = 0
            playerBulletExecutionTime = 0
            transitionLastExecutionTime = currentTime
            transitionStartExecutionTime = currentTime
            // Clear out the nodes
            playerBulletLayerNode.removeAllChildren()
            enemyLayerNode.removeAllChildren()
            enemyBulletLayerNode.removeAllChildren()
            levelLabel.removeFromParent()
            tapScreenLabel.removeFromParent()
            countdownLabel.removeFromParent()
            
            bonusMode = false
            
            // printNodes()
            
            // Set the state to transitioning
            gameState = .transitioning
            playLevelComplete()
            break
        case .transitioning:
            // Get the delta from the last time we executed until now
            let transitionExeuctionTimeDelta = currentTime - transitionLastExecutionTime
            
            // If we've waited long enough, call transition player to move him closer to his starting spot
            if (transitionExeuctionTimeDelta >= (transitionExecutionRate)) {
                // Store the current time as our current transition execution time
                transitionLastExecutionTime = currentTime
                transitionPlayer()
            }
            break
        case (.gameOver):
            // When the game is over remove all the entities from the scene and add the game over labels
            if (gameOverLabel.parent == nil) {
                playerBulletLayerNode.removeAllChildren()
                enemyLayerNode.removeAllChildren()
                enemyBulletLayerNode.removeAllChildren()
                playerShip.removeFromParent()
                countdownLabel.removeFromParent()
                
                hudLayerNode.addChild(gameOverLabel)
                hudLayerNode.addChild(tapScreenLabel)
                tapScreenLabel.run(screenPulseAction)
            }
            
            // Set a random color for the game over label
            gameOverLabel.fontColor = SKColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
            break
        }

    }
    
    // This method is called by the physics engine when two physics body collide
    func didBegin(_ contact: SKPhysicsContact) {
        // Get the nodes that triggered the collision
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        // Get the entity (identity) of the nodes
        let nodeAEntity = nodeA as! Entity
        let nodeBEntity = nodeB as! Entity
        //
        // In a collision, two nodes hit so let's apply damage to both nodes.
        if (nodeA?.name == Entity.EntityClassName.EnemyShip.rawValue ||
            nodeA?.name == Entity.EntityClassName.PlayerShip.rawValue ||
            nodeA?.name == Entity.EntityClassName.PlayerBullet.rawValue ||
            nodeA?.name == Entity.EntityClassName.EnemyBullet.rawValue) {
            // Run the collision method
            nodeAEntity.collidedWith(contact.bodyA, contact: contact, damage: nodeBEntity.collisionDamage)
            // If the player ship was hit, then trigger the screen flash
            if (nodeA?.name == Entity.EntityClassName.PlayerShip.rawValue) {
               flashScreenBasedOnDamage(SKColor.red, nodeBEntity.collisionDamage) // Flash the screen
                // If we get hit in bonus mode, end the bonus mode
                if (bonusMode) {
                    endBonusMode = true
                }
            }
        }
        if (nodeB?.name == Entity.EntityClassName.EnemyShip.rawValue ||
            nodeB?.name == Entity.EntityClassName.PlayerShip.rawValue ||
            nodeB?.name == Entity.EntityClassName.PlayerBullet.rawValue ||
            nodeB?.name == Entity.EntityClassName.EnemyBullet.rawValue) {
            // Run the collision method
            nodeBEntity.collidedWith(contact.bodyB, contact: contact, damage: nodeAEntity.collisionDamage)
            if (nodeB?.name == Entity.EntityClassName.PlayerShip.rawValue) {
                // If the player ship was hit, then trigger the screen flash
                flashScreenBasedOnDamage(SKColor.red, nodeAEntity.collisionDamage) // Flash the screen
                // If we get hit in bonus mode, end the bonus mode
                if (bonusMode) {
                    endBonusMode = true
                }

            }
        }
    }

    //
    // Flash the screen red based upon the damage taken
    func flashScreenBasedOnDamage(_ color: SKColor, _ damage: Int) {
        var duration: TimeInterval = 0.25
        if damage == 1 {
            duration = 0.05
        } else if damage == 2 {
            duration = 0.1
        } else if damage == 3 {
            duration = 0.15
        } else if damage == 4 {
            duration = 0.2
        }
        
        // Flash the screen red
        self.run(SKAction.sequence([
            SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: duration),
            SKAction.colorize(with: screenBackgroundColor, colorBlendFactor: 1.0, duration: duration), SKAction.removeFromParent()]))
    }
    
    // Setup the initial screen node layers
    // Notes:  Here we set the z axis values of the nodes and create the starfield background
    func setupSceneLayers() {
        // Setup the z axis for the nodes.  The higher the number, the closer the node is to the user (i.e. on top of
        // the other nodes).
        hudLayerNode.zPosition = 100
        playerLayerNode.zPosition = 50
        enemyLayerNode.zPosition = 35
        playerBulletLayerNode.zPosition = 25
        starfieldLayerNode.zPosition = 10
        //
        // Fade to background color
        self.run(SKAction.sequence([SKAction.colorize(with: screenBackgroundColor, colorBlendFactor: 1.0, duration: 0), SKAction.removeFromParent()]))
        
        // Lets build the background node (starfield)
        let starfieldNode = SKNode()
        starfieldNode.name = "starfieldNode"
        //
        // As the stars move backwards in the z axis, make them darker, smaller, move slower, and more populas.
        // 1st layer:
        starfieldNode.addChild(starfieldEmitterNode(speed: -48, lifetime: size.height / 23, scale: 0.2, birthRate: 1, color: SKColor.lightGray))
        starfieldLayerNode.addChild(starfieldNode)
        // 2nd layer:
        var emitterNode = starfieldEmitterNode(speed: -32, lifetime: size.height / 10, scale: 0.14, birthRate: 2, color: SKColor.gray)
        emitterNode.zPosition = -10
        starfieldNode.addChild(emitterNode)
        // 3rd layer:
        emitterNode = starfieldEmitterNode(speed: -20, lifetime: size.height / 5, scale: 0.1, birthRate: 5, color: SKColor.darkGray)
        emitterNode.zPosition = -20
        starfieldNode.addChild(emitterNode)
        
        // Add the nodes to the screen
        addChild(playerLayerNode)
        addChild(hudLayerNode)
        addChild(playerBulletLayerNode)
        addChild(enemyLayerNode)
        addChild(enemyBulletLayerNode)
        addChild(starfieldLayerNode)
    }

    // Setup the user interface
    func setUpUI() {
        let backgroundSize = CGSize(width: size.width, height:hudHeight)
        let hudBarBackground = SKSpriteNode(color: screenBackgroundColor, size: backgroundSize)
        hudBarBackground.position = CGPoint(x:0, y: size.height - hudHeight)
        hudBarBackground.anchorPoint = CGPoint.zero
        hudLayerNode.addChild(hudBarBackground)

        //
        // Score:
        //   Setup the score label
        scoreLabel.fontSize = 50
        scoreLabel.text = "Score: 0"
        scoreLabel.name = "scoreLabel"
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 30, y: size.height - scoreLabel.frame.size.height + 3)
        //    Add the score lable to the hud layer node
        hudLayerNode.addChild(scoreLabel)

        //
        // Wave:
        //   Setup the wave label
        waveLabel.fontSize = 20
        waveLabel.fontColor = UIColor.cyan
        waveLabel.text = "Wave: 1"
        waveLabel.name = "waveLabel"
        waveLabel.horizontalAlignmentMode = .right
        let waveHeight = size.height - waveLabel.frame.size.height + 3
        waveLabel.position = CGPoint(x: size.width - 3, y: waveHeight)
        //    Add the score lable to the hud layer node
        hudLayerNode.addChild(waveLabel)

        //
        // Funds:
        //   Setup the funds label
        fundsLabel.fontSize = 20
        fundsLabel.fontColor = UIColor.green
        fundsLabel.text = "Funds: $0"
        fundsLabel.name = "fundsLabel"
        fundsLabel.horizontalAlignmentMode = .right
        fundsLabel.position = CGPoint(x: size.width - 3, y: waveHeight - 3 - fundsLabel.frame.size.height)
        //    Add the score lable to the hud layer node
        hudLayerNode.addChild(fundsLabel)

        levelLabel.name = "levelLabel"
        levelLabel.fontSize = 50
        levelLabel.fontColor = SKColor.white
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.verticalAlignmentMode = .center
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        levelLabel.text = "WAVE COMPLETE";
        
        //
        // Player health:
        //   Setup the player health label.  This is the gray version of the health bar that always displayes (though it might
        //   be under the colored version).
        let playerHealthBackgroundLabel = SKLabelNode(fontNamed: "Arial")
        playerHealthBackgroundLabel.name = "playerHealthBackground"
        playerHealthBackgroundLabel.fontColor = SKColor.darkGray
        playerHealthBackgroundLabel.fontSize = 50
        playerHealthBackgroundLabel.text = healthBarString as String
        playerHealthBackgroundLabel.zPosition = 0
        playerHealthBackgroundLabel.horizontalAlignmentMode = .left
        playerHealthBackgroundLabel.verticalAlignmentMode = .top
        playerHealthBackgroundLabel.position = CGPoint(x: playableRect.minX, y: size.height - CGFloat(hudHeight) + playerHealthBackgroundLabel.frame.size.height)
        hudLayerNode.addChild(playerHealthBackgroundLabel)
        //
        //   Setup the color heath label that shows the current player health.  This label changes colors as the
        //   player's health goes down
        playerHealthLabel.name = "playerHealthLabel"
        playerHealthLabel.fontColor = SKColor.green
        playerHealthLabel.fontSize = 50
        playerHealthLabel.text = healthBarString.substring(to: 20*100/100) // health is at 100% when we start
        playerHealthLabel.zPosition = 1
        playerHealthLabel.horizontalAlignmentMode = .left
        playerHealthLabel.verticalAlignmentMode = .top
        playerHealthLabel.position = CGPoint(x: playableRect.minX, y: size.height - CGFloat(hudHeight) +
            playerHealthLabel.frame.size.height)
        // Add the player health label to the hud layer node
        hudLayerNode.addChild(playerHealthLabel)
        
        // Setup the game over label
        gameOverLabel.name = "gameOverLabel"
        gameOverLabel.fontSize = 100
        gameOverLabel.fontColor = SKColor.white
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.verticalAlignmentMode = .center
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel.text = "GAME OVER";

        
        countdownLabel.name = "countdownLabel"
        countdownLabel.fontSize = 100
        countdownLabel.fontColor = SKColor.white
        countdownLabel.horizontalAlignmentMode = .center
        countdownLabel.verticalAlignmentMode = .center
        countdownLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Setup the tap screen message
        tapScreenLabel.name = "tapScreen"
        tapScreenLabel.fontSize = 22;
        tapScreenLabel.fontColor = SKColor.white
        tapScreenLabel.horizontalAlignmentMode = .center
        tapScreenLabel.verticalAlignmentMode = .center
        tapScreenLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 100)
        tapScreenLabel.text = "Tap Screen To Start Attack Wave"
    }

    //
    // StartGame
    //   Notes:  This method is called when the system needs to start a new game.
    func startGame() {
        // Reset the state of the game
        gameState = .gameRunning
        
        // Setup the entities and reset the score
        score = 0
        funds = 0
        wave = startingWave // Set the starting level
        bonusTimeRemaining = 0
        lastBonusTimeRemaining = 0
        bonusStartTime = 0
        
        updateScore()
        updateFunds()

        setupEntities()
        //
        // Setup initial weapons
        playerShipCenterCannon = .railGun
        playerShipWingCannons = .none
        playerShipTailCannons = .none

        // Upgrade the weapons (if we start on an higher level)
        upgradeWeapons()

        // Set player health
        playerShip.health = playerShip.maxHealth
        playerShip.position = CGPoint(x: size.width / 2, y: 100)
        playerShip.ventingPlasma.isHidden = true
        
        // Remove the game over HUD labels
        countdownLabel.removeFromParent()
        gameOverLabel.removeFromParent()
        tapScreenLabel.removeAllActions()
        tapScreenLabel.removeFromParent()
        levelLabel.removeFromParent()
        
        SKTAudio.sharedInstance().setBackgroundMusicVolume(Float(musicVolume)) // Set the background music volume
    }
    
    //
    // Slowly move the player to the starting location
    func transitionPlayer() {
        // Get the current player position
        var deltas: CGPoint = playerShip.position
        // Figure out the deltas to the starting position
        deltas.x = CGFloat(Int(deltas.x - CGFloat(Int((size.width / 2)))))
        deltas.y = CGFloat(Int(deltas.y - 100))
        //
        // First, lets move the x position to the starting coordinates
        if (deltas.x != 0) {
            let xmovementDirection: Int = Int(deltas.x / abs(deltas.x))
            var xmovement = abs(deltas.x)
            // If we are more than the speed, then we move just the speed
            if (xmovement > CGFloat(transitionExecutionSpeed)) {
                xmovement = CGFloat(transitionExecutionSpeed)
            }
            playerShip.position = CGPoint(x: CGFloat(Int(playerShip.position.x) - Int(xmovement) * xmovementDirection), y: playerShip.position.y)
        } else if (deltas.y != 0) {
            let ymovementDirection: Int = Int(deltas.y / abs(deltas.y))
            var ymovement = abs(deltas.y)
            // If we are more than the speed, then we move just the speed
            if (ymovement > CGFloat(transitionExecutionSpeed)) {
                ymovement = CGFloat(transitionExecutionSpeed)
            }
            playerShip.position = CGPoint(x: playerShip.position.x, y: CGFloat(Int(playerShip.position.y) - Int(ymovement) * ymovementDirection))
        } else {
            let transitionDelta = Date().timeIntervalSince1970 - transitionStartExecutionTime
            // If we've waited the minimum amount of time, then we can change the state
            if (transitionDelta >= transitionMiminumTime) {
                gameState = .readyToStartWave
            }
        }
    }
    
    //
    // Continue the game by going to the next wave and starting it
    func startNextWave() {
        // Reset the state of the game
        gameState = .gameRunning
        
        // Move to the next wave
        wave += 1

        bonusTimeRemaining = 0
        lastBonusTimeRemaining = 0
        bonusStartTime = 0
        
        // Setup the entities
        setupEntities()
        
        upgradeWeapons()

        // Reset the players health and position
        playerShip.position = CGPoint(x: size.width / 2, y: 100)
        
        // Remove the game over HUD labels
        gameOverLabel.removeFromParent()
        tapScreenLabel.removeAllActions()
        tapScreenLabel.removeFromParent()
        levelLabel.removeFromParent()
        
        SKTAudio.sharedInstance().setBackgroundMusicVolume(Float(musicVolume))  // Set the music volume
    }
    
    //
    // Create the individual entities for the game.
    func setupEntities() {
        // Initialize the player ship
        if (playerShip == nil) {
            playerShip = PlayerShip(entityPosition: CGPoint(x: size.width / 2, y: 100))
        }

        // Add the ship to the parent node and create the particle engine effect
        if (playerShip.parent == nil) {
            playerLayerNode.addChild(playerShip)
            playerShip.createEngine()
        }
        // If we are on a bonus wave, setup that wave specially
        if (wave%bonusWaveInterval == 0 && wave != 0) {
            bonusMode = true
            addBonusEnemies()
        } else {  // Normal wave
            // Add enemies to this wave
            addScouts()
            addSwarmers()
            addFighters()
            addBossBombers()
            addBossFighters()
        }
    }

    func upgradeWeapons() {
        // Upgrade weapons
        switch (wave) {
        case 0...weaponUpgradeInterval:
            playerShipCenterCannon = .railGun
            playerShipWingCannons = .none
            playerShipTailCannons = .none
        case weaponUpgradeInterval+1...weaponUpgradeInterval*2:
            playerShipCenterCannon = .particleLaser
            playerShipWingCannons = .none
            playerShipTailCannons = .none
        case weaponUpgradeInterval*2+1...weaponUpgradeInterval*3:
            playerShipCenterCannon = .particleLaser
            playerShipWingCannons = .railGun
            playerShipTailCannons = .none
        case  weaponUpgradeInterval*3+1...weaponUpgradeInterval*4:
            playerShipCenterCannon = .particleLaser
            playerShipWingCannons = .particleLaser
            playerShipTailCannons = .none
        case  weaponUpgradeInterval*4+1...weaponUpgradeInterval*5:
            playerShipCenterCannon = .particleLaser
            playerShipWingCannons = .particleLaser
            playerShipTailCannons = .railGun
        case  weaponUpgradeInterval*5+1...weaponUpgradeInterval*6:
            playerShipCenterCannon = .particleLaser
            playerShipWingCannons = .particleLaser
            playerShipTailCannons = .particleLaser
        case  weaponUpgradeInterval*6+1...weaponUpgradeInterval*7:
            playerShipCenterCannon = .protonLaser
            playerShipWingCannons = .particleLaser
            playerShipTailCannons = .particleLaser
        case  weaponUpgradeInterval*7+1...weaponUpgradeInterval*8:
            playerShipCenterCannon = .protonLaser
            playerShipWingCannons = .protonLaser
            playerShipTailCannons = .particleLaser
        default:
            if (wave > weaponUpgradeInterval*8) {
                playerShipCenterCannon = .protonLaser
                playerShipWingCannons = .protonLaser
                playerShipTailCannons = .protonLaser
                let increaseFirerateBy: Int = (wave - weaponUpgradeInterval*8)/10

                // Keep adding more bullets every 10 levels
                if (wave%10 == 0) {
                    playerBulletFireRateInterval = (1.0 / Double(playerBulletsPerSecond + Float(increaseFirerateBy)))
                }
            }
        }
    }
    
    // Bonus Levels
    func addBonusEnemies() {
        var number: Int = 15 + ((wave+1)/5) * 5
        if (number > enemySwarmersMaximumNumber * 10) {
            number = enemySwarmersMaximumNumber * 10
        }
        for _ in 0..<number {
            let enemy = EnemySwarmer(entityPosition: CGPoint(
                x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                y: playableRect.size.height+100), playableRect: playableRect)
            let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
            enemy.aiSteering.updateWaypoint(initialWaypoint)
            enemy.health = 5
            enemy.maxHealth = 5
            enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
            enemy.lives = 1 + 99 // For the bonus mode, just keep adding new lives
            enemy.setSpawnDelay(Double(CGFloat.random())*enemySwarmersSpawnDelay + enemySwarmersSpawnMinimum)
            enemyLayerNode.addChild(enemy)
        }
        
    }


    // Scouts enemy add method:
    func addScouts() {
        // If we aren't at the level where they first appear yet, return
        if (wave < enemyScoutsLevelFirstAppear) {
            return
        }
        // Calculate the number of enemies.  We take the current level, subtract from it the level that they first appeared,
        // and then divide that by the number of levels we wait to add one.  We add this number to the initial number
        // to spawn with to get our new number.  If that new number is greater than the maximum number, then use the max.
        var number: Int = Int(enemyScoutsStartingNumber + (wave - enemyScoutsLevelFirstAppear)/enemyScoutsLevelsToAddAdditional)
        if (number > enemyScoutsMaximumNumber) {
            number = enemyScoutsMaximumNumber
        }
        // To compute the number of lives, we take the current wave, subtract from it the level that they first appeared,
        // and then divide that number by the level gain before additional lives.  If this number is greater than then
        // maximum number of lives we're allowed, then use the max number.
        var additionalLives: Int = (wave - enemyScoutsLevelFirstAppear)/enemyScoutsLevelGainAdditionalLives
        if (enemyScoutsMaximumNumberOfAdditioinalLives != 0) {
            additionalLives = (additionalLives > enemyScoutsMaximumNumberOfAdditioinalLives ? enemyScoutsMaximumNumberOfAdditioinalLives : additionalLives)
        }
        
        // Add enemies
        for _ in 0..<number {
            let enemy = EnemyScout(entityPosition: CGPoint(
                x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                y: playableRect.size.height+100), playableRect: playableRect)
            let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
            enemy.aiSteering.updateWaypoint(initialWaypoint)
            enemy.health = enemyScoutsStartingHPs + enemyScoutsStartingHPs * (Double(wave - enemyScoutsLevelFirstAppear) * enemyScoutsHPStrengthMultiplier)
            enemy.maxHealth = enemy.health
            enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
            if (wave - enemyScoutsLevelFirstAppear >= enemyScoutsLevelGainAdditionalLives) {
                enemy.lives = 1 + additionalLives
            }
            enemy.setSpawnDelay(Double(CGFloat.random())*enemyScoutSpawnDelay + enemyScoutsSpawnMinimum)
            enemyLayerNode.addChild(enemy)
        }
    }
    
    // Swarmers enemy add method:
    func addSwarmers() {
        // If we aren't at the level where they first appear yet, return
        if (wave < enemySwarmersLevelFirstAppear) {
            return
        }
        // Calculate the number of enemies.  We take the current level, subtract from it the level that they first appeared,
        // and then divide that by the number of levels we wait to add one.  We add this number to the initial number
        // to spawn with to get our new number.  If that new number is greater than the maximum number, then use the max.
        var number: Int = enemySwarmersStartingNumber + (wave - enemySwarmersLevelFirstAppear)/enemySwarmersLevelsToAddAdditional
        if (number > enemySwarmersMaximumNumber) {
            number = enemySwarmersMaximumNumber
        }
        // To compute the number of lives, we take the current wave, subtract from it the level that they first appeared,
        // and then divide that number by the level gain before additional lives.  If this number is greater than then
        // maximum number of lives we're allowed, then use the max number.
        var additionalLives: Int = (enemySwarmersLevelGainAdditionalLives > 0 ? ((wave - enemySwarmersLevelFirstAppear)/enemySwarmersLevelGainAdditionalLives) : 0)
        additionalLives = (additionalLives > enemySwarmersMaximumNumberOfAdditioinalLives ? enemySwarmersMaximumNumberOfAdditioinalLives : additionalLives)
        
        // Add enemies
        for _ in 0..<number {
            let enemy = EnemySwarmer(entityPosition: CGPoint(
                x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                y: playableRect.size.height+100), playableRect: playableRect)
            let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
            enemy.aiSteering.updateWaypoint(initialWaypoint)
            enemy.health = enemySwarmersStartingHPs + enemySwarmersStartingHPs * (Double(wave - enemySwarmersLevelFirstAppear) * enemySwarmersHPStrengthMultiplier)
            enemy.maxHealth = enemy.health
            enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
            if (wave - enemySwarmersLevelFirstAppear >= enemySwarmersLevelGainAdditionalLives) {
                enemy.lives = 1 + additionalLives
            }
            enemy.setSpawnDelay(Double(CGFloat.random())*enemySwarmersSpawnDelay + enemySwarmersSpawnMinimum)
            enemyLayerNode.addChild(enemy)
        }

    }
    
    // Fighter enemy add method:
    func addFighters() {
        // If we aren't at the level where they first appear yet, return
        if (wave < enemyFightersLevelFirstAppear) {
            return
        }
        // Calculate the number of enemies.  We take the current level, subtract from it the level that they first appeared,
        // and then divide that by the number of levels we wait to add one.  We add this number to the initial number
        // to spawn with to get our new number.  If that new number is greater than the maximum number, then use the max.
        var number: Int = enemyFightersStartingNumber + (wave - enemyFightersLevelFirstAppear)/enemyFightersLevelsToAddAdditional
        if (number > enemyFightersMaximumNumber) {
            number = enemyFightersMaximumNumber
        }
        // To compute the number of lives, we take the current wave, subtract from it the level that they first appeared,
        // and then divide that number by the level gain before additional lives.  If this number is greater than then
        // maximum number of lives we're allowed, then use the max number.
        var additionalLives: Int = (enemyFightersLevelGainAdditionalLives > 0 ? ((wave - enemyFightersLevelFirstAppear)/enemyFightersLevelGainAdditionalLives) : 0)
        additionalLives = (additionalLives > enemyFightersMaximumNumberOfAdditioinalLives ? enemyFightersMaximumNumberOfAdditioinalLives : additionalLives)
        
        // Add mini enemies starting at wave 5
        if (wave >= enemyFightersLevelFirstAppear) {
            for _ in 0..<number {
                let enemy = EnemyFighter(entityPosition: CGPoint(
                    x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    y: playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = enemyFightersStartingHPs + enemyFightersStartingHPs * (Double(wave - enemyFightersLevelFirstAppear) * enemyFightersHPStrengthMultiplier)
                enemy.maxHealth = enemy.health
                enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
                enemy.railGunFireInterval *= programDifficulty.rawValue
                if (wave - enemyFightersLevelFirstAppear >= enemyFightersLevelGainAdditionalLives) {
                    enemy.lives = 1 + additionalLives
                }
                enemy.setSpawnDelay(Double(CGFloat.random())*enemyFightersSpawnDelay + enemyFightersSpawnMinimum)
                enemyLayerNode.addChild(enemy)
            }
        }
    }
    
    // Boss Bombers add method:
    func addBossBombers() {
        // If we aren't at the level where they first appear yet, return
        if (wave < enemyBossBombersLevelFirstAppear) {
            return
        }
        // Calculate the number of enemies.  We take the current level, subtract from it the level that they first appeared,
        // and then divide that by the number of levels we wait to add one.  We add this number to the initial number
        // to spawn with to get our new number.  If that new number is greater than the maximum number, then use the max.
        var number: Int = enemyBossBombersStartingNumber + (wave - enemyBossBombersLevelFirstAppear)/enemyBossBombersLevelsToAddAdditional
        if (number > enemyBossBombersMaximumNumber) {
            number = enemyBossBombersMaximumNumber
        }
        // To compute the number of lives, we take the current wave, subtract from it the level that they first appeared,
        // and then divide that number by the level gain before additional lives.  If this number is greater than then
        // maximum number of lives we're allowed, then use the max number.
        var additionalLives: Int = (enemyBossBombersLevelGainAdditionalLives > 0 ? ((wave - enemyBossBombersLevelFirstAppear)/enemyBossBombersLevelGainAdditionalLives) : 0)
        additionalLives = (additionalLives > enemyBossBombersMaximumNumberOfAdditioinalLives ? enemyBossBombersMaximumNumberOfAdditioinalLives : additionalLives)
        
        // Add enemies
        let enemy = EnemyBossBomber(entityPosition: CGPoint(x: CGFloat.random(min: playableRect.origin.x, max:
            playableRect.size.width), y: playableRect.size.height+100), playableRect: playableRect)
        let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2,   max: playableRect.height))
        enemy.aiSteering.updateWaypoint(initialWaypoint)
        enemy.health = enemyBossBombersStartingHPs + enemyBossBombersStartingHPs * (Double(wave - enemyBossBombersLevelFirstAppear) * enemyBossBombersHPStrengthMultiplier)
        enemy.maxHealth = enemy.health
        enemy.staticGunFireInterval *= programDifficulty.rawValue
        // Enable the additional lives if we have reached the right level
        if (wave - enemyBossBombersLevelFirstAppear >= enemyBossBombersLevelGainAdditionalLives) {
            enemy.lives = 1 + additionalLives
        }
        enemy.speed = CGFloat(0.25 / programDifficulty.rawValue)
        enemy.setSpawnDelay(Double(CGFloat.random())*enemyBossBombersSpawnDelay + enemyBossBombersSpawnMinimum)
        enemyLayerNode.addChild(enemy)
    }
    
    // Boss Fighters add method:
    func addBossFighters() {
        // If we aren't at the level where they first appear yet, return
        if (wave < enemyBossFightersLevelFirstAppear) {
            return
        }
        // Calculate the number of enemies.  We take the current level, subtract from it the level that they first appeared,
        // and then divide that by the number of levels we wait to add one.  We add this number to the initial number
        // to spawn with to get our new number.  If that new number is greater than the maximum number, then use the max.
        var number: Int = enemyBossFightersStartingNumber + (wave - enemyBossFightersLevelFirstAppear)/enemyBossFightersLevelsToAddAdditional
        if (number > enemyBossFightersMaximumNumber) {
            number = enemyBossFightersMaximumNumber
        }
        // To compute the number of lives, we take the current wave, subtract from it the level that they first appeared,
        // and then divide that number by the level gain before additional lives.  If this number is greater than then
        // maximum number of lives we're allowed, then use the max number.
        var additionalLives: Int = (enemyBossFightersLevelGainAdditionalLives > 0 ? ((wave - enemyBossFightersLevelFirstAppear)/enemyBossFightersLevelGainAdditionalLives) : 0)
        additionalLives = (additionalLives > enemyBossFightersMaximumNumberOfAdditioinalLives ? enemyBossFightersMaximumNumberOfAdditioinalLives : additionalLives)
        
        // Add boss enemies
        let enemy = EnemyBossFighter(entityPosition: CGPoint(x: CGFloat.random(min: playableRect.origin.x, max:
            playableRect.size.width), y: playableRect.size.height+100), playableRect: playableRect)
        let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2,   max: playableRect.height))
        enemy.aiSteering.updateWaypoint(initialWaypoint)
        enemy.health = enemyBossFightersStartingHPs + enemyBossFightersStartingHPs * (Double(wave - enemyBossFightersLevelFirstAppear) * enemyBossFightersHPStrengthMultiplier)
        enemy.maxHealth = enemy.maxHealth
        // Enable the additional lives if we have reached the right level
        if (wave - enemyBossFightersLevelFirstAppear >= enemyBossFightersLevelGainAdditionalLives) {
            enemy.lives = 1 + additionalLives
        }
        enemy.speed = CGFloat(0.25 / programDifficulty.rawValue)
        enemy.railGunFireInterval *= programDifficulty.rawValue
        enemy.setSpawnDelay(Double(CGFloat.random())*enemyBossFightersSpawnDelay + enemyBossFightersSpawnMinimum)
        enemyLayerNode.addChild(enemy)
    }
    
    //
    // This method fires the bullets in the game.  Each time this is called, it adds another set of bullets
    // to the node depending on the level.  This needs to be upgraded to allow users to purchase
    // new guns.
    func firePlayerBullets() {
        // Fire the player cannons
        //
        // We always have a center forward cannon
        bulletCenterForward()
        // If we have wing cannons, fire them
        switch(playerShipWingCannons) {
        case .none:  // No wing cannons
            break
        default:  // Everything else means we have cannons
            bulletWingsForward()
        }
        // If we have wing cannons, fire them
        switch(playerShipTailCannons) {
        case .none:  // No wing cannons
            break
        default:  // Everything else means we have cannons
            bulletWingsBackward()
        }
        playLaserSound()
    }

    //
    // Fire the enemies bullets
    func fireEnemyBullets() {
        let currentTime = Date().timeIntervalSince1970  // Get the current time
        // Loop through all enemy nodes and run their update method.
        // This causes them to update their position based on their currentWaypoint and position
        for node in enemyLayerNode.children {
            let enemy = node as! Enemy
            // If the enemy has a rail gun and has spawned
            if (enemy.railGun && enemy.spawned) {
                // If the gun has never been fired
                if enemy.railGunTimeLastFired <= 0.0 {
                    enemy.railGunTimeLastFired = enemy.spawnTime  // Set the last time fired to the spawn time
                }
                // Get the delta since the last firing
                let enemyLastFiredDelta = currentTime - enemy.railGunTimeLastFired
                // If we've exceeded the firing delta
                if (enemyLastFiredDelta >= enemy.railGunFireInterval) {
                    let bullet = EnemyBulletRailGun(entityPosition: enemy.position)
                    enemyBulletLayerNode.addChild(bullet)
                    let movement1 = CGVector(
                        dx: (playerShip.position.x - enemy.position.x)*10,
                        dy: (playerShip.position.y - enemy.position.y)*10
                    )
                    // Setup the bullet to move by a vector at a calculated speed
                    let movement = SKAction.sequence([SKAction.move(by: movement1, duration: getDuration(
                        pointA: playerShip.position, pointB: enemy.position,
                        speed: CGFloat(enemyBulletSpeed/programDifficulty.rawValue))), SKAction.removeFromParent()])
                    // Let's add a lot of special effects to this type of bullet
                    // Group the actions
                    let group = SKAction.group([movement, colorPulseRed, pewSound])
                    // Execute the group
                    bullet.run(group)
                    
                    enemy.railGunTimeLastFired = currentTime  // Reset the time to the current time
                }
            }
            // If the enemy has a static gun and has spawned
            if (enemy.staticGun && enemy.spawned) {
                // If the gun has never been fired
                if enemy.staticGunTimeLastFired <= 0.0 {
                    enemy.staticGunTimeLastFired = enemy.spawnTime  // Set the last time fired to the spawn time
                }
                // Get the delta since the last firing
                let enemyLastFiredDelta = currentTime - enemy.staticGunTimeLastFired
                // If we've exceeded the firing delta
                if (enemyLastFiredDelta >= enemy.staticGunFireInterval) {
                    let bullet = EnemyBulletStaticGun(entityPosition: enemy.position)
                    enemyBulletLayerNode.addChild(bullet)
                    let movement1 = CGVector(
                        dx: (playerShip.position.x - enemy.position.x)*10,
                        dy: (playerShip.position.y - enemy.position.y)*10
                    )
                    //
                    // Setup the bullet to move by a vector at a calculated speed
                    let movement = SKAction.sequence([SKAction.move(by: movement1, duration: getDuration(
                        pointA: playerShip.position, pointB: enemy.position,
                        speed: CGFloat(enemyBulletSpeed/programDifficulty.rawValue))), SKAction.removeFromParent()])
                    // Let's add a lot of special effects to this type of bullet
                    // Group the actions
                    let group = SKAction.group([movement, rotateNode, pulseNode, colorPulseBlue, electricSound])
                    // Execute the group
                    bullet.run(group)
                    // Pulse the screen
                    self.run(SKAction.sequence([
                        SKAction.colorize(with: SKColor.darkGray, colorBlendFactor: 1.0, duration: 0.25),
                        SKAction.colorize(with: screenBackgroundColor, colorBlendFactor: 1.0, duration: 0.25), SKAction.removeFromParent()]))
                    enemy.staticGunTimeLastFired = currentTime  // Reset the time to the current time
                }
            }
        }
    }
    
    //
    // Calculate the duration based upon a set speed applied to a given distance
    func getDuration(pointA:CGPoint,pointB:CGPoint,speed:CGFloat)->TimeInterval {
        let xDist = (pointB.x - pointA.x)
        let yDist = (pointB.y - pointA.y)
        let distance = sqrt((xDist * xDist) + (yDist * yDist));
        let duration : TimeInterval = TimeInterval(distance/speed)
        return duration
    }
    
    //
    // Fire the center forward cannon
    func bulletCenterForward() {
        switch(playerShipCenterCannon) {
        case .railGun:
            let bullet = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x, y: playerShip.position.y+25))
            playerBulletLayerNode.addChild(bullet)
            bullet.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height+20, duration: 1), SKAction.removeFromParent()]))
        case .particleLaser:
            let bullet = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x, y: playerShip.position.y+25))
            playerBulletLayerNode.addChild(bullet)
            bullet.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height+20, duration: 1), SKAction.removeFromParent()]))
        case .protonLaser:
            let bullet = BulletProtonLaser(entityPosition: CGPoint(x: playerShip.position.x, y: playerShip.position.y+25))
            playerBulletLayerNode.addChild(bullet)
            bullet.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height+20, duration: 1), SKAction.removeFromParent()]))
        }
    }

    //
    // Fire the wing cannons forward
    func bulletWingsForward() {
        switch(playerShipWingCannons) {
        case .none:
            break
        case .railGun:
            // Double bullet
            let bullet1 = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x-19, y: playerShip.position.y+20))
            let bullet2 = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x+19, y: playerShip.position.y+20))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
        case .particleLaser:
            // Double bullet
            let bullet1 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x-19, y: playerShip.position.y+20))
            let bullet2 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x+19, y: playerShip.position.y+20))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
        case .protonLaser:
            // Double bullet
            let bullet1 = BulletProtonLaser(entityPosition: CGPoint(x: playerShip.position.x-19, y: playerShip.position.y+20))
            let bullet2 = BulletProtonLaser(entityPosition: CGPoint(x: playerShip.position.x+19, y: playerShip.position.y+20))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
        }
    }

    //
    // Fire the wing cannons backwards
    func bulletWingsBackward() {
        switch(playerShipTailCannons) {
        case .none:
            break
        case .railGun:
            // Double bullet
            let bullet1 = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x-10, y: playerShip.position.y))
            let bullet2 = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x+10, y: playerShip.position.y))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
        case .particleLaser:
            // Double bullet
            let bullet1 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x-10, y: playerShip.position.y))
            let bullet2 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x+10, y: playerShip.position.y))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
        case .protonLaser:
            // Double bullet
            let bullet1 = BulletProtonLaser2(entityPosition: CGPoint(x: playerShip.position.x-10, y: playerShip.position.y))
            let bullet2 = BulletProtonLaser2(entityPosition: CGPoint(x: playerShip.position.x+10, y: playerShip.position.y))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
        }
    }
    
    //
    // Increase the score
    func increaseScoreBy(_ increment: Int) {
        score += increment
        updateScore()
    }

    func updateScore() {
        scoreLabel.text = "Score: \(score)"
    }
    
    //
    // Increase the funds
    func increaseFundsBy(_ increment: Int) {
        funds += increment
        updateFunds()
    }
    
    func updateFunds() {
        fundsLabel.text = "Funds: $\(funds)"
    }
    
    //
    // Generate the starfield
    // Notes:
    //
    func starfieldEmitterNode(speed: CGFloat, lifetime: CGFloat, scale: CGFloat, birthRate: CGFloat, color: SKColor) -> SKEmitterNode {
        // For the stars, we're going to use the 'Helvetica' symbol
        let star = SKLabelNode(fontNamed: "Helvetica")
        star.fontSize = 80.0
        star.text = "✦"
        // Create a SKView to hold a star
        let textureView = SKView()
        let texture = textureView.texture(from: star)
        texture!.filteringMode = .nearest
        // The emitterNode will be used to hold the stars generated and to animate them (twinkle)
        let emitterNode = SKEmitterNode()
        emitterNode.particleTexture = texture  // Star symbol
        emitterNode.particleBirthRate = birthRate // Density
        emitterNode.particleColor = color  // Color (used to determine how dark a star is)
        emitterNode.particleLifetime = lifetime // Duration
        emitterNode.particleSpeed = speed
        emitterNode.particleScale = scale // Size
        emitterNode.particleColorBlendFactor = 1
        // Generate the starting position
        emitterNode.position = CGPoint(x: frame.midX, y: frame.maxY)
        emitterNode.particlePositionRange = CGVector(dx: frame.maxX, dy: 0)
        // Create an action that rotates the stars
        emitterNode.particleAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle: CGFloat(-Double.pi / 4), duration: 1),
            SKAction.rotate(byAngle: CGFloat(Double.pi / 4), duration: 1)
            ]))
        emitterNode.particleSpeedRange = 16.0
        // Create the twinkle affect
        let twinkles = 20
        let colorSequence = SKKeyframeSequence(capacity: twinkles * 2)
        let twinkleTime = 1.0 / CGFloat(twinkles)
        // Rotate the colors
        for i in 0..<twinkles {
            colorSequence.addKeyframeValue(SKColor.white, time: CGFloat(i) * 2 * twinkleTime / 2)
            switch i%4 {
            case 0:
                colorSequence.addKeyframeValue(SKColor.yellow, time: (CGFloat(i) * 2 + 1) * twinkleTime / 2)
            case 1:
                colorSequence.addKeyframeValue(SKColor.blue, time: (CGFloat(i) * 2 + 1) * twinkleTime / 2)
            case 2:
                colorSequence.addKeyframeValue(SKColor.orange, time: (CGFloat(i) * 2 + 1) * twinkleTime / 2)
            default:
                colorSequence.addKeyframeValue(SKColor.red, time: (CGFloat(i) * 2 + 1) * twinkleTime / 2)
                
            }
        }
        // Add the sequence to the node
        emitterNode.particleColorSequence = colorSequence
        // Set the time to the duration of the star
        emitterNode.advanceSimulationTime(TimeInterval(lifetime))
        // Return the emitter node
        return emitterNode
    }
    
    func printNodes() {
        print("Start:")
        printNodes(name: "  playerLayerNode", node: playerLayerNode)
        printNodes(name: "  hudLayerNode", node: hudLayerNode)
        printNodes(name: "  playerBulletLayerNode", node: playerBulletLayerNode)
        printNodes(name: "  enemyBulletLayerNode", node: enemyBulletLayerNode)
        printNodes(name: "  enemyLayerNode", node: enemyLayerNode)
        printNodes(name: "  starfieldLayerNode", node: starfieldLayerNode)
    }
    
    func printNodes(name: String, node: SKNode) {
        for node in node.children {
            let nodeName = node.name ?? "Unknown"
            print("  \(name)->\(nodeName): ")
            printNodes(name: "  " + nodeName, node: node)
        }
    }
    
    func playGameOver() {
        SKTAudio.sharedInstance().setBackgroundMusicVolume(Float(0.0)) // Set the background music volume
        run(gameOverSound)
    }
    
    func playLevelComplete() {
        SKTAudio.sharedInstance().setBackgroundMusicVolume(Float(0.0)) // Set the background music volume
        run(levelCompleteSound)
    }

    func playExplodeSound() {
        // Calling SKTAudio directly like this is a slight lag during execution
        //        SKTAudio.sharedInstance().playSoundEffect("explode.wav", specialEffectsVolume)
        run(explodeSound)
    }
    
    func playLaserSound() {
        // Calling SKTAudio directly like this is a slight lag during execution
        //        SKTAudio.sharedInstance().playSoundEffect("laser.wav", laserVolume)
        run(laserSound)
    }
}
