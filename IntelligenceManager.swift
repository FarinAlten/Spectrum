//
//  IntelligenceManager.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
//
import Foundation
import Observation

@Observable
final class IntelligenceManager {
    func performSearch(matching query: String, using apiClient: RadioAPIClient) async {
        // Sicherstellen, dass der Suchbegriff nicht leer ist
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        await apiClient.searchStations(matching: query)
    }
}
