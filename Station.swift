//
//  Station.swift
//  Spectrum
//
//  Created by Farin  on 6/14/26.
//
import Foundation

struct RadioStation: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let url: String
    let favicon: String
    let tags: String
    let clickcount: Int
    
    // Geo-Daten für das MapKit
    let latitude: Double?
    let longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case id = "stationuuid"
        case name
        case url = "url_resolved" // Mappt auf den korrekten API-Stream-Key
        case favicon
        case tags
        case clickcount
        case latitude = "geo_lat"
        case longitude = "geo_long"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(String.self, forKey: .url).trimmingCharacters(in: .whitespacesAndNewlines)
        self.favicon = try container.decodeIfPresent(String.self, forKey: .favicon) ?? ""
        self.tags = try container.decodeIfPresent(String.self, forKey: .tags) ?? ""
        self.clickcount = try container.decodeIfPresent(Int.self, forKey: .clickcount) ?? 0
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
    }
}

extension RadioStation {
    init(id: String, name: String, url: String, favicon: String?, tags: String?, clickcount: Int = 0, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.favicon = favicon ?? ""
        self.tags = tags ?? ""
        self.clickcount = clickcount
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var shareURL: URL? {
        URL(string: url)
    }
}
