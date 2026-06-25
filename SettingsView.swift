import SwiftUI

struct SettingsView: View {
    @AppStorage("highAudioQuality") private var highAudioQuality = true
    @AppStorage("onDeviceProcessing") private var onDeviceProcessing = true
    @AppStorage("selectedTheme") private var selectedTheme = 0
    @AppStorage("autoCacheClear") private var autoCacheClear = false
    
    @Environment(\.dismiss) private var dismiss
    
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        Form {
            Section(header: Text("Playback")) {
                Toggle(isOn: $highAudioQuality) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("High Audio Quality")
                            .font(.body)
                        Text("Prefers uncompressed streams")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                #if os(macOS)
                .toggleStyle(.checkbox)
                #endif
                
                Toggle(isOn: $autoCacheClear) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear Cache Automatically")
                            .font(.body)
                        Text("Deletes station art icons on exit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                #if os(macOS)
                .toggleStyle(.checkbox)
                #endif
            }
            
            Section(header: Text("Open Source")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Radio Browser API")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("This application utilizes the free and community-driven radio-browser.info directory service. All stream links and station metadata are provided by their open-source database.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Link(destination: URL(string: "https://www.radio-browser.info")!) {
                        HStack(spacing: 4) {
                            Text("Visit Radio Browser Website")
                            Image(systemName: "arrow.up.forward.app")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                    }
                    .padding(.top, 2)
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("General")) {
                LabeledContent("Developer") {
                    Text("Farin Altenhöner")
                        .foregroundColor(.secondary)
                }
                
                LabeledContent("Version") {
                    Text(appVersionString)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(minWidth: 280, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
            #endif
        }
    }
}
