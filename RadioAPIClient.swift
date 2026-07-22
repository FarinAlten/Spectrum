//
//  RadioAPIClient.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//
import Foundation

@Observable
final class RadioAPIClient {
    var countries: [String] = []
    var genres: [String] = []
    var stations: [RadioStation] = []
    var searchResults: [RadioStation] = []
    var isLoading = false
    
    enum CategoryType: Hashable {
        case country
        case genre
        case search
    }
    
    // Aktuell ausgewählter, funktionierender Base-URL Mirror
    private var activeBaseURL: URL = URL(string: "https://de1.api.radio-browser.info/json")!
    private var isBaseURLResolved = false
    
    // Hält die Referenz zum aktuellen Karten-Task, um ihn bei Bewegung abzubrechen
    private var currentMapTask: Task<Void, Never>?
    
    private var apiSession: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": "SpectrumRadioApp/1.0",
            "Accept": "application/json"
        ]
        configuration.timeoutIntervalForRequest = 10.0
        return URLSession(configuration: configuration)
    }
    
    /// Holt dynamisch einen fitten Mirror-Server, falls noch nicht geschehen
    private func ensureValidBaseURL() async {
        if isBaseURLResolved { return }
        
        guard let url = URL(string: "https://all.api.radio-browser.info/json/servers") else { return }
        
        do {
            let (data, _) = try await apiSession.data(from: url)
            struct APIServer: Codable { let name: String }
            let servers = try JSONDecoder().decode([APIServer].self, from: data)
            
            // Wähle zufällig einen Server aus, um die Last perfekt zu verteilen
            if let randomServer = servers.randomElement() {
                if let newURL = URL(string: "https://\(randomServer.name)/json") {
                    self.activeBaseURL = newURL
                    self.isBaseURLResolved = true
                    print("🌐 Erfolgreich verbunden mit Mirror: \(newURL.absoluteString)")
                }
            }
        } catch {
            print("⚠️ Mirror-Auflösung fehlgeschlagen, nutze Fallback-Server: \(error)")
            isBaseURLResolved = true
        }
    }
    
    // Lädt Sender dynamisch basierend auf dem aktuellen Kartenausschnitt
    func fetchStationsInRegion(latitude: Double, longitude: Double, latDelta: Double, lonDelta: Double) async {
        // Alten Task sofort abbrechen, um API-Spam zu verhindern
        currentMapTask?.cancel()
        
        // Begrenzung deutlich erhöht: Lädt jetzt auch bei sehr weitem Herauszoomen (z.B. Kontinent-Ebene)
        guard latDelta < 120.0 else { return }
        
        currentMapTask = Task {
            await ensureValidBaseURL()
            
            if Task.isCancelled { return }
            
            // Berechne die Bounding Box aus Zentrum und Zoom-Delta
            let minLat = latitude - (latDelta / 2.0)
            let maxLat = latitude + (latDelta / 2.0)
            let minLon = longitude - (lonDelta / 2.0)
            let maxLon = longitude + (lonDelta / 2.0)
            
            // DYNAMISCHES LIMIT: Wenn weit herausgezoomt ist, fordern wir mehr Stationen (400) an,
            // damit große Gebiete nicht leer wirken. Nah dran reichen 150 für beste Performance.
            let dynamicLimit = latDelta > 20.0 ? 400 : 150
            
            guard let url = URL(string: "\(activeBaseURL.absoluteString)/stations/search?minlatitude=\(minLat)&maxlatitude=\(maxLat)&minlongitude=\(minLon)&maxlongitude=\(maxLon)&limit=\(dynamicLimit)&has_geo=true&hidebroken=true&order=clickcount&reverse=true") else {
                return
            }
            
            do {
                let (data, _) = try await apiSession.data(from: url)
                
                if Task.isCancelled { return }
                
                let decodedStations = try JSONDecoder().decode([RadioStation].self, from: data)
                
                await MainActor.run {
                    self.stations = decodedStations
                    print("🗺️ Region-Update: \(decodedStations.count) Sender geladen (Delta: \(latDelta)).")
                }
            } catch {
                if !(error is CancellationError) {
                    print("Fehler beim Laden der regionalen Stationen: \(error)")
                }
            }
        }
    }
    
    // Lädt bis zu 250 Top-Sender eines spezifischen Landes mit Geo-Daten für die Karte
    func fetchTopStationsForMap(country: String = "Germany") async {
        guard !isLoading else { return }
        await MainActor.run { self.isLoading = true }
        
        await ensureValidBaseURL()
        
        guard let encodedCountry = country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(activeBaseURL.absoluteString)/stations/search?limit=250&country=\(encodedCountry)&has_geo=true&hidebroken=true&order=clickcount&reverse=true") else {
            await MainActor.run { self.isLoading = false }
            return
        }
        
        do {
            let (data, _) = try await apiSession.data(from: url)
            let decodedStations = try JSONDecoder().decode([RadioStation].self, from: data)
            await MainActor.run {
                self.stations = decodedStations
                self.isLoading = false
                print("🗺️ Karte: \(decodedStations.count) Sender für \(country) erfolgreich geladen.")
            }
        } catch {
            print("Fehler beim Laden der Karten-Stationen: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
    
    func fetchDiscoverData() async {
        guard !isLoading else { return }
        await MainActor.run { self.isLoading = true }
        
        await ensureValidBaseURL()
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchCountries() }
            group.addTask { await self.fetchGenres() }
        }
        
        await MainActor.run { self.isLoading = false }
    }
    
    private func fetchCountries() async {
        guard let url = URL(string: "\(activeBaseURL.absoluteString)/countries") else { return }
        do {
            let (data, _) = try await apiSession.data(from: url)
            let apiCountries = try JSONDecoder().decode([APICountry].self, from: data)
            await MainActor.run {
                self.countries = apiCountries
                    .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .sorted()
            }
        } catch {
            print("Fehler beim Laden der Länder: \(error)")
        }
    }
    
    private func fetchGenres() async {
        guard let url = URL(string: "\(activeBaseURL.absoluteString)/tags") else { return }
        do {
            let (data, _) = try await apiSession.data(from: url)
            let apiTags = try JSONDecoder().decode([APITag].self, from: data)
            await MainActor.run {
                self.genres = apiTags
                    .filter { $0.stationcount > 100 }
                    .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .sorted()
            }
        } catch {
            print("Fehler beim Laden der Genres: \(error)")
        }
    }
    
    func fetchStations(for value: String, type: CategoryType) async {
        guard type != .search else { return }
        await MainActor.run { self.isLoading = true }
        
        await ensureValidBaseURL()
        
        let endpoint: String
        switch type {
        case .country:
            endpoint = "bycountry"
        case .genre:
            endpoint = "bytag"
        case .search:
            await MainActor.run { self.isLoading = false }
            return
        }
        
        guard let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(activeBaseURL.absoluteString)/stations/\(endpoint)/\(encodedValue)?order=clickcount&reverse=true&hidebroken=true&has_geo=true") else {
            await MainActor.run { self.isLoading = false }
            return
        }
        
        do {
            let (data, _) = try await apiSession.data(from: url)
            let decodedStations = try JSONDecoder().decode([RadioStation].self, from: data)
            await MainActor.run {
                self.stations = decodedStations
                self.isLoading = false
            }
        } catch {
            print("Fehler beim Laden der Stationen: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
    
    func searchStations(matching query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                self.searchResults = []
                self.isLoading = false
            }
            return
        }
        
        await MainActor.run { self.isLoading = true }
        await ensureValidBaseURL()
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(activeBaseURL.absoluteString)/stations/byname/\(encodedQuery)") else {
            await MainActor.run { self.isLoading = false }
            return
        }
        
        do {
            let (data, _) = try await apiSession.data(from: url)
            let decodedResults = try JSONDecoder().decode([RadioStation].self, from: data)
            
            let sortedResults = decodedResults.sorted { $0.clickcount > $1.clickcount }
            
            await MainActor.run {
                self.searchResults = sortedResults
                self.isLoading = false
            }
        } catch {
            print("Fehler bei der Sendersuche: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

// MARK: - API Helper Models
struct APICountry: Codable {
    let name: String
    let iso3166_1: String?
    let stationcount: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case iso3166_1 = "iso_3166_1"
        case stationcount
    }
}

struct APITag: Codable {
    let name: String
    let stationcount: Int
}
