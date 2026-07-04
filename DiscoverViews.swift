import SwiftUI

struct StationGroup: Identifiable, Hashable {
    var id: String { mainStation.id }
    let mainStation: RadioStation
    var subStations: [RadioStation]
}

struct CategorySelectionView: View {
    enum CategoryTab: String, CaseIterable, Identifiable {
        case countries = "Länder"
        case genres = "Genres"
        
        var id: Self { self }
        
        var icon: String {
            switch self {
            case .countries: return "globe"
            case .genres: return "music.note"
            }
        }
    }

    @Environment(RadioAPIClient.self) private var apiClient
    @Environment(PlaybackManager.self) private var playbackManager: PlaybackManager?
    
    @State private var selectedTab: CategoryTab = .countries
    @State private var isShowingSettings = false
    @State private var searchText = ""
    @State private var searchedGroups: [StationGroup] = []
    @State private var isSearchingAPI = false
    
    private var filteredCountries: [String] {
        apiClient.countries.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredGenres: [String] {
        apiClient.genres.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            if !searchText.isEmpty {
                if !filteredCountries.isEmpty {
                    Section("Länder") {
                        ForEach(filteredCountries, id: \.self) { country in
                            NavigationLink(value: SelectedCategory(name: country, type: .country)) {
                                Label(country, systemImage: "globe")
                            }
                        }
                    }
                }
                
                if !filteredGenres.isEmpty {
                    Section("Genres") {
                        ForEach(filteredGenres, id: \.self) { genre in
                            NavigationLink(value: SelectedCategory(name: genre, type: .genre)) {
                                Label(genre, systemImage: "music.note")
                            }
                        }
                    }
                }
                
                Section("Sender-Ergebnisse") {
                    if isSearchingAPI {
                        HStack {
                            Spacer()
                            ProgressView("Suche Sender...")
                            Spacer()
                        }
                    } else if searchedGroups.isEmpty && filteredCountries.isEmpty && filteredGenres.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        ForEach(searchedGroups) { group in
                            if group.subStations.isEmpty {
                                Button(action: {
                                    playbackManager?.play(station: group.mainStation)
                                }) {
                                    stationRow(group.mainStation)
                                }
                                .buttonStyle(.plain)
                            } else {
                                DisclosureGroup {
                                    Button(action: {
                                        playbackManager?.play(station: group.mainStation)
                                    }) {
                                        stationRow(group.mainStation)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    ForEach(group.subStations) { subStation in
                                        Button(action: {
                                            playbackManager?.play(station: subStation)
                                        }) {
                                            stationRow(subStation)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } label: {
                                    stationRow(group.mainStation)
                                }
                            }
                        }
                    }
                }
            } else {
                defaultContentSection
            }
        }
        .listStyle(.inset)
        .navigationTitle("Discover")
        .searchable(text: $searchText, placement: searchPlacement, prompt: "Sender, Länder, Genres...")
        .onChange(of: searchText) { _, newValue in
            Task {
                await performStationSearch(query: newValue)
            }
        }
        .toolbar {
            ToolbarItem(placement: leadingPlacement) {
                Button(action: { isShowingSettings = true }) {
                    Label("Einstellungen", systemImage: "gearshape")
                }
            }
            
            ToolbarItem(placement: trailingPlacement) {
                Menu {
                    Picker("Kategorie wechseln", selection: $selectedTab) {
                        ForEach(CategoryTab.allCases) { tab in
                            Label(tab.rawValue, systemImage: tab.icon)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: selectedTab == .countries ? "globe" : "music.note")
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .overlay {
            if apiClient.isLoading && apiClient.countries.isEmpty && apiClient.genres.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Lade Kategorien...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor)
            }
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
    }
    
    @ViewBuilder
    private func stationRow(_ station: RadioStation) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: station.favicon)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "radio").foregroundColor(.secondary)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if !station.tags.isEmpty {
                    Text(station.tags)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
    
    @ViewBuilder
    private var defaultContentSection: some View {
        switch selectedTab {
        case .countries:
            Section("Länder") {
                ForEach(apiClient.countries, id: \.self) { country in
                    NavigationLink(value: SelectedCategory(name: country, type: .country)) {
                        Label(country, systemImage: "globe")
                    }
                }
            }
        case .genres:
            Section("Genres") {
                ForEach(apiClient.genres, id: \.self) { genre in
                    NavigationLink(value: SelectedCategory(name: genre, type: .genre)) {
                        Label(genre, systemImage: "music.note")
                    }
                }
            }
        }
    }
    
    private func performStationSearch(query: String) async {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedQuery.count > 1 else {
            searchedGroups = []
            return
        }
        
        isSearchingAPI = true
        
        guard let encodedQuery = cleanedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://de1.api.radio-browser.info/json/stations/byname/\(encodedQuery)?hidebroken=true&limit=50") else {
            isSearchingAPI = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedStations = try JSONDecoder().decode([RadioStation].self, from: data)
            
            let validStations = decodedStations.filter { station in
                guard !station.favicon.isEmpty,
                      let faviconURL = URL(string: station.favicon),
                      faviconURL.scheme != nil else {
                    return false
                }
                
                guard !station.url.isEmpty else {
                    return false
                }
                
                let lowercasedURL = station.url.lowercased()
                if lowercasedURL.hasSuffix(".m3u") || lowercasedURL.hasSuffix(".pls") {
                    return false
                }
                
                return true
            }
            
            let sortedStations = validStations.sorted { $0.clickcount > $1.clickcount }
            
            var groups: [StationGroup] = []
            
            for station in sortedStations {
                let stationNameLower = station.name.lowercased()
                
                if let index = groups.firstIndex(where: {
                    let mainNameLower = $0.mainStation.name.lowercased()
                    return (stationNameLower.hasPrefix(mainNameLower) || mainNameLower.hasPrefix(stationNameLower)) && $0.mainStation.name != station.name
                }) {
                    groups[index].subStations.append(station)
                } else {
                    groups.append(StationGroup(mainStation: station, subStations: []))
                }
            }
            
            await MainActor.run {
                self.searchedGroups = groups
                self.isSearchingAPI = false
            }
        } catch {
            print("Fehler bei der Sendersuche: \(error)")
            await MainActor.run { self.isSearchingAPI = false }
        }
    }
    
    private var searchPlacement: SearchFieldPlacement {
        #if os(iOS)
        return .navigationBarDrawer(displayMode: .always)
        #else
        return .automatic
        #endif
    }
    
    private var leadingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarLeading
        #else
        return .navigation
        #endif
    }
    
    private var trailingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .primaryAction
        #endif
    }
    
    private var backgroundColor: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
    
    private func loadData() async {
        await apiClient.fetchDiscoverData()
    }
}

struct StationGridView: View {
    let categoryName: String
    let categoryType: RadioAPIClient.CategoryType
    
    @Environment(RadioAPIClient.self) private var apiClient
    @Environment(PlaybackManager.self) private var playbackManager
    
    @State private var searchText: String = ""
    
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
    
    private var filteredStations: [RadioStation] {
        if searchText.isEmpty {
            return targetStations
        } else {
            return targetStations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ScrollView {
            if apiClient.isLoading {
                ProgressView()
                    .padding(.top, 40)
            } else if filteredStations.isEmpty {
                Text(LocalizedStringKey("no_stations_found"))
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredStations) { station in
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
        .searchable(text: $searchText, placement: .automatic, prompt: Text("Sender in \(categoryName) suchen"))
        .task {
            if categoryType != .search {
                await apiClient.fetchStations(for: categoryName, type: categoryType)
            }
        }
    }
}
