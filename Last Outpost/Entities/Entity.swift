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
    
    //
    // It's imporatant that we use standarized names for the entities since we use this to determine what entity was collided
    // with.  If the names don't match in the collision detection method, then we won't be able to register a collision
    // with this entity.
    enum EntityClassName: String {
        case PlayerShip = "PlayerShip"
        case EnemyShip = "EnemyShip"
        case PlayerBullet = "PlayerBullet"
        case EnemyBullet = "EnemyBullet"
    }
    
    //
    // We use the size to determine the size of the special effects
    enum Size: Double {
        case Tiny = 0.1
        case Small = 0.25
        case Medium = 0.5
        case Normal = 1.0
        case Large = 1.5
        case VeryLarge = 2.0
        case Huge = 3.0
    }
    
    var direction = CGPoint.zero
    var health = 100.0
    var maxHealth = 100.0
    var score: Int = 0
    var funds: Int = 0
    var lives: Int = 1  // Number of times to respawn
    var collisionDamage: Int = 1
    var entitySize: Size = .Normal
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
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
