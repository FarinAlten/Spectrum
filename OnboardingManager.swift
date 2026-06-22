//
//  OnboardingManager.swift
//  Spectrum
//
//  Created by Farin  on 6/22/26.
//
import SwiftUI

struct UpdateRelease {
    let version: String
    let title: String
    let features: [String]
}

enum OnboardingContent {
    // Inhalte für die allererste Installation
    static let welcomeTitle = "Willkommen bei Spectrum"
    static let welcomeFeatures = [
        "Globale Suche nach tausenden Sendern",
        "Intelligente Gruppierung von Regionalstationen",
        "Favoriten-Synchronisation mit SwiftData"
    ]
    
    // HIER STEUERST DU DEINE UPDATES: Sobald du die Version erhöhst, ploppt das Update-Onboarding auf
    static let currentAppVersion = "1.1.0"
    
    static let currentUpdate = UpdateRelease(
        version: currentAppVersion,
        title: "Neu in Version \(currentAppVersion)",
        features: [
            "Fehlerbehebungen beim Favoriten-Speichern",
            "Automatischer Filter für defekte Stream-Formate",
            "Plattform-Optimierungen für macOS"
        ]
    )
}
