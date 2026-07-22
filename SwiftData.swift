//
//  SwiftData.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
//
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
    
    convenience init(fromStationWithID id: String, name: String, urlString: String, favicon: String, tags: String) {
        let stationURL = URL(string: urlString) ?? URL(string: "about:blank")!
        self.init(
            id: id,
            name: name,
            url: stationURL,
            favicon: favicon,
            tags: tags
        )
    }
    
    convenience init(from station: RadioStation) {
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
