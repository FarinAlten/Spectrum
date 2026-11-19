//
//  ContentView.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//

import SwiftUI
import SwiftData

#if !os(watchOS)

struct ContentView: View {
    @State private var apiClient = RadioAPIClient()
    @Environment(PlaybackManager.self) private var playbackManager

    @State private var selectedSidebarItem: SidebarItem? = .discover
    @State private var activeCategoryType: RadioAPIClient.CategoryType = .country
    @State private var searchText = ""
    @State private var showSettings = false
    @State private var showFullPlayer = false
    @State private var startupComplete = false

    @Namespace private var playerAnimation

    enum SidebarItem: Hashable {
        case favorites
        case discover
        case map
    }

    var body: some View {
        #if os(macOS)

        MacOSContentView(
            apiClient: apiClient,
            selectedSidebarItem: $selectedSidebarItem,
            activeCategoryType: $activeCategoryType,
            searchText: $searchText,
            showSettings: $showSettings,
            showFullPlayer: $showFullPlayer,
            playerAnimation: playerAnimation
        )
        .task {
            await apiClient.fetchDiscoverData()
            withAnimation(.easeOut(duration: 0.3)) {
                startupComplete = true
            }
        }

        #else

        TabView(
                selection: Binding(
                    get: {
                        selectedSidebarItem ?? .discover
                    },
                    set: {
                        selectedSidebarItem = $0
                    }
                )
        ) {

                // MARK: - Favorites

                NavigationStack {
                    List {
                        Section(
                            header: Text("Deine Favoriten")
                        ) {
                            FavoritesSectionView()
                        }
                    }
                    .listStyle(.inset)
                    .navigationTitle("Favorites")
                    .toolbar {
                        ToolbarItem(
                            placement: .topBarLeading
                        ) {
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                }
                .tabItem {
                    Label(
                        "Favorites",
                        systemImage: "star.fill"
                    )
                }
                .tag(SidebarItem.favorites)

                // MARK: - Discover

                NavigationStack {
                    DiscoverView(
                        apiClient: apiClient,
                        categoryType: $activeCategoryType,
                        searchText: $searchText
                    )
                    .navigationTitle("Discover")
                    .toolbar {

                        ToolbarItem(
                            placement: .topBarLeading
                        ) {
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }

                        ToolbarItem(
                            placement: .topBarTrailing
                        ) {
                            Menu {

                                Picker(
                                    "Kategorie",
                                    selection: $activeCategoryType
                                ) {
                                    Label(
                                        "Länder",
                                        systemImage: "globe"
                                    )
                                    .tag(
                                        RadioAPIClient.CategoryType.country
                                    )

                                    Label(
                                        "Genres",
                                        systemImage: "music.note"
                                    )
                                    .tag(
                                        RadioAPIClient.CategoryType.genre
                                    )
                                }

                            } label: {
                                Image(systemName: "globe")
                            }
                        }
                    }
                    .searchable(
                        text: $searchText,
                        prompt: "Sender, Länder, Genres..."
                    )
                }
                .tabItem {
                    Label(
                        "Discover",
                        systemImage: "safari.fill"
                    )
                }
                .tag(SidebarItem.discover)

                // MARK: - Map

                NavigationStack {
                    StationMapView(
                        apiClient: apiClient
                    )
                    .toolbar {
                        ToolbarItem(
                            placement: .topBarLeading
                        ) {
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                }
                .tabItem {
                    Label(
                        "Karte",
                        systemImage: "map.fill"
                    )
                }
                .tag(SidebarItem.map)
            }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PlayerExpansionView(
                progress: showFullPlayer ? 1 : 0,

                miniPlayer: {
                    MiniPlayerView(
                        action: {
                            withAnimation(
                                .spring(
                                    response: 0.48,
                                    dampingFraction: 0.86
                                )
                            ) {
                                showFullPlayer = true
                            }
                        },
                        animation: playerAnimation,
                        isExpanded: showFullPlayer
                    )
                    .padding(.horizontal, isPad ? 20 : 12)
                    .padding(.top, 8)
                    .padding(.bottom, 95)
                },

                fullPlayer: {
                    FullPlayerView(
                        animation: playerAnimation,
                        isExpanded: showFullPlayer,
                        onDismiss: {
                            withAnimation(
                                .spring(
                                    response: 0.48,
                                    dampingFraction: 0.86
                                )
                            ) {
                                showFullPlayer = false
                            }
                        }
                    )
                },

                onDismiss: {
                    withAnimation(
                        .spring(
                            response: 0.48,
                            dampingFraction: 0.86
                        )
                    ) {
                        showFullPlayer = false
                    }
                }
            )
        }
        .task {
            await apiClient.fetchDiscoverData()
            withAnimation(.easeOut(duration: 0.3)) {
                startupComplete = true
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .overlay {
            if !startupComplete {
                StartupView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }

        #endif
    }

    private var isPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
}

private struct StartupView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 44, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)

            Text("Spectrum")
                .font(.title2.weight(.semibold))

            ProgressView()
                .controlSize(.regular)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(platformColor: .windowBackground).ignoresSafeArea())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Spectrum wird geladen")
    }
}


// MARK: - Favorites Section View

struct FavoritesSectionView: View {

    @Query(
        sort: \FavoriteStation.createdAt,
        order: .reverse
    )
    private var favoriteStations: [FavoriteStation]

    @Environment(\.modelContext)
    private var modelContext

    @Environment(PlaybackManager.self)
    private var playbackManager

    var body: some View {

        if favoriteStations.isEmpty {

            Text("Noch keine Favoriten vorhanden")
                .foregroundColor(.secondary)
                .italic()

        } else {

            ForEach(favoriteStations) { favorite in

                Button {

                    let station = RadioStation(
                        id: favorite.id,
                        name: favorite.name,
                        url: favorite.url.absoluteString,
                        favicon: favorite.favicon,
                        tags: favorite.tags
                    )

                    playbackManager.play(
                        station: station
                    )

                } label: {

                    HStack(spacing: 12) {

                        AsyncImage(
                            url: URL(
                                string: favorite.favicon
                            )
                        ) { phase in

                            if let image = phase.image {

                                image
                                    .resizable()
                                    .aspectRatio(
                                        contentMode: .fit
                                    )

                            } else {

                                Image(
                                    systemName: "radio"
                                )
                                .foregroundColor(
                                    .secondary
                                )
                            }

                        }
                        .frame(
                            width: 30,
                            height: 30
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 6
                            )
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 2
                        ) {

                            Text(favorite.name)
                                .font(.body)
                                .fontWeight(.medium)

                            if !favorite.tags.isEmpty {

                                Text(favorite.tags)
                                    .font(.caption)
                                    .foregroundColor(
                                        .secondary
                                    )
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if playbackManager.currentStation?.id ==
                            favorite.id &&
                            playbackManager.isPlaying {

                            LiquidLiveWaveformView(
                                isPlaying: true,
                                tint: .accentColor,
                                barCount: 3
                            )
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contextMenu {

                    Button(
                        role: .destructive
                    ) {

                        modelContext.delete(
                            favorite
                        )

                    } label: {

                        Label(
                            "Entfernen",
                            systemImage: "trash"
                        )
                    }
                }
            }
        }
    }
}


#if os(macOS)

// MARK: - macOS Content View

struct MacOSContentView: View {

    @Bindable var apiClient: RadioAPIClient

    @Binding var selectedSidebarItem:
        ContentView.SidebarItem?

    @Binding var activeCategoryType:
        RadioAPIClient.CategoryType

    @Binding var searchText: String

    @Binding var showSettings: Bool

    @Binding var showFullPlayer: Bool

    let playerAnimation: Namespace.ID

    @Environment(PlaybackManager.self)
    private var playbackManager

    var body: some View {

        NavigationSplitView {

            List(
                selection: $selectedSidebarItem
            ) {

                Text("Mediathek")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                NavigationLink(
                    value: ContentView.SidebarItem.favorites
                ) {
                    Label(
                        "Favorites",
                        systemImage: "star.fill"
                    )
                }

                NavigationLink(
                    value: ContentView.SidebarItem.discover
                ) {
                    Label(
                        "Discover",
                        systemImage: "safari.fill"
                    )
                }

                NavigationLink(
                    value: ContentView.SidebarItem.map
                ) {
                    Label(
                        "Karte",
                        systemImage: "map.fill"
                    )
                }
            }
            .foregroundColor(.primary)
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(
                min: 180,
                ideal: 220,
                max: 300
            )

        } detail: {

            Group {

                switch selectedSidebarItem {

                case .favorites:

                    List {

                        Section(
                            header: Text(
                                "Deine Favoriten"
                            )
                        ) {
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
                        StationMapView(
                            apiClient: apiClient
                        )
                    }
                }
            }
            .navigationTitle(
                titleForSelection(
                    selectedSidebarItem
                )
            )
            .safeAreaInset(
                edge: .bottom,
                spacing: 0
            ) {

                MiniPlayerView(
                    action: {
                        showFullPlayer = true
                    },
                    animation: playerAnimation
                )
            }
            .toolbar {

                ToolbarItem(
                    placement: .navigation
                ) {

                    Button {
                        showSettings = true
                    } label: {

                        Label(
                            "Einstellungen",
                            systemImage: "gearshape"
                        )
                    }
                    .help("Einstellungen")
                }

                if selectedSidebarItem == .discover {

                    ToolbarItem(
                        placement: .primaryAction
                    ) {

                        Menu {

                            Picker(
                                "Kategorie",
                                selection: $activeCategoryType
                            ) {

                                Label(
                                    "Länder",
                                    systemImage: "globe"
                                )
                                .tag(
                                    RadioAPIClient.CategoryType.country
                                )

                                Label(
                                    "Genres",
                                    systemImage: "music.note"
                                )
                                .tag(
                                    RadioAPIClient.CategoryType.genre
                                )
                            }

                        } label: {
                            Image(systemName: "globe")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView(onDismiss: {
                showFullPlayer = false
            })
        }
    }

    private func titleForSelection(_ item: ContentView.SidebarItem?) -> String {
        switch item {
        case .favorites:
            return "Favorites"
        case .discover:
            return "Discover"
        case .map, .none:
            return "Karte"
        }
    }
}

#endif
#endif
