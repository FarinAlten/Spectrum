//
//  PlaybackManager.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
//
import Foundation
import AVFoundation
import MediaPlayer

#if os(iOS)
import UIKit
#endif

private let sharedAudioPlayer = AVPlayer()

@Observable
final class PlaybackManager {
    var currentStation: RadioStation?
    var isPlaying = false
    
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    
    init() {
        setupRemoteCommandCenter()
        sharedAudioPlayer.automaticallyWaitsToMinimizeStalling = true
        nowPlayingInfoCenter.playbackState = .paused
    }
    
    func play(station: RadioStation) {
        self.currentStation = station
        
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try audioSession.setActive(true)
        } catch {
            print("Fehler bei der Audio-Session-Initialisierung: \(error)")
        }
        #endif
        
        var urlString = station.url
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        
        guard let secureUrl = URL(string: urlString) else { return }
        
        let options: [String: Any] = [
            "AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"],
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ]
        
        let asset = AVURLAsset(url: secureUrl, options: options)
        let playerItem = AVPlayerItem(asset: asset)
        
        playerItem.preferredForwardBufferDuration = 5
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        sharedAudioPlayer.replaceCurrentItem(with: playerItem)
        sharedAudioPlayer.play()
        
        self.isPlaying = true
        nowPlayingInfoCenter.playbackState = .playing
        
        updateNowPlaying(station: station, artwork: nil)
        
        if !station.favicon.isEmpty, let url = URL(string: station.favicon) {
            Task {
                #if os(iOS)
                if let image = await downloadFavicon(from: url) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    await MainActor.run {
                        self.updateNowPlaying(station: station, artwork: artwork)
                    }
                }
                #endif
            }
        }
    }
    
    func togglePlayback() {
        guard sharedAudioPlayer.currentItem != nil else { return }
        
        if isPlaying {
            sharedAudioPlayer.pause()
            isPlaying = false
            nowPlayingInfoCenter.playbackState = .paused
        } else {
            sharedAudioPlayer.play()
            isPlaying = true
            nowPlayingInfoCenter.playbackState = .playing
        }
        
        if let station = currentStation {
            updateNowPlayingStatusOnly(station: station)
        }
    }
    
    private func updateNowPlaying(station: RadioStation, artwork: MPMediaItemArtwork?) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = station.name
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Live"
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        if let artwork = artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlayingStatusOnly(station: RadioStation) {
        if var info = nowPlayingInfoCenter.nowPlayingInfo {
            info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
            nowPlayingInfoCenter.nowPlayingInfo = info
        }
    }
    
    #if os(iOS)
    private func downloadFavicon(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Fehler beim Laden des Kontrollzentrum-Covers: \(error)")
            return nil
        }
    }
    #endif
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.togglePlayback()
            }
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.togglePlayback()
            }
            return .success
        }
    }
}
