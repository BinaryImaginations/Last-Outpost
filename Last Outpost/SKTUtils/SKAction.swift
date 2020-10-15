//
//  SKAction.swift
//  Last Outpost
//
//  Created by George McMullen on 9/1/18.
//  Copyright © 2018 George McMullen. All rights reserved.
//

import SpriteKit
import AVFoundation


public extension SKAction {
    class func playSoundFileNamed(fileName: String, atVolume: Float, waitForCompletion: Bool) -> SKAction {
        
        do {
            let player: AVAudioPlayer = try AVAudioPlayer(data: BundleAudioBuffer.get(fileName)!)
            player.volume = atVolume
            player.prepareToPlay()
            let playAction = SKAction.run {
                player.play()
            }
            if(waitForCompletion){
                let waitAction = SKAction.wait(forDuration: player.duration)
                let groupAction: SKAction = SKAction.group([playAction, waitAction])
                return groupAction
            }
            return playAction
        } catch let error {
            debugPrint("\(fileName) caused: \(error.localizedDescription)")
        }
        return .run{}
    }
}

class BundleAudioBuffer{
    
    static var buffer=[String:Data]()
    
    static func addtobuffer(_ file:String) {
        if buffer[file] != nil {
            return
        }
        
        let nameOnly = (file as NSString).deletingPathExtension
        let fileExt  = (file as NSString).pathExtension
        
        let soundPath = Bundle.main.url(forResource: nameOnly, withExtension: fileExt)
        let audio = try! Data(contentsOf: soundPath!)
        buffer[file]=audio as Data?
    }
    
    static func get(_ file:String) -> Data? {
        addtobuffer(file)
        if buffer[file] != nil {
            return buffer[file]!
        }
        return nil
    }
    
}
