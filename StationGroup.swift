//
//  StationGroup.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
//
import Foundation

struct StationGroup: Identifiable, Hashable {
    let id: String // Name des Hauptsenders
    let mainStation: RadioStation
    var subStations: [RadioStation]
}
