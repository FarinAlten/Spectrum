import SwiftUI

struct RootContentView: View {
    @Environment(RadioAPIClient.self) private var apiClient
    @Environment(PlaybackManager.self) private var playbackManager
    
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif
    
    @State private var selectedSidebarItem: SidebarItem? = .discover
    @State private var navigationPath = NavigationPath()
    @State private var isShowingFullPlayer = false
    
    @AppStorage("hasCompletedInitialOnboarding") private var hasCompletedInitialOnboarding = false
    @State private var showInitialOnboarding = false
    
    enum SidebarItem: Hashable {
        case favorites
        case discover
    }
    
    var body: some View {
        #if os(iOS)
        if sizeClass == .compact {
            TabView(selection: $selectedSidebarItem) {
                NavigationStack(path: $navigationPath) {
                    FavoritesTabView()
                        .safeAreaPadding(.bottom, playbackManager.currentStation != nil ? 75 : 0)
                        .navigationDestination(for: SelectedCategory.self) { category in
                            StationGridView(categoryName: category.name, categoryType: category.type)
                        }
                }
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
                .tag(SidebarItem.favorites)
                
                NavigationStack(path: $navigationPath) {
                    CategorySelectionView()
                        .safeAreaPadding(.bottom, playbackManager.currentStation != nil ? 75 : 0)
                        .navigationDestination(for: SelectedCategory.self) { category in
                            StationGridView(categoryName: category.name, categoryType: category.type)
                        }
                }
                .tabItem {
                    Label("Discover", systemImage: "globe")
                }
                .tag(SidebarItem.discover)
            }
            .overlay(alignment: .bottom) {
                if playbackManager.currentStation != nil {
                    MiniPlayerView(action: {
                        isShowingFullPlayer = true
                    })
                    .padding(.horizontal, 12)
                    .padding(.bottom, 56)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playbackManager.currentStation)
            .sheet(isPresented: $isShowingFullPlayer) {
                FullPlayerView()
            }
            .task {
                checkOnboardingState()
            }
            .sheet(isPresented: $showInitialOnboarding, onDismiss: {
                hasCompletedInitialOnboarding = true
            }) {
                OnboardingView(isUpdate: false)
            }
        } else {
            regularSplitView
        }
        #else
        VStack(spacing: 0) {
            regularSplitView
            
            if playbackManager.currentStation != nil {
                Divider()
                MiniPlayerView(action: {
                    openWindow(id: "full-player")
                })
                .padding(12)
                .background(.ultraThinMaterial)
            }
        }
        .task {
            checkOnboardingState()
        }
        .sheet(isPresented: $showInitialOnboarding, onDismiss: {
            hasCompletedInitialOnboarding = true
        }) {
            OnboardingView(isUpdate: false)
        }
        #endif
    }
    
    private var regularSplitView: some View {
        NavigationSplitView {
            List(selection: $selectedSidebarItem) {
                Label("Favorites", systemImage: "star.fill")
                    .tag(SidebarItem.favorites)
                
                Label("Discover", systemImage: "globe")
                    .tag(SidebarItem.discover)
            }
            .listStyle(.sidebar)
            .navigationTitle("Spectrum")
        } detail: {
            NavigationStack(path: $navigationPath) {
                Group {
                    switch selectedSidebarItem {
                    case .favorites:
                        FavoritesTabView()
                        
                    case .discover:
                        CategorySelectionView()
                        
                    case .none:
                        ContentUnavailableView(
                            "Keine Auswahl",
                            systemImage: "radio",
                            description: Text("Wähle einen Bereich aus der Seitenleiste.")
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationDestination(for: SelectedCategory.self) { category in
                    StationGridView(categoryName: category.name, categoryType: category.type)
                }
                .safeAreaPadding(.bottom, playbackManager.currentStation != nil ? 16 : 0)
            }
        }
    }
    
    private func checkOnboardingState() {
        if !hasCompletedInitialOnboarding {
            showInitialOnboarding = true
        }
    }
}
