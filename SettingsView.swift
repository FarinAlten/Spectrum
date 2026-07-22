//
//  SettingsView.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//
import SwiftUI

struct SettingsView: View {
    @AppStorage("accentColorSelection") private var accentColorSelection = "blue"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        #if os(macOS)
        TabView {
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
            
            AudioSettingsView()
                .tabItem {
                    Label("Audio", systemImage: "waveform.circle")
                }
            
            PrivacyAndDataSettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised.square")
                }
            
            MacInfoSettingsView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
        }
        .frame(width: 420, height: 260)
        .padding(.top, 12)
        .tint(getAccentColor(accentColorSelection))
        #else
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Label("Settings_Row_AppearanceAndLayout", systemImage: "paintpalette")
                    }
                } header: {
                    Text("Settings_Section_Appearance")
                }
                
                Section {
                    NavigationLink(destination: AudioSettingsView()) {
                        Label("Settings_Row_AudioPlayback", systemImage: "waveform.circle")
                    }
                    
                    NavigationLink(destination: PrivacyAndDataSettingsView()) {
                        Label("Settings_Row_PrivacyData", systemImage: "hand.raised.square")
                    }
                } header: {
                    Text("Settings_Section_AppOptions")
                }
                
                Section {
                    HStack(alignment: .top) {
                        Label("Settings_Row_Credits", systemImage: "person.text.rectangle")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(localized: "Info_Developer_Name")).fontWeight(.medium)
                            Text(String(localized: "Settings_Row_MadeInGermany")).font(.footnote).foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Label("Settings_Row_Version", systemImage: "info.circle")
                        Spacer()
                        Text(String(localized: "Info_App_Version_Build")).foregroundColor(.secondary)
                    }
                } header: {
                    Text("Settings_Section_Info")
                }
            }
            .listStyle(.insetGrouped)
            .tint(getAccentColor(accentColorSelection))
            .navigationTitle("Settings_Title_Main")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        #endif
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("preferredDisplayMode") private var preferredDisplayMode = "grid"
    @AppStorage("maxGridColumns") private var maxGridColumns = 4
    @AppStorage("showFlagsAndEmojis") private var showFlagsAndEmojis = true
    @AppStorage("accentColorSelection") private var accentColorSelection = "blue"
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(localized: "Appearance_Label_Layout"))
                        .frame(width: 90, alignment: .trailing)
                    Picker("", selection: $preferredDisplayMode) {
                        Text("Appearance_Option_Grid").tag("grid")
                        Text("Appearance_Option_List").tag("list")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                if preferredDisplayMode == "grid" {
                    HStack {
                        Spacer()
                            .frame(width: 90)
                        Stepper(value: $maxGridColumns, in: 2...5) {
                            Text(String(localized: "Appearance_Label_Columns")) + Text(": ") + Text("**\(maxGridColumns)**")
                        }
                    }
                }
                
                Divider()
                    .padding(.leading, 95)
                
                HStack(alignment: .firstTextBaseline) {
                    Text(String(localized: "Appearance_Label_AccentColor"))
                        .frame(width: 90, alignment: .trailing)
                    Picker("", selection: $accentColorSelection) {
                        Text("Color_Option_Blue").tag("blue")
                        Text("Color_Option_Purple").tag("purple")
                        Text("Color_Option_Orange").tag("orange")
                        Text("Color_Option_Red").tag("red")
                        Text("Color_Option_Green").tag("green")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 120)
                }
                
                HStack {
                    Spacer()
                        .frame(width: 95)
                    Toggle(String(localized: "Appearance_Toggle_ShowVisualSymbols"), isOn: $showFlagsAndEmojis)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        #if !os(macOS)
        .navigationTitle("Settings_Row_AppearanceAndLayout")
        .tint(getAccentColor(accentColorSelection))
        #endif
    }
}

struct AudioSettingsView: View {
    @AppStorage("streamQuality") private var streamQuality = "high"
    @AppStorage("autoPlayOnStart") private var autoPlayOnStart = false
    @AppStorage("fadeTransitions") private var fadeTransitions = true
    @AppStorage("bufferSize") private var bufferSize = "medium"
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(localized: "Audio_Label_Quality"))
                        .frame(width: 90, alignment: .trailing)
                    Picker("", selection: $streamQuality) {
                        Text("Audio_Option_HQ").tag("high")
                        Text("Audio_Option_LQ").tag("low")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text(String(localized: "Audio_Label_BufferSize"))
                        .frame(width: 90, alignment: .trailing)
                    Picker("", selection: $bufferSize) {
                        Text("Audio_Buffer_Small").tag("small")
                        Text("Audio_Buffer_Medium").tag("medium")
                        Text("Audio_Buffer_Large").tag("large")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 120)
                }
                
                Divider()
                    .padding(.leading, 95)
                
                HStack {
                    Spacer()
                        .frame(width: 95)
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(String(localized: "Audio_Toggle_AutoPlayOnStart"), isOn: $autoPlayOnStart)
                        Toggle(String(localized: "Audio_Toggle_CrossfadeOnStationChange"), isOn: $fadeTransitions)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        #if !os(macOS)
        .navigationTitle("Settings_Row_AudioPlayback")
        #endif
    }
}

struct PrivacyAndDataSettingsView: View {
    @AppStorage("allowTelemetry") private var allowTelemetry = true
    @AppStorage("loadFaviconsMobileData") private var loadFaviconsMobileData = true
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Spacer()
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(String(localized: "Privacy_Toggle_SendAnonymousTelemetry"), isOn: $allowTelemetry)
                        Text(String(localized: "Privacy_Helper_TelemetryDescription"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                #if !os(macOS)
                Divider()
                    .padding(.vertical, 4)
                
                Toggle(String(localized: "Privacy_Toggle_LoadFaviconsOnCellular"), isOn: $loadFaviconsMobileData)
                #endif
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
        #if !os(macOS)
        .navigationTitle("Settings_Row_PrivacyData")
        #endif
    }
}

#if os(macOS)
struct MacInfoSettingsView: View {
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 12) {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text(String(localized: "Info_Label_Developer"))
                            .fontWeight(.semibold)
                            .gridCellAnchor(.trailing)
                        Text(String(localized: "Info_Developer_Name"))
                    }
                    GridRow {
                        Text(String(localized: "Info_Label_Origin"))
                            .fontWeight(.semibold)
                            .gridCellAnchor(.trailing)
                        Text(String(localized: "Info_Origin_MadeInGermany"))
                    }
                    GridRow {
                        Text(String(localized: "Info_Label_Version"))
                            .fontWeight(.semibold)
                            .gridCellAnchor(.trailing)
                        Text(String(localized: "Info_App_Version_Build"))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
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
