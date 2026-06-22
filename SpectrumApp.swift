import SwiftUI
import AVFoundation

@main
struct SpectrumApp: App {
    @State private var apiClient = RadioAPIClient()
    @State private var playbackManager = PlaybackManager()
    
    init() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Fehler bei der Audio-Session-Initialisierung: \(error)")
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environment(apiClient)
                .environment(playbackManager)
        }
        
        // Neues, separates Fenster für den Player unter macOS
        #if os(macOS)
        WindowGroup("Now Playing", id: "full-player") {
            FullPlayerView()
                .environment(playbackManager)
                .frame(minWidth: 380, idealWidth: 400, minHeight: 550, idealHeight: 600)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
