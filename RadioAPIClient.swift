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
    var hasMoreStations = true
    
    private var currentCategoryValue: String = ""
    private var currentCategoryType: CategoryType = .country
    private var currentOffset = 0
    private let pageSize = 100
    
    enum CategoryType: Hashable {
        case country
        case genre
        case search
    }
    
    private var activeBaseURL: URL = URL(string: "https://de1.api.radio-browser.info/json")!
    private var isBaseURLResolved = false
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
    
    private func filterUniqueNames(_ incomingStations: [RadioStation], existingNames: inout Set<String>) -> [RadioStation] {
        var uniqueStations: [RadioStation] = []
        
        for station in incomingStations {
            let cleanName = station.name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            
            guard !cleanName.isEmpty else { continue }
            
            if !existingNames.contains(cleanName) {
                existingNames.insert(cleanName)
                uniqueStations.append(station)
            }
        }
        
        return uniqueStations
    }
    
    private func ensureValidBaseURL() async {
        if isBaseURLResolved { return }
        
        guard let url = URL(string: "https://all.api.radio-browser.info/json/servers") else { return }
        
        do {
            let (data, _) = try await apiSession.data(from: url)
            struct APIServer: Codable { let name: String }
            let servers = try JSONDecoder().decode([APIServer].self, from: data)
            
            if let randomServer = servers.randomElement() {
                if let newURL = URL(string: "https://\(randomServer.name)/json") {
                    self.activeBaseURL = newURL
                    self.isBaseURLResolved = true
                }
            }
        } catch {
            isBaseURLResolved = true
        }
    }
    
    func fetchStationsInRegion(latitude: Double, longitude: Double, latDelta: Double, lonDelta: Double) async {
        currentMapTask?.cancel()
        
        guard latDelta < 120.0 else { return }
        
        currentMapTask = Task {
            await ensureValidBaseURL()
            
            if Task.isCancelled { return }
            
            let minLat = latitude - (latDelta / 2.0)
            let maxLat = latitude + (latDelta / 2.0)
            let minLon = longitude - (lonDelta / 2.0)
            let maxLon = longitude + (lonDelta / 2.0)
            
            let dynamicLimit = latDelta > 20.0 ? 400 : 200
            
            guard let url = URL(string: "\(activeBaseURL.absoluteString)/stations/search?minlatitude=\(minLat)&maxlatitude=\(maxLat)&minlongitude=\(minLon)&maxlongitude=\(maxLon)&limit=\(dynamicLimit)&has_geo=true&hidebroken=true&order=clickcount&reverse=true") else {
                return
            }
            
            do {
                let (data, _) = try await apiSession.data(from: url)
                if Task.isCancelled { return }
                let decodedStations = try JSONDecoder().decode([RadioStation].self, from: data)
                
                await MainActor.run {
                    var seenNames = Set<String>()
                    self.stations = self.filterUniqueNames(decodedStations, existingNames: &seenNames)
                }
            } catch {
                if !(error is CancellationError) {
                    print("Fehler beim Laden der regionalen Stationen: \(error)")
                }
            }
        }
    }
    
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
                var seenNames = Set<String>()
                self.stations = self.filterUniqueNames(decodedStations, existingNames: &seenNames)
                self.isLoading = false
            }
        } catch {
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
        } catch {}
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
        } catch {}
    }
    
    func fetchStations(for value: String, type: CategoryType) async {
        guard type != .search else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.stations = []
            self.currentOffset = 0
            self.hasMoreStations = true
            self.currentCategoryValue = value
            self.currentCategoryType = type
        }
        
        await ensureValidBaseURL()
        await loadStationsPage(reset: true)
    }
    
    func loadMoreStations() async {
        guard !isLoading && hasMoreStations else { return }
        await MainActor.run { self.isLoading = true }
        await loadStationsPage(reset: false)
    }
    
    private func loadStationsPage(reset: Bool) async {
        let endpoint = currentCategoryType == .country ? "bycountry" : "bytag"
        
        guard let encodedValue = currentCategoryValue.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(activeBaseURL.absoluteString)/stations/\(endpoint)/\(encodedValue)?order=clickcount&reverse=true&hidebroken=true&offset=\(currentOffset)&limit=\(pageSize)") else {
            await MainActor.run { self.isLoading = false }
            return
        }
        
        do {
            let (data, _) = try await apiSession.data(from: url)
            let newStations = try JSONDecoder().decode([RadioStation].self, from: data)
            
            await MainActor.run {
                if reset {
                    var seenNames = Set<String>()
                    self.stations = self.filterUniqueNames(newStations, existingNames: &seenNames)
                } else {
                    var existingNames = Set(self.stations.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
                    let uniqueNewStations = self.filterUniqueNames(newStations, existingNames: &existingNames)
                    self.stations.append(contentsOf: uniqueNewStations)
                }
                
                self.currentOffset += newStations.count
                self.hasMoreStations = newStations.count >= self.pageSize
                self.isLoading = false
            }
        } catch {
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
                var seenNames = Set<String>()
                self.searchResults = self.filterUniqueNames(sortedResults, existingNames: &seenNames)
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
}

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
