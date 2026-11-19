import SwiftUI

import SwiftData

import AVKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif



struct AirPlayPickerView: View {
    var body: some View {
        #if os(iOS)
        AirPlayRoutePickerRepresentable()
            .frame(width: 48, height: 48)
            .background(.regularMaterial, in: Circle())
        #elseif os(macOS)
        MacAirPlayRoutePickerRepresentable()
            .frame(width: 48, height: 48)
            .background(.regularMaterial, in: Circle())
        #endif
    }
}


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

    private let animation: Namespace.ID?
    private let isExpanded: Bool
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext

    @Environment(\.openURL) private var openURL

    @Query private var favorites: [FavoriteStation]

    @State private var isSleepTimerSheetPresented = false

    @State private var artworkTint: Color = .accentColor

    @State private var sleepEndDate: Date? = nil

    @State private var sleepTimer: Timer?

    // Shazam State

    @State private var showInstallShazamAlert = false

    private var isCurrentStationFavorite: Bool {

        guard let currentId = playbackManager.currentStation?.id else { return false }

        return favorites.contains { $0.id == currentId }

    }

    init(animation: Namespace.ID? = nil, isExpanded: Bool = true, onDismiss: @escaping () -> Void = {}) {
        self.animation = animation
        self.isExpanded = isExpanded
        self.onDismiss = onDismiss
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

    private var playerTitle: some View {
        Group {
            if let animation {
                Text(playbackManager.currentStation?.name ?? String(localized: "Player_Status_Pause"))
                    .matchedGeometryEffect(id: "playerTitle", in: animation, isSource: isExpanded)
            } else {
                Text(playbackManager.currentStation?.name ?? String(localized: "Player_Status_Pause"))
            }
        }
    }

    private func updateArtworkTint() async {
        guard let urlString = playbackManager.currentStation?.favicon,
              let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled, let color = Self.saturatedArtworkColor(from: data) else { return }
            await MainActor.run { artworkTint = color }
        } catch {
            // Keep the system accent when artwork can't be loaded.
        }
    }

    private static func saturatedArtworkColor(from data: Data) -> Color? {
        #if os(iOS)
        guard let image = UIImage(data: data)?.cgImage else { return nil }
        #elseif os(macOS)
        guard let nativeImage = NSImage(data: data),
              let image = nativeImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #else
        return nil
        #endif

        let sampleSize = 8
        var pixels = [UInt8](repeating: 0, count: sampleSize * sampleSize * 4)
        guard let context = CGContext(
            data: &pixels,
            width: sampleSize,
            height: sampleSize,
            bitsPerComponent: 8,
            bytesPerRow: sampleSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        var red = 0.0
        var green = 0.0
        var blue = 0.0
        var count = 0.0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let r = Double(pixels[index]) / 255
            let g = Double(pixels[index + 1]) / 255
            let b = Double(pixels[index + 2]) / 255
            guard max(r, g, b) - min(r, g, b) > 0.12 else { continue }
            red += r
            green += g
            blue += b
            count += 1
        }
        guard count > 0 else { return nil }
        return Color(red: red / count, green: green / count, blue: blue / count)
    }

    @ViewBuilder
    private func glassContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12) {
                content()
            }
        } else {
            content()
        }
        #else
        content()
        #endif
    }

    var body: some View {

        ZStack {
            Color(platformColor: .windowBackground)
                .ignoresSafeArea()
            RadialGradient(
                colors: [artworkTint.opacity(0.24), artworkTint.opacity(0.08), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 760
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (Dismiss & Menu)
                glassContainer {
                    HStack {
                    #if os(iOS)
                    Button(action: { onDismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary.opacity(0.85))
                            .frame(width: 38, height: 38)
                            .modifier(SystemGlassCircleStyle(isInteractive: true))
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
                            .foregroundColor(.primary.opacity(0.85))
                            .frame(width: 38, height: 38)
                            .modifier(SystemGlassCircleStyle(isInteractive: true))
                    }
                    .buttonStyle(.plain)
                }
                        .padding(.horizontal, 24)
                        .padding(.top, 48)
                        .zIndex(100)
                }

                Spacer(minLength: 18)

                // Station artwork remains the focus; the surrounding view stays quiet.
                AsyncImage(url: URL(string: playbackManager.currentStation?.favicon ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        Image(systemName: "radio")
                            .font(.system(size: 72, weight: .light))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                }
                #if os(macOS)
                .frame(width: 190, height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                #else
                .frame(width: 250, height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                #endif
                .modifier(PlayerArtworkMatch(animation: animation, isSource: isExpanded))
                .padding(.horizontal, 40)

                // Station Info & Status
                VStack(spacing: 14) {
                    playerTitle
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
                                Image(systemName: "waveform")
                                    .symbolEffect(.variableColor.iterative, options: .repeating)
                                Text(String(localized: "Player_Status_Live"))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
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
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

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
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(.thinMaterial, in: Capsule())
                                .padding(.top, 2)
                            }
                        }
                    }
                }

                Spacer(minLength: 28)

                // Control Buttons (Genau 3 Buttons – Play zentriert)
                glassContainer {
                    HStack(spacing: 30) {
                    // 1. AirPlay Button
                    AirPlayPickerView()

                    // 2. Play/Pause Button (Zentriert)
                    Button {
                        playbackManager.togglePlayback()
                    } label: {
                        Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 72, height: 72)
                            .modifier(SystemGlassCircleStyle(isInteractive: true))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(PressScaleButtonStyle())

                    // 3. Favorite Button
                    Button(action: toggleFavoriteStatus) {
                        Image(systemName: isCurrentStationFavorite ? "star.fill" : "star")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(isCurrentStationFavorite ? .yellow : .primary)
                            .frame(width: 48, height: 48)
                            .modifier(SystemGlassCircleStyle(isInteractive: true))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                }
                        .padding(.bottom, 36)
                }

            }
            .safeAreaPadding(.top)
            .safeAreaPadding(.bottom, 32)
        }
        .task(id: playbackManager.currentStation?.favicon) {
            await updateArtworkTint()
        }
        #if os(macOS)

        .frame(width: 380, height: 560)

        #else

        .frame(maxWidth: .infinity, maxHeight: .infinity)

        .ignoresSafeArea()

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


// MARK: - Player Expansion Animation

private struct PlayerFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

private struct MeasurePlayerFrame: ViewModifier {
    @Binding var frame: CGRect
    let coordinateSpace: CoordinateSpace

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: PlayerFramePreferenceKey.self,
                            value: geometry.frame(in: coordinateSpace)
                        )
                }
            }
            .onPreferenceChange(PlayerFramePreferenceKey.self) { frame in
                guard frame != .zero else { return }
                self.frame = frame
            }
    }
}

private extension View {
    func measurePlayerFrame(
        _ frame: Binding<CGRect>,
        in coordinateSpace: CoordinateSpace
    ) -> some View {
        modifier(MeasurePlayerFrame(frame: frame, coordinateSpace: coordinateSpace))
    }
}

struct PlayerExpansionView<MiniPlayer: View, FullPlayer: View>: View, Animatable {
    var animatableData: CGFloat

    private let miniPlayer: MiniPlayer
    private let fullPlayer: FullPlayer
    private let onDismiss: () -> Void

    @State private var miniFrame: CGRect = .zero
    @State private var fullFrame: CGRect = .zero
    @State private var dragOffset: CGFloat = 0

    init(
        progress: CGFloat,
        @ViewBuilder miniPlayer: () -> MiniPlayer,
        @ViewBuilder fullPlayer: () -> FullPlayer,
        onDismiss: @escaping () -> Void
    ) {
        self.animatableData = progress
        self.miniPlayer = miniPlayer()
        self.fullPlayer = fullPlayer()
        self.onDismiss = onDismiss
    }

    private var progress: CGFloat {
        min(max(animatableData, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let screenHeight = proxy.size.height
            let measuredFullHeight = fullFrame.height > 0 ? fullFrame.height : screenHeight
            let miniHeight = max(miniFrame.height, 1)

            // The article's approach: interpolate one CGFloat between the
            // measured mini-player height and the measured full-player height.
            let expandedHeight = miniHeight + (measuredFullHeight - miniHeight) * progress

            let safeDrag = min(max(dragOffset, 0), screenHeight * 0.72)
            let dragFraction = min(safeDrag / max(screenHeight, 1), 0.72)
            let cornerRadius = 22 * (1 - progress) + 18 * dragFraction

            ZStack(alignment: .bottom) {
                // Full player exists during the entire animation. The parent
                // container reveals it progressively from bottom to top.
                fullPlayer
                    .frame(width: proxy.size.width, height: measuredFullHeight)
                    .measurePlayerFrame($fullFrame, in: .local)
                    .opacity(progress)
                    .allowsHitTesting(progress > 0.55)

                // Mini player stays in the hierarchy while expanding so its
                // measured height remains stable.
                miniPlayer
                    .frame(maxWidth: .infinity)
                    .measurePlayerFrame($miniFrame, in: .local)
                    .opacity(1 - progress)
                    .allowsHitTesting(progress < 0.45)
            }
            .frame(
                width: proxy.size.width,
                height: expandedHeight,
                alignment: .bottom
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
            .frame(
                width: proxy.size.width,
                height: proxy.size.height,
                alignment: .bottom
            )
            .offset(y: safeDrag)
            .scaleEffect(1 - dragFraction * 0.025, anchor: .center)
            .simultaneousGesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .local)
                    .onChanged { value in
                        guard progress > 0.8 else { return }

                        let vertical = value.translation.height
                        let horizontal = abs(value.translation.width)

                        guard vertical > 0, vertical > horizontal else { return }

                        dragOffset = vertical
                    }
                    .onEnded { value in
                        guard progress > 0.8 else {
                            dragOffset = 0
                            return
                        }

                        let distance = value.translation.height
                        let predictedDistance = value.predictedEndTranslation.height
                        let shouldDismiss = distance > 90 || predictedDistance > 160

                        if shouldDismiss {
                            withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
                                dragOffset = 0
                                onDismiss()
                            }
                        } else {
                            withAnimation(.spring(response: 0.40, dampingFraction: 0.84)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .ignoresSafeArea()
    }
}

struct PlayerArtworkMatch: ViewModifier {
    var animation: Namespace.ID?
    var isSource = true

    @ViewBuilder
    func body(content: Content) -> some View {
        if let animation {
            content.matchedGeometryEffect(id: "playerArtwork", in: animation, isSource: isSource)
        } else {
            content
        }
    }
}

private struct SystemGlassCircleStyle: ViewModifier {
    var isInteractive = false

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            let glass = isInteractive
                ? Glass.regular.interactive()
                : Glass.regular
            content.glassEffect(glass, in: Circle())
        } else {
            content.background(.regularMaterial, in: Circle())
        }
        #else
        content.background(.regularMaterial, in: Circle())
        #endif
    }
}

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.68), value: configuration.isPressed)
    }
}

