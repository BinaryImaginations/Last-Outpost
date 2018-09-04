//
//  BulletRailGun.swift
//  Last Outpost
//
//  Created by George McMullen on 8/31/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

class BulletRailGun: Bullet {
    
    init(entityPosition: CGPoint) {
        let entityTexture = BulletRailGun.generateTexture()!
        
        super.init(position: entityPosition, texture: entityTexture)
        
        name = EntityClassName.PlayerBullet.rawValue

        collisionDamage = 1
        damage = 1
        configureCollisionBody()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override class func generateTexture() -> SKTexture? {
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken = "bulletRailGun"
        }
        
        DispatchQueue.once(token: SharedTexture.onceToken) {
            let bullet = SKLabelNode(fontNamed: "Arial")
            bullet.name = "bulletRailGun"
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
        physicsBody!.categoryBitMask = ColliderType.PlayerBullet
        physicsBody!.collisionBitMask = 0
        physicsBody!.contactTestBitMask = ColliderType.Enemy
    }
    
    override func collidedWith(_ body: SKPhysicsBody, contact: SKPhysicsContact, damage: Int) {
        removeFromParent()
    }
    
}
