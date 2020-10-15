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
    case extreme = 0.5
}

enum EnemyType {
    case None
    case Scout
    case Fighter
    case Swarmer
    case AdvancedSwarmer
    case AdvancedFighter
    case AdvancedBomber
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
    let enemyBulletLayerNode = SKNode()   // Contains the enemies bullets
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
    let waveTitleDisplayTime: Double = 5.0

    
    // Enemy Definitions:
    struct EnemyWave {
        var title: String?
        var displayTitleDelay: Double = 0.0
        var type: EnemyType = .None
        var number: Int = 0
        var hps: Double = 0.0
        var lives: Int = 0
        var spawnDelay: Double = 0.0
        var spawnMinimum: Double = 0.0
        var gunType: Enemy.GunType = .None
    }
    
    var laserSound: SKAction = SKAction.sequence([SKAction.playSoundFileNamed("laser.wav", waitForCompletion: false), SKAction.removeFromParent()])
    var explodeSound:  SKAction = SKAction.sequence([SKAction.playSoundFileNamed(fileName: "explode.wav",  atVolume: 0.8, waitForCompletion: false), SKAction.removeFromParent()])
    var levelCompleteSound:  SKAction = SKAction.sequence([SKAction.playSoundFileNamed(fileName: "levelcomplete.mp3", atVolume: 1.0, waitForCompletion: false), SKAction.removeFromParent()])
    var gameOverSound:  SKAction = SKAction.sequence([SKAction.playSoundFileNamed(fileName: "gameover.mp3", atVolume: 1.0, waitForCompletion: false), SKAction.removeFromParent()])
    
    // Pulse action
    let slowPulseAction = SKAction.repeatForever(SKAction.sequence([SKAction.fadeOut(withDuration: 1), SKAction.fadeIn(withDuration: 1)]))
    let fasePulseAction = SKAction.repeatForever(SKAction.sequence([SKAction.fadeOut(withDuration: 0.25), SKAction.fadeIn(withDuration: 0.25)]))

    // Player ship
    var playerShip: PlayerShip!
    var playerShipCenterCannon: PlayerCenterLaserCannonState = .railGun
    var playerShipWingCannons: PlayerWingLaserCannonState = .none
    var playerShipTailCannons: PlayerTailLaserCannonState = .none
    
    var deltaPoint = CGPoint.zero
    var previousTouchLocation = CGPoint.zero
    
    // Initilization method
    override init(size: CGSize) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        super.init(size: size)
        
        // Calculate playable margin.  Put a boarder of 20 pixels on each side
        playableRect = CGRect(x: 20, y: 20, width: size.width-40, height: size.height - hudHeight-40)
        playerBulletFireRateInterval = TimeInterval(1.0 / playerBulletsPerSecond)
        enemyBulletFireRateInterval = TimeInterval(1.0 / enemyBulletsPerSecond)
        
        // Set the starting wave
        wave = startingWave < 2 ? 0 : startingWave - 1
        
        // Setup the initial game state
        gameState = .gameOver
        // Setup the starting screen
        setupSceneLayers()
        setUpUI()

        SKTAudio.sharedInstance().playBackgroundMusic("bgmusic.mp3", 0.0)
    }

    required init(coder aDecoder: NSCoder) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
    }
    
    //
    // TouchBegan
    // Notes:  This method is called when the user touches the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        switch (gameState) {
        case .gameOver:  // If we are in game over mode, start a new game
            startGame()
            break
        case .gameRunning:  // If we are currently in a game, do nothing
            break
        case .splashScreen:  // If we are at the splash screen, start a new game
            startGame()
            break
        case .readyToStartWave:  // If we are waiting to start a wave, then start it
            startNextWave()
            break
        case .waveComplete:  // If we are at a wave complete, ignore it
            break
        case .transitioning:  // IF we are transitioning, keep transitioning
            transitionPlayer()
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        let touch = (touches as NSSet).anyObject() as! UITouch
        let currentPoint = touch.location(in: self)
        previousTouchLocation = touch.previousLocation(in: self)
        deltaPoint = currentPoint - previousTouchLocation
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        deltaPoint = CGPoint.zero
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        deltaPoint = CGPoint.zero
    }
    
    //
    // The update method is used to control the game play and scenes.  A governor is used to control
    // the pace of the game during game play with the exception of the player movement.  Players are
    // allowed to move as quick as they can so that we try and minimize the finger moving quicker than
    // the player sprite.
    override func update(_ delta: TimeInterval) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        let currentTime = Date().timeIntervalSince1970
        
        // BONUS MODE:
        // If we are in bonus mode, and we don't have a bonusStartTime, get the current time
        if bonusMode && bonusStartTime == 0 {
            bonusStartTime = currentTime
            lastBonusTimeRemaining = bonusTime
        }
        // If we are in bonus mode and we have time remaining...
        if (bonusMode && bonusStartTime > 0) {
            // Figure out the time remaining
            bonusTimeRemaining = bonusTime - Int(currentTime - bonusStartTime)
            if bonusTimeRemaining < 0 {
                bonusTimeRemaining = 0
            }
            // Add the health regeneration for the number of seconds that we
            // stayed alive since the last check
            let healthPerTick: Double = ((playerShip.maxHealth*bonusTimeMaxRegenerationPercent)/Double(bonusTime))
            // Calcuate the amount of health to regenerate
            playerShip.health += Double(lastBonusTimeRemaining - bonusTimeRemaining)*healthPerTick
            // Make sure we don't have too much health
            if (playerShip.health > playerShip.maxHealth) {
                playerShip.health = playerShip.maxHealth
            }
            lastBonusTimeRemaining = bonusTimeRemaining
        }
        
        //
        // Do processes that are being governored (like moving the enemy ships, bullets, etc.)
        switch gameState {
        case (.splashScreen):
            break
        case .readyToStartWave:
            // If we don't have a levelLabel, then we just changed to this games status
            // Display the level label
            if (levelLabel.parent == nil) {
                levelLabel.text = "WAVE \(wave+1)"
                // If the next wave is the bonus wave and we aren't already in a bonus wave,
                // change the text.  Because we take the wave and -1 from it when we are in
                // a bonus wave, we will be on the bonus wave level twice - one with the
                // flag turned off (we will be starting the bonus wave next), and one with
                // the bonus wave turned on (we are ending the bonus wave).
                if (wave > 0 && (wave+1)%bonusWaveInterval == 1 && !bonusMode) {
                    levelLabel.text = "BONUS WAVE"
                }
                levelLabel.removeAllActions()
                hudLayerNode.addChild(tapScreenLabel)
                hudLayerNode.addChild(levelLabel)
                tapScreenLabel.run(slowPulseAction)
                levelLabel.run(slowPulseAction)
            }
            break
        case (.gameRunning):
            // Get the new player ship location
            var newPoint:CGPoint = playerShip.position + deltaPoint
            
            // Move the player's ship
            _ = newPoint.x.clamp(playableRect.minX, playableRect.maxX)
            _ = newPoint.y.clamp(playableRect.minY,playableRect.maxY)
            playerShip.position = newPoint
            deltaPoint = CGPoint.zero

            // If we are in a bonus mode and we need to end it
            if (bonusMode && endBonusMode) {
                endBonusMode = true
                bonusTimeRemaining = 0
            }
            // If we are in a bonus mode
            if (bonusMode) {
                // Add the count down label if we haven't already
                if (countdownLabel.parent == nil) {
                    hudLayerNode.addChild(countdownLabel)
                }
                // Update the displayed text on the count down label
                countdownLabel.text = "\(bonusTimeRemaining)"
                countdownLabel.fontSize = bonusTimeRemaining > 10 ? CGFloat(36) : CGFloat(144)
                countdownLabel.fontColor = SKColor(red: CGFloat(drand48()),
                                                   green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
                // If we are out of time for this bonus
                if (bonusTimeRemaining == 0) {
                    gameState = .waveComplete  // Change modes
                    // Remove enemies from wave
                    for node in enemyLayerNode.children {
                        node.removeFromParent()  // Remove the enemy
                    }
                }
            }

            //
            // Player Update:
            //
            // Fire the player bullet
            //
            // Initiate the last player bullet execution time
            if (playerBulletExecutionTime == 0) {
                playerBulletExecutionTime = currentTime
            }
            // Get the delta from the last time we executed until now
            let playerBulletExecutionTimeDelta = currentTime - playerBulletExecutionTime
            // Check to see if we've waited long enough to do our processing.  We multiple this
            // raw value by the difficulty setting value to increase the time or decease it
            if (playerBulletExecutionTimeDelta >= (playerBulletFireRateInterval)) {
                firePlayerBullets()  // Fire a new set of player bullets
                // Yes we've waited long enough, store the new execution time
                playerBulletExecutionTime = currentTime
            }

            //
            // Update the player's health
            //
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

            //
            // Enemy Update:
            //
            // Update the enemies (move and fire their weapon
            //
            // Loop through all enemy nodes and run their update method.
            // This causes them to update their position based on their currentWaypoint and position
            var nodeCounter = 0
            for node in enemyLayerNode.children {
                nodeCounter += 1  // Keep track of the number of enemies remaining
                let enemy = node as! Enemy
                // Update the enemy and let the AI know how long the wait has been
                enemy.updateEnemy(bulletNode: enemyBulletLayerNode, playerPosition: playerShip.position) // Update the enemy
            }
            // If all of the enemies are gone, wave is complete
            if (nodeCounter == 0) {
                gameState = .waveComplete
            }
            break
        case (.waveComplete):
            // Clear out the last execution times
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
                tapScreenLabel.run(slowPulseAction)

                // Force the background to black to override a bug that may leave the screen red from damage.
                self.run(SKAction.sequence([SKAction.colorize(with: screenBackgroundColor, colorBlendFactor: 1.0, duration: 0), SKAction.removeFromParent()]))
            }
            
            // Set a random color for the game over label
            gameOverLabel.fontColor = SKColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
            break
        }
    }
    
    // This method is called by the physics engine when two physics body collide
    func didBegin(_ contact: SKPhysicsContact) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        // Get the nodes that triggered the collision
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        // If either node is NIL, then we don't have a collision
        if (nodeA == nil || nodeB == nil) {
            return;
        }
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

    // Setup the initial screen node layers
    // Notes:  Here we set the z axis values of the nodes and create the starfield background
    func setupSceneLayers() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        // Set the node names
        playerLayerNode.name = "PlayerLayerNode"
        hudLayerNode.name = "HUDLayerNode"
        playerBulletLayerNode.name = "PlayerBulletLayerNode"
        enemyBulletLayerNode.name = "EnemyBulletLayerNode"
        enemyLayerNode.name = "EnemyLayerNode"
        starfieldLayerNode.name = "StarfieldLayerNode"
        
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
        
        // Initialize the player ship
        if (playerShip == nil) {
            playerShip = PlayerShip(entityPosition: CGPoint(x: size.width / 2, y: 100))
        }
        
        // Add the ship to the parent node and create the particle engine effect
        if (playerShip.parent == nil) {
            playerLayerNode.addChild(playerShip)
            playerShip.createEngine()
        }
    }

    // Setup the user interface
    func setUpUI() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
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
        countdownLabel.position = CGPoint(x: size.width / 2, y: (size.height / 2) - 50)
        
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
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        
        // Setup the entities and reset the score
        score = 0
        funds = 0
        playerShip.health = playerShip.maxHealth
        playerShip.ventingPlasma.isHidden = true
        
        // Set the starting wave
        wave = startingWave < 2 ? 0 : startingWave - 1
        
        startNextWave()
    }
    
    //
    // Continue the game by going to the next wave and starting it
    func startNextWave() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
       // Reset the state of the game
        gameState = .gameRunning

        // Move to the next wave
        wave += 1

        bonusTimeRemaining = 0
        lastBonusTimeRemaining = 0
        bonusStartTime = 0
        
        // Remove the game over HUD labels
        countdownLabel.removeFromParent()
        gameOverLabel.removeFromParent()
        tapScreenLabel.removeAllActions()
        tapScreenLabel.removeFromParent()
        levelLabel.removeFromParent()

        // Setup the entities (player, enemies)
        setupEntities()
        // Upgrade weapons if needed
        upgradeWeapons()

        // Reset the players position
        playerShip.position = CGPoint(x: size.width / 2, y: 100)
        
        SKTAudio.sharedInstance().setBackgroundMusicVolume(Float(musicVolume))  // Set the music volume
    }
    
    //
    // Create the individual entities for the game.
    func setupEntities() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif

        // Add the ship to the parent node and create the particle engine effect
        if (playerShip.parent == nil) {
            playerLayerNode.addChild(playerShip)
            playerShip.createEngine()
        }
        let healthBonus = 5.0 * Double(Int(wave/20))
        var spawnMinimum = 0.0
        let spawnDelay = 5.0
        let waveLevels = 5;
        // Variables used to control the level that enemies appear and the number of lives that they have
        let level1 = 1;
        let level2 = waveLevels+1;
        let level3 = waveLevels*2+1;
        let level4 = waveLevels*3+1;
        let level5 = waveLevels*4+1;
        let lives1 = 1 + (wave / waveLevels) > 4 ? 4 : (wave / waveLevels);
        let lives2 = 2 + (wave - level2) / waveLevels > 4 ? 4 : (wave - level2) / waveLevels;
        let lives3 = 2 + (wave - level3) / waveLevels > 4 ? 4 : (wave - level3) / waveLevels;
        let lives4 = 2 + (wave - level4) / waveLevels > 5 ? 5 : (wave - level4) / waveLevels;
        let lives5 = 3 + (wave - level5) / waveLevels > 7 ? 7 : (wave - level5) / waveLevels;
        
        // If we are on a bonus level, start the bonus mode
        if (wave > 1 && wave%bonusWaveInterval == 1 && !bonusMode) {
            bonusMode = true
            endBonusMode = false
            addBonusEnemies()
            wave -= 1 // Reset the level counter so that we still get this level when we exit the bonus mode
            return;
        }
        // Make sure the end bonus level is set
        bonusMode = false
        endBonusMode = true
        
        switch (wave%waveLevels) {
          case 1:  // Scout wave
            addEnemyWave(enemyWave: EnemyWave(title: "Scout ships approaching!", displayTitleDelay: spawnMinimum, type: .Scout, number: 5, hps: 5.0 + healthBonus, lives: lives1, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level1)
            spawnMinimum += 5
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum, type: .Scout, number: 5, hps: 5.0 + healthBonus, lives: lives1, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level1)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum, type: .Scout, number: 5, hps: 5.0 + healthBonus, lives: lives2, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level2)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Incoming Fighters!", displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 3, hps: 5.0 + healthBonus, lives: lives3, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level3)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 3, hps: 5.0 + healthBonus, lives: lives4, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level4)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 3, hps: 5.0 + healthBonus, lives: lives5, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level5)
            break;
          case 2:  // Fighter wave
            addEnemyWave(enemyWave: EnemyWave(title: "Scout ships approaching!", displayTitleDelay: spawnMinimum, type: .Scout, number: 5, hps: 5.0 + healthBonus, lives: lives1, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level1)
            spawnMinimum += 5
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum, type: .Scout, number: 5, hps: 5.0 + healthBonus, lives: lives1, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level1)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Incoming Fighters!", displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 3, hps: 5.0 + healthBonus, lives: lives2, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level2)
            spawnMinimum += 5
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 3, hps: 5.0 + healthBonus, lives: lives3, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level3)
            spawnMinimum += 5
            addEnemyWave(enemyWave: EnemyWave(title: "Swarmers detected on radar!", displayTitleDelay: spawnMinimum-5, type: .Swarmer, number: 5, hps: 5.0 + healthBonus, lives: lives4, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level4)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .Swarmer, number: 5, hps: 5.0 + healthBonus, lives: lives5, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level5)
            break;
          case 3:  // Swarmer wave
            addEnemyWave(enemyWave: EnemyWave(title: "Incoming Fighters!", displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 3, hps: 5.0 + healthBonus, lives: lives1, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level1)
            spawnMinimum += 5
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 3, hps: 5.0 + healthBonus, lives: lives1, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level1)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Swarmers detected on radar!", displayTitleDelay: spawnMinimum-5, type: .Swarmer, number: 5, hps: 5.0 + healthBonus, lives: lives2, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level2)
            spawnMinimum += 7
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .Swarmer, number: 5, hps: 5.0 + healthBonus, lives: lives3, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level3)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Incoming Fighters and Swarmers!", displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 5, hps: 5.0 + healthBonus, lives: lives4, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level4)
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .Swarmer, number: 5, hps: 5.0 + healthBonus, lives: lives4, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level4)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Advanced Swarmers detected on radar!", displayTitleDelay: spawnMinimum-5, type: .AdvancedSwarmer, number: 5, hps: 5.0 + healthBonus, lives: lives5, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level5)
            break;
          case 4:  // Boss fighter
            addEnemyWave(enemyWave: EnemyWave(title: "Incoming Fighters and Swarmers!", displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 3, hps: 5.0 + healthBonus, lives: lives1, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level1)
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .Swarmer, number: 3, hps: 5.0 + healthBonus, lives: lives1, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level1)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Advanced Swarmers detected on radar!", displayTitleDelay: spawnMinimum-5, type: .AdvancedSwarmer, number: 3, hps: 5.0 + healthBonus, lives: lives2, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level2)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .AdvancedSwarmer, number: 3, hps: 5.0 + healthBonus, lives: lives3, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level3)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Incoming Advanced Fighters!", displayTitleDelay: spawnMinimum-5, type: .AdvancedFighter, number: 2, hps: 50.0 + healthBonus, lives: lives4, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level4)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .AdvancedSwarmer, number: 3, hps: 5.0 + healthBonus, lives: lives5, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level5)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Incoming Advanced Fighters!", displayTitleDelay: spawnMinimum-5, type: .AdvancedFighter, number: 2, hps: 50.0 + healthBonus, lives: lives5, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level5)
            break;
          case 0:  // Stealth bomber
            addEnemyWave(enemyWave: EnemyWave(title: "Incoming Fighters and Swarmers!", displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 3, hps: 5.0 + healthBonus, lives: lives1, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level1)
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .Swarmer, number: 3, hps: 5.0 + healthBonus, lives: lives1, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .None), minimumWave: level1)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Advanced Swarmers detected on radar!", displayTitleDelay: spawnMinimum-5, type: .AdvancedSwarmer, number: 3, hps: 5.0 + healthBonus, lives: lives2, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level2)
            spawnMinimum += 5
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .AdvancedSwarmer, number: 3, hps: 5.0 + healthBonus, lives: lives3, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level3)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Incoming Advanced Fighters!", displayTitleDelay: spawnMinimum-5, type: .AdvancedFighter, number: 2, hps: 50.0 + healthBonus, lives: lives3, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level3)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: "Radar Jammed!", displayTitleDelay: spawnMinimum-5, type: .AdvancedSwarmer, number: 3, hps: 5.0 + healthBonus, lives: lives4, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level4)
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .AdvancedBomber, number: 1, hps: 75.0 + healthBonus, lives: lives4, spawnDelay: 0, spawnMinimum: spawnMinimum, gunType: .StaticGun), minimumWave: level4)
            spawnMinimum += 10
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .Fighter, number: 3, hps: 5.0 + healthBonus, lives: lives5, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level5)
            spawnMinimum += 15
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .AdvancedSwarmer, number: 3, hps: 5.0 + healthBonus, lives: lives5, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level5)
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .AdvancedFighter, number: 2, hps: 50.0 + healthBonus, lives: lives5, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level5)
            spawnMinimum += 7
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .AdvancedBomber, number: 2, hps: 75.0 + healthBonus, lives: lives5, spawnDelay: 0, spawnMinimum: spawnMinimum, gunType: .StaticGun), minimumWave: level5)
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: spawnMinimum-5, type: .AdvancedSwarmer, number: 3, hps: 5.0 + healthBonus, lives: lives5, spawnDelay: spawnDelay, spawnMinimum: spawnMinimum, gunType: .RailGun), minimumWave: level5)
            break
          default:  // Bonus
            bonusMode = true
            addBonusEnemies()
            break
        }
    }
    
    // Bonus Levels
    func addBonusEnemies() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif

        addEnemyWave(enemyWave: EnemyWave(title: "Swarmers detected on radar!", displayTitleDelay: 0, type: .Swarmer, number: 15, hps: 5.0, lives: 99, spawnDelay: 0, spawnMinimum: 5, gunType: .None))
        if (wave > bonusWaveInterval * 4 - 1) {
            addEnemyWave(enemyWave: EnemyWave(title: nil, displayTitleDelay: 0, type: .AdvancedSwarmer, number: 5, hps: 5.0, lives: 99, spawnDelay: 5, spawnMinimum: 15, gunType: .RailGun))
        }

    }
    
    // Enemy wave method
    // Note:  This method will add a wave to the current enemy list.  Waves themselves aren't anything special but they add a method
    //        that we can increase the delays between groups of enemies that attack the user.  You can call this multiple times to
    //        build the enemy list for the current game wave.
    func addEnemyWave(enemyWave: EnemyWave, minimumWave: Int = 0) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        
        // If we haven't reached the minimum wave yet, then don't add the enemies.
        if (wave < minimumWave) {
            return
        }
        
        // Setup the wave message
        let waveMessage = SKLabelNode(fontNamed: "Edit Undo Line BRK")
        waveMessage.name = "waveTitle"
        waveMessage.fontSize = 26;
        waveMessage.fontColor = SKColor.white
        waveMessage.horizontalAlignmentMode = .center
        waveMessage.verticalAlignmentMode = .center
        waveMessage.position = CGPoint(x: size.width / 2, y: size.height + 100)  // Hide the text
        waveMessage.text = enemyWave.title
        // If we have a wave title, add it to the hud layer
        if (enemyWave.title != nil) {
            hudLayerNode.addChild(waveMessage)
            // Build a custom action that displays the wave title message and then removes it
            let waveMessageAction: SKAction = SKAction.sequence([SKAction.wait(forDuration: enemyWave.displayTitleDelay), SKAction.move(to: CGPoint(x: size.width / 2, y: size.height / 2), duration: 0.0), SKAction.wait(forDuration: waveTitleDisplayTime), SKAction.removeFromParent()])
            waveMessage.run(waveMessageAction) // Start the wave title action
            waveMessage.run(fasePulseAction) // Pulse the text
        }

        switch(enemyWave.type) {
        case .Scout:
            for _ in 0..<enemyWave.number {
                let enemy = EnemyScout(entityPosition: CGPoint(
                    x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    y: playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = enemyWave.hps
                enemy.maxHealth = enemy.health
                enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
                enemy.executionTimeGovernor = (enemyExecutionGovernor * programDifficulty.rawValue)
                enemy.lives = 1 + enemyWave.lives == 0 ? 1 : enemyWave.lives  // At least 1 life
                enemy.setSpawnDelay(Double(CGFloat.random())*enemyWave.spawnDelay + enemyWave.spawnMinimum)
                enemy.gunType = enemyWave.gunType
                enemyLayerNode.addChild(enemy)
            }
            break
        case .Fighter:
            for _ in 0..<enemyWave.number {
                let enemy = EnemyFighter(entityPosition: CGPoint(
                    x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    y: playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = enemyWave.hps
                enemy.maxHealth = enemy.health
                enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
                enemy.executionTimeGovernor = (enemyExecutionGovernor * programDifficulty.rawValue)
                enemy.lives = 1 + enemyWave.lives == 0 ? 1 : enemyWave.lives  // At least 1 life
                enemy.setSpawnDelay(Double(CGFloat.random())*enemyWave.spawnDelay + enemyWave.spawnMinimum)
                enemy.gunType = enemyWave.gunType
                enemyLayerNode.addChild(enemy)
            }
            break
        case .Swarmer:
            for _ in 0..<enemyWave.number {
                let enemy = EnemySwarmer(entityPosition: CGPoint(
                    x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    y: playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = enemyWave.hps
                enemy.maxHealth = enemy.health
                enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
                enemy.executionTimeGovernor = (enemyExecutionGovernor * programDifficulty.rawValue)
                enemy.lives = 1 + enemyWave.lives == 0 ? 1 : enemyWave.lives  // At least 1 life
                enemy.setSpawnDelay(Double(CGFloat.random())*enemyWave.spawnDelay + enemyWave.spawnMinimum)
                enemy.gunType = enemyWave.gunType
                enemy.gunFireInterval *= programDifficulty.rawValue
                enemy.gunBurstFireNumber = 1
                enemy.gunFireInterval *= programDifficulty.rawValue
                enemyLayerNode.addChild(enemy)
            }
            break
        case .AdvancedSwarmer:
            for _ in 0..<enemyWave.number {
                let enemy = EnemySwarmer(entityPosition: CGPoint(
                    x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    y: playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = enemyWave.hps
                enemy.maxHealth = enemy.health
                enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
                enemy.executionTimeGovernor = (enemyExecutionGovernor * programDifficulty.rawValue)
                enemy.lives = 1 + enemyWave.lives == 0 ? 1 : enemyWave.lives  // At least 1 life
                enemy.setSpawnDelay(Double(CGFloat.random())*enemyWave.spawnDelay + enemyWave.spawnMinimum)
                enemy.gunType = enemyWave.gunType
                enemy.gunFireInterval *= programDifficulty.rawValue
                enemy.gunBurstFireNumber = 5
                enemy.gunFireInterval *= programDifficulty.rawValue
                enemyLayerNode.addChild(enemy)
            }
            break
        case .AdvancedFighter:
            for _ in 0..<enemyWave.number {
                let enemy = EnemyBossFighter(entityPosition: CGPoint(
                    x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    y: playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = enemyWave.hps
                enemy.maxHealth = enemy.health
                enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
                enemy.executionTimeGovernor = (enemyExecutionGovernor * programDifficulty.rawValue)
                enemy.lives = 1 + enemyWave.lives == 0 ? 1 : enemyWave.lives  // At least 1 life
                enemy.setSpawnDelay(Double(CGFloat.random())*enemyWave.spawnDelay + enemyWave.spawnMinimum)
                enemy.gunType = enemyWave.gunType
                enemyLayerNode.addChild(enemy)
            }
            break
        case .AdvancedBomber:
            for _ in 0..<enemyWave.number {
                let enemy = EnemyBossBomber(entityPosition: CGPoint(
                    x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    y: playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = enemyWave.hps
                enemy.maxHealth = enemy.health
                enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
                enemy.executionTimeGovernor = (enemyExecutionGovernor * programDifficulty.rawValue)
                enemy.lives = 1 + enemyWave.lives == 0 ? 1 : enemyWave.lives  // At least 1 life
                enemy.setSpawnDelay(Double(CGFloat.random())*enemyWave.spawnDelay + enemyWave.spawnMinimum)
                enemy.gunType = enemyWave.gunType
                enemyLayerNode.addChild(enemy)
            }
            break
        default:
            break
        }
    }
    
    func upgradeWeapons() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
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
    
    //
    // This method fires the bullets in the game.  Each time this is called, it adds another set of bullets
    // to the node depending on the level.  This needs to be upgraded to allow users to purchase
    // new guns.
    func firePlayerBullets() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
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
    // Fire the center forward cannon
    func bulletCenterForward() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
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
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        switch(playerShipWingCannons) {
        case .none:
            break
        case .railGun:
            // Double bullet
            let bullet1 = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x-14, y: playerShip.position.y+20))
            let bullet2 = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x+14, y: playerShip.position.y+20))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
        case .particleLaser:
            // Double bullet
            let bullet1 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x-14, y: playerShip.position.y+20))
            let bullet2 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x+14, y: playerShip.position.y+20))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
        case .protonLaser:
            // Double bullet
            let bullet1 = BulletProtonLaser(entityPosition: CGPoint(x: playerShip.position.x-14, y: playerShip.position.y+20))
            let bullet2 = BulletProtonLaser(entityPosition: CGPoint(x: playerShip.position.x+14, y: playerShip.position.y+20))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1), SKAction.removeFromParent()]))
        }
    }

    //
    // Fire the wing cannons backwards
    func bulletWingsBackward() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        switch(playerShipTailCannons) {
        case .none:
            break
        case .railGun:
            // Double bullet
            let bullet1 = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x-10, y: playerShip.position.y-10))
            let bullet2 = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x+10, y: playerShip.position.y-10))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
        case .particleLaser:
            // Double bullet
            let bullet1 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x-10, y: playerShip.position.y-10))
            let bullet2 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x+10, y: playerShip.position.y-10))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
        case .protonLaser:
            // Double bullet
            let bullet1 = BulletProtonLaser2(entityPosition: CGPoint(x: playerShip.position.x-10, y: playerShip.position.y-10))
            let bullet2 = BulletProtonLaser2(entityPosition: CGPoint(x: playerShip.position.x+10, y: playerShip.position.y-10))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1), SKAction.removeFromParent()]))
        }
    }
    
    //
    // Increase the score
    func increaseScoreBy(_ increment: Int) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
       score += increment
        updateScore()
    }

    func updateScore() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        scoreLabel.text = "Score: \(score)"
    }
    
    //
    // Increase the funds
    func increaseFundsBy(_ increment: Int) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        funds += increment
        updateFunds()
    }
    
    func updateFunds() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        fundsLabel.text = "Funds: $\(funds)"
    }
    
    //
    // Slowly move the player to the starting location
    func transitionPlayer() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
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
    // Generate the starfield
    // Notes:
    //
    func starfieldEmitterNode(speed: CGFloat, lifetime: CGFloat, scale: CGFloat, birthRate: CGFloat, color: SKColor) -> SKEmitterNode {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
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
    
    //
    // Flash the screen red based upon the damage taken
    func flashScreenBasedOnDamage(_ color: SKColor, _ damage: Int) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
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
    
    func printNodes() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        print("Start:")
//        for node in self.children {
//            printNodes(name: node.name ?? "Unknown", node: node)
//        }
        printNodes(name: "  playerLayerNode", node: playerLayerNode)
        printNodes(name: "  hudLayerNode", node: hudLayerNode)
        printNodes(name: "  playerBulletLayerNode", node: playerBulletLayerNode)
        printNodes(name: "  enemyBulletLayerNode", node: enemyBulletLayerNode)
        printNodes(name: "  enemyLayerNode", node: enemyLayerNode)
        printNodes(name: "  starfieldLayerNode", node: starfieldLayerNode)
    }
    
    func printNodes(name: String, node: SKNode) {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        for node in node.children {
            let nodeName = node.name ?? "Unknown"
            print("  \(name)->\(nodeName): ")
            printNodes(name: "  " + nodeName, node: node)
        }
    }
    
    func playGameOver() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        SKTAudio.sharedInstance().setBackgroundMusicVolume(Float(0.0)) // Set the background music volume
        run(gameOverSound)
    }
    
    func playLevelComplete() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        
        SKTAudio.sharedInstance().setBackgroundMusicVolume(Float(0.0)) // Set the background music volume
        run(levelCompleteSound)
    }

    func playExplodeSound() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        // Calling SKTAudio directly like this is a slight lag during execution
        //        SKTAudio.sharedInstance().playSoundEffect("explode.wav", specialEffectsVolume)
        run(explodeSound)
    }
    
    func playLaserSound() {
        #if DEBUG_OFF
        print("File: \(#file)\tMethod: \(#function)\tLine: \(#line)")
        #endif
        // Calling SKTAudio directly like this is a slight lag during execution
        //        SKTAudio.sharedInstance().playSoundEffect("laser.wav", laserVolume)
        run(laserSound)
    }
}
