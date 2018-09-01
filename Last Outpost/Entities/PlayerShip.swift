//
//  PlayerShip.swift
//  Last Outpost
//
//  Created by George McMullen on 8/30/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

class PlayerShip: Entity {
    
    init(entityPosition: CGPoint) {
        let entityTexture = PlayerShip.generateTexture()!
        
        super.init(position: entityPosition, texture: entityTexture)
        
        name = "playerShip"
        
        collisionDamage = 5 // This is the collision damage if we run into something
        
        // Details on how the Sprite Kit physics engine works can be found in the book in
        // Chapter 9, "Beginner Physics"
        if #available(iOS 10.0, *) {
            self.scale(to: CGSize(width: 64, height: 64))
        } else {
            // Fallback on earlier versions
            self.setScale(0.25)
        }
        configureCollisionBody()
        ventingPlasma.isHidden = true
        //        damageEmitter.hidden = true
        self.addChild(ventingPlasma)
        //        self.addChild(damageEmitter)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    let ventingPlasma:SKEmitterNode = SKEmitterNode(fileNamed: "ventingPlasma.sks")!
    //    let damageEmitter:SKEmitterNode = SKEmitterNode(fileNamed: "ventingPlasma.sks")!
    
    override class func generateTexture() -> SKTexture? {
        // 1
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken = "playerShip"
        }
        
        DispatchQueue.once(token: SharedTexture.onceToken) {
            let spaceshipSprite = SKSpriteNode(imageNamed: "Spaceship")
            SharedTexture.texture = spaceshipSprite.texture!
            SharedTexture.texture.filteringMode = .nearest
        }
        
        return SharedTexture.texture
    }
    
    func configureCollisionBody() {
        // Set up the physics body for this entity using a circle around the ship
        physicsBody = SKPhysicsBody(circleOfRadius: self.size.width/2)
        
        // There is no gravity in the game so it shoud be switched off for this physics body
        physicsBody!.affectedByGravity = false
        
        // Specify the type of physics body this is using the ColliderType defined in the Entity
        // class. This tells the physics engine that this entity is the player
        physicsBody!.categoryBitMask = ColliderType.Player
        
        // We don't want the physics engine applying it's own effects when physics body collide so
        // we switch it off
        physicsBody!.collisionBitMask = 0
        
        // Specify physics bodies we want this entity to be able to collide with. Specifying Enemy
        // means that the physics collision method inside GameScene will be called when this entity
        // collides with an Entity that is marked as ColliderType.Enemy
        physicsBody!.contactTestBitMask = ColliderType.Enemy
    }
    
    override func collidedWith(_ body: SKPhysicsBody, contact: SKPhysicsContact, damage: Int = 5) {
        // This method is called from GameScene didBeginContact(contact:) when the player entity
        // hits an enemy entity. When that happens the players health is reduced by 5 and a check
        // makes sure that the health cannot drop below zero
        let mainScene = scene as! GameScene
        mainScene.playExplodeSound()
        
        health -= Double(damage)
        if health < 0 {
            health = 0
        }
        
        ventingPlasma.isHidden = health > 30
        
        //        damageEmitter.setScale(CGFloat(1.5))
        //        damageEmitter.hidden = false
        //        damageEmitter.alpha = 1.0
        //        damageEmitter.runAction(SKAction.sequence([SKAction.fadeOutWithDuration(1.0),SKAction.hide()]))
        //        damageEmitter.resetSimulation()
        
        mainScene.playExplodeSound()
    }
    
    //
    // Creates the engine flame.  This method uses the size of the ship to calculate the size of the flame so it should scale
    // automatically if you resize the ship.
    func createEngine() {
        // Use the engine animation graphic
        let engineEmitter = SKEmitterNode(fileNamed: "engine.sks")
        // Position it
        engineEmitter!.position = CGPoint(x: 1, y: -4)
        engineEmitter!.name = "engineEmitter"
        // Set the width and height based upon the size of the ship
        engineEmitter!.particleSize = CGSize(width: self.size.width/4, height: self.size.height)
        // Add this to the main screen
        addChild(engineEmitter!)
        // Get a copy of the game scene
        let mainScene = scene as! GameScene
        // and then add this to the bottom layer so that it sits beneith the ship
        engineEmitter!.targetNode = mainScene.starfieldLayerNode
    }
    
}
