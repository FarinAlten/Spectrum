import SwiftUI
import SwiftData

// MARK: - MAIN CONTENT VIEW
struct ContentView: View {
    @Environment(RadioAPIClient.self) private var apiClient
    @Environment(PlaybackManager.self) private var playbackManager
    
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif
    
    // Verwende einen fixen Standardwert ohne Optional-Konflikt für die Liste
    @State private var selectedSidebarItem: SidebarItem = .discover
    @State private var navigationPath = NavigationPath()
    @State private var isShowingFullPlayer = false
    
    @AppStorage("hasCompletedInitialOnboarding") private var hasCompletedInitialOnboarding = false
    @State private var showInitialOnboarding = false
    
    enum SidebarItem: String, Hashable, CaseIterable {
        case favorites = "Favorites"
        case discover = "Discover"
    }
    
    var body: some View {
        #if os(iOS)
        Group {
            if sizeClass == .compact {
                TabView(selection: $selectedSidebarItem) {
                    NavigationStack(path: $navigationPath) {
                        FavoritesTabView()
                            .safeAreaPadding(.bottom, playbackManager.currentStation != nil ? 90 : 0)
                            .navigationDestination(for: SelectedCategory.self) { category in
                                StationGridView(categoryName: category.name, categoryType: category.type)
                                    .safeAreaPadding(.bottom, playbackManager.currentStation != nil ? 90 : 0)
                            }
                    }
                    .tabItem { Label("Favorites", systemImage: "star.fill") }
                    .tag(SidebarItem.favorites)
                    
                    NavigationStack(path: $navigationPath) {
                        CategorySelectionView()
                            .safeAreaPadding(.bottom, playbackManager.currentStation != nil ? 90 : 0)
                            .navigationDestination(for: SelectedCategory.self) { category in
                                StationGridView(categoryName: category.name, categoryType: category.type)
                                    .safeAreaPadding(.bottom, playbackManager.currentStation != nil ? 90 : 0)
                            }
                    }
                    .tabItem { Label("Discover", systemImage: "globe") }
                    .tag(SidebarItem.discover)
                }
                .overlay(alignment: .bottom) {
                    if playbackManager.currentStation != nil {
                        MiniPlayerView(action: { isShowingFullPlayer = true })
                            .padding(.horizontal, 16)
                            .padding(.bottom, 68)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .zIndex(1)
                    }
                }
            } else {
                regularSplitView
            }
        }
        .fullScreenCover(isPresented: $isShowingFullPlayer) { FullPlayerView() }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playbackManager.currentStation)
        .task {
            await apiClient.fetchDiscoverData()
            if !hasCompletedInitialOnboarding { showInitialOnboarding = true }
        }
        .sheet(isPresented: $showInitialOnboarding, onDismiss: { hasCompletedInitialOnboarding = true }) {
            OnboardingView(isUpdate: false)
        }
        #else
        // macOS Layout
        regularSplitView
            .frame(minWidth: 700, minHeight: 500) // Verhindert, dass das Fenster zu klein komprimiert wird
            .safeAreaInset(edge: .bottom) {
                if playbackManager.currentStation != nil {
                    VStack(spacing: 0) {
                        Divider()
                        MiniPlayerView(action: { openWindow(id: "full-player") })
                            .padding(12)
                            .background(.ultraThinMaterial)
                    }
                }
            }
            .task {
                await apiClient.fetchDiscoverData()
                if !hasCompletedInitialOnboarding { showInitialOnboarding = true }
            }
            .sheet(isPresented: $showInitialOnboarding, onDismiss: { hasCompletedInitialOnboarding = true }) {
                OnboardingView(isUpdate: false)
            }
        #endif
    }
    
    private var regularSplitView: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, id: \.self, selection: $selectedSidebarItem) { item in
                Label(item.rawValue, systemImage: item == .favorites ? "star.fill" : "globe")
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationTitle("Spectrum")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
            #endif
        } detail: {
            GeometryReader { geometry in
                NavigationStack(path: $navigationPath) {
                    Group {
                        switch selectedSidebarItem {
                        case .favorites:
                            FavoritesTabView()
                        case .discover:
                            CategorySelectionView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationDestination(for: SelectedCategory.self) { category in
                        StationGridView(categoryName: category.name, categoryType: category.type)
                            .safeAreaPadding(.bottom, playbackManager.currentStation != nil ? 88 : 0)
                    }
                    .safeAreaPadding(.bottom, playbackManager.currentStation != nil ? 88 : 0)
                }
                #if os(iOS)
                .overlay(alignment: .bottom) {
                    if playbackManager.currentStation != nil {
                        MiniPlayerView(action: { isShowingFullPlayer = true })
                            .padding(.horizontal, 24)
                            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 16 : 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .zIndex(10)
                    }
                }
                #endif
            }
        }
        .navigationSplitViewStyle(.balanced) // Sorgt für stabiles Multi-Column Verhalten auf macOS/iPadOS
    }
}

// MARK: - FAVORITES TAB VIEW
struct FavoritesTabView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteStation.name) private var favoriteStations: [FavoriteStation]
    @State private var isShowingSettings = false
    
    var body: some View {
        List {
            if favoriteStations.isEmpty {
                ContentUnavailableView("Keine Favoriten", systemImage: "star.slash", description: Text("Füge Sender über das Menü im Player zu deinen Favoriten hinzu."))
            } else {
                ForEach(favoriteStations, id: \.id) { favorite in
                    Button(action: {
                        playbackManager.play(station: RadioStation(id: favorite.id, name: favorite.name, url: favorite.url.absoluteString, favicon: favorite.favicon, tags: favorite.tags, clickcount: 0))
                    }) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: favorite.favicon)) { phase in
                                if let image = phase.image { image.resizable().aspectRatio(contentMode: .fill) }
                                else { ZStack { Color.white.opacity(0.05); Image(systemName: "radio").font(.system(size: 14)).foregroundColor(.secondary) } }
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(favorite.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
                                if !favorite.tags.isEmpty { Text(favorite.tags).font(.caption).foregroundColor(.secondary).lineLimit(1) }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote).foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { @MainActor in modelContext.delete(favorite); try? modelContext.save() }
                        } label: { Label("Löschen", systemImage: "trash") }
                    }
                }
            }
        }
        .navigationTitle("Favoriten")
        .toolbar {
            ToolbarItem(placement: leadingPlacement) {
                Button(action: { isShowingSettings = true }) { Label("Einstellungen", systemImage: "gearshape") }
            }
        }
        .sheet(isPresented: $isShowingSettings) { NavigationStack { SettingsView() } }
    }
    
    private var leadingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarLeading
        #else
        return .navigation
        #endif
    }
}

// MARK: - CATEGORY SELECTION VIEW
struct CategorySelectionView: View {
    enum CategoryTab: String, CaseIterable, Identifiable {
        case countries = "Länder"
        case genres = "Genres"
        var id: Self { self }
        var icon: String { self == .countries ? "globe" : "music.note" }
    }

    @Environment(RadioAPIClient.self) private var apiClient
    @Environment(PlaybackManager.self) private var playbackManager: PlaybackManager?
    @State private var selectedTab: CategoryTab = .countries
    @State private var isShowingSettings = false
    @State private var searchText = ""
    @State private var searchedGroups: [StationGroup] = []
    @State private var isSearchingAPI = false
    
    var body: some View {
        List {
            if !searchText.isEmpty {
                if !apiClient.countries.filter({ $0.localizedCaseInsensitiveContains(searchText) }).isEmpty {
                    Section("Länder") {
                        ForEach(apiClient.countries.filter({ $0.localizedCaseInsensitiveContains(searchText) }), id: \.self) { country in
                            NavigationLink(value: SelectedCategory(name: country, type: .country)) { Label(country, systemImage: "globe") }
                        }
                    }
                }
                if !apiClient.genres.filter({ $0.localizedCaseInsensitiveContains(searchText) }).isEmpty {
                    Section("Genres") {
                        ForEach(apiClient.genres.filter({ $0.localizedCaseInsensitiveContains(searchText) }), id: \.self) { genre in
                            NavigationLink(value: SelectedCategory(name: genre, type: .genre)) { Label(genre, systemImage: "music.note") }
                        }
                    }
                }
                Section("Sender-Ergebnisse") {
                    if isSearchingAPI {
                        HStack { Spacer(); ProgressView("Suche Sender..."); Spacer() }
                    } else if searchedGroups.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        ForEach(searchedGroups) { group in
                            if group.subStations.isEmpty {
                                Button(action: { playbackManager?.play(station: group.mainStation) }) { stationRow(group.mainStation) }.buttonStyle(.plain)
                            } else {
                                DisclosureGroup {
                                    Button(action: { playbackManager?.play(station: group.mainStation) }) { stationRow(group.mainStation) }.buttonStyle(.plain)
                                    ForEach(group.subStations) { sub in
                                        Button(action: { playbackManager?.play(station: sub) }) { stationRow(sub) }.buttonStyle(.plain)
                                    }
                                } label: { stationRow(group.mainStation) }
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
        .searchable(text: $searchText, placement: osSearchPlacement, prompt: "Sender, Länder, Genres...")
        .onChange(of: searchText) { _, newValue in Task { await performStationSearch(query: newValue) } }
        .toolbar {
            ToolbarItem(placement: leadingPlacement) {
                Button(action: { isShowingSettings = true }) { Label("Einstellungen", systemImage: "gearshape") }
            }
            ToolbarItem(placement: trailingPlacement) {
                Menu {
                    Picker("Kategorie wechseln", selection: $selectedTab) {
                        ForEach(CategoryTab.allCases) { tab in Label(tab.rawValue, systemImage: tab.icon).tag(tab) }
                    }.pickerStyle(.inline)
                } label: { Image(systemName: selectedTab == .countries ? "globe" : "music.note") }
            }
        }
        .sheet(isPresented: $isShowingSettings) { NavigationStack { SettingsView() } }
    }
    
    @ViewBuilder
    private var defaultContentSection: some View {
        if selectedTab == .countries {
            Section("Länder") {
                ForEach(apiClient.countries, id: \.self) { country in
                    NavigationLink(value: SelectedCategory(name: country, type: .country)) { Label(country, systemImage: "globe") }
                }
            }
        } else {
            Section("Genres") {
                ForEach(apiClient.genres, id: \.self) { genre in
                    NavigationLink(value: SelectedCategory(name: genre, type: .genre)) { Label(genre, systemImage: "music.note") }
                }
            }
        }
    }
    
    private func stationRow(_ station: RadioStation) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: station.favicon)) { phase in
                if let image = phase.image { image.resizable().aspectRatio(contentMode: .fit) }
                else { Image(systemName: "radio").foregroundColor(.secondary) }
            }.frame(width: 32, height: 32).clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(station.name).font(.body).fontWeight(.medium).lineLimit(1)
                if !station.tags.isEmpty { Text(station.tags).font(.caption).foregroundColor(.secondary).lineLimit(1) }
            }
        }
    }
    
    private func performStationSearch(query: String) async {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count > 1 else { searchedGroups = []; return }
        isSearchingAPI = true
        guard let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://de1.api.radio-browser.info/json/stations/byname/\(encoded)?hidebroken=true&limit=50") else { isSearchingAPI = false; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([RadioStation].self, from: data)
            let valid = decoded.filter { !$0.favicon.isEmpty && !$0.url.isEmpty && !$0.url.hasSuffix(".m3u") && !$0.url.hasSuffix(".pls") }
            let sorted = valid.sorted { $0.clickcount > $1.clickcount }
            var groups: [StationGroup] = []
            for station in sorted {
                if let idx = groups.firstIndex(where: { $0.mainStation.name.lowercased().hasPrefix(station.name.lowercased()) && $0.mainStation.name != station.name }) {
                    groups[idx].subStations.append(station)
                } else {
                    groups.append(StationGroup(id: station.id, mainStation: station, subStations: []))
                }
            }
            await MainActor.run { self.searchedGroups = groups; self.isSearchingAPI = false }
        } catch {
            print(error); await MainActor.run { self.isSearchingAPI = false }
        }
    }
    
    private var osSearchPlacement: SearchFieldPlacement {
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
}

// MARK: - STATION GRID VIEW
struct StationGridView: View {
    let categoryName: String
    let categoryType: RadioAPIClient.CategoryType
    @Environment(RadioAPIClient.self) private var apiClient
    @Environment(PlaybackManager.self) private var playbackManager
    @State private var searchText: String = ""
    
    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)]
    private var targetStations: [RadioStation] { categoryType == .search ? apiClient.searchResults : apiClient.stations }
    private var filteredStations: [RadioStation] { searchText.isEmpty ? targetStations : targetStations.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
    
    var body: some View {
        ScrollView {
            if apiClient.isLoading { ProgressView().padding(.top, 40) }
            else if filteredStations.isEmpty { Text(LocalizedStringKey("no_stations_found")).foregroundColor(.secondary).padding(.top, 40) }
            else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredStations) { station in
                        Button(action: { playbackManager.play(station: station) }) {
                            VStack {
                                AsyncImage(url: URL(string: station.favicon)) { ph in
                                    if let img = ph.image { img.resizable().aspectRatio(contentMode: .fit) }
                                    else { Image(systemName: "radio").font(.largeTitle).foregroundColor(.secondary) }
                                }.frame(width: 60, height: 60).cornerRadius(12)
                                Text(station.name).font(.headline).lineLimit(2).multilineTextAlignment(.center)
                            }
                            .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(white: 0.5, opacity: 0.05)).cornerRadius(12)
                        }.buttonStyle(.plain)
                    }
                }.padding()
            }
        }
        .navigationTitle(categoryName)
        .searchable(text: $searchText, prompt: Text("Sender suchen"))
        .task { if categoryType != .search { await apiClient.fetchStations(for: categoryName, type: categoryType) } }
    }
}
