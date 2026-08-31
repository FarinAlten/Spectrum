import SwiftUI
import SwiftData
import AVKit

// MARK: - AirPlay Picker View
struct AirPlayPickerView: View {
    var body: some View {
        #if os(iOS)
        AirPlayRoutePickerRepresentable()
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial, in: Circle())
        #elseif os(macOS)
        MacAirPlayRoutePickerRepresentable()
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial, in: Circle())
        #endif
    }
}

// MARK: - macOS AVRoutePickerView Wrapper
#if os(macOS)
struct MacAirPlayRoutePickerRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.isRoutePickerButtonBordered = false
        picker.player = AVPlayer()
        return picker
    }
    
    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}
#endif

// MARK: - iOS AVRoutePickerView Wrapper
#if os(iOS)
struct AirPlayRoutePickerRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = UIColor.systemBlue
        picker.tintColor = UIColor.label.withAlphaComponent(0.85)
        picker.prioritizesVideoDevices = false
        return picker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
#endif

// MARK: - Full Player View
#if !os(watchOS)
struct FullPlayerView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    
    @Query private var favorites: [FavoriteStation]
    
    @State private var isSleepTimerSheetPresented = false
    @State private var sleepEndDate: Date? = nil
    @State private var sleepTimer: Timer?
    @State private var isPlayButtonPressed = false
    
    // Shazam State
    @State private var showInstallShazamAlert = false
    
    private var isCurrentStationFavorite: Bool {
        guard let currentId = playbackManager.currentStation?.id else { return false }
        return favorites.contains { $0.id == currentId }
    }
    
    // Prüft, ob Shazam auf dem Gerät installiert ist
    private var isShazamInstalled: Bool {
        #if os(iOS)
        if let shazamURL = URL(string: "shazam://") {
            return UIApplication.shared.canOpenURL(shazamURL)
        }
        #endif
        return false
    }
    
    var body: some View {
        ZStack {
            // Background Artwork Blur Effect
            GeometryReader { geometry in
                AsyncImage(url: URL(string: playbackManager.currentStation?.favicon ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .blur(radius: 70, opaque: true)
                            .opacity(0.4)
                    } else {
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.2), Color.black.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Dismiss & Menu)
                HStack {
                    #if os(iOS)
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    #endif
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            isSleepTimerSheetPresented = true
                        } label: {
                            Label(String(localized: "Sleep Timer"), systemImage: "moon.zzz")
                        }
                        if let shareURL = playbackManager.currentStation?.shareURL {
                            ShareLink(item: shareURL) {
                                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer(minLength: 16)
                
                // Station Artwork
                AsyncImage(url: URL(string: playbackManager.currentStation?.favicon ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "radio")
                            .font(.system(size: 80))
                            .foregroundColor(.primary.opacity(0.5))
                    }
                }
                #if os(macOS)
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                #else
                .frame(width: 240, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
                #endif
                .padding(.horizontal, 40)
                
                Spacer(minLength: 24)
                
                // Station Info & Status
                VStack(spacing: 12) {
                    Text(playbackManager.currentStation?.name ?? String(localized: "Player_Status_Pause"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 32)
                    
                    // Live & Status Indicators
                    HStack(spacing: 8) {
                        if playbackManager.isPlaying {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text(String(localized: "Player_Status_Live"))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                        } else {
                            Text("Pausiert")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Shazam Button Badge
                    Button(action: handleShazamAction) {
                        HStack(spacing: 6) {
                            Image(systemName: "shazam.logo.fill")
                                .font(.caption)
                            Text("Song erkennen")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    // Sleep Timer Remaining Display
                    if let end = sleepEndDate {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            let remaining = max(Int(end.timeIntervalSince(context.date)), 0)
                            if remaining > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "moon.zzz.fill")
                                        .font(.caption2)
                                    Text(formatSeconds(remaining))
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                                .foregroundColor(.primary.opacity(0.9))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(.top, 2)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 32)
                
                // Control Buttons (Genau 3 Buttons – Play zentriert)
                HStack(spacing: 36) {
                    // 1. AirPlay Button
                    AirPlayPickerView()
                    
                    // 2. Play/Pause Button (Zentriert)
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.68)) {
                            playbackManager.togglePlayback()
                        }
                    }) {
                        Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: Color.accentColor.opacity(0.35), radius: 12, x: 0, y: 6)
                            .scaleEffect(isPlayButtonPressed ? 0.92 : 1.0)
                    }
                    .buttonStyle(.plain)
                    ._onButtonGesture { isPressed in
                        withAnimation(.easeInOut(duration: 0.12)) {
                            isPlayButtonPressed = isPressed
                        }
                    } perform: {}
                    
                    // 3. Favorite Button
                    Button(action: toggleFavoriteStatus) {
                        Image(systemName: isCurrentStationFavorite ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isCurrentStationFavorite ? .yellow : .primary.opacity(0.85))
                            .frame(width: 48, height: 48)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 36)
            }
        }
        #if os(macOS)
        .frame(width: 380, height: 560)
        #else
        .frame(minWidth: 360, minHeight: 550)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        #endif
        .userActivity("com.spectrum.radio.playback", isActive: playbackManager.currentStation != nil) { activity in
            guard let station = playbackManager.currentStation else { return }
            activity.title = "Spectrum: \(station.name)"
            activity.isEligibleForHandoff = true
            if let urlString = station.shareURL?.absoluteString {
                activity.userInfo = ["stationURL": urlString]
            }
        }
        .sheet(isPresented: $isSleepTimerSheetPresented) {
            SleepTimerSheet(
                initialSeconds: sleepEndDate != nil ? max(Int(sleepEndDate!.timeIntervalSince(Date())), 0) : 900,
                onStart: { seconds in
                    scheduleSleepTimer(seconds: seconds)
                    isSleepTimerSheetPresented = false
                },
                onCancel: {
                    cancelSleepTimer()
                    isSleepTimerSheetPresented = false
                }
            )
        }
        .alert("Shazam erforderlich", isPresented: $showInstallShazamAlert) {
            Button("Im App Store anzeigen") {
                if let appStoreURL = URL(string: "https://apps.apple.com/app/id284993459") {
                    openURL(appStoreURL)
                }
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Um laufende Songs zu erkennen, muss die Shazam-App auf deinem Gerät installiert sein.")
        }
    }
    
    private func handleShazamAction() {
        if isShazamInstalled {
            if let shazamURL = URL(string: "shazam://") {
                openURL(shazamURL)
            }
        } else {
            showInstallShazamAlert = true
        }
    }
    
    private func toggleFavoriteStatus() {
        guard let station = playbackManager.currentStation else { return }
        
        if isCurrentStationFavorite {
            if let entity = favorites.first(where: { $0.id == station.id }) {
                modelContext.delete(entity)
                try? modelContext.save()
            }
        } else {
            let newFavorite = FavoriteStation(from: station)
            modelContext.insert(newFavorite)
            try? modelContext.save()
        }
    }
    
    private func scheduleSleepTimer(seconds: Int) {
        cancelSleepTimer()
        guard seconds > 0 else { return }
        sleepEndDate = Date().addingTimeInterval(TimeInterval(seconds))
        sleepTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { _ in
            Task { @MainActor in
                if playbackManager.isPlaying {
                    playbackManager.togglePlayback()
                }
                sleepTimer = nil
                sleepEndDate = nil
            }
        }
    }

    private func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepEndDate = nil
    }

    private func formatSeconds(_ seconds: Int) -> String {
        if seconds >= 3600 {
            return String(format: "%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
        } else {
            return String(format: "%d:%02d", seconds / 60, seconds % 60)
        }
    }
}

// MARK: - Sleep Timer Sheet (Plattformspezifisches Layout)
struct SleepTimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedHours: Int
    @State private var selectedMinutes: Int
    @State private var selectedSeconds: Int

    let onStart: (Int) -> Void
    let onCancel: () -> Void

    init(initialSeconds: Int = 900, onStart: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        _selectedHours = State(initialValue: initialSeconds / 3600)
        _selectedMinutes = State(initialValue: (initialSeconds % 3600) / 60)
        _selectedSeconds = State(initialValue: (initialSeconds % 60))
        self.onStart = onStart
        self.onCancel = onCancel
    }

    private var totalSeconds: Int {
        (selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(String(localized: "Sleep Timer"))
                .font(.headline)
                .padding(.top, 10)

            #if os(iOS)
            HStack {
                Text(String(localized: "Stunden"))
                    .frame(maxWidth: .infinity)
                Text(String(localized: "Minuten"))
                    .frame(maxWidth: .infinity)
                Text(String(localized: "Sekunden"))
                    .frame(maxWidth: .infinity)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)

            HStack(spacing: 0) {
                Picker("Stunden", selection: $selectedHours) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour)").tag(hour)
                    }
                }
                .pickerStyle(.wheel)

                Picker("Minuten", selection: $selectedMinutes) {
                    ForEach(0..<60, id: \.self) { minute in
                        Text("\(minute)").tag(minute)
                    }
                }
                .pickerStyle(.wheel)

                Picker("Sekunden", selection: $selectedSeconds) {
                    ForEach(0..<60, id: \.self) { second in
                        Text("\(second)").tag(second)
                    }
                }
                .pickerStyle(.wheel)
            }
            .frame(height: 120)
            .clipped()
            #elseif os(macOS)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Stunden"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $selectedHours) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour) h").tag(hour)
                        }
                    }
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Minuten"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $selectedMinutes) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text("\(minute) min").tag(minute)
                        }
                    }
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Sekunden"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $selectedSeconds) {
                        ForEach(0..<60, id: \.self) { second in
                            Text("\(second) s").tag(second)
                        }
                    }
                    .labelsHidden()
                }
            }
            .padding(.vertical, 8)
            #endif

            VStack(spacing: 12) {
                Button {
                    onStart(totalSeconds)
                    dismiss()
                } label: {
                    Text(String(localized: "Start Timer"))
                        .font(.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(totalSeconds <= 0)

                Button(role: .destructive) {
                    onCancel()
                    dismiss()
                } label: {
                    Text(String(localized: "Cancel"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        #if os(iOS)
        .presentationDetents([.height(340)])
        #elseif os(macOS)
        .frame(width: 300)
        #endif
    }
}

// MARK: - Favorite Button View
struct FavoriteButton: View {
    let station: RadioStation
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteStation]
    
    private var isFavorite: Bool {
        favorites.contains { String($0.id) == String(station.id) }
    }
    
    var body: some View {
        Button(action: {
            Task { @MainActor in
                if isFavorite {
                    if let entity = favorites.first(where: { String($0.id) == String(station.id) }) {
                        modelContext.delete(entity)
                    }
                } else {
                    let newFavorite = FavoriteStation(from: station)
                    modelContext.insert(newFavorite)
                }
                
                do {
                    try modelContext.save()
                } catch {
                    print("Fehler beim Speichern des Favoriten: \(error)")
                }
            }
        }) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isFavorite ? .yellow : .primary)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
#endif

