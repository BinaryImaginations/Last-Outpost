//
//  BulletLaser.swift
//  Last Outpost
//
//  Created by George McMullen on 8/31/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

class BulletParticleLaser: Bullet {

    init(entityPosition: CGPoint) {
        let entityTexture = BulletParticleLaser.generateTexture()!

        super.init(position: entityPosition, texture: entityTexture)
        
        name = EntityClassName.PlayerBullet.rawValue
        
        entitySize = Size.Small
        collisionDamage = 2
        damage = 2
        configureCollisionBody()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override class func generateTexture() -> SKTexture? {
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken = "bulletParticleLaser"
        }
        
        DispatchQueue.once(token: SharedTexture.onceToken) {
            let bullet = SKLabelNode(fontNamed: "Arial")
            bullet.name = "bulletParticleLaser"
            bullet.fontSize = 35
            bullet.fontColor = SKColor.yellow
            bullet.text = "|"
            
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
