//
//  PolyphonicAudioPlayer.swift
//  AudioTools
//
//  Created by James Bean on 11/22/16.
//
//

import AudioKit

/// Source locations of audio files.
public typealias Directory = AKAudioFile.BaseDirectory

/// `PolyphonicAudioPlayer` manages the polyphonic playback of multiple audio files.
///
/// - note: You must prepare the audio file before playing it. This ensures that there is
///     not accumulated latency for managing files, buffers, etc.
///
/// **Example:**
///
/// ```
/// do {
///     let poly = try PolyphonicAudioPlayer(voices: 4)
///     try poly.prepare("sample1")
///     try poly.play("sample1")
///     try poly.prepare("sample2")
///     try poly.play("sample2")
///     // ...
///     try poly.stop("sample2")
///     // ...
///     try poly.stop("sample1")
/// } catch {
///     print(error)
/// }
/// ```
public final class PolyphonicAudioPlayer: AKMixer {
    
    /// Errors possible when attempting to start or stop audio files.
    public enum PlaybackError: Error {
        
        /// No players are available, because there are only so many `voices`.
        case noPlayersAvailable(voices: Int)
        
        /// No player is found with the given `name`.
        case playerNotFound(name: String)
    }
    
    /// - returns: The next available player, if one exists. Otherwise, `nil`.
    fileprivate var nextAvailablePlayer: AKAudioPlayer? {
        return players.filter { $0.isAvailable }.first
    }
    
    /// `AKAudioPlayer` objects stored by the name of the file they are playing.
    fileprivate var playerByName: [String: AKAudioPlayer] = [:]

    /// `AKAudioPlayer` objects available to play
    fileprivate let players: [AKAudioPlayer]
    
    /// Create a `PolyphonicAudioPlayer` with the given amount of voices.
    public init(voices: UInt = 3) throws {
        self.players = try audioPlayers(amount: voices)
        super.init()
        connectAudioPlayers()
    }
    
    /// - returns: The player playing the file with the given `name`, if one exists. Otherwise,
    ///     `nil`.
    public subscript(name: String) -> AKAudioPlayer? {
        return playerByName[name]
    }
    
    /// Begin the playback of the file with the given `name`.
    ///
    /// - throws: `PlaybackError` if a player is not found for the given `name`.
    public func play(name: String) throws {
        
        guard let player = playerByName[name] else {
            throw PlaybackError.playerNotFound(name: name)
        }
        
        player.start()
    }
    
    /// Stop the playback of the file with the given `name`.
    ///
    /// - throws: `PlaybackError` if a player is not found for the given `name`.
    public func stop(name: String) throws {
        
        guard let player = playerByName[name] else {
            throw PlaybackError.playerNotFound(name: name)
        }
        
        player.stop()
    }
    
    /// Stop the playback of all players contained herein.
    public func stopAll() {
        players.forEach { $0.stop() }
    }
    
    /// Prepare a player to play the file with the given `name`, coming from the given
    ///     `directory`, to be played at the given `volume`, and whether or not it `shouldLoop`.
    ///
    /// - throws: `PlaybackError` if no players are available to prepare, or 
    ///     `AudioKit`-specific errors if `AKAudioPlayer` configuration is not successful.
    public func prepare(
        name: String,
        directory: Directory = .documents,
        volume: Double = 1.0,
        shouldLoop: Bool = false
    ) throws
    {
        guard let player = nextAvailablePlayer else {
            throw PlaybackError.noPlayersAvailable(voices: players.count)
        }
        
        try configure(player: player,
            toPlay: name,
            from: directory,
            volume: volume,
            shouldLoop: shouldLoop
        )
        
        store(player, by: name)
    }
    
    /// Store the given `player` by the given `name`.
    private func store(_ player: AKAudioPlayer, by name: String) {
        playerByName[name] = player
    }
    
    // - MARK: Audio graph
    
    /// Connects all of the audio players to the output of this node.
    private func connectAudioPlayers() {
        players.forEach(connect)
    }
}

extension PolyphonicAudioPlayer: Collection {
    
    // MARK: - Collection
    
    /// - returns: The index after the given `i`.
    public func index(after i: Int) -> Int {
        return players.index(after: i)
    }
    
    /// - returns: The start index of the internal array of audio players.
    public var startIndex: Int {
        return players.startIndex
    }
    
    /// - returns: The end index of the internal array of audio players.
    public var endIndex: Int {
        return players.endIndex
    }
    
    /// - returns: The player at the given `index`.
    public subscript(index: Int) -> AKAudioPlayer {
        return players[index]
    }
}

/// Create the given `amount` of audio players, configured to play a default file.
private func audioPlayers(amount: UInt) throws -> [AKAudioPlayer] {
    return try (0..<amount).map { _ in
        return try AKAudioPlayer(file: file(name: "a440", directory: .documents))
    }
}

/// Configure a player to play an audio file with the given `name` and properties.
///
/// - throws: `AudioKit`-specific errors if `AKAudioPlayer` configuration is not
///     successful.
private func configure(player: AKAudioPlayer,
    toPlay name: String,
    from directory: Directory = .documents,
    volume: Double = 1.0,
    shouldLoop looping: Bool = false
) throws
{
    try player.replaceFile(file(name: name, directory: directory))
    player.volume = volume
    player.looping = looping
}

/// - throws: `AudioKit`-specific errors if `AKAudioFile` configuration is not successful.
///
/// - returns: The file with the given `name`, coming from the given `directory`.
private func file(name: String, directory: Directory = .documents) throws -> AKAudioFile {
    return try AKAudioFile(readFileName: name, baseDir: directory)
}
