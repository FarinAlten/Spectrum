import Foundation
import SwiftData

@Model
final class FavoriteStation {
    @Attribute(.unique) var id: String
    var name: String
    var url: URL
    var favicon: String
    var tags: String
    var createdAt: Date

    init(id: String, name: String, url: URL, favicon: String, tags: String) {
        self.id = id
        self.name = name
        self.url = url
        self.favicon = favicon
        self.tags = tags
        self.createdAt = Date()
    }
    
    // KORREKTUR: Initialisierer auf das neue RadioStation-Modell umgestellt
    convenience init(from station: RadioStation) {
        // Wandelt den url-String aus RadioStation in ein valides URL-Objekt um (Fallback auf leere URL im Fehlerfall)
        let stationURL = URL(string: station.url) ?? URL(string: "about:blank")!
        
        self.init(
            id: station.id,
            name: station.name,
            url: stationURL,
            favicon: station.favicon,
            tags: station.tags
        )
    }
}
