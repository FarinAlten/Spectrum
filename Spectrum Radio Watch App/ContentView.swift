//
//  WatchContentView.swift
//  SpectrumWatch
//
//  Created by Farin on 8/11/26.
//

import SwiftUI
import SwiftData

struct WatchContentView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(RadioAPIClient.self) private var apiClient
    @Query(sort: \FavoriteStation.name) private var favorites: [FavoriteStation]
    
    private var connectivity = WatchConnectivityManager.shared

    var body: some View {
        NavigationStack {  
            List {
                // Sektion: Live-Status / iPhone Erkennung
                if let iPhoneStation = connectivity.iPhoneStationName {
                    Section(header: Text("Auf iPhone aktiv")) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(iPhoneStation)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(connectivity.isPhonePlaying ? "Wird abgespielt" : "Pausiert")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                connectivity.sendCommand("togglePlayback")
                            }) {
                                Image(systemName: connectivity.isPhonePlaying ? "pause.fill" : "play.fill")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Sektion: Lokaler Watch Player
                if let station = playbackManager.currentStation {
                    Section(header: Text("Auf Watch aktiv")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(station.name)
                                .font(.headline)
                                .lineLimit(1)
                            
                            HStack {
                                Button(action: { playbackManager.togglePlayback() }) {
                                    Label(
                                        playbackManager.isPlaying ? "Pause" : "Play",
                                        systemImage: playbackManager.isPlaying ? "pause.circle.fill" : "play.circle.fill"
                                    )
                                }
                                .tint(.accentColor)
                            }
                        }
                    }
                }

                // Sektion: Lokale SwiftData Favoriten
                Section(header: Text("Favoriten")) {
                    if favorites.isEmpty {
                        Text("Keine Favoriten vorhanden")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(favorites) { favorite in
                            Button(action: {
                                let station = RadioStation(
                                    id: favorite.id,
                                    name: favorite.name,
                                    url: favorite.url.absoluteString,
                                    favicon: favorite.favicon,
                                    tags: favorite.tags
                                )
                                playbackManager.play(station: station)
                            }) {
                                VStack(alignment: .leading) {
                                    Text(favorite.name)
                                        .font(.body)
                                        .lineLimit(1)
                                    if !favorite.tags.isEmpty {
                                        Text(favorite.tags)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Spectrum")
        }
    }
}

