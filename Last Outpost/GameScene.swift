//
//  GameScene.swift
//  Last Outpost
//
//  Created by George McMullen on 8/28/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

// The update method uses the GameState to work out what should be done during each update
// loop
enum GameState {
    case splashScreen
    case gameRunning
    case gameOver
    case waveComplete
}

enum PlayerCenterLaserCannonState {
    case railGun
    case particleLaser
    case protonLaser
}

enum PlayerWingLaserCannonState {
    case none
    case railGun
    case particleLaser
    case protonLaser
}

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
    
    // Screen nodes:
    let playerLayerNode = SKNode()  // Contains the player ship images and effects
    let hudLayerNode = SKNode()  // Contains the score, health, press any key messages
    let playerBulletLayerNode = SKNode()  // Contains the player's bullets
    let enemyBulletLayerNode = SKNode()  // Contains the enemies bullets
    var enemyLayerNode = SKNode()  // Contains the enemy ship images and effects
    let starfieldLayerNode = SKNode()  // Contains the starfield particles (background)
    
    let playableRect: CGRect  // Defined playable area of the screen (screen size)
    let hudHeight: CGFloat = 90  // Total height of the HUD (subtracted from the play area size)
    var musicVolume: Float = 0.8 // Play music at only 80%
    var specialEffectsVolume: Float = 1.0 // Play these at 100%
    var laserVolume: Float = 0.8  // Laser volume
    
    var gameState = GameState.splashScreen  // Current game state
    
    // The executiong time and governor variables are used to control the speed of the objects
    // during the game.  These variables allow us to try and standarize on a set speed indepenent
    // of the processor CPU speed.  We limit the movement of an enemy, for instance, to 30 movements
    // per second.
    var lastEnemyExecutionTime: TimeInterval = 0
    let enemyExecutionGovernor: TimeInterval = 1 / 30  // 30 mps
    var playerBulletExecutionTime: TimeInterval = 0
    let playerBulletsPerSecond: Float = 4
    var playerBulletFireRateInterval: TimeInterval

    // We can use this to increase/decrease the player difficulty. The smaller the number, the faster
    // the screen should do updates for the enemies.  We use the value from this enum to multiply
    // against objects during game play.
    var programDifficulty: GameDifficulty = .normal
    
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
    
    var textFlashAction: SKAction!
    let screenBackgroundColor = SKColor.black
    
    var score = 0
    var funds = 0  // Amount of money earned by the player to purchase upgrades
    var wave = 0  // Current wave
    
    // Enemy Definitions:
    //   Scouts
    var enemyScoutsLevelFirstAppear: Int = 1
    var enemyScoutsStartingNumber: Int = 5
    var enemyScoutsLevelsToAddAdditional: Int = 3
    var enemyScoutsMaximumNumber: Int = 20
    var enemyScoutsLevelGainAdditionalLives: Int = 3
    var enemyScoutsMaximumNumberOfAdditioinalLives: Int = 5

    //   Swarmers
    var enemySwarmersLevelFirstAppear: Int = 5
    var enemySwarmersStartingNumber: Int = 3
    var enemySwarmersLevelsToAddAdditional: Int = 5
    var enemySwarmersMaximumNumber: Int = 20
    var enemySwarmersLevelGainAdditionalLives: Int = 10
    var enemySwarmersMaximumNumberOfAdditioinalLives: Int = 3

    //   Fighters
    var enemyFightersLevelFirstAppear: Int = 11
    var enemyFightersStartingNumber: Int = 2
    var enemyFightersLevelsToAddAdditional: Int = 5
    var enemyFightersMaximumNumber: Int = 10
    var enemyFightersLevelGainAdditionalLives: Int = 21
    var enemyFightersMaximumNumberOfAdditioinalLives: Int = 5

    //   Boss Bombers
    var enemyBossBombersLevelFirstAppear: Int = 20
    var enemyBossBombersStartingNumber: Int = 1
    var enemyBossBomberLevelInterval: Int = 10 // Show bosses every 10 levels from first appearing
    var enemyBossBombersLevelsToAddAdditional: Int = 10
    var enemyBossBombersMaximumNumber: Int = 5
    var enemyBossBombersLevelGainAdditionalLives: Int = 50
    var enemyBossBombersMaximumNumberOfAdditioinalLives: Int = 1

    //   Boss Fighter
    var enemyBossFightersLevelFirstAppear: Int = 50
    var enemyBossFightersStartingNumber: Int = 1
    var enemyBossFightersLevelInterval: Int = 25 // Show bosses every 25 levels from first appearing
    var enemyBossFightersLevelsToAddAdditional: Int = 25
    var enemyBossFightersMaximumNumber: Int = 2
    var enemyBossFightersLevelGainAdditionalLives: Int = 25
    var enemyBossFightersMaximumNumberOfAdditioinalLives: Int = 0
    
    // Pulse action
    let screenPulseAction = SKAction.repeatForever(SKAction.sequence([SKAction.fadeOut(withDuration: 1), SKAction.fadeIn(withDuration: 1)]))
    let laserSound = SKAction.playSoundFileNamed("laser.wav", waitForCompletion: false)
    let explodeSound = SKAction.playSoundFileNamed("explode.wav", waitForCompletion: false)
    
    var playerShip: PlayerShip!
    var playerShipCenterCannon: PlayerCenterLaserCannonState = .railGun
    var playerShipWingCannons: PlayerWingLaserCannonState = .none
    var playerShipTailCannons: PlayerTailLaserCannonState = .none
    
    var deltaPoint = CGPoint.zero
    var previousTouchLocation = CGPoint.zero
    
    // Initilization method
    override init(size: CGSize) {
        // Calculate playable margin.  Put a boarder of 20 pixels on each side
        playableRect = CGRect(x: 20, y: 20, width: size.width-40, height: size.height - hudHeight-40)
        playerBulletFireRateInterval = TimeInterval(1.0 / playerBulletsPerSecond)
        
        super.init(size: size)
        
        // Setup the initial game state
        gameState = .gameOver
        // Setup the starting screen
        setupSceneLayers()
        setUpUI()
        setupEntities()
        
        SKTAudio.sharedInstance().playBackgroundMusic("bgMusic.mp3", musicVolume)
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
        if gameState == .gameOver {
            startGame()
        }
        if gameState == .waveComplete {
            startNextWave()
        }
        if gameState == .splashScreen {
            startGame()
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
    override func update(_ currentTime: TimeInterval) {
        // Get the new player ship location
        var newPoint:CGPoint = playerShip.position + deltaPoint
        
        var executeEnemyMovement: Bool = true
        var playerBulletExeuctionTimeElapsed: Bool = true
        
        // Initiate the last execution time
        if (lastEnemyExecutionTime == 0) {
            lastEnemyExecutionTime = currentTime
        }
        // Initiate the last player bullet execution time
        if (playerBulletExecutionTime == 0) {
            playerBulletExecutionTime = currentTime
        }
        // Get the delta from the last time we executed until now
        let enemyExecutionTimeDelta = currentTime - lastEnemyExecutionTime
        // Get the delta from the last time we executed until now
        let playerBulletExecutionTimeDelta = currentTime - playerBulletExecutionTime

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
            playerBulletExeuctionTimeElapsed = false
        } else {
            //
            // Yes we've waited long enough, store the new execution time
            playerBulletExecutionTime = currentTime
        }
        
        //
        // Do processes that are being governored (like moving the enemy ships, bullets, etc.)
        
        switch gameState {
        case (.splashScreen):
            break
        case (.gameRunning):
            // Move the player's ship
            _ = newPoint.x.clamp(playableRect.minX, playableRect.maxX)
            _ = newPoint.y.clamp(playableRect.minY,playableRect.maxY)

            playerShip.position = newPoint
            deltaPoint = CGPoint.zero

            //
            // If the player bullet execution time has elapsed, then fire the bullets
            if (playerBulletExeuctionTimeElapsed) {
                firePlayerBullets()  // Fire a new set of player bullets
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
                lastEnemyExecutionTime = currentTime
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
            }
            break
        case (.waveComplete):
            // Reset the players position
            playerShip.position = CGPoint(x: size.width / 2, y: 100)

            // Clear out the last execution times
            lastEnemyExecutionTime = 0
            playerBulletExecutionTime = 0
            
            // If we don't have a levelLabel, then we just changed to this games status
            if (levelLabel.parent == nil) {
                playerBulletLayerNode.removeAllChildren()
                enemyLayerNode.removeAllChildren()
                enemyBulletLayerNode.removeAllChildren()
                levelLabel.removeFromParent()
                tapScreenLabel.removeFromParent()
                
                levelLabel.text = "WAVE \(wave+1)"
                if ((wave+1)%5 == 0) {
                    levelLabel.text = "WAVE \(wave+1): BONUS WAVE"
                }
                levelLabel.removeAllActions()
                hudLayerNode.addChild(tapScreenLabel)
                hudLayerNode.addChild(levelLabel)
                tapScreenLabel.run(screenPulseAction)
                levelLabel.run(screenPulseAction)
            }
            break
        case (.gameOver):
            // When the game is over remove all the entities from the scene and add the game over labels
            if (gameOverLabel.parent == nil) {
                playerBulletLayerNode.removeAllChildren()
                enemyLayerNode.removeAllChildren()
                enemyBulletLayerNode.removeAllChildren()
                playerShip.removeFromParent()

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
        // Get the enemy node
        let enemyNode = contact.bodyA.node
        let playerNode = contact.bodyB.node
        // Enemy ship was hit
        let enemy = enemyNode as! Entity
        let player = playerNode as! Entity

        // If an enemy ship was hit, apply damage to it
        if enemyNode?.name == "enemy" {
            // Damage the enemy ship
            enemy.collidedWith(contact.bodyA, contact: contact, damage: player.collisionDamage)
        }
        // If a player node (ship or bullet) was hit, apply damage to it
        if playerNode?.name == "playerShip" || playerNode?.name == "playerBullet" {
            player.collidedWith(contact.bodyA, contact: contact, damage: enemy.collisionDamage)
            // If this was the player ship, flash the screen when we take damage
            if (playerNode?.name == "playerShip") {
                flashScreenBasedOnDamage(SKColor.red, enemy.collisionDamage) // Flash the screen
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
            SKAction.colorize(with: screenBackgroundColor, colorBlendFactor: 1.0, duration: duration)]))
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
        self.run(SKAction.sequence([SKAction.colorize(with: screenBackgroundColor, colorBlendFactor: 1.0, duration: 0)]))
        
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
        
        // Action to flash the text (used in the score)
        textFlashAction = SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)])

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
        //    Add the flash action to the score lable
        // scoreLabel.run(SKAction.repeat(textFlashAction, count: 20))

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
        
        updateScore()
        updateFunds()

        setupEntities()
        //
        // Setup initial weapons
        playerShipCenterCannon = .railGun
        playerShipWingCannons = .none
        playerShipTailCannons = .none
        
        upgradeWeapons()

        playerShip.health = playerShip.maxHealth
        playerShip.position = CGPoint(x: size.width / 2, y: 100)
        
        // Remove the game over HUD labels
        gameOverLabel.removeFromParent()
        tapScreenLabel.removeAllActions()
        tapScreenLabel.removeFromParent()
        levelLabel.removeFromParent()
    }

    //
    // Continue the game by going to the next wave and starting it
    func startNextWave() {
        // Reset the state of the game
        gameState = .gameRunning
        
        // Move to the next wave
        wave += 1

        // Setup the entities and reset the score
        setupEntities()
        
        upgradeWeapons()

        // Reset the players health and position
        playerShip.position = CGPoint(x: size.width / 2, y: 100)
        
        // Remove the game over HUD labels
        gameOverLabel.removeFromParent()
        tapScreenLabel.removeAllActions()
        tapScreenLabel.removeFromParent()
        levelLabel.removeFromParent()
        

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
        
        // Add enemies to this wave
        addScouts()
        addSwarmers()
        addFighters()
        addBossBombers()
        addBossFighters()
        
    }

    func upgradeWeapons() {
        // Upgrade weapons
        switch (wave) {
        case 1:
            playerShipCenterCannon = .railGun
            playerShipWingCannons = .none
            playerShipTailCannons = .none
        case  6:
            playerShipCenterCannon = .particleLaser
            playerShipWingCannons = .none
            playerShipTailCannons = .none
        case  11:
            playerShipCenterCannon = .particleLaser
            playerShipWingCannons = .railGun
            playerShipTailCannons = .none
        case  16:
            playerShipCenterCannon = .particleLaser
            playerShipWingCannons = .particleLaser
            playerShipTailCannons = .none
        case  21:
            playerShipCenterCannon = .particleLaser
            playerShipWingCannons = .particleLaser
            playerShipTailCannons = .railGun
        case  26:
            playerShipCenterCannon = .particleLaser
            playerShipWingCannons = .particleLaser
            playerShipTailCannons = .particleLaser
        case  31:
            playerShipCenterCannon = .protonLaser
            playerShipWingCannons = .particleLaser
            playerShipTailCannons = .particleLaser
        case  36:
            playerShipCenterCannon = .protonLaser
            playerShipWingCannons = .protonLaser
            playerShipTailCannons = .particleLaser
        default:
            if (wave > 40) {
                playerShipCenterCannon = .protonLaser
                playerShipWingCannons = .protonLaser
                playerShipTailCannons = .protonLaser
                let increaseFirerateBy: Int = (wave - 40)/10

                // Keep adding more bullets every 10 levels
                if ((wave+1)-50 > 0 && wave%10 == 0) {
                    playerBulletFireRateInterval = (1.0 / Double(playerBulletsPerSecond + Float(increaseFirerateBy)))
                }
            }
        }
    }
    
    // Scouts enemy add method:
    func addScouts() {
        var number: Int = (wave/enemyScoutsLevelGainAdditionalLives) + enemyScoutsStartingNumber
        if (number > enemyScoutsMaximumNumber) {
            number = enemyScoutsMaximumNumber
        }
        var lives = ((wave + 1)/enemyScoutsLevelGainAdditionalLives)
        if (enemyScoutsMaximumNumberOfAdditioinalLives != 0) {
            lives = (lives > enemyScoutsMaximumNumberOfAdditioinalLives ? enemyScoutsMaximumNumberOfAdditioinalLives : lives)
        }
        
        // Add mini boss enemies starting at wave 5
        if (wave >= enemyScoutsLevelFirstAppear) {
            for _ in 0..<number {
                let enemy = EnemyScout(entityPosition: CGPoint(
                    x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    y: playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = 5
                enemy.maxHealth = 5
                enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
                if (wave >= enemyScoutsLevelGainAdditionalLives) {
                    enemy.lives = lives
                }
                enemyLayerNode.addChild(enemy)
            }
        }

    }
    
    // Swarmers enemy add method:
    func addSwarmers() {
        var number: Int = (wave/enemySwarmersLevelGainAdditionalLives) + enemySwarmersStartingNumber
        if (number > enemySwarmersMaximumNumber) {
            number = enemySwarmersMaximumNumber
        }
        var lives = (wave/enemySwarmersLevelGainAdditionalLives)
        if (enemySwarmersMaximumNumberOfAdditioinalLives != 0) {
            lives = (lives > enemySwarmersMaximumNumberOfAdditioinalLives ? enemySwarmersMaximumNumberOfAdditioinalLives : lives)
        }
        
        // Add mini enemies starting at wave 5
        if (wave >= enemySwarmersLevelFirstAppear) {
            for _ in 0..<number {
                let enemy = EnemySwarmer(entityPosition: CGPoint(
                    x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    y: playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = 5
                enemy.maxHealth = 5
                enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
                if (wave >= enemySwarmersLevelGainAdditionalLives) {
                    enemy.lives = lives
                }
                enemyLayerNode.addChild(enemy)
            }
        }
    }
    
    // Fighter enemy add method:
    func addFighters() {
        var number: Int = (wave/enemyFightersLevelGainAdditionalLives) + enemyFightersStartingNumber
        if (number > enemyFightersMaximumNumber) {
            number = enemyFightersMaximumNumber
        }
        var lives = (wave/enemyFightersLevelGainAdditionalLives)
        if (enemyFightersMaximumNumberOfAdditioinalLives != 0) {
            lives = (lives > enemyFightersMaximumNumberOfAdditioinalLives ? enemyFightersMaximumNumberOfAdditioinalLives : lives)
        }
        
        // Add mini enemies starting at wave 5
        if (wave >= enemyFightersLevelFirstAppear) {
            for _ in 0..<number {
                let enemy = EnemyFighter(entityPosition: CGPoint(
                    x: CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    y: playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = 5
                enemy.maxHealth = 5
                enemy.speed = CGFloat(1.0 / programDifficulty.rawValue)
                if (wave >= enemyFightersLevelGainAdditionalLives) {
                    enemy.lives = lives
                }
                enemyLayerNode.addChild(enemy)
            }
        }
    }
    
    // Boss Bombers add method:
    func addBossBombers() {
        // If we are on at least the starting level for this boss and the level is
        // evenly divisible by the frequency, then we'll need to generate bosses
        if (wave < enemyBossBombersLevelFirstAppear || (wave - enemyBossBombersLevelFirstAppear) % enemyBossBomberLevelInterval != 0) {
            return
        }
        
        var number: Int = ((wave + 1 - enemyBossBombersLevelFirstAppear)/enemyBossBombersLevelsToAddAdditional) + 1
        if (number > enemyBossBombersMaximumNumber) {
            number = enemyBossBombersMaximumNumber
        }
        
        var lives = (wave/enemyBossBombersLevelGainAdditionalLives)
        if (enemyBossBombersMaximumNumberOfAdditioinalLives != 0) {
            lives = (lives > enemyBossBombersMaximumNumberOfAdditioinalLives ? enemyBossBombersMaximumNumberOfAdditioinalLives : lives)
        }
        
        // Add boss enemies
        for _ in 0..<number {
            let enemy = EnemyBossBomber(entityPosition: CGPoint(x: CGFloat.random(min: playableRect.origin.x, max:
                    playableRect.size.width), y: playableRect.size.height+100), playableRect: playableRect)
            let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2,   max: playableRect.height))
            enemy.aiSteering.updateWaypoint(initialWaypoint)
            enemy.health = Double((wave)/enemyBossBomberLevelInterval) * 25.0
            enemy.maxHealth = Double((wave)/enemyBossBomberLevelInterval) * 25.0
            // Enable the additional lives if we have reached the right level
            if (wave >= enemyBossBombersLevelGainAdditionalLives) {
                enemy.lives = lives
            }
            enemy.speed = CGFloat(0.25 / programDifficulty.rawValue)
            enemyLayerNode.addChild(enemy)
        }
    }
    
    // Boss Fighters add method:
    func addBossFighters() {
        // If we are on at least the starting level for this boss and the level is
        // evenly divisible by the frequency, then we'll need to generate bosses
        if (wave < enemyBossFightersLevelFirstAppear || (wave - enemyBossFightersLevelFirstAppear) % enemyBossFightersLevelInterval != 0) {
            return
        }
        
        var number: Int = ((wave - enemyBossFightersLevelFirstAppear)/enemyBossFightersLevelsToAddAdditional) + 1
        if (number > enemyBossFightersMaximumNumber) {
            number = enemyBossFightersMaximumNumber
        }
        
        var lives = (wave/enemyBossFightersLevelGainAdditionalLives)
        if (enemyBossFightersMaximumNumberOfAdditioinalLives != 0) {
            lives = (lives > enemyBossFightersMaximumNumberOfAdditioinalLives ? enemyBossFightersMaximumNumberOfAdditioinalLives : lives)
        }
        
        // Add boss enemies
        for _ in 0..<number {
            let enemy = EnemyBossFighter(entityPosition: CGPoint(x: CGFloat.random(min: playableRect.origin.x, max:
                playableRect.size.width), y: playableRect.size.height+100), playableRect: playableRect)
            let initialWaypoint = CGPoint(x: CGFloat.random(min: playableRect.origin.x, max: playableRect.width), y: CGFloat.random(min: playableRect.height / 2,   max: playableRect.height))
            enemy.aiSteering.updateWaypoint(initialWaypoint)
            enemy.health = Double((wave)/enemyBossFightersLevelInterval) * 25.0
            enemy.maxHealth = Double((wave)/enemyBossFightersLevelInterval) * 25.0
            // Enable the additional lives if we have reached the right level
            if (wave >= enemyBossFightersLevelGainAdditionalLives) {
                enemy.lives = lives
            }
            enemy.speed = CGFloat(0.25 / programDifficulty.rawValue)
            enemyLayerNode.addChild(enemy)
        }
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
    // Fire the center forward cannon
    func bulletCenterForward() {
        switch(playerShipCenterCannon) {
        case .railGun:
            let bullet = BulletRailGun(entityPosition: playerShip.position)
            playerBulletLayerNode.addChild(bullet)
            bullet.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height+20, duration: 1),
                                          SKAction.removeFromParent()]))
        case .particleLaser:
            let bullet = BulletParticleLaser(entityPosition: playerShip.position)
            playerBulletLayerNode.addChild(bullet)
            bullet.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height+20, duration: 1),
                                          SKAction.removeFromParent()]))
        case .protonLaser:
            let bullet = BulletProtonLaser(entityPosition: playerShip.position)
            playerBulletLayerNode.addChild(bullet)
            bullet.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height+20, duration: 1),
                                          SKAction.removeFromParent()]))
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
            let bullet1 = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x-20, y: playerShip.position.y))
            let bullet2 = BulletRailGun(entityPosition: CGPoint(x: playerShip.position.x+20, y: playerShip.position.y))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1),                SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1),                SKAction.removeFromParent()]))
        case .particleLaser:
            // Double bullet
            let bullet1 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x-20, y: playerShip.position.y))
            let bullet2 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x+20, y: playerShip.position.y))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1),                SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1),                SKAction.removeFromParent()]))
        case .protonLaser:
            // Double bullet
            let bullet1 = BulletProtonLaser(entityPosition: CGPoint(x: playerShip.position.x-20, y: playerShip.position.y))
            let bullet2 = BulletProtonLaser(entityPosition: CGPoint(x: playerShip.position.x+20, y: playerShip.position.y))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1),                SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: 1, y: size.height, duration: 1),                SKAction.removeFromParent()]))
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
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1),                SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1),                SKAction.removeFromParent()]))
        case .particleLaser:
            // Double bullet
            let bullet1 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x-10, y: playerShip.position.y))
            let bullet2 = BulletParticleLaser(entityPosition: CGPoint(x: playerShip.position.x+10, y: playerShip.position.y))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1),                SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1),                SKAction.removeFromParent()]))
        case .protonLaser:
            // Double bullet
            let bullet1 = BulletProtonLaser2(entityPosition: CGPoint(x: playerShip.position.x-10, y: playerShip.position.y))
            let bullet2 = BulletProtonLaser2(entityPosition: CGPoint(x: playerShip.position.x+10, y: playerShip.position.y))
            playerBulletLayerNode.addChild(bullet1)
            playerBulletLayerNode.addChild(bullet2)
            bullet1.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1),                SKAction.removeFromParent()]))
            bullet2.run(SKAction.sequence([SKAction.moveBy(x: -1, y: -size.height, duration: 1),                SKAction.removeFromParent()]))
        }
    }

    //
    // Increase the score
    func increaseScoreBy(_ increment: Int) {
        score += increment
        updateScore()
        scoreLabel.run(textFlashAction)
    }

    func updateScore() {
        scoreLabel.text = "Score: \(score)"
        scoreLabel.removeAllActions()
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
