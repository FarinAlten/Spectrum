//
//  StatioGridView.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
//
import SwiftUI

struct StationGridView: View {
    let categoryName: String
    let categoryType: RadioAPIClient.CategoryType
    
    @Environment(RadioAPIClient.self) private var apiClient
    @Environment(PlaybackManager.self) private var playbackManager
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    private var backgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(UIColor.secondarySystemBackground)
        #endif
    }
    
    private var targetStations: [RadioStation] {
        categoryType == .search ? apiClient.searchResults : apiClient.stations
    }
    
    var body: some View {
        ScrollView {
            if apiClient.isLoading {
                ProgressView()
                    .padding(.top, 40)
            } else if targetStations.isEmpty {
                Text(LocalizedStringKey("no_stations_found"))
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(targetStations) { station in
                        Button(action: {
                            playbackManager.play(station: station)
                        }) {
                            VStack {
                                AsyncImage(url: URL(string: station.favicon)) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fit)
                                    } else {
                                        Image(systemName: "radio")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)
                                
                                Text(station.name)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(backgroundColor)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(categoryName)
        .task {
            if categoryType != .search {
                await apiClient.fetchStations(for: categoryName, type: categoryType)
            }
        }
    }
}
