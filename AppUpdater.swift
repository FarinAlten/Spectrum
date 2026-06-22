import Foundation
import Observation

struct GitHubRelease: Codable {
    let tagName: String
    let htmlUrl: String
    let body: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "FarinAlten"
        case htmlUrl = "https://github.com/FarinAlten/Spectrum"
        case body
    }
}

@Observable
final class AppUpdater {
    var isUpdateAvailable = false
    var latestReleaseURL: String?
    var updateChangelog: [String] = []
    var hasChecked = false
    
    func checkForUpdates() async {
        // TODO: Ersetze DEIN_GITHUB_NAME und DEIN_REPO_NAME mit deinen Projektdaten
        guard let url = URL(string: "https://api.github.com/repos/FarinAlten/Spectrum/releases/latest") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Spectrum-App-Updater", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            
            if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                let cleanTagName = release.tagName.replacingOccurrences(of: "v", with: "")
                
                if cleanTagName.compare(currentVersion, options: .numeric) == .orderedDescending {
                    await MainActor.run {
                        self.latestReleaseURL = release.htmlUrl
                        self.isUpdateAvailable = true
                        self.updateChangelog = release.body.components(separatedBy: "\r\n").filter { !$0.isEmpty }
                        self.hasChecked = true
                    }
                } else {
                    await MainActor.run {
                        self.isUpdateAvailable = false
                        self.hasChecked = true
                    }
                }
            }
        } catch {
            print("Fehler beim Update-Check: \(error)")
            await MainActor.run { self.hasChecked = true }
        }
    }
}
