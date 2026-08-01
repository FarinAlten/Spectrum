//
//  AppUpdater.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//
import Foundation
import Sparkle
import SwiftUI

// MARK: - Sparkle Controller Wrapper
@Observable
final class AppUpdater: NSObject, SPUUpdaterDelegate {
    private var updaterController: SPUStandardUpdaterController!
    
    override init() {
        super.init()
        // Initialisiert Sparkle mit dem Standard-UI-Dialog von macOS
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

