import SwiftUI
import AVFoundation

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
                // Öffnet das Info-Sheet, sobald der Menü-Button gedrückt wird
                .sheet(isPresented: $showMacUpdateSheet) {
                    OnboardingView(isUpdate: true, updater: updater)
                }
                #endif
        }
        .commands {
            #if os(macOS)
            CommandGroup(after: .appInfo) {
                Button("Nach Updates suchen...") {
                    // Setzt den Status zurück, damit die Ladeanimation startet
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
    }
}
