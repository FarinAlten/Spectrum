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
    @Bindable var apiClient: RadioAPIClient
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !searchText.isEmpty {
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
    
    /// Manuelle Zuordnung aller Länder und Flaggen via Switch-Statement
    private func countryFlag(for country: String) -> String {
        let cleanCountry = country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        let isoCode: String
        switch cleanCountry {
            
        // MARK: - Europa
        case "germany", "deutschland":
            isoCode = "DE"
        case "belgium", "belgien":
            isoCode = "BE"
        case "austria", "österreich":
            isoCode = "AT"
        case "switzerland", "schweiz":
            isoCode = "CH"
        case "france", "frankreich":
            isoCode = "FR"
        case "spain", "spanien":
            isoCode = "ES"
        case "italy", "italien":
            isoCode = "IT"
        case "netherlands", "niederlande", "the netherlands":
            isoCode = "NL"
        case "united kingdom", "uk", "great britain", "großbritannien":
            isoCode = "GB"
        case "ireland", "irland":
            isoCode = "IE"
        case "poland", "polen":
            isoCode = "PL"
        case "czech republic", "czechia", "tschechien":
            isoCode = "CZ"
        case "slovakia", "slowakei":
            isoCode = "SK"
        case "denmark", "dänemark":
            isoCode = "DK"
        case "sweden", "schweden":
            isoCode = "SE"
        case "norway", "norwegen":
            isoCode = "NO"
        case "finland", "finnland":
            isoCode = "FI"
        case "portugal":
            isoCode = "PT"
        case "greece", "griechenland":
            isoCode = "GR"
        case "turkey", "türkei", "türkiye":
            isoCode = "TR"
        case "ukraine":
            isoCode = "UA"
        case "russia", "russland", "russian federation":
            isoCode = "RU"
        case "romania", "rumänien":
            isoCode = "RO"
        case "hungary", "ungarn":
            isoCode = "HU"
        case "croatia", "kroatien":
            isoCode = "HR"
        case "serbia", "serbien":
            isoCode = "RS"
        case "bulgaria", "bulgarien":
            isoCode = "BG"
        case "slovenia", "slowenien":
            isoCode = "SI"
        case "iceland", "island":
            isoCode = "IS"
        case "luxembourg", "luxemburg":
            isoCode = "LU"
        case "liechtenstein":
            isoCode = "LI"
        case "monaco":
            isoCode = "MC"
        case "andorra":
            isoCode = "AD"
        case "malta":
            isoCode = "MT"
        case "cyprus", "zypern":
            isoCode = "CY"
        case "albania", "albanien":
            isoCode = "AL"
        case "bosnia and herzegovina", "bosnien und herzegowina":
            isoCode = "BA"
        case "north macedonia", "nordmazedonien":
            isoCode = "MK"
        case "montenegro":
            isoCode = "ME"
        case "estonia", "estland":
            isoCode = "EE"
        case "latvia", "lettland":
            isoCode = "LV"
        case "lithuania", "litauen":
            isoCode = "LT"
        case "belarus", "weißrussland":
            isoCode = "BY"
        case "moldova", "moldawien":
            isoCode = "MD"

        case "united states", "united states of america", "usa", "the united states":
            isoCode = "US"
        case "canada", "kanada":
            isoCode = "CA"
        case "mexico", "mexiko":
            isoCode = "MX"
        case "cuba", "kuba":
            isoCode = "CU"
        case "jamaica", "jamaika":
            isoCode = "JM"
        case "dominican republic", "dominikanische republik":
            isoCode = "DO"
        case "puerto rico":
            isoCode = "PR"
        case "haiti":
            isoCode = "HT"
        case "bahamas":
            isoCode = "BS"
        case "costa rica":
            isoCode = "CR"
        case "panama":
            isoCode = "PA"
        case "guatemala":
            isoCode = "GT"
        case "honduras":
            isoCode = "HN"
        case "el salvador":
            isoCode = "SV"
        case "nicaragua":
            isoCode = "NI"

        // MARK: - Südamerika
        case "brazil", "brasilien":
            isoCode = "BR"
        case "argentina", "argentinien":
            isoCode = "AR"
        case "chile":
            isoCode = "CL"
        case "colombia", "kolumbien":
            isoCode = "CO"
        case "peru":
            isoCode = "PE"
        case "venezuela":
            isoCode = "VE"
        case "ecuador":
            isoCode = "EC"
        case "bolivia", "bolivien":
            isoCode = "BO"
        case "paraguay":
            isoCode = "PY"
        case "uruguay":
            isoCode = "UY"

        // MARK: - Asien
        case "japan":
            isoCode = "JP"
        case "china":
            isoCode = "CN"
        case "south korea", "korea", "republic of korea", "südkorea":
            isoCode = "KR"
        case "north korea", "nordkorea":
            isoCode = "KP"
        case "india", "indien":
            isoCode = "IN"
        case "thailand":
            isoCode = "TH"
        case "vietnam":
            isoCode = "VN"
        case "indonesia", "indonesien":
            isoCode = "ID"
        case "philippines", "philippinen":
            isoCode = "PH"
        case "malaysia":
            isoCode = "MY"
        case "singapore", "singapur":
            isoCode = "SG"
        case "taiwan":
            isoCode = "TW"
        case "hong kong", "hongkong":
            isoCode = "HK"
        case "pakistan":
            isoCode = "PK"
        case "bangladesh", "bangladesch":
            isoCode = "BD"
        case "sri lanka":
            isoCode = "LK"
        case "nepal":
            isoCode = "NP"
        case "kazakhstan", "kasachstan":
            isoCode = "KZ"
        case "uzbekistan", "usbekistan":
            isoCode = "UZ"

        // MARK: - Naher Osten & Nordafrika
        case "israel":
            isoCode = "IL"
        case "saudi arabia", "saudi-arabien":
            isoCode = "SA"
        case "united arab emirates", "uae", "vereinigte arabische emirate":
            isoCode = "AE"
        case "qatar", "katar":
            isoCode = "QA"
        case "kuwait":
            isoCode = "KW"
        case "iran":
            isoCode = "IR"
        case "iraq", "irak":
            isoCode = "IQ"
        case "jordan", "jordanien":
            isoCode = "JO"
        case "lebanon", "libanon":
            isoCode = "LB"
        case "egypt", "ägypten":
            isoCode = "EG"
        case "morocco", "marokko":
            isoCode = "MA"
        case "algeria", "algerien":
            isoCode = "DZ"
        case "tunisia", "tunesien":
            isoCode = "TN"

        // MARK: - Sub-Sahara Afrika
        case "south africa", "südafrika":
            isoCode = "ZA"
        case "nigeria":
            isoCode = "NG"
        case "kenya", "kenia":
            isoCode = "KE"
        case "ghana":
            isoCode = "GH"
        case "ethiopia", "äthiopien":
            isoCode = "ET"
        case "tanzania", "tansania":
            isoCode = "TZ"
        case "uganda":
            isoCode = "UG"
        case "senegal":
            isoCode = "SN"
        case "cameroon", "Kamerun":
            isoCode = "CM"
        case "madagascar", "madagaskar":
            isoCode = "MG"

        // MARK: - Ozeanien
        case "australia", "australien":
            isoCode = "AU"
        case "new zealand", "neuseeland":
            isoCode = "NZ"
        case "fiji", "fidschi":
            isoCode = "FJ"
        case "papua new guinea", "papua-neuguinea":
            isoCode = "PG"

        // Fallback für ungematchte Eingaben
        default:
            return "🌍"
        }

        return flagEmoji(for: isoCode)
    }

    /// Konvertiert einen ISO-2 Code (z.B. "DE") in das Unicode-Flaggen-Emoji (🇩🇪)
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

// MARK: - UI-KOMPONENTEN
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
    @Bindable var apiClient: RadioAPIClient
    
    @State private var categorySearchText = ""
    @State private var showFullPlayer = false
    
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
        List {
            ForEach(filteredStations) { station in
                StationRow(station: station)
                    .onAppear {
                        if station.id == apiClient.stations.last?.id {
                            Task {
                                await apiClient.loadMoreStations()
                            }
                        }
                    }
            }
            
            if apiClient.isLoading {
                HStack {
                    Spacer()
                    ProgressView("Lade weitere Sender...")
                        .padding()
                    Spacer()
                }
            }
        }
        #if os(macOS)
        .listStyle(.inset)
        #else
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle(category.name)
        .searchable(text: $categorySearchText, prompt: "In \(category.name) suchen...")
        .safeAreaInset(edge: .bottom) {
            MiniPlayerView(action: { showFullPlayer = true })
        }
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView()
        }
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

