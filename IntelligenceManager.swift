//
//  IntelligenceManager.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
//
import Foundation
import Observation

protocol RadioAPIClientProtocol {
    func searchStations(matching query: String) async
}

@Observable
final class IntelligenceManager {
    func performSearch(matching query: String, using client: RadioAPIClientProtocol) async {
        // Sicherstellen, dass der Suchbegriff nicht leer ist
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        await client.searchStations(matching: query)
    }
}

