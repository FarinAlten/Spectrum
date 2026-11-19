//
//  AppUpdater.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//

#if os(macOS)
import Foundation
import SwiftUI
#if canImport(Sparkle)
import Sparkle

// MARK: - Sparkle Controller Wrapper
@Observable
final class AppUpdater: NSObject, SPUUpdaterDelegate {
    private var updaterController: SPUStandardUpdaterController!
    
    override init() {
        super.init()
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }
    
    /// Stößt manuell oder automatisch die Prüfung an
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
    
    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }
}
#else
@Observable
final class AppUpdater: NSObject {
    func checkForUpdates() {
        if let url = URL(string: "https://github.com/farin/Spectrum/releases") {
            NSWorkspace.shared.open(url)
        }
    }
    
    var canCheckForUpdates: Bool {
        true
    }
}
#endif
#endif
