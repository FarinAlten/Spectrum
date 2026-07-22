//
//  IntelligenceManager.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
//
import Foundation
import Observation

/// A minimal protocol to resolve ambiguity and improve testability.
protocol RadioAPIClientProtocol {
    func searchStations(matching query: String) async
}

@Observable
final class IntelligenceManager {
    // If 'RadioAPIClient' remains ambiguous, qualify it with its module (e.g., MyNetworking.RadioAPIClient) or use a protocol type.
    func performSearch(matching query: String, using client: RadioAPIClientProtocol) async {
        // Sicherstellen, dass der Suchbegriff nicht leer ist
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        await client.searchStations(matching: query)
    }
}

