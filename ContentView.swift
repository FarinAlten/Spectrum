//
//  ContentView.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//
import SwiftUI

struct ContentView: View {
    @State private var apiClient = RadioAPIClient()
    @Environment(PlaybackManager.self) private var playbackManager
    
    @State private var selectedSidebarItem: SidebarItem? = .discover
    @State private var activeCategoryType: RadioAPIClient.CategoryType = .country
    @State private var searchText = ""
    @State private var showSettings = false
    @State private var showFullPlayer = false 
    
    enum SidebarItem: Hashable {
        case favorites
        case discover
        case map
    }
    
    var body: some View {
        #if os(macOS)
        // macOS nutzt die dedizierte, saubere Subview
        MacOSContentView(
            apiClient: apiClient,
            selectedSidebarItem: $selectedSidebarItem,
            activeCategoryType: $activeCategoryType,
            searchText: $searchText,
            showSettings: $showSettings,
            showFullPlayer: $showFullPlayer // Binding nach macOS übergeben
        )
        #else
        // iOS Code bleibt unangetastet funktional
        ZStack(alignment: .bottom) {
            TabView(selection: Binding(
                get: { selectedSidebarItem ?? .discover },
                set: { selectedSidebarItem = $0 }
            )) {
                NavigationStack {
                    DiscoverView(
                        apiClient: apiClient,
                        categoryType: $activeCategoryType,
                        searchText: $searchText
                    )
                    .navigationTitle("Discover")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showSettings = true }) { Image(systemName: "gearshape") }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Picker("Kategorie", selection: $activeCategoryType) {
                                    Label("Länder", systemImage: "globe").tag(RadioAPIClient.CategoryType.country)
                                    Label("Genres", systemImage: "music.note").tag(RadioAPIClient.CategoryType.genre)
                                }
                            } label: { Image(systemName: "globe") }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Sender, Länder, Genres...")
                }
                .tabItem { Label("Discover", systemImage: "safari.fill") }
                .tag(SidebarItem.discover)
                
                NavigationStack {
                    StationMapView(apiClient: apiClient)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: { showSettings = true }) { Image(systemName: "gearshape") }
                            }
                        }
                }
                .tabItem { Label("Map_Tab_Label", systemImage: "map.fill") }
                .tag(SidebarItem.map)
            }
            
            // HIER ANGEPASST: Die Bedingung wurde entfernt, der Miniplayer ist dauerhaft sichtbar
            MiniPlayerView(action: { showFullPlayer = true })
                .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 8 : 64)
        }
        .sheet(isPresented: $showSettings) { NavigationStack { SettingsView() } }
        .sheet(isPresented: $showFullPlayer) { FullPlayerView() }
        #endif
    }
}

// MARK: - Separate macOS Ansichtsstruktur (Behebt den Compiler-Fehler)
#if os(macOS)
struct MacOSContentView: View {
    var apiClient: RadioAPIClient
    @Binding var selectedSidebarItem: ContentView.SidebarItem?
    @Binding var activeCategoryType: RadioAPIClient.CategoryType
    @Binding var searchText: String
    @Binding var showSettings: Bool
    @Binding var showFullPlayer: Bool // Empfängt das Binding zur Steuerung des Fullplayers
    
    @Environment(PlaybackManager.self) private var playbackManager
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSidebarItem) {
                Text("Mediathek")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                NavigationLink(value: ContentView.SidebarItem.favorites) {
                    Label("Favorites", systemImage: "star.fill")
                        .foregroundColor(.blue)
                }
                
                NavigationLink(value: ContentView.SidebarItem.discover) {
                    Label("Discover", systemImage: "safari.fill")
                }
                
                NavigationLink(value: ContentView.SidebarItem.map) {
                    Label("Map_Tab_Label", systemImage: "map.fill")
                        .foregroundColor(.green)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
            
        } detail: {
            Group {
                switch selectedSidebarItem {
                case .favorites:
                    List {
                        Section(header: Text("Deine Favoriten")) {
                            FavoritesSectionView()
                        }
                    }
                    .listStyle(.inset)
                    
                case .discover:
                    DiscoverView(
                        apiClient: apiClient,
                        categoryType: $activeCategoryType,
                        searchText: $searchText
                    )
                    
                case .map, .none:
                    NavigationStack {
                        StationMapView(apiClient: apiClient)
                    }
                }
            }
            .navigationTitle(titleForSelection(selectedSidebarItem))
            // HIER ANGEPASST: Die Bedingung wurde entfernt, der Miniplayer bleibt permanent verankert
            .safeAreaInset(edge: .bottom, spacing: 0) {
                MiniPlayerView(action: { showFullPlayer = true })
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: { showSettings = true }) {
                        Label("Einstellungen", systemImage: "gearshape")
                    }
                    .help("Einstellungen")
                }
                
                if selectedSidebarItem == .discover {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Picker("Kategorie", selection: $activeCategoryType) {
                                Label("Länder", systemImage: "globe").tag(RadioAPIClient.CategoryType.country)
                                Label("Genres", systemImage: "music.note").tag(RadioAPIClient.CategoryType.genre)
                            }
                        } label: {
                            Image(systemName: activeCategoryType == .country ? "globe" : "music.note")
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: "Sender, Länder, Genres...")
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .frame(width: 450, height: 480)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Schließen") { showSettings = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView()
        }
    }
    
    private func titleForSelection(_ item: ContentView.SidebarItem?) -> String {
        switch item {
        case .favorites: return "Favorites"
        case .discover: return "Discover"
        case .map: return "Map_Title_Main"
        case .none: return "Discover"
        }
    }
}
#endif
