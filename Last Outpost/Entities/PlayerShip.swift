//
//  PlayerShip.swift
//  Last Outpost
//
//  Created by George McMullen on 8/30/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit

class PlayerShip: Entity {
    
    let ventingPlasma:SKEmitterNode = SKEmitterNode(fileNamed: "ventingPlasma.sks")!
    let damageEmitter:SKEmitterNode = SKEmitterNode(fileNamed: "ventingPlasma.sks")!
    let startShowingPlasma = 30.0  // Health value to start showing the plasma affect
    
    init(entityPosition: CGPoint) {
        let entityTexture = PlayerShip.generateTexture()!
        
        super.init(position: entityPosition, texture: entityTexture)
        
        name = EntityClassName.PlayerShip.rawValue
        
        entitySize = Size.Normal
        collisionDamage = 5 // This is the collision damage if we run into something
        
        // Details on how the Sprite Kit physics engine works can be found in the book in
        // Chapter 9, "Beginner Physics"
        if #available(iOS 10.0, *) {
           // self.scale(to: CGSize(width: 64, height: 64))
            self.setScale(1)
        } else {
            // Fallback on earlier versions
            self.setScale(1)
        }

        configureCollisionBody()
        ventingPlasma.isHidden = true
        damageEmitter.isHidden = true

        self.addChild(ventingPlasma)
        self.addChild(damageEmitter)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override class func generateTexture() -> SKTexture? {
        // 1
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken = "playerShip"
        }
        
        DispatchQueue.once(token: SharedTexture.onceToken) {
            // Use an image for the ship
//            let spaceshipSprite = SKSpriteNode(imageNamed: "Spaceship")
//            SharedTexture.texture = textureView.textureFromNode(mainShip)!
            // Use ASCII for the ship
            let mainShip = SKLabelNode(fontNamed: "Arial")
            mainShip.name = "mainship"
            mainShip.fontSize = 30
            mainShip.fontColor = SKColor.white
            mainShip.text = "▲"
            // 3
            let wings = SKLabelNode(fontNamed: "PF Tempesta Seven")
            wings.name = "wings"
            wings.fontSize = 30
            wings.text = "<•>"
            //wings.text = "≤ ≥"
            wings.fontColor = SKColor.white
            wings.position = CGPoint(x: 1, y: 7)
            // 4
            wings.yScale = 1.0
            wings.xScale = 0.75
            wings.zRotation = CGFloat(180).degreesToRadians()
            wings.zPosition = mainShip.zPosition - 1

            let forwardGuns = SKLabelNode(fontNamed: "PF Tempesta Seven")
            forwardGuns.name = "guns"
            forwardGuns.fontSize = 30
            // wings.text = "< >"
            forwardGuns.text = "∏"
            forwardGuns.fontColor = SKColor.blue
            forwardGuns.position = CGPoint(x: 0, y: 10)
            forwardGuns.yScale = 0.75
            forwardGuns.xScale = 2.0
            // 4
            forwardGuns.zRotation = CGFloat(180).degreesToRadians()
            forwardGuns.zPosition = mainShip.zPosition - 2
            forwardGuns.isHidden = false
            
            let rearGuns = SKLabelNode(fontNamed: "PF Tempesta Seven")
            rearGuns.name = "guns"
            rearGuns.fontSize = 30
            // wings.text = "< >"
            rearGuns.text = "∏"
            rearGuns.fontColor = SKColor.orange
            rearGuns.position = CGPoint(x: 0, y: -24)
            rearGuns.yScale = 0.75
            rearGuns.xScale = 1.5
            // 4
            rearGuns.zRotation = CGFloat(0).degreesToRadians()
            rearGuns.zPosition = mainShip.zPosition - 2
            rearGuns.isHidden = false;
            
            let decoration = SKLabelNode(fontNamed: "PF Tempesta Seven")
            decoration.alpha = 1.0
            decoration.name = "guns"
            decoration.fontSize = 20
            // wings.text = "< >"
            decoration.text = "▲"
            decoration.fontColor = SKColor.darkGray
            decoration.position = CGPoint(x: 1, y: 2)
            decoration.yScale = 1.0
            decoration.xScale = 1.0
            // 4
            decoration.zPosition = mainShip.zPosition + 1

            mainShip.addChild(forwardGuns)
            mainShip.addChild(rearGuns)
            mainShip.addChild(wings)
            mainShip.addChild(decoration)
            // 5
            let textureView = SKView()
            
            SharedTexture.texture =
                textureView.texture(from: mainShip)!
            SharedTexture.texture.filteringMode = .nearest
        }
        return SharedTexture.texture
    }
    
    func configureCollisionBody() {
        // Set up the physics body for this entity using a circle around the ship
        // physicsBody = SKPhysicsBody(circleOfRadius: self.size.width/2)
        // Using this method results in the ship registering a collision for every pixel hit.
        // physicsBody = SKPhysicsBody(texture: self.texture!, size: self.size)
        let path = CGMutablePath()
        path.addLines(between: [CGPoint(x: -self.size.width/2, y: -self.size.height/2),
                                CGPoint(x: self.size.width/2, y: -self.size.height/2),
                                CGPoint(x: self.size.width/20, y: self.size.height/2),
                                CGPoint(x: -self.size.width/2, y: -self.size.height/2)])
        path.closeSubpath()
        physicsBody = SKPhysicsBody(polygonFrom: path)

        
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
        physicsBody!.contactTestBitMask = ColliderType.Enemy | ColliderType.EnemyBullet
    }
    
    override func collidedWith(_ body: SKPhysicsBody, contact: SKPhysicsContact, damage: Int = 5) {
        // This method is called from GameScene didBeginContact(contact:) when the player entity
        // hits an enemy entity. When that happens the players health is reduced by 'n'' and a check
        // makes sure that the health cannot drop below zero
        let mainScene = scene as! GameScene
        mainScene.playExplodeSound()
        
        health -= Double(damage)
        if health < 0 {
            health = 0
        }
        
        if (health <= startShowingPlasma) {
            ventingPlasma.isHidden = false
            // Show the plasma as a % of the damage taken
            ventingPlasma.alpha = CGFloat((1.0 - (health / startShowingPlasma)))
        }
            
        damageEmitter.setScale(CGFloat(1.0))
        damageEmitter.isHidden = false
        damageEmitter.alpha = 0.9
        damageEmitter.run(SKAction.sequence([SKAction.fadeOut(withDuration: 1.0),SKAction.hide()]))
        damageEmitter.resetSimulation()
        
        mainScene.playExplodeSound()
    }
    
    //
    // Creates the engine flame.  This method uses the size of the ship to calculate the size of the flame so it should scale
    // automatically if you resize the ship.
    func createEngine() {
        // Use the engine animation graphic
        let engineEmitter = SKEmitterNode(fileNamed: "engine.sks")
        // Position it
        engineEmitter!.position = CGPoint(x: 0, y: -20)
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
