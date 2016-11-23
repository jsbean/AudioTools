//
//  AKAudioPlayer+Fader.swift
//  AudioTools
//
//  Created by James Bean on 11/22/16.
//
//

import AudioKit

extension AKAudioPlayer {
    
    public func fadeOut(over duration: Double) {
        Fader(audioPlayer: self).fadeOut(over: duration)
    }
}
