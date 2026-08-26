import SwiftUI
import SwiftData

@main
struct WatchSpectrumApp: App {
    @State private var playbackManager = PlaybackManager()
    @State private var apiClient = RadioAPIClient()
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(playbackManager)
                .environment(apiClient)
        }
        .modelContainer(for: FavoriteStation.self)
    }
}
