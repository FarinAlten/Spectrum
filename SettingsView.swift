//
//  SettingsView.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

fileprivate struct JSONDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        if let file = configuration.file.regularFileContents {
            self.data = file
        } else {
            self.data = Data()
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - App Version Helper
extension Bundle {
    var appVersionString: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Custom Settings Icon Style
struct SettingsIcon: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 26, height: 26)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Enum für macOS-Selektion
enum SettingsTab: Hashable, CaseIterable {
    case appearance
    case audio
    case privacy
    case info
    
    var title: LocalizedStringKey {
        switch self {
        case .appearance: return "Settings_Row_AppearanceAndLayout"
        case .audio: return "Settings_Row_AudioPlayback"
        case .privacy: return "Settings_Row_PrivacyData"
        case .info: return "Settings_Section_Info"
        }
    }
}

// MARK: - Main Settings View
struct SettingsView: View {
    @Query private var storedFavorites: [FavoriteStation] // Query hier in der Haupt-View!
    
    @AppStorage("accentColorSelection") private var accentColorSelection = "blue"
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTab: SettingsTab? = .appearance
    
    private var matchesSearch: (String) -> Bool {
        { title in
            searchText.isEmpty || title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            // Linke Custom Sidebar
            VStack(spacing: 12) {
                // Suchfeld oben
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Einstellungen suchen", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 10)
                .padding(.top, 10)

                // Navigationselemente
                ScrollView {
                    VStack(spacing: 4) {
                        if matchesSearch("Erscheinungsbild") || matchesSearch("Layout") || matchesSearch("Appearance") {
                            sidebarRow(title: "Settings_Row_AppearanceAndLayout", icon: "paintpalette.fill", color: .orange, tab: .appearance)
                        }
                        
                        if matchesSearch("Audio") || matchesSearch("Wiedergabe") {
                            sidebarRow(title: "Settings_Row_AudioPlayback", icon: "waveform", color: .purple, tab: .audio)
                        }
                        
                        if matchesSearch("Datenschutz") || matchesSearch("Export") || matchesSearch("Import") || matchesSearch("Privacy") {
                            sidebarRow(title: "Settings_Row_PrivacyData", icon: "hand.raised.fill", color: .blue, tab: .privacy)
                        }
                        
                        if matchesSearch("Info") || matchesSearch("Version") || matchesSearch("Build") {
                            sidebarRow(title: "Settings_Section_Info", icon: "info.circle.fill", color: .gray, tab: .info)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(width: 230)
            .background(Color(nsColor: .underPageBackgroundColor).opacity(0.4))

            Divider()

            // Rechter Detail-Bereich
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(selectedTab?.title ?? "")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                Divider()

                ScrollView {
                    Group {
                        switch selectedTab {
                        case .appearance:
                            AppearanceSettingsView()
                        case .audio:
                            AudioSettingsView()
                        case .privacy:
                            PrivacyAndDataSettingsView(storedFavorites: storedFavorites)
                        case .info:
                            MacInfoSettingsView()
                        case .none:
                            AppearanceSettingsView()
                        }
                    }
                    .padding(16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 650, height: 460)
        .tint(getAccentColor(accentColorSelection))
        #else
        // Klassische iOS Inset-Grouped Liste
        NavigationStack {
            List {
                // SECTION: CUSTOMIZE / DARSTELLUNG
                if matchesSearch("Erscheinungsbild") || matchesSearch("Layout") || matchesSearch("Appearance") {
                    Section {
                        NavigationLink(destination: AppearanceSettingsView()) {
                            Label {
                                Text("Settings_Row_AppearanceAndLayout")
                            } icon: {
                                SettingsIcon(systemName: "paintpalette.fill", color: .orange)
                            }
                        }
                    } header: {
                        Text("Settings_Section_Appearance")
                    }
                }
                
                // SECTION: AUDIO & DATEN
                if matchesSearch("Audio") || matchesSearch("Wiedergabe") || matchesSearch("Datenschutz") || matchesSearch("Export") || matchesSearch("Import") {
                    Section {
                        if matchesSearch("Audio") || matchesSearch("Wiedergabe") {
                            NavigationLink(destination: AudioSettingsView()) {
                                Label {
                                    Text("Settings_Row_AudioPlayback")
                                } icon: {
                                    SettingsIcon(systemName: "waveform", color: .purple)
                                }
                            }
                        }
                        
                        if matchesSearch("Datenschutz") || matchesSearch("Export") || matchesSearch("Import") || matchesSearch("Privacy") {
                            NavigationLink(destination: PrivacyAndDataSettingsView(storedFavorites: storedFavorites)) {
                                Label {
                                    Text("Settings_Row_PrivacyData")
                                } icon: {
                                    SettingsIcon(systemName: "hand.raised.fill", color: .blue)
                                }
                            }
                        }
                    } header: {
                        Text("Settings_Section_AppOptions")
                    }
                }
                
                // SECTION: ABOUT / INFO
                if matchesSearch("Info") || matchesSearch("Version") || matchesSearch("Entwickler") || matchesSearch("Build") {
                    Section {
                        HStack(alignment: .center) {
                            Label {
                                Text("Settings_Row_Credits")
                            } icon: {
                                SettingsIcon(systemName: "person.text.rectangle.fill", color: .teal)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(localized: "Info_Developer_Name"))
                                    .fontWeight(.medium)
                                Text(String(localized: "Settings_Row_MadeInGermany"))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Label {
                                Text("Settings_Row_Version")
                            } icon: {
                                SettingsIcon(systemName: "info.circle.fill", color: .gray)
                            }
                            Spacer()
                            Text(Bundle.main.appVersionString)
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Settings_Section_Info")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, placement: .automatic, prompt: "Einstellungen suchen")
            .tint(getAccentColor(accentColorSelection))
            .navigationTitle("Settings_Title_Main")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        #endif
    }
}

// MARK: - macOS Sidebar Builder Extension
#if os(macOS)
extension SettingsView {
    @ViewBuilder
    private func sidebarRow(title: LocalizedStringKey, icon: String, color: Color, tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab
        
        Button(action: {
            selectedTab = tab
        }) {
            HStack(spacing: 10) {
                SettingsIcon(systemName: icon, color: color)
                
                Text(title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? getAccentColor(accentColorSelection) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
#endif

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @AppStorage("preferredDisplayMode") private var preferredDisplayMode = "grid"
    @AppStorage("maxGridColumns") private var maxGridColumns = 4
    @AppStorage("showFlagsAndEmojis") private var showFlagsAndEmojis = true
    @AppStorage("accentColorSelection") private var accentColorSelection = "blue"
    
    var body: some View {
        Form {
            Section {
                Picker("Appearance_Label_Layout", selection: $preferredDisplayMode) {
                    Text("Appearance_Option_Grid").tag("grid")
                    Text("Appearance_Option_List").tag("list")
                }
                .pickerStyle(.segmented)
                
                if preferredDisplayMode == "grid" {
                    Stepper(value: $maxGridColumns, in: 2...5) {
                        Text(String(localized: "Appearance_Label_Columns")) + Text(": ") + Text("**\(maxGridColumns)**")
                    }
                }
            }
            
            Section {
                Picker("Appearance_Label_AccentColor", selection: $accentColorSelection) {
                    Text("Color_Option_Blue").tag("blue")
                    Text("Color_Option_Purple").tag("purple")
                    Text("Color_Option_Orange").tag("orange")
                    Text("Color_Option_Red").tag("red")
                    Text("Color_Option_Green").tag("green")
                }
                
                Toggle(String(localized: "Appearance_Toggle_ShowVisualSymbols"), isOn: $showFlagsAndEmojis)
            }
        }
        #if !os(macOS)
        .formStyle(.grouped)
        .navigationTitle("Settings_Row_AppearanceAndLayout")
        #endif
        .tint(getAccentColor(accentColorSelection))
    }
}

// MARK: - Audio Settings
struct AudioSettingsView: View {
    @AppStorage("streamQuality") private var streamQuality = "high"
    @AppStorage("autoPlayOnStart") private var autoPlayOnStart = false
    @AppStorage("fadeTransitions") private var fadeTransitions = true
    @AppStorage("bufferSize") private var bufferSize = "medium"
    
    var body: some View {
        Form {
            Section {
                Picker("Audio_Label_Quality", selection: $streamQuality) {
                    Text("Audio_Option_HQ").tag("high")
                    Text("Audio_Option_LQ").tag("low")
                }
                .pickerStyle(.segmented)
                
                Picker("Audio_Label_BufferSize", selection: $bufferSize) {
                    Text("Audio_Buffer_Small").tag("small")
                    Text("Audio_Buffer_Medium").tag("medium")
                    Text("Audio_Buffer_Large").tag("large")
                }
            }
            
            Section {
                Toggle(String(localized: "Audio_Toggle_AutoPlayOnStart"), isOn: $autoPlayOnStart)
                Toggle(String(localized: "Audio_Toggle_CrossfadeOnStationChange"), isOn: $fadeTransitions)
            }
        }
        #if !os(macOS)
        .formStyle(.grouped)
        .navigationTitle("Settings_Row_AudioPlayback")
        #endif
    }
}

// MARK: - Privacy & Data Settings (Export/Import)
struct PrivacyAndDataSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    let storedFavorites: [FavoriteStation] // Kein @Query mehr in dieser View!
    
    @AppStorage("allowTelemetry") private var allowTelemetry = true
    @AppStorage("loadFaviconsMobileData") private var loadFaviconsMobileData = true
    
    @State private var isImporting = false
    #if os(macOS)
    @State private var isExporting = false
    @State private var exportDocument: JSONDataDocument? = nil
    @State private var showExportAlert = false
    @State private var exportAlertMessage: String = ""
    #endif
    
    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "Privacy_Toggle_SendAnonymousTelemetry"), isOn: $allowTelemetry)
                #if !os(macOS)
                Toggle(String(localized: "Privacy_Toggle_LoadFaviconsOnCellular"), isOn: $loadFaviconsMobileData)
                #endif
            } header: {
                Text("Datenschutz")
            } footer: {
                Text(String(localized: "Privacy_Helper_TelemetryDescription"))
            }
            
            Section {
                Button(action: exportFavorites) {
                    Label("Data_Export_Favorites", systemImage: "square.and.arrow.up")
                }
                #if os(macOS)
                .disabled(isExporting)
                #endif
                
                Button(action: { isImporting = true }) {
                    Label("Data_Import_Favorites", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Daten verwalten")
            }
        }
        #if !os(macOS)
        .formStyle(.grouped)
        .navigationTitle("Settings_Row_PrivacyData")
        #endif
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                importFavorites(from: url)
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
        #if os(macOS)
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "Spectrum_Favorites"
        ) { result in
            switch result {
            case .success:
                exportAlertMessage = String(localized: "Export erfolgreich gespeichert.")
                showExportAlert = true
            case .failure(let error):
                exportAlertMessage = String(localized: "Export fehlgeschlagen: ") + error.localizedDescription
                showExportAlert = true
            }
            exportDocument = nil
            isExporting = false
        }
        .alert("Export", isPresented: $showExportAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(exportAlertMessage)
        })
        #endif
    }
    
    @MainActor
    private func exportFavorites() {
        let exportableStations = storedFavorites.map { fav in
            RadioStation(
                id: fav.id,
                name: fav.name,
                url: fav.url.absoluteString,
                favicon: fav.favicon,
                tags: fav.tags
            )
        }

        do {
            let data = try JSONEncoder().encode(exportableStations)
            #if os(macOS)
            // Prevent re-entrant exports
            guard !isExporting else { return }
            exportDocument = JSONDataDocument(data: data)
            isExporting = true
            #else
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SpectrumExport", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            } catch {
                print("⚠️ Konnte temp-Verzeichnis nicht erstellen: \(error)")
            }
            var fileURL = tempDir.appendingPathComponent("Spectrum_Favorites_\(UUID().uuidString).json")
            do {
                try data.write(to: fileURL, options: [.atomic])
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try? fileURL.setResourceValues(resourceValues)
            } catch {
                print("⚠️ Schreiben der Export-Datei fehlgeschlagen: \(error)")
                return
            }

            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                // Optionally clean up old temp files later; keep directory for future exports
            }

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                // Ensure presentation from the top-most view controller
                var presenter = rootVC
                while let presented = presenter.presentedViewController { presenter = presented }
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = presenter.view
                    popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                presenter.present(activityVC, animated: true)
            } else {
                print("⚠️ Konnte UIActivityViewController nicht präsentieren: keine aktive WindowScene gefunden.")
            }
            #endif
        } catch {
            print("⚠️ JSON-Encoding der Favoriten fehlgeschlagen: \(error)")
        }
    }
    
    private func importFavorites(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let importedStations = try JSONDecoder().decode([RadioStation].self, from: data)
            
            let existingIDs = Set(storedFavorites.map { $0.id })
            
            for station in importedStations {
                if !existingIDs.contains(station.id) {
                    let newFav = FavoriteStation(from: station)
                    modelContext.insert(newFav)
                }
            }
            try modelContext.save()
        } catch {
            print("Failed to decode or save imported favorites: \(error)")
        }
    }
}

// MARK: - Mac Info View
#if os(macOS)
struct MacInfoSettingsView: View {
    var body: some View {
        Form {
            Section {
                LabeledContent(String(localized: "Info_Label_Developer"), value: String(localized: "Info_Developer_Name"))
                LabeledContent(String(localized: "Info_Label_Origin"), value: String(localized: "Info_Origin_MadeInGermany"))
                LabeledContent(String(localized: "Info_Label_Version"), value: Bundle.main.appVersionString)
            }
        }
    }
}
#endif

func getAccentColor(_ name: String) -> Color {
    switch name {
    case "purple": return .purple
    case "orange": return .orange
    case "red": return .red
    case "green": return .green
    default: return .blue
    }
}
