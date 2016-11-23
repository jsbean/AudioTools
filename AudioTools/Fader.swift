//
//  Fader.swift
//  AudioTools
//
//  Created by James Bean on 11/22/16.
//
//

import AudioKit

public final class Fader {
    
    public typealias Seconds = Double
    
    private let audioPlayer: AKAudioPlayer
    
    private var timer: Timer!
    private var timeGrain: Seconds
    private var interpolationIsInProgress: Bool = false
    
    public init(audioPlayer: AKAudioPlayer, timeGrain: Seconds = 1/20) {
        self.audioPlayer = audioPlayer
        self.timeGrain = timeGrain
    }
    
    public func fadeOut(over duration: Seconds = 1.0) {
        fade(to: 0, over: duration)
    }
    
    // TODO: Consider adding to master `Timeline`.
    public func fade(to destinationVolume: Double, over duration: Seconds) {
        
        let startVolume = audioPlayer.volume
        let deltaVolume = destinationVolume - startVolume
        let numberOfSteps = duration / timeGrain
        let volumeGrain = deltaVolume / numberOfSteps
        
        engageTimer(withVolumeGrain: volumeGrain)
    }
    
    public func engageTimer(withVolumeGrain volumeGrain: Double) {
        
        self.timer = Timer.scheduledTimer(timeInterval: 1/20,
            target: self,
            selector: #selector(adjustVolume),
            userInfo: volumeGrain,
            repeats: true
        )
        
        interpolationIsInProgress = true
    }
    
    @objc public func adjustVolume(_ sender: Timer) {
        
        guard let amount = sender.userInfo as? Double else {
            return
        }
        
        abortInterpolationIfNecessary()
        audioPlayer.volume += amount
    }
    
    private func abortInterpolationIfNecessary() {
        
        guard interpolationIsInProgress && audioPlayer.volume <= 0 else {
            return
        }
        
        timer.invalidate()
        interpolationIsInProgress = false
    }
}
