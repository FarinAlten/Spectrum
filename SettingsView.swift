//
//  SettingsView.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if !os(watchOS)

// MARK: - JSON Export Helper Document
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

// MARK: - Bundle Version Helper
extension Bundle {
    var appVersionString: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Liquid Glass Settings Icon
struct SettingsIcon: View {
    let systemName: String
    let gradient: LinearGradient
    
    init(systemName: String, color: Color) {
        self.systemName = systemName
        self.gradient = LinearGradient(
            colors: [color.opacity(0.9), color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    init(systemName: String, gradient: LinearGradient) {
        self.systemName = systemName
        self.gradient = gradient
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(gradient)
            
            // Specular top sheen
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.35), location: 0),
                            .init(color: .white.opacity(0.05), location: 0.45),
                            .init(color: .clear, location: 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Specular beveled rim
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.65), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.45),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
            
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
        }
        .frame(width: 28, height: 28)
        .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Liquid Glass Section Card Container
struct LiquidGlassSection<Content: View>: View {
    var title: LocalizedStringKey? = nil
    var icon: String? = nil
    var iconColor: Color? = nil
    var footer: LocalizedStringKey? = nil
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                HStack(spacing: 8) {
                    if let icon, let iconColor {
                        SettingsIcon(systemName: icon, color: iconColor)
                    }
                    Text(title)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .padding(.horizontal, 4)
            }
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(platformColor: .controlBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.top, 2)
            }
        }
    }
}

// MARK: - Liquid Glass Row
struct LiquidGlassRow<Trailing: View>: View {
    var icon: String? = nil
    var iconColor: Color? = nil
    var title: LocalizedStringKey
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon, let iconColor {
                SettingsIcon(systemName: icon, color: iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Liquid Glass Divider
struct LiquidGlassDivider: View {
    var body: some View {
        Divider()
            .opacity(0.15)
            .padding(.horizontal, 16)
    }
}

// MARK: - Settings Tab Enumeration
enum SettingsTab: Hashable, CaseIterable {
    case appearance
    case audio
    case privacy
    case openSource
    case info
    
    var title: LocalizedStringKey {
        switch self {
        case .appearance: return "Settings_Row_AppearanceAndLayout"
        case .audio: return "Settings_Row_AudioPlayback"
        case .privacy: return "Settings_Row_PrivacyData"
        case .openSource: return "Settings_Row_OpenSource"
        case .info: return "Settings_Section_Info"
        }
    }
    
    var icon: String {
        switch self {
        case .appearance: return "paintpalette.fill"
        case .audio: return "waveform"
        case .privacy: return "hand.raised.fill"
        case .openSource: return "doc.text.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .appearance: return .orange
        case .audio: return .purple
        case .privacy: return .blue
        case .openSource: return .green
        case .info: return .teal
        }
    }
}

// MARK: - Accent Color Resolver
func getAccentColor(_ name: String) -> Color {
    switch name {
    case "purple": return .purple
    case "orange": return .orange
    case "red": return .red
    case "green": return .green
    default: return .blue
    }
}

// MARK: - Main Settings View
struct SettingsView: View {
    @Query private var storedFavorites: [FavoriteStation]
    @AppStorage("accentColorSelection") private var accentColorSelection = "blue"
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedTab: SettingsTab = .appearance
    
    private var matchesSearch: (String) -> Bool {
        { query in
            searchText.isEmpty || query.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            // MARK: macOS Glass Sidebar
            VStack(spacing: 12) {
                // Sidebar Header with Glass Search
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(getAccentColor(accentColorSelection))
                        Text("Settings_Title_Main")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    
                    // Glass Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("Einstellungen suchen", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .liquidGlass(cornerRadius: 10, material: .ultraThinMaterial, borderWidth: 0.8)
                    .padding(.horizontal, 12)
                }
                
                // Sidebar Tab Navigation
                ScrollView {
                    VStack(spacing: 4) {
                        if matchesSearch("Erscheinungsbild") || matchesSearch("Layout") || matchesSearch("Appearance") {
                            sidebarRow(tab: .appearance)
                        }
                        
                        if matchesSearch("Audio") || matchesSearch("Wiedergabe") || matchesSearch("Sound") {
                            sidebarRow(tab: .audio)
                        }
                        
                        if matchesSearch("Datenschutz") || matchesSearch("Export") || matchesSearch("Import") || matchesSearch("Privacy") {
                            sidebarRow(tab: .privacy)
                        }
                        
                        if matchesSearch("Open Source") || matchesSearch("Lizenzen") || matchesSearch("Licenses") || matchesSearch("Sparkle") {
                            sidebarRow(tab: .openSource)
                        }
                        
                        if matchesSearch("Info") || matchesSearch("Version") || matchesSearch("Entwickler") || matchesSearch("Build") {
                            sidebarRow(tab: .info)
                        }
                    }
                    .padding(.horizontal, 10)
                }
                
                Spacer()
                
                // Footer Version Tag
                HStack(spacing: 6) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.caption2)
                        .foregroundColor(getAccentColor(accentColorSelection))
                    Text("Spectrum \(Bundle.main.appVersionString)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .frame(width: 230)
            .background(.ultraThinMaterial)
            
            // Vertical Glass Divider
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1)
                .ignoresSafeArea()
            
            // MARK: macOS Glass Detail Pane
            VStack(alignment: .leading, spacing: 0) {
                // Header Bar with Tab Title and Close Button
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedTab.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .liquidGlassCircle(material: .ultraThinMaterial, borderWidth: 0.8)
                    }
                    .buttonStyle(.plain)
                    .help("Schließen")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Divider()
                    .opacity(0.15)
                
                // Content Scroll View
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch selectedTab {
                        case .appearance:
                            AppearanceSettingsView()
                        case .audio:
                            AudioSettingsView()
                        case .privacy:
                            PrivacyAndDataSettingsView(storedFavorites: storedFavorites)
                        case .openSource:
                            OpenSourceLicensesView()
                        case .info:
                            MacInfoSettingsView()
                        }
                    }
                    .padding(24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor).ignoresSafeArea())
        }
        .frame(minWidth: 700, idealWidth: 720, maxWidth: 820, minHeight: 480, idealHeight: 520, maxHeight: 650)
        .tint(getAccentColor(accentColorSelection))
        
        #else
        // MARK: iOS Liquid Glass Settings Navigation
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    iosAppearanceSection
                    iosAppOptionsSection
                    iosInfoSection
                }
                .padding(16)
            }
            .background(Color(platformColor: .windowBackground).ignoresSafeArea())
            .searchable(text: $searchText, placement: .automatic, prompt: "Einstellungen suchen")
            .navigationTitle("Settings_Title_Main")
            .tint(getAccentColor(accentColorSelection))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color(platformColor: .controlBackground), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        #endif
    }
}

// MARK: - macOS Sidebar Row Extension
#if os(macOS)
extension SettingsView {
    @ViewBuilder
    private func sidebarRow(tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab
        
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        }) {
            HStack(spacing: 10) {
                SettingsIcon(systemName: tab.icon, color: tab.color)
                
                Text(tab.title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 5, height: 5)
                        .shadow(color: .white.opacity(0.6), radius: 2)
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background {
                if isSelected {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(getAccentColor(accentColorSelection))
                        
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: .white.opacity(0.3), location: 0),
                                        .init(color: .clear, location: 0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 0.8)
                    }
                    .shadow(color: getAccentColor(accentColorSelection).opacity(0.35), radius: 6, x: 0, y: 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#endif

// MARK: - iOS Section Builders Extension
#if !os(macOS)
extension SettingsView {
    @ViewBuilder
    private var iosAppearanceSection: some View {
        if matchesSearch("Erscheinungsbild") || matchesSearch("Layout") || matchesSearch("Appearance") {
            LiquidGlassSection(title: "Settings_Section_Appearance") {
                NavigationLink(destination: AppearanceSettingsView()) {
                    LiquidGlassRow(
                        icon: "paintpalette.fill",
                        iconColor: .orange,
                        title: "Settings_Row_AppearanceAndLayout",
                        subtitle: "Design, Raster und Akzentfarben"
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private var iosAppOptionsSection: some View {
        if matchesSearch("Audio") || matchesSearch("Wiedergabe") || matchesSearch("Datenschutz") || matchesSearch("Export") || matchesSearch("Import") {
            LiquidGlassSection(title: "Settings_Section_AppOptions") {
                if matchesSearch("Audio") || matchesSearch("Wiedergabe") {
                    NavigationLink(destination: AudioSettingsView()) {
                        LiquidGlassRow(
                            icon: "waveform",
                            iconColor: .purple,
                            title: "Settings_Row_AudioPlayback",
                            subtitle: "Qualität, Puffer und Übergänge"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                if (matchesSearch("Audio") || matchesSearch("Wiedergabe")) && (matchesSearch("Datenschutz") || matchesSearch("Export") || matchesSearch("Import") || matchesSearch("Privacy")) {
                    LiquidGlassDivider()
                }
                
                if matchesSearch("Datenschutz") || matchesSearch("Export") || matchesSearch("Import") || matchesSearch("Privacy") {
                    NavigationLink(destination: PrivacyAndDataSettingsView(storedFavorites: storedFavorites)) {
                        LiquidGlassRow(
                            icon: "hand.raised.fill",
                            iconColor: .blue,
                            title: "Settings_Row_PrivacyData",
                            subtitle: "Favoriten sichern & Telemetrie"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    @ViewBuilder
    private var iosInfoSection: some View {
        if matchesSearch("Info") || matchesSearch("Version") || matchesSearch("Entwickler") || matchesSearch("Build") || matchesSearch("Open Source") || matchesSearch("Lizenzen") || matchesSearch("Sparkle") {
            LiquidGlassSection(title: "Settings_Section_Info") {
                if matchesSearch("Open Source") || matchesSearch("Lizenzen") || matchesSearch("Licenses") || matchesSearch("Sparkle") {
                    NavigationLink(destination: OpenSourceLicensesView()) {
                        LiquidGlassRow(
                            icon: "doc.text.fill",
                            iconColor: .green,
                            title: "Settings_Row_OpenSource",
                            subtitle: "Verwendete Bibliotheken & Lizenzen"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    LiquidGlassDivider()
                }
                
                LiquidGlassRow(
                    icon: "person.text.rectangle.fill",
                    iconColor: .teal,
                    title: "Settings_Row_Credits"
                ) {
                    Text(String(localized: "Info_Developer_Name"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                LiquidGlassDivider()
                
                LiquidGlassRow(
                    icon: "info.circle.fill",
                    iconColor: .gray,
                    title: "Settings_Row_Version"
                ) {
                    Text(Bundle.main.appVersionString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
#endif
struct AppearanceSettingsView: View {
    @AppStorage("preferredDisplayMode") private var preferredDisplayMode = "grid"
    @AppStorage("maxGridColumns") private var maxGridColumns = 1
    @AppStorage("showFlagsAndEmojis") private var showFlagsAndEmojis = true
    @AppStorage("accentColorSelection") private var accentColorSelection = "blue"
    
    private let accentColors: [(tag: String, label: LocalizedStringKey, color: Color)] = [
        ("blue", "Color_Option_Blue", .blue),
        ("purple", "Color_Option_Purple", .purple),
        ("orange", "Color_Option_Orange", .orange),
        ("red", "Color_Option_Red", .red),
        ("green", "Color_Option_Green", .green)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Visual Layout Mode Selector (Grid vs List)
            LiquidGlassSection(
                title: "Appearance_Label_Layout",
                icon: "rectangle.grid.2x2.fill",
                iconColor: .orange
            ) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Option 1: Grid
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                preferredDisplayMode = "grid"
                            }
                        } label: {
                            VStack(spacing: 8) {
                                // Mini visual grid mockup
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                            .fill(Color.primary.opacity(0.15))
                                            .frame(width: 28, height: 18)
                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                            .fill(Color.primary.opacity(0.15))
                                            .frame(width: 28, height: 18)
                                    }
                                    HStack(spacing: 4) {
                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                            .fill(Color.primary.opacity(0.15))
                                            .frame(width: 28, height: 18)
                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                            .fill(Color.primary.opacity(0.15))
                                            .frame(width: 28, height: 18)
                                    }
                                }
                                .padding(8)
                                .background(Color.primary.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                
                                HStack(spacing: 4) {
                                    Text("Appearance_Option_Grid")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    if preferredDisplayMode == "grid" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(getAccentColor(accentColorSelection))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .liquidGlass(
                                cornerRadius: 12,
                                tint: preferredDisplayMode == "grid" ? getAccentColor(accentColorSelection) : nil,
                                borderWidth: preferredDisplayMode == "grid" ? 1.5 : 0.8
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // Option 2: List
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                preferredDisplayMode = "list"
                            }
                        } label: {
                            VStack(spacing: 8) {
                                // Mini visual list mockup
                                VStack(spacing: 4) {
                                    ForEach(0..<3) { _ in
                                        HStack(spacing: 5) {
                                            Circle()
                                                .fill(Color.primary.opacity(0.25))
                                                .frame(width: 6, height: 6)
                                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                                .fill(Color.primary.opacity(0.15))
                                                .frame(height: 5)
                                        }
                                        .frame(width: 60)
                                    }
                                }
                                .padding(8)
                                .background(Color.primary.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                
                                HStack(spacing: 4) {
                                    Text("Appearance_Option_List")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    if preferredDisplayMode == "list" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(getAccentColor(accentColorSelection))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .liquidGlass(
                                cornerRadius: 12,
                                tint: preferredDisplayMode == "list" ? getAccentColor(accentColorSelection) : nil,
                                borderWidth: preferredDisplayMode == "list" ? 1.5 : 0.8
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    
                    // Columns Stepper (visible in grid mode)
                    if preferredDisplayMode == "grid" {
                        LiquidGlassDivider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Appearance_Label_Columns")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("Anzahl der Spalten in der Senderansicht")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button {
                                    if maxGridColumns > 1 {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                            maxGridColumns -= 1
                                        }
                                    }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(maxGridColumns <= 1 ? .secondary.opacity(0.4) : .primary)
                                        .frame(width: 28, height: 28)
                                        .liquidGlassCircle(material: .ultraThinMaterial, borderWidth: 0.8)
                                }
                                .buttonStyle(.plain)
                                .disabled(maxGridColumns <= 1)
                                
                                Text("\(maxGridColumns)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 20)
                                
                                Button {
                                    if maxGridColumns < 5 {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                            maxGridColumns += 1
                                        }
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(maxGridColumns >= 5 ? .secondary.opacity(0.4) : .primary)
                                        .frame(width: 28, height: 28)
                                        .liquidGlassCircle(material: .ultraThinMaterial, borderWidth: 0.8)
                                }
                                .buttonStyle(.plain)
                                .disabled(maxGridColumns >= 5)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
            }
            
            // Accent Color Selection with Glowing Glass Orbs
            LiquidGlassSection(
                title: "Appearance_Label_AccentColor",
                icon: "paintpalette.fill",
                iconColor: .purple
            ) {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        ForEach(accentColors, id: \.tag) { item in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    accentColorSelection = item.tag
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [item.color.opacity(0.85), item.color],
                                                    center: .topLeading,
                                                    startRadius: 2,
                                                    endRadius: 20
                                                )
                                            )
                                            .frame(width: 34, height: 34)
                                            .overlay {
                                                Circle()
                                                    .strokeBorder(
                                                        LinearGradient(
                                                            stops: [
                                                                .init(color: .white.opacity(0.7), location: 0),
                                                                .init(color: .white.opacity(0.1), location: 0.6),
                                                                .init(color: .clear, location: 1)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 1.0
                                                    )
                                            }
                                            .shadow(color: item.color.opacity(accentColorSelection == item.tag ? 0.5 : 0.15), radius: 6, x: 0, y: 2)
                                        
                                        if accentColorSelection == item.tag {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                        }
                                    }
                                    .overlay {
                                        if accentColorSelection == item.tag {
                                            Circle()
                                                .strokeBorder(item.color.opacity(0.6), lineWidth: 2)
                                                .frame(width: 42, height: 42)
                                        }
                                    }
                                    .frame(width: 42, height: 42)
                                    
                                    Text(item.label)
                                        .font(.caption2)
                                        .fontWeight(accentColorSelection == item.tag ? .semibold : .regular)
                                        .foregroundColor(accentColorSelection == item.tag ? .primary : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
            }
            
            // Visual Elements Toggle
            LiquidGlassSection {
                LiquidGlassRow(
                    icon: "flag.fill",
                    iconColor: .teal,
                    title: "Appearance_Toggle_ShowVisualSymbols",
                    subtitle: "Länderflaggen und Icons bei Stationen einblenden"
                ) {
                    Toggle("", isOn: $showFlagsAndEmojis)
                        .labelsHidden()
                        .tint(getAccentColor(accentColorSelection))
                }
            }
        }
        #if !os(macOS)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .navigationTitle("Settings_Row_AppearanceAndLayout")
        .background(Color(platformColor: .windowBackground).ignoresSafeArea())
        #endif
    }
}

// MARK: - Audio Settings View
struct AudioSettingsView: View {
    @AppStorage("streamQuality") private var streamQuality = "high"
    @AppStorage("autoPlayOnStart") private var autoPlayOnStart = false
    @AppStorage("fadeTransitions") private var fadeTransitions = true
    @AppStorage("bufferSize") private var bufferSize = "medium"
    @AppStorage("accentColorSelection") private var accentColorSelection = "blue"
    
    var body: some View {
        VStack(spacing: 20) {
            // Stream Quality Selector Cards
            LiquidGlassSection(
                title: "Audio_Label_Quality",
                icon: "sparkles",
                iconColor: .purple
            ) {
                VStack(spacing: 10) {
                    // High Quality Option
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            streamQuality = "high"
                        }
                    } label: {
                        HStack(spacing: 14) {
                            SettingsIcon(systemName: "sparkles", color: .purple)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Audio_Option_HQ")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text("320 kbps")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .liquidGlassCapsule(tint: .purple)
                                }
                                Text("Höchste Klangauflösung für kristallklaren Sound")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: streamQuality == "high" ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 19))
                                .foregroundColor(streamQuality == "high" ? getAccentColor(accentColorSelection) : .secondary.opacity(0.35))
                        }
                        .padding(12)
                        .liquidGlass(
                            cornerRadius: 12,
                            tint: streamQuality == "high" ? getAccentColor(accentColorSelection) : nil,
                            borderWidth: streamQuality == "high" ? 1.5 : 0.8
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Low Quality Option
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            streamQuality = "low"
                        }
                    } label: {
                        HStack(spacing: 14) {
                            SettingsIcon(systemName: "antenna.radiowaves.left.and.right", color: .orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Audio_Option_LQ")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text("128 kbps")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .liquidGlassCapsule(tint: .orange)
                                }
                                Text("Reduzierter Datenverbrauch, ideal für unterwegs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: streamQuality == "low" ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 19))
                                .foregroundColor(streamQuality == "low" ? getAccentColor(accentColorSelection) : .secondary.opacity(0.35))
                        }
                        .padding(12)
                        .liquidGlass(
                            cornerRadius: 12,
                            tint: streamQuality == "low" ? getAccentColor(accentColorSelection) : nil,
                            borderWidth: streamQuality == "low" ? 1.5 : 0.8
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
            }
            
            // Buffer Size Selector
            LiquidGlassSection(
                title: "Audio_Label_BufferSize",
                icon: "timer",
                iconColor: .blue
            ) {
                HStack(spacing: 10) {
                    let buffers: [(tag: String, label: LocalizedStringKey, desc: String)] = [
                        ("small", "Audio_Buffer_Small", "Schnell"),
                        ("medium", "Audio_Buffer_Medium", "Standard"),
                        ("large", "Audio_Buffer_Large", "Stabil")
                    ]
                    
                    ForEach(buffers, id: \.tag) { item in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                bufferSize = item.tag
                            }
                        } label: {
                            VStack(spacing: 3) {
                                Text(item.label)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(bufferSize == item.tag ? .primary : .secondary)
                                Text(item.desc)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .liquidGlass(
                                cornerRadius: 10,
                                tint: bufferSize == item.tag ? getAccentColor(accentColorSelection) : nil,
                                borderWidth: bufferSize == item.tag ? 1.5 : 0.8
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
            
            // Playback Options
            LiquidGlassSection(
                title: "Settings_Row_AudioPlayback",
                icon: "play.circle.fill",
                iconColor: .green
            ) {
                LiquidGlassRow(
                    icon: "play.circle.fill",
                    iconColor: .green,
                    title: "Audio_Toggle_AutoPlayOnStart",
                    subtitle: "Letzten Sender beim Öffnen der App automatisch starten"
                ) {
                    Toggle("", isOn: $autoPlayOnStart)
                        .labelsHidden()
                        .tint(getAccentColor(accentColorSelection))
                }
                
                LiquidGlassDivider()
                
                LiquidGlassRow(
                    icon: "waveform.path",
                    iconColor: .indigo,
                    title: "Audio_Toggle_CrossfadeOnStationChange",
                    subtitle: "Sanftes Ein- und Ausblenden beim Senderwechsel"
                ) {
                    Toggle("", isOn: $fadeTransitions)
                        .labelsHidden()
                        .tint(getAccentColor(accentColorSelection))
                }
            }
        }
        #if !os(macOS)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .navigationTitle("Settings_Row_AudioPlayback")
        .background(Color(platformColor: .windowBackground).ignoresSafeArea())
        #endif
    }
}

// MARK: - Privacy & Data Settings View
struct PrivacyAndDataSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    let storedFavorites: [FavoriteStation]
    
    @AppStorage("allowTelemetry") private var allowTelemetry = true
    @AppStorage("loadFaviconsMobileData") private var loadFaviconsMobileData = true
    @AppStorage("accentColorSelection") private var accentColorSelection = "blue"
    
    @State private var isImporting = false
    #if os(macOS)
    @State private var isExporting = false
    @State private var exportDocument: JSONDataDocument? = nil
    @State private var showExportAlert = false
    @State private var exportAlertMessage: String = ""
    #endif
    
    var body: some View {
        VStack(spacing: 20) {
            // Favorites Status Card
            LiquidGlassSection(
                title: "Daten & Mediathek",
                icon: "heart.fill",
                iconColor: .pink
            ) {
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(storedFavorites.count) Favoriten")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("Deine persönliche Sender-Sammlung")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    LiquidGlassDivider()
                    
                    // Backup Buttons: Export and Import
                    HStack(spacing: 12) {
                        Button {
                            exportFavorites()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Data_Export_Favorites")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .liquidGlass(cornerRadius: 10, tint: .blue, borderWidth: 1.0)
                        }
                        .buttonStyle(.plain)
                        #if os(macOS)
                        .disabled(isExporting)
                        #endif
                        
                        Button {
                            isImporting = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Data_Import_Favorites")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .liquidGlass(cornerRadius: 10, tint: .green, borderWidth: 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }
            
            // Privacy Toggles
            LiquidGlassSection(
                title: "Datenschutz",
                icon: "hand.raised.fill",
                iconColor: .blue,
                footer: "Privacy_Helper_TelemetryDescription"
            ) {
                LiquidGlassRow(
                    icon: "chart.bar.xaxis",
                    iconColor: .blue,
                    title: "Privacy_Toggle_SendAnonymousTelemetry",
                    subtitle: "Hilft uns, Fehler zu beheben und die Stabilität zu verbessern"
                ) {
                    Toggle("", isOn: $allowTelemetry)
                        .labelsHidden()
                        .tint(getAccentColor(accentColorSelection))
                }
                
                #if !os(macOS)
                LiquidGlassDivider()
                
                LiquidGlassRow(
                    icon: "antenna.radiowaves.left.and.right",
                    iconColor: .teal,
                    title: "Privacy_Toggle_LoadFaviconsOnCellular",
                    subtitle: "Sender-Logos auch im Mobilfunknetz laden"
                ) {
                    Toggle("", isOn: $loadFaviconsMobileData)
                        .labelsHidden()
                        .tint(getAccentColor(accentColorSelection))
                }
                #endif
            }
        }
        #if !os(macOS)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .navigationTitle("Settings_Row_PrivacyData")
        .background(Color(platformColor: .windowBackground).ignoresSafeArea())
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
            activityVC.completionWithItemsHandler = { _, _, _, _ in }

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                var presenter = rootVC
                while let presented = presenter.presentedViewController { presenter = presented }
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = presenter.view
                    popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                presenter.present(activityVC, animated: true)
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

// MARK: - Open Source Licenses View
struct OpenSourceItem: Identifiable {
    let id = UUID()
    let name: String
    let licenseType: String
    let description: String
    let url: String
}

struct OpenSourceLicensesView: View {
    private let packages: [OpenSourceItem] = [
        OpenSourceItem(
            name: "Sparkle Framework",
            licenseType: "MIT License",
            description: "Zuverlässiges Software-Update-Framework für nahtlose macOS Aktualisierungen.",
            url: "https://sparkle-project.org"
        ),
        OpenSourceItem(
            name: "Radio Browser API",
            licenseType: "Community / Public Domain",
            description: "Freie und weltweite Radiodatenbank mit über 30.000 Stationen.",
            url: "https://www.radio-browser.info"
        ),
        OpenSourceItem(
            name: "SwiftData & SwiftUI",
            licenseType: "Apple Native",
            description: "Frameworks von Apple für reaktive Oberflächen und performante Datenhaltung.",
            url: "https://developer.apple.com/swiftui"
        ),
        OpenSourceItem(
            name: "Liquid Glass Design Engine",
            licenseType: "Spectrum Native",
            description: "Transluzente Glas-Shader, volumetrischer Bevel und dynamische Aurora-Lichteffekte.",
            url: "https://github.com/farin/Spectrum"
        )
    ]
    
    var body: some View {
        VStack(spacing: 14) {
            ForEach(packages) { package in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(package.name)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(package.licenseType)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .liquidGlassCapsule(tint: .secondary.opacity(0.15))
                        
                        if let url = URL(string: package.url) {
                            Link(destination: url) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Text(package.description)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .liquidGlass(cornerRadius: 14, material: .ultraThinMaterial, borderWidth: 0.8)
            }
        }
        #if !os(macOS)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .navigationTitle("Settings_Row_OpenSource")
        .background(Color(platformColor: .windowBackground).ignoresSafeArea())
        #endif
    }
}

// MARK: - Mac Info View
#if os(macOS)
struct MacInfoSettingsView: View {
    @AppStorage("accentColorSelection") private var accentColorSelection = "blue"
    @State private var appUpdater = AppUpdater()
    
    var body: some View {
        VStack(spacing: 20) {
            // Hero Spectrum Brand Glass Card
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [getAccentColor(accentColorSelection).opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.0)
                        }
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                VStack(spacing: 4) {
                    Text("Spectrum")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [getAccentColor(accentColorSelection), .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Version \(Bundle.main.appVersionString)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .liquidGlassCapsule(tint: getAccentColor(accentColorSelection))
                    
                    Text("Elegantes Internetradio im Apple Liquid Glass Design")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                Divider()
                    .opacity(0.15)
                    .padding(.horizontal, 20)
                
                // Update Button
                Button {
                    appUpdater.checkForUpdates()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .bold))
                        Text("Nach Updates suchen...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .liquidGlassCapsule(tint: getAccentColor(accentColorSelection))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .liquidGlass(cornerRadius: 18, material: .ultraThinMaterial, borderWidth: 1.0)
            
            // Developer and Origin Info
            LiquidGlassSection(
                title: "Informationen",
                icon: "info.circle.fill",
                iconColor: .teal
            ) {
                LiquidGlassRow(
                    icon: "person.text.rectangle.fill",
                    iconColor: .teal,
                    title: "Info_Label_Developer"
                ) {
                    Text(String(localized: "Info_Developer_Name"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                LiquidGlassDivider()
                
                LiquidGlassRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Info_Label_Origin"
                ) {
                    Text(String(localized: "Info_Origin_MadeInGermany"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
#endif

#endif
