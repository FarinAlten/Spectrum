//
//  PlaybackManager.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
//
import Foundation
import AVFoundation
import MediaPlayer
import Observation
import AppKit

@Observable
@MainActor
final class PlaybackManager {
    // MARK: - Properties
    var currentStation: RadioStation?
    var isPlaying = false
    var isLoadingStation = false
    
    private let sharedAudioPlayer = AVPlayer()
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private var playerItemObserver: NSKeyValueObservation?
    
    // MARK: - Init
    init() {
        setupRemoteCommandCenter()
        sharedAudioPlayer.automaticallyWaitsToMinimizeStalling = true
        nowPlayingInfoCenter.playbackState = .paused
    }
    
    // MARK: - Public Control Methods
    func play(station: RadioStation) {
        self.currentStation = station
        self.isLoadingStation = true
        
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
        
        guard let secureUrl = URL(string: urlString) else {
            self.isLoadingStation = false
            return
        }
        
        let options: [String: Any] = [
            "AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"],
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ]
        
        let asset = AVURLAsset(url: secureUrl, options: options)
        let playerItem = AVPlayerItem(asset: asset)
        
        playerItem.preferredForwardBufferDuration = 5
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        // KVO-Observer für den Ladezustand des aktuellen Audio-Items
        playerItemObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            Task { @MainActor in
                if item.status == .readyToPlay {
                    self?.isLoadingStation = false
                } else if item.status == .failed {
                    self?.isLoadingStation = false
                    self?.isPlaying = false
                }
            }
        }
        
        sharedAudioPlayer.replaceCurrentItem(with: playerItem)
        sharedAudioPlayer.play()
        
        self.isPlaying = true
        nowPlayingInfoCenter.playbackState = .playing
        
        updateNowPlaying(station: station, artwork: nil)
        
        if !station.favicon.isEmpty, let url = URL(string: station.favicon) {
            Task {
                if let artwork = await fetchArtwork(from: url) {
                    self.updateNowPlaying(station: station, artwork: artwork)
                }
            }
        }
    }
    
    func togglePlayback() {
        guard sharedAudioPlayer.currentItem != nil else { return }
        
        if isPlaying {
            sharedAudioPlayer.pause()
            isPlaying = false
            nowPlayingInfoCenter.playbackState = .paused
            isLoadingStation = false
        } else {
            sharedAudioPlayer.play()
            isPlaying = true
            nowPlayingInfoCenter.playbackState = .playing
            if sharedAudioPlayer.currentItem?.status != .readyToPlay {
                isLoadingStation = true
            }
        }
        
        if let station = currentStation {
            updateNowPlayingStatusOnly(station: station)
        }
    }
    
    // MARK: - Private Helper Methods
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.togglePlayback()
                return .success
            }
            return .noActionableNowPlayingItem
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.togglePlayback()
                return .success
            }
            return .noActionableNowPlayingItem
        }
    }
    
    private func updateNowPlaying(station: RadioStation, artwork: MPMediaItemArtwork?) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = station.name
        info[MPMediaItemPropertyArtist] = "Live Radio"
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        
        if let artwork = artwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = info
    }
    
    private func updateNowPlayingStatusOnly(station: RadioStation) {
        if var info = nowPlayingInfoCenter.nowPlayingInfo {
            info[MPNowPlayingInfoPropertyIsLiveStream] = true
            nowPlayingInfoCenter.nowPlayingInfo = info
        } else {
            updateNowPlaying(station: station, artwork: nil)
        }
    }
    
    private func fetchArtwork(from url: URL) async -> MPMediaItemArtwork? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            #if os(iOS)
            if let image = UIImage(data: data) {
                return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            }
            #elseif os(macOS)
            if let image = NSImage(data: data) {
                return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            }
            #endif
        } catch {
            print("Fehler beim Laden des Artworks: \(error)")
        }
        return nil
    }
}
