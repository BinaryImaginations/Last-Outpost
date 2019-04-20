//
//  enemyBullet.swift
//  Last Outpost
//
//  Created by George McMullen on 9/1/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

class EnemyBulletRailGun: Bullet {
    
    init(entityPosition: CGPoint) {
        let entityTexture = EnemyBulletRailGun.generateTexture()!
        
        super.init(position: entityPosition, texture: entityTexture)
        
        name = EntityClassName.EnemyBullet.rawValue
        
        entitySize = Size.Tiny
        collisionDamage = 1
        damage = 1
        health = 1
        maxHealth = 1

        configureCollisionBody()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override class func generateTexture() -> SKTexture? {
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken = "enemyBulletRailGun"
        }
        
        DispatchQueue.once(token: SharedTexture.onceToken) {
            let bullet = SKLabelNode(fontNamed: "Arial")
            bullet.name = "enemyBulletRailGun"
            bullet.fontSize = 30
            bullet.fontColor = SKColor.white
            bullet.text = "•"
            
            let textureView = SKView()
            SharedTexture.texture = textureView.texture(from: bullet)!
            SharedTexture.texture.filteringMode = .nearest
        }
        
        return SharedTexture.texture
    }
    
    func configureCollisionBody() {
        // Set the PlayerShip class for details of how the physics body configuration is used.
        // More details are provided in Chapter 9 "Beginner Physics" in the book also
        physicsBody = SKPhysicsBody(circleOfRadius:5)
        physicsBody!.affectedByGravity = false
        physicsBody!.categoryBitMask = ColliderType.EnemyBullet
        physicsBody!.collisionBitMask = 0
        physicsBody!.contactTestBitMask = ColliderType.Player
    }
    
    override func collidedWith(_ body: SKPhysicsBody, contact: SKPhysicsContact, damage: Int) {
        removeFromParent()
    }
    
}
