//
//  Bullet.swift
//  Last Outpost
//
//  Created by George McMullen on 9/3/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import UIKit

class Bullet: Entity {
    enum BulletDirection {
        case Up
        case Down
    }
    
    var bulletDirection: BulletDirection = .Up
    var damage: Int = 1  // Default damage
}
