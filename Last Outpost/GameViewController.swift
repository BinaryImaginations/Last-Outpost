//
//  GameViewController.swift
//  Last Outpost
//
//  Created by George McMullen on 8/28/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//
import UIKit
import SpriteKit

class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = GameScene(size: CGSize(width: 768, height: 1024))
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
//        skView.preferredFramesPerSecond = 30
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
