//
//  DiscoverViews.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//
import SwiftUI
import SwiftData

#if !os(watchOS)

// MARK: - Country Translation Extension (Ansatz 1)
extension String {
    var localizedCountryName: String {
        let cleanCountry = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Suche die passende ISO-Region anhand des englischen Namens
        if let region = Locale.Region.isoRegions.first(where: { region in
            let englishName = Locale(identifier: "en_US").localizedString(forRegionCode: region.identifier)
            return englishName?.caseInsensitiveCompare(cleanCountry) == .orderedSame
        }) {
            // 2. Gib den lokalisierten Namen in der aktuellen Sprache des Nutzers zurück
            if let localizedName = Locale.current.localizedString(forRegionCode: region.identifier) {
                return localizedName.capitalized
            }
        }
        
        // Fallback: Falls keine Entsprechung gefunden wird, den Originalnamen nutzen
        return self
    }
}

struct SelectedCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: RadioAPIClient.CategoryType
}

struct DiscoverView: View {
    @Bindable var apiClient: RadioAPIClient
    @Binding var categoryType: RadioAPIClient.CategoryType
    @Binding var searchText: String
    
    @AppStorage("preferredDisplayMode") private var preferredDisplayMode = "grid"
    @AppStorage("maxGridColumns") private var maxGridColumns = 1
    @AppStorage("showFlagsAndEmojis") private var showFlagsAndEmojis = true
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: maxGridColumns)
    }
    
    private var sectionHeaderTitle: String {
        categoryType == .country ? "Countries" : "Genres"
    }
    
    // MARK: - Filter für lokale Kategorien (Durchsucht Original- & übersetzte Namen)
    private var filteredCountries: [String] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return apiClient.countries
        }
        return apiClient.countries.filter { country in
            country.localizedCaseInsensitiveContains(searchText) ||
            country.localizedCountryName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredGenres: [String] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return apiClient.genres
        }
        return apiClient.genres.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        #if os(macOS)
        mainContent
            .searchable(text: $searchText, prompt: "Sender, Länder, Genres...")
        #else
        NavigationStack {
            mainContent
                .searchable(text: $searchText, prompt: "Sender, Länder, Genres...")
        }
        #endif
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // MARK: - Wenn etwas gesucht wird
                if !searchText.isEmpty {
                    
                    // 1. Treffer in Kategorien (Länder oder Genres)
                    let matchingCategories = categoryType == .country ? filteredCountries : filteredGenres
                    if !matchingCategories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(sectionHeaderTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if preferredDisplayMode == "grid" {
                                LazyVGrid(columns: gridColumns, spacing: 12) {
                                    categoryItems(for: matchingCategories)
                                }
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 0) {
                                    categoryItems(for: matchingCategories)
                                }
                                .background(Color(platformColor: .controlBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // 2. Sender-Ergebnisse aus der API-Suche
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sender")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if apiClient.isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Suche Sender...")
                                    .padding()
                                Spacer()
                            }
                        } else if apiClient.searchResults.isEmpty {
                            Text("Keine Sender gefunden")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(apiClient.searchResults) { station in
                                    StationRow(station: station)
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                    Divider().padding(.leading, 68)
                                }
                            }
                        }
                    }
                    
                } else {
                    // MARK: - Standardsicht ohne Suche
                    VStack(alignment: .leading, spacing: 12) {
                        Text(sectionHeaderTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        let currentCategories = categoryType == .country ? apiClient.countries : apiClient.genres
                        
                        if preferredDisplayMode == "grid" {
                            LazyVGrid(columns: gridColumns, spacing: 12) {
                                categoryItems(for: currentCategories)
                            }
                            .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 0) {
                                categoryItems(for: currentCategories)
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
        .navigationDestination(for: SelectedCategory.self) { category in
            CategoryStationListView(category: category, apiClient: apiClient)
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
    
    // MARK: - Dynamische Darstellung der Kategorien (Inklusive Übersetzung)
    @ViewBuilder
    private func categoryItems(for categories: [String]) -> some View {
        ForEach(categories, id: \.self) { item in
            // Für die Navigation schicken wir den API-Schlüssel (Original) mit, für das Display übersetzen wir
            let displayTitle = categoryType == .country ? item.localizedCountryName : item
            
            NavigationLink(value: SelectedCategory(name: item, type: categoryType)) {
                if preferredDisplayMode == "grid" {
                    CategoryGridCard(
                        title: displayTitle,
                        visualElement: showFlagsAndEmojis ? (categoryType == .country ? countryFlag(for: item) : genreEmoji(for: item)) : ""
                    )
                } else {
                    CategoryListRow(
                        title: displayTitle,
                        visualElement: showFlagsAndEmojis ? (categoryType == .country ? countryFlag(for: item) : genreEmoji(for: item)) : "",
                        accentColor: categoryType == .country ? .blue : .purple
                    )
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // Dynamische Flaggenauflösung mit Locale.Region.isoRegions (iOS 16+)
    private func countryFlag(for country: String) -> String {
        let cleanCountry = country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 1. Ist es bereits ein 2-stelliger ISO Code?
        if cleanCountry.count == 2 {
            return flagEmoji(for: cleanCountry)
        }
        
        // 2. Dynamische Lokalisations-Suche über Locale.Region.isoRegions
        if let region = Locale.Region.isoRegions.first(where: { region in
            let code = region.identifier
            let GermanName = Locale(identifier: "de_DE").localizedString(forRegionCode: code)?.lowercased()
            let EnglishName = Locale(identifier: "en_US").localizedString(forRegionCode: code)?.lowercased()
            let CurrentName = Locale.current.localizedString(forRegionCode: code)?.lowercased()
            
            return GermanName == cleanCountry || EnglishName == cleanCountry || CurrentName == cleanCountry
        }) {
            return flagEmoji(for: region.identifier)
        }
        
        // 3. Spezifische Namensabweichungen & Aliase
        let isoCode: String
        switch cleanCountry {
        case "germany", "deutschland": isoCode = "DE"
        case "austria", "österreich": isoCode = "AT"
        case "switzerland", "schweiz": isoCode = "CH"
        case "united states", "united states of america", "usa", "the united states": isoCode = "US"
        case "united kingdom", "uk", "great britain", "großbritannien": isoCode = "GB"
        case "russia", "russland", "russian federation": isoCode = "RU"
        case "south korea", "korea", "republic of korea", "südkorea": isoCode = "KR"
        case "north korea", "nordkorea": isoCode = "KP"
        case "turkey", "türkei", "türkiye": isoCode = "TR"
        case "czech republic", "czechia", "tschechien": isoCode = "CZ"
        default:
            return "🌍"
        }

        return flagEmoji(for: isoCode)
    }

    private func flagEmoji(for isoCode: String) -> String {
        let code = isoCode.uppercased()
        guard code.count == 2 else { return "🌍" }
        
        var scalarView = String.UnicodeScalarView()
        for i in code.utf16 {
            guard let scalar = UnicodeScalar(127397 + UInt32(i)) else { return "🌍" }
            scalarView.append(scalar)
        }
        return String(scalarView)
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
        #if !os(watchOS)
        .onHover { hovering in isHovered = hovering }
        #endif
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

// MARK: - Category Station List View (Zeigt im Titel den übersetzten Namen)
struct CategoryStationListView: View {
    let category: SelectedCategory
    @Bindable var apiClient: RadioAPIClient
    
    @State private var categorySearchText = ""
    
    private var displayTitle: String {
        category.type == .country ? category.name.localizedCountryName : category.name
    }
    
    private var filteredStations: [RadioStation] {
        if categorySearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return apiClient.stations
        } else {
            return apiClient.stations.filter { station in
                station.name.localizedCaseInsensitiveContains(categorySearchText) ||
                station.tags.localizedCaseInsensitiveContains(categorySearchText)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filteredStations.isEmpty && !apiClient.isLoading {
                    ContentUnavailableView(
                        "Keine Sender gefunden",
                        systemImage: "radio",
                        description: Text("Versuche einen anderen Suchbegriff.")
                    )
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredStations.enumerated()), id: \.element.id) { index, station in
                            StationRow(station: station)
                                .onAppear {
                                    if station.id == apiClient.stations.last?.id {
                                        Task {
                                            await apiClient.loadMoreStations()
                                        }
                                    }
                                }
                            
                            if index < filteredStations.count - 1 {
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                    }
                    .background(Color(platformColor: .controlBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                
                if apiClient.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Lade Sender...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(platformColor: .windowBackground))
        .navigationTitle(displayTitle)
        .searchable(
            text: $categorySearchText,
            placement: .automatic,
            prompt: "In \(displayTitle) suchen..."
        )
        .task {
            await apiClient.fetchStations(for: category.name, type: category.type)
        }
    }
}

// MARK: - Station Row
struct StationRow: View {
    let station: RadioStation
    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteStation]
    
    @State private var isHovered = false
    
    private var isPlayingCurrent: Bool {
        playbackManager.currentStation?.id == station.id && playbackManager.isPlaying
    }
    
    private var isFavorite: Bool {
        favorites.contains { $0.id == station.id }
    }
    
    var body: some View {
        Button(action: { playbackManager.play(station: station) }) {
            HStack(spacing: 14) {
                // Station Favicon / Icon
                AsyncImage(url: URL(string: station.favicon)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ZStack {
                            Color.secondary.opacity(0.12)
                            Image(systemName: "radio")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                
                // Station Info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(station.name)
                            .font(.body)
                            .fontWeight(isPlayingCurrent ? .bold : .medium)
                            .foregroundColor(isPlayingCurrent ? .accentColor : .primary)
                            .lineLimit(1)
                        
                        if isPlayingCurrent {
                            Image(systemName: "waveform")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .symbolEffect(.variableColor.iterative, options: .repeating)
                        }
                    }
                    
                    if !station.tags.isEmpty {
                        Text(formattedTags(station.tags))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Quick Favorite Button
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isFavorite ? .yellow : .secondary.opacity(isHovered ? 0.8 : 0.3))
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isHovered ? Color.primary.opacity(0.04) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        #if !os(watchOS)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        #endif
    }
    
    private func formattedTags(_ tags: String) -> String {
        tags.split(separator: ",")
            .prefix(3)
            .map { $0.trimmingCharacters(in: .whitespaces).capitalized }
            .joined(separator: " • ")
    }
    
    private func toggleFavorite() {
        if isFavorite {
            if let entity = favorites.first(where: { $0.id == station.id }) {
                modelContext.delete(entity)
            }
        } else {
            let newFavorite = FavoriteStation(from: station)
            modelContext.insert(newFavorite)
        }
        try? modelContext.save()
    }
}

enum PlatformColorSelection {
    case windowBackground
    case controlBackground
}

extension Color {
    init(platformColor: PlatformColorSelection) {
        #if os(macOS)
        switch platformColor {
        case .windowBackground: self.init(nsColor: .windowBackgroundColor)
        case .controlBackground: self.init(nsColor: .controlBackgroundColor)
        }
        #elseif os(iOS)
        switch platformColor {
        case .windowBackground: self.init(uiColor: .systemGroupedBackground)
        case .controlBackground: self.init(uiColor: .secondarySystemGroupedBackground)
        }
        #else
        switch platformColor {
        case .windowBackground: self.init(Color.black)
        case .controlBackground: self.init(Color.gray.opacity(0.2))
        }
        #endif
    }
}

#endif

