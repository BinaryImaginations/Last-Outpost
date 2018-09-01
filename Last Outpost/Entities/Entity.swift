//
//  Entity.swift
//  Last Outpost
//
//  Created by George McMullen on 8/30/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

class Entity: SKSpriteNode {
    
    struct ColliderType {
        static var Player: UInt32 = 1
        static var Enemy: UInt32 = 2
        static var PlayerBullet: UInt32 = 4
        static var EnemyBullet: UInt32 = 8
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var direction = CGPoint.zero
    var health = 100.0
    var maxHealth = 100.0
    var score = 0
    var funds = 0
    var lives = 1  // Number of times to respawn
    var collisionDamage = 1
    
    init(position: CGPoint, texture: SKTexture) {
        super.init(texture: texture, color: SKColor.white, size: texture.size())
        self.position = position
    }
    
    class func generateTexture() -> SKTexture? {
        // Overridden by subclasses
        return nil
    }
    
    func update(_ delta: TimeInterval) {
        // Overridden by subclasses
    }
    
    func collidedWith(_ body: SKPhysicsBody, contact: SKPhysicsContact, damage: Int) {
        // Overridden by subsclasses to implement actions to be carried out when an entity
        // collides with another entity e.g. PlayerShip or Bullet
    }
}

public extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    /* Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     * only execute the code once even in the presence of multithreaded calls.
     *
     * - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     * - parameter block: Block to execute once
     */
    class func once(token: String, block: () -> ()) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}
