import Foundation
import Observation

@Observable
final class IntelligenceManager {
    // Falls apiClient global im Manager existieren soll, hier deklarieren:
    // var apiClient = RadioAPIClient()
    
    /// Führt die Sendersuche mit den korrekt übergebenen Parametern aus
    func performSearch(matching query: String, using apiClient: RadioAPIClient) async {
        // Sicherstellen, dass der Suchbegriff nicht leer ist
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Behebt beide 'Cannot find in scope'-Fehler durch Nutzung der Parameter
        await apiClient.searchStations(matching: query)
    }
}
