//
//  EnemySwarmer.swift
//  Last Outpost
//
//  Created by George McMullen on 8/31/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

class EnemySwarmer: Enemy, SKPhysicsContactDelegate {
    
    override class func generateTexture() -> SKTexture? {
        
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken = "Swarmer"
        }
        
        // See extension in Entity.swift
        DispatchQueue.once(token: SharedTexture.onceToken) {
            let mainShip:SKLabelNode = SKLabelNode(fontNamed: "Arial")
            mainShip.name = "mainship"
            mainShip.fontSize = 18
            mainShip.fontColor = SKColor.orange
            mainShip.text = "<⚉>"
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
        self.init(entityPosition: entityPosition, playableRect: playableRect, color: SKColor(red:0.5, green:1, blue:1, alpha:1))
    }

    init(entityPosition: CGPoint, playableRect: CGRect, color: SKColor) {
        
        let entityTexture = EnemySwarmer.generateTexture()!
        super.init(entityPosition: entityPosition, texture: entityTexture, playableRect: playableRect)
        
        name = EntityClassName.EnemyShip.rawValue
        score = 10
        funds = 10
        lives = 1
        collisionDamage = 3
        enemyClass = EnemyClass.mini
        entitySize = Size.Normal
        
        Enemy.loadSharedAssets()
        configureCollisionBody()
        
        scoreLabel.name = "scoreLabel"
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = color
        scoreLabel.text = String(score)

        gunType = .RailGun  // Use a rail gun
        gunFireInterval = 5.0  // Fire the gun every 5 seconds
        gunBurstFireNumber = 5  // Fire a burst of 5
        gunBurstFireGovernor = 0.05  // Seperated by 0.1 seconds per round
        
        // Set a default waypoint. The actual waypoint will be called by whoever created this instance
        aiSteering = AISteering(entity:self, waypoint:CGPoint.zero)
        
        // Changing the maxVelicity and maxSteeringForce will change how an entity moves towards its waypoint.
        // Changing these values can generate some interesting movement effects
        aiSteering.maxVelocity = 20.0
        aiSteering.maxSteeringForce = 0.75
    }
}

