//
//  RadioAPIClient.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
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
    
    private var baseURL: URL {
        return URL(string: "https://de1.api.radio-browser.info/json")!
    }
    
    private var apiSession: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": "SpectrumRadioApp/1.0",
            "Accept": "application/json"
        ]
        configuration.timeoutIntervalForRequest = 10.0
        return URLSession(configuration: configuration)
    }
    
    func fetchDiscoverData() async {
        guard !isLoading else { return }
        await MainActor.run { self.isLoading = true }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchCountries() }
            group.addTask { await self.fetchGenres() }
        }
        
        await MainActor.run { self.isLoading = false }
    }
    
    private func fetchCountries() async {
        guard let url = URL(string: "\(baseURL.absoluteString)/countries") else { return }
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
        guard let url = URL(string: "\(baseURL.absoluteString)/tags") else { return }
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
              let url = URL(string: "\(baseURL.absoluteString)/stations/\(endpoint)/\(encodedValue)?order=clickcount&reverse=true&hidebroken=true") else {
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
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL.absoluteString)/stations/byname/\(encodedQuery)") else {
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


struct APICountry: Codable {
    let name: String
}

struct APITag: Codable {
    let name: String
    let stationcount: Int
}

struct SelectedCategory: Hashable {
    let name: String
    let type: RadioAPIClient.CategoryType
}

struct RadioStation: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let url: String
    let favicon: String
    let tags: String
    let clickcount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "stationuuid"
        case name
        case url
        case favicon
        case tags
        case clickcount
    }
}
