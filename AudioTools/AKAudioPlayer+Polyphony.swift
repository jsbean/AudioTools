//
//  AKAudioPlayer+Polyphony.swift
//  AudioTools
//
//  Created by James Bean on 11/22/16.
//
//

import AudioKit

extension AKAudioPlayer {
    
    public var isDonePlaying: Bool {
        return currentTime > duration || isStopped
    }
    
    public var isAvailable: Bool {
        return isDonePlaying
    }
    
    
}
