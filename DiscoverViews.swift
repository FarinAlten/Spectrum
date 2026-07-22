//
//  DiscoverViews.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//
import SwiftUI
import SwiftData

struct SelectedCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: RadioAPIClient.CategoryType
}

struct DiscoverView: View {
    var apiClient: RadioAPIClient
    @Binding var categoryType: RadioAPIClient.CategoryType
    @Binding var searchText: String
    
    @Query(sort: \FavoriteStation.createdAt, order: .reverse) private var favoriteStations: [FavoriteStation]
    
    @AppStorage("preferredDisplayMode") private var preferredDisplayMode = "grid"
    @AppStorage("maxGridColumns") private var maxGridColumns = 4
    @AppStorage("showFlagsAndEmojis") private var showFlagsAndEmojis = true
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: maxGridColumns)
    }
    
    private var sectionHeaderTitle: String {
        categoryType == .country ? "Countries" : "Genres"
    }
    
    var body: some View {
        // HIER GEÄNDERT: Ein NavigationStack umschließt nun den Inhalt der Detail-Spalte
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !searchText.isEmpty {
                        // Suchergebnisse...
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suchergebnisse")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if apiClient.searchResults.isEmpty {
                                Text("Keine Sender gefunden")
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(apiClient.searchResults) { station in
                                        StationRow(station: station)
                                            .padding(.horizontal)
                                            .padding(.vertical, 8)
                                        Divider().padding(.leading, 56)
                                    }
                                }
                            }
                        }
                    } else {
                        // Favoriten (iOS)...
                        #if os(iOS)
                        if !favoriteStations.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Favorites")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                LazyVStack(spacing: 0) {
                                    FavoritesSectionView()
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                }
                                .background(Color(platformColor: .controlBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                        #endif
                        
                        // Grid / Listen Inhalt
                        VStack(alignment: .leading, spacing: 12) {
                            Text(sectionHeaderTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if preferredDisplayMode == "grid" {
                                LazyVGrid(columns: gridColumns, spacing: 12) {
                                    contentItems
                                }
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 0) {
                                    contentItems
                                }
                                .background(Color(platformColor: .controlBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(platformColor: .windowBackground))
            // Der Destination-Modifikator greift jetzt korrekt innerhalb des Stacks!
            .navigationDestination(for: SelectedCategory.self) { category in
                CategoryStationListView(category: category, apiClient: apiClient)
            }
        }
        .onChange(of: searchText) { _, newValue in
            Task { await apiClient.searchStations(matching: newValue) }
        }
        .task {
            if apiClient.countries.isEmpty || apiClient.genres.isEmpty {
                await apiClient.fetchDiscoverData()
            }
        }
    }
    
    @ViewBuilder
    private var contentItems: some View {
        switch categoryType {
        case .country:
            ForEach(apiClient.countries, id: \.self) { country in
                NavigationLink(value: SelectedCategory(name: country, type: .country)) {
                    if preferredDisplayMode == "grid" {
                        CategoryGridCard(
                            title: country,
                            visualElement: showFlagsAndEmojis ? countryFlag(for: country) : ""
                        )
                    } else {
                        CategoryListRow(
                            title: country,
                            visualElement: showFlagsAndEmojis ? countryFlag(for: country) : "",
                            accentColor: .blue
                        )
                    }
                }
                .buttonStyle(.plain)
            }
            
        case .genre:
            ForEach(apiClient.genres, id: \.self) { genre in
                NavigationLink(value: SelectedCategory(name: genre, type: .genre)) {
                    if preferredDisplayMode == "grid" {
                        CategoryGridCard(
                            title: genre,
                            visualElement: showFlagsAndEmojis ? genreEmoji(for: genre) : ""
                        )
                    } else {
                        CategoryListRow(
                            title: genre,
                            visualElement: showFlagsAndEmojis ? genreEmoji(for: genre) : "",
                            accentColor: .purple
                        )
                    }
                }
                .buttonStyle(.plain)
            }
        case .search:
            EmptyView()
        }
    }
    
    private func countryFlag(for country: String) -> String {
        switch country.lowercased() {
        case "germany", "deutschland": return "🇩🇪"
        case "united kingdom", "uk": return "🇬🇧"
        case "united states", "usa": return "🇺🇸"
        case "france", "frankreich": return "🇫🇷"
        case "italy", "italien": return "🇮🇹"
        case "spain", "spanien": return "🇪🇸"
        case "austria", "österreich": return "🇦🇹"
        case "switzerland", "schweiz": return "🇨🇭"
        default: return "🌍"
        }
    }
    
    private func genreEmoji(for genre: String) -> String {
        let g = genre.lowercased()
        if g.contains("rock") { return "🎸" }
        if g.contains("pop") { return "🎤" }
        if g.contains("jazz") { return "🎷" }
        if g.contains("electro") || g.contains("dance") { return "🕺" }
        if g.contains("classic") { return "🎻" }
        if g.contains("rap") || g.contains("hip") { return "🧢" }
        return "🎵"
    }
}

// MARK: - ZWEI UI-KOMPONENTEN
struct CategoryGridCard: View {
    let title: String
    let visualElement: String
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            if !visualElement.isEmpty {
                Text(visualElement)
                    .font(.system(size: 26))
            }
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(platformColor: .controlBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isHovered ? Color.primary.opacity(0.15) : Color.primary.opacity(0.04), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { hovering in isHovered = hovering }
    }
}

struct CategoryListRow: View {
    let title: String
    let visualElement: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            if !visualElement.isEmpty {
                Text(visualElement)
                    .font(.title3)
                    .frame(width: 24)
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        #if os(iOS)
        Divider().padding(.leading, 54)
        #endif
    }
}

// MARK: - Favoriten & Stations-Zeilen
struct FavoritesSectionView: View {
    @Query(sort: \FavoriteStation.createdAt, order: .reverse) private var favoriteStations: [FavoriteStation]
    @Environment(\.modelContext) private var modelContext
    @Environment(PlaybackManager.self) private var playbackManager
    
    var body: some View {
        ForEach(favoriteStations) { favorite in
            Button(action: {
                let station = RadioStation(id: favorite.id, name: favorite.name, url: favorite.url.absoluteString, favicon: favorite.favicon, tags: favorite.tags)
                playbackManager.play(station: station)
            }) {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: favorite.favicon)) { phase in
                        if let image = phase.image { image.resizable().aspectRatio(contentMode: .fit) }
                        else { Image(systemName: "radio").foregroundColor(.secondary) }
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(favorite.name).font(.body).fontWeight(.medium)
                        if !favorite.tags.isEmpty { Text(favorite.tags).font(.caption).foregroundColor(.secondary).lineLimit(1) }
                    }
                    Spacer()
                    if playbackManager.currentStation?.id == favorite.id && playbackManager.isPlaying {
                        Image(systemName: "waveform").foregroundColor(.blue).symbolEffect(.variableColor.iterative, options: .repeating)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) { modelContext.delete(favorite) } label: { Label("Entfernen", systemImage: "trash") }
            }
        }
    }
}

struct CategoryStationListView: View {
    let category: SelectedCategory
    var apiClient: RadioAPIClient
    
    var body: some View {
        List(apiClient.stations) { station in
            StationRow(station: station)
        }
        #if os(macOS)
        .listStyle(.inset)
        #else
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle(category.name)
        .task {
            await apiClient.fetchStations(for: category.name, type: category.type)
        }
    }
}

struct StationRow: View {
    let station: RadioStation
    @Environment(PlaybackManager.self) private var playbackManager
    
    var body: some View {
        Button(action: { playbackManager.play(station: station) }) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: station.favicon)) { phase in
                    if let image = phase.image { image.resizable().aspectRatio(contentMode: .fit) }
                    else { Image(systemName: "radio").foregroundColor(.secondary) }
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name).font(.body).foregroundColor(.primary)
                    if !station.tags.isEmpty { Text(station.tags).font(.caption).foregroundColor(.secondary).lineLimit(1) }
                }
                Spacer()
                if playbackManager.currentStation?.id == station.id && playbackManager.isPlaying {
                    Image(systemName: "waveform").foregroundColor(.blue).symbolEffect(.variableColor.iterative, options: .repeating)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lokale Farb-Erweiterung
enum PlatformColorSelection {
    case windowBackground
    case controlBackground
}

fileprivate extension Color {
    init(platformColor: PlatformColorSelection) {
        #if os(macOS)
        switch platformColor {
        case .windowBackground: self.init(nsColor: .windowBackgroundColor)
        case .controlBackground: self.init(nsColor: .controlBackgroundColor)
        }
        #else
        switch platformColor {
        case .windowBackground: self.init(uiColor: .systemGroupedBackground)
        case .controlBackground: self.init(uiColor: .secondarySystemGroupedBackground)
        }
        #endif
    }
}
