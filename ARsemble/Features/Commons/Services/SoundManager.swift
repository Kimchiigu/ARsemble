//
//  SoundManager.swift
//  ARsemble
//
//  Created by Muhammad Hafizh Raihan Daniswara on 16/08/26.
//

import AVFoundation

final class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?
    private var musicPlayer: AVAudioPlayer?
    
    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error.localizedDescription)")
        }
    }
    
    func playSound(named soundName: String, extension soundExtension: String = "mp3") {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: soundExtension) else {
            print("Audio file \(soundName).\(soundExtension) not found.")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    func playBackgroundMusic(named soundName: String, extension soundExtension: String = "mp3") {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: soundExtension) else {
            print("Music file \(soundName).\(soundExtension) not found.")
            return
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
        } catch {
            print("Error playing background music: \(error.localizedDescription)")
        }
    }
    
    func stopBackgroundMusic() {
        musicPlayer?.stop()
    }
}
