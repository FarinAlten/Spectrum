//
//  SpectrumCore.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//
import SwiftUI
import SwiftData

#if !os(watchOS)
@main
struct SpectrumApp: App {
    @State private var playbackManager = PlaybackManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(playbackManager)
        }
        .modelContainer(for: FavoriteStation.self)
    }
}
#endif

