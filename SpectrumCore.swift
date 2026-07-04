//
//  SpectrumCore.swift
//  Spectrum
//
//  Created by Farin  on 7/4/26.
//
//
import Foundation
import SwiftData
import SwiftUI
import AVFoundation
import MediaPlayer

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - 1. SWIFTDATA MODELS

@Model
final class FavoriteStation {
    @Attribute(.unique) var id: String
    var name: String
    var url: URL
    var favicon: String
    var tags: String
    var createdAt: Date

    init(id: String, name: String, url: URL, favicon: String, tags: String) {
        self.id = id
        self.name = name
        self.url = url
        self.favicon = favicon
        self.tags = tags
        self.createdAt = Date()
    }
    
    convenience init(from station: RadioStation) {
        let stationURL = URL(string: station.url) ?? URL(string: "about:blank")!
        
        self.init(
            id: station.id,
            name: station.name,
            url: stationURL,
            favicon: station.favicon,
            tags: station.tags
        )
    }
}

// MARK: - 2. DATA MODELS & STRUCTURES

struct StationGroup: Identifiable, Hashable {
    let id: String // Name des Hauptsenders
    let mainStation: RadioStation
    var subStations: [RadioStation]
}

struct APICountry: Codable {
    let name: String
}

struct APITag: Codable {
    let name: String
    let stationcount: Int
}

struct SelectedCategory: Hashable {
    let name: String
    let type: RadioAPIClient.CategoryType
}

struct RadioStation: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let url: String
    let favicon: String
    let tags: String
    let clickcount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "stationuuid"
        case name
        case url
        case favicon
        case tags
        case clickcount
    }
}

struct Station: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let url: URL
    let favicon: String?
    let tags: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "stationuuid"
        case name
        case url
        case favicon
        case tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        let urlString = try container.decode(String.self, forKey: .url)
        if let decodedURL = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) {
            self.url = decodedURL
        } else {
            throw DecodingError.dataCorruptedError(forKey: .url, in: container, debugDescription: "Ungültige Stream-URL")
        }
        
        self.favicon = try container.decodeIfPresent(String.self, forKey: .favicon)
        self.tags = try container.decodeIfPresent(String.self, forKey: .tags)
    }
}

extension Station {
    init(id: String, name: String, url: URL, favicon: String?, tags: String?) {
        self.id = id
        self.name = name
        self.url = url
        self.favicon = favicon
        self.tags = tags
    }
}

// MARK: - 3. PLAYBACK MANAGER

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
                if let artwork = await fetchArtwork(from: url) {
                    await MainActor.run {
                        self.updateNowPlaying(station: station, artwork: artwork)
                    }
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
            print("Fehler beim Laden des Kontrollzentrum-Covers: \(error)")
        }
        return nil
    }
    
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

// MARK: - 4. RADIO API CLIENT

@Observable
final class RadioAPIClient {
    var countries: [String] = []
    var genres: [String] = []
    var stations: [RadioStation] = []
    var searchResults: [RadioStation] = []
    var isLoading = false
    
    enum CategoryType: Hashable {
        case country
        case genre
        case search
    }
    
    private var baseURL: URL {
        return URL(string: "https://de1.api.radio-browser.info/json")!
    }
    
    private var apiSession: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": "SpectrumRadioApp/1.0",
            "Accept": "application/json"
        ]
        configuration.timeoutIntervalForRequest = 10.0
        return URLSession(configuration: configuration)
    }
    
    func fetchDiscoverData() async {
        guard !isLoading else { return }
        await MainActor.run { self.isLoading = true }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchCountries() }
            group.addTask { await self.fetchGenres() }
        }
        
        await MainActor.run { self.isLoading = false }
    }
    
    private func fetchCountries() async {
        guard let url = URL(string: "\(baseURL.absoluteString)/countries") else { return }
        do {
            let (data, _) = try await apiSession.data(from: url)
            let apiCountries = try JSONDecoder().decode([APICountry].self, from: data)
            await MainActor.run {
                self.countries = apiCountries
                    .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .sorted()
            }
        } catch {
            print("Fehler beim Laden der Länder: \(error)")
        }
    }
    
    private func fetchGenres() async {
        guard let url = URL(string: "\(baseURL.absoluteString)/tags") else { return }
        do {
            let (data, _) = try await apiSession.data(from: url)
            let apiTags = try JSONDecoder().decode([APITag].self, from: data)
            await MainActor.run {
                self.genres = apiTags
                    .filter { $0.stationcount > 100 }
                    .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .sorted()
            }
        } catch {
            print("Fehler beim Laden der Genres: \(error)")
        }
    }
    
    func fetchStations(for value: String, type: CategoryType) async {
        guard type != .search else { return }
        await MainActor.run { self.isLoading = true }
        
        let endpoint: String
        switch type {
        case .country:
            endpoint = "bycountry"
        case .genre:
            endpoint = "bytag"
        case .search:
            await MainActor.run { self.isLoading = false }
            return
        }
        
        guard let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL.absoluteString)/stations/\(endpoint)/\(encodedValue)?order=clickcount&reverse=true&hidebroken=true") else {
            await MainActor.run { self.isLoading = false }
            return
        }
        
        do {
            let (data, _) = try await apiSession.data(from: url)
            let decodedStations = try JSONDecoder().decode([RadioStation].self, from: data)
            await MainActor.run {
                self.stations = decodedStations
                self.isLoading = false
            }
        } catch {
            print("Fehler beim Laden der Stationen: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
    
    func searchStations(matching query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                self.searchResults = []
                self.isLoading = false
            }
            return
        }
        
        await MainActor.run { self.isLoading = true }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL.absoluteString)/stations/byname/\(encodedQuery)") else {
            await MainActor.run { self.isLoading = false }
            return
        }
        
        do {
            let (data, _) = try await apiSession.data(from: url)
            let decodedResults = try JSONDecoder().decode([RadioStation].self, from: data)
            
            let sortedResults = decodedResults.sorted { $0.clickcount > $1.clickcount }
            
            await MainActor.run {
                self.searchResults = sortedResults
                self.isLoading = false
            }
        } catch {
            print("Fehler bei der Sendersuche: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}
