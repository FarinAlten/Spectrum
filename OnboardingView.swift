import SwiftUI

enum OnboardingContent {
    static let welcomeTitle = "Willkommen bei Spectrum"
    static let welcomeFeatures = [
        "Globale Suche nach tausenden Sendern weltweit",
        "Intelligente Gruppierung von Regionalstationen",
        "Favoriten-Synchronisation mit SwiftData"
    ]
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    let isUpdate: Bool
    var updater: AppUpdater? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: isUpdate ? "sparkles" : "radio.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            if isUpdate {
                if let updater = updater {
                    if !updater.hasChecked {
                        ProgressView("Suche nach Updates...")
                        Spacer()
                    } else if updater.isUpdateAvailable {
                        Text("Neue Version verfügbar!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(updater.updateChangelog, id: \.self) { line in
                                HStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.accentColor)
                                    Text(line)
                                        .font(.body)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                        
                        Button(action: {
                            if let urlString = updater.latestReleaseURL, let url = URL(string: urlString) {
                                openURL(url)
                                dismiss()
                            }
                        }) {
                            Text("Update auf GitHub herunterladen")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        
                    } else {
                        Text("Spectrum ist aktuell")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Du nutzt bereits die neueste Version.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                Button("Schließen") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
                
            } else {
                Text(OnboardingContent.welcomeTitle)
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(OnboardingContent.welcomeFeatures, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(feature)
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Fortfahren")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(minWidth: 340, minHeight: 460)
    }
}
