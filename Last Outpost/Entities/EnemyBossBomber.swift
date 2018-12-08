//
//  EnemyBomber.swift
//  Last Outpost
//
//  Created by George McMullen on 8/31/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

class EnemyBossBomber: Enemy, SKPhysicsContactDelegate {
    
    override class func generateTexture() -> SKTexture? {
        
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken = "EnemyBossBomber"
        }
        
        // See extension in Entity.swift
        DispatchQueue.once(token: SharedTexture.onceToken) {
            let mainShip:SKLabelNode = SKLabelNode(fontNamed: "Arial")
            mainShip.name = "mainship"
            mainShip.fontSize = 33
            mainShip.fontColor = SKColor.black
            mainShip.text = "(-x=⚉=x-)"
            
            let textureView = SKView()
            SharedTexture.texture = textureView.texture(from: mainShip)!
            SharedTexture.texture.filteringMode = .nearest
        }
        
        return SharedTexture.texture
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(entityPosition: CGPoint, playableRect: CGRect) {
        
        let entityTexture = EnemyBossBomber.generateTexture()!
        super.init(entityPosition: entityPosition, texture: entityTexture, playableRect: playableRect)
        
        name = EntityClassName.EnemyShip.rawValue
        score = 500
        funds = 250
        lives = 1
        collisionDamage = 20
        enemyClass = EnemyClass.boss
        entitySize = Size.Large
        Enemy.loadSharedAssets()
        configureCollisionBody()
        
        scoreLabel.name = "scoreLabel"
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = SKColor(red:0.5, green:1, blue:1, alpha:1)
        scoreLabel.text = String(score)
        
        
        staticGun = true
        staticGunFireInterval = 1.0
        
        // Set a default waypoint. The actual waypoint will be called by whoever created this instance
        aiSteering = AISteering(entity:self, waypoint:CGPoint.zero)
        
        // Changing the maxVelicity and maxSteeringForce will change how an entity moves towards its waypoint.
        // Changing these values can generate some interesting movement effects
        aiSteering.maxVelocity = 9.0
        aiSteering.maxSteeringForce = 0.15
    }
}

