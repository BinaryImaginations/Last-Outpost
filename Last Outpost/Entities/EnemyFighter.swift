//
//  EnemyFighter.swift
//  Last Outpost
//
//  Created by George McMullen on 8/31/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

class EnemyFighter: Enemy, SKPhysicsContactDelegate {
    
    override class func generateTexture() -> SKTexture? {
        
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken = "Fighter"
        }
        // See extension in Entity.swift
        DispatchQueue.once(token: SharedTexture.onceToken) {
            let mainShip:SKLabelNode = SKLabelNode(fontNamed: "Arial")
            mainShip.name = "mainship"
            mainShip.fontSize = 25
            mainShip.fontColor = SKColor.yellow
            mainShip.text = "(x⚇x)"
            
            let textureView = SKView()
            SharedTexture.texture = textureView.texture(from: mainShip)!
            SharedTexture.texture.filteringMode = .nearest
        }
        
        return SharedTexture.texture
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(entityPosition: CGPoint, playableRect: CGRect) {
        self.init(entityPosition: entityPosition, playableRect: playableRect, color: SKColor(red: 0.5, green: 1, blue: 1, alpha: 1))
    }
    
    init(entityPosition: CGPoint, playableRect: CGRect, color: SKColor) {
        
        let entityTexture = EnemyFighter.generateTexture()!
        super.init(entityPosition: entityPosition, texture: entityTexture, playableRect: playableRect)
        
        name = EntityClassName.EnemyShip.rawValue
        score = 250
        funds = 50
        lives = 1
        collisionDamage = 5
        enemyClass = EnemyClass.fighter
        entitySize = Size.Normal
        
        Enemy.loadSharedAssets()
        configureCollisionBody()
        
        scoreLabel.name = "scoreLabel"
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = color
        scoreLabel.text = String(score)
        
        gunType = .RailGun  // No guns
        gunFireInterval = 3.0  // Fire the gun every 3 seconds
        gunBurstFireNumber = 1  // Fire a burst of 1
        gunBurstFireGovernor = 0.0  // Seperated by 0.0 seconds per round
        
        // Set a default waypoint. The actual waypoint will be called by whoever created this instance
        aiSteering = AISteering(entity: self, waypoint: CGPoint.zero)
        
        // Changing the maxVelicity and maxSteeringForce will change how an entity moves towards its waypoint.
        // Changing these values can generate some interesting movement effects
        aiSteering.maxVelocity = 15.0
        aiSteering.maxSteeringForce = 0.4
    }
}
