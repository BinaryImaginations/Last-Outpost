//
//  EnemyBulletStatic.swift
//  Last Outpost
//
//  Created by George McMullen on 9/2/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

class EnemyBulletStaticGun: Bullet {
    
    init(entityPosition: CGPoint) {
        let entityTexture = EnemyBulletStaticGun.generateTexture()!
        
        super.init(position: entityPosition, texture: entityTexture)
        
        name = EntityClassName.EnemyBullet.rawValue
        
        collisionDamage = 25
        damage = 25
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
            static var onceToken = "enemyBulletStatic"
        }
        
        DispatchQueue.once(token: SharedTexture.onceToken) {
            let bullet = SKLabelNode(fontNamed: "Arial")
            bullet.name = "enemyBulletRailGun"
            bullet.fontSize = 75
            bullet.fontColor = SKColor(red: 0.9, green: 0.9, blue: 1, alpha: 1)
            bullet.text = "*"
            
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
        physicsBody!.contactTestBitMask = ColliderType.Player | ColliderType.PlayerBullet
    }
    
    override func collidedWith(_ body: SKPhysicsBody, contact: SKPhysicsContact, damage: Int) {
        health -= Double(damage)
        if health <= 0 {
            removeFromParent()
        }
    }
    
}
