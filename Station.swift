//
//  Station.swift
//  Spectrum
//
//  Created by Farin  on 6/14/26.
//
import Foundation

struct Station: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let url: URL
    let favicon: String?
    let tags: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "stationuuid" // Mapping auf den eindeutigen API-Schlüssel von Radio-Browser
        case name
        case url
        case favicon
        case tags
    }
    
    // Failsafe-Initialisierer für die Decodierung unvollständiger API-Daten
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        // Fängt ungültige oder leere URL-Strings ab
        let urlString = try container.decode(String.self, forKey: .url)
        if let decodedURL = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) {
            self.url = decodedURL
        } else {
            throw DecodingError.dataCorruptedError(forKey: .url, in: container, debugDescription: "Ungültige Stream-URL")
        }
        
        self.favicon = try container.decodeIfPresent(String.self, forKey: .favicon)
        self.tags = try container.decodeIfPresent(String.self, forKey: .tags)
    }
}
// Ergänzung in Station.swift, damit das Mapping in der View fehlerfrei kompiliert
extension Station {
    init(id: String, name: String, url: URL, favicon: String?, tags: String?) {
        self.id = id
        self.name = name
        self.url = url
        self.favicon = favicon
        self.tags = tags
    }
}
