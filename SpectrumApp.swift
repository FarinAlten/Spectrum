import SwiftUI
import AVFoundation
import SwiftData

@main
struct SpectrumApp: App {
    @State private var apiClient = RadioAPIClient()
    @State private var playbackManager = PlaybackManager()
    
    #if os(macOS)
    @State private var updater = AppUpdater()
    @State private var showMacUpdateSheet = false
    #endif
    
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
                #if os(macOS)
                .environment(updater)
                .sheet(isPresented: $showMacUpdateSheet) {
                    OnboardingView(isUpdate: true, updater: updater)
                }
                #endif
        }
        .modelContainer(for: FavoriteStation.self)
        .commands {
            #if os(macOS)
            CommandGroup(after: .appInfo) {
                Button("Nach Updates suchen...") {
                    updater.hasChecked = false
                    showMacUpdateSheet = true
                    Task {
                        await updater.checkForUpdates()
                    }
                }
                .keyboardShortcut("U", modifiers: .command)
            }
            #endif
        }
        
        #if os(macOS)
        WindowGroup(id: "full-player") {
            FullPlayerView()
                .environment(playbackManager)
                .modelContainer(for: FavoriteStation.self)
                .frame(minWidth: 380, idealWidth: 400, minHeight: 550, idealHeight: 600)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
