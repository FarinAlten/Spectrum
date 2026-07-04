import SwiftUI
import SwiftData

// MARK: - MINI PLAYER VIEW
struct MiniPlayerView: View {
    let action: () -> Void
    @Environment(PlaybackManager.self) private var playbackManager
    
    var body: some View {
        if let station = playbackManager.currentStation {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: station.favicon)) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Color.white.opacity(0.05)
                            Image(systemName: "radio")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(playbackManager.isPlaying ? "Wird abgespielt..." : "Pausiert")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    playbackManager.togglePlayback()
                }) {
                    Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                
                FavoriteButton(station: station)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .onTapGesture {
                action()
            }
        }
    }
}

// MARK: - FULL PLAYER VIEW
struct FullPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PlaybackManager.self) private var playbackManager
    @State private var volume: Double = 0.5
    
    var body: some View {
        if let station = playbackManager.currentStation {
            VStack(spacing: 24) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Jetzt läuft")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    FavoriteButton(station: station)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                AsyncImage(url: URL(string: station.favicon)) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ZStack {
                            Color.white.opacity(0.05)
                            Image(systemName: "radio")
                                .font(.system(size: 64))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 240, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 8) {
                    Text(station.name)
                        .font(.title).bold()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if !station.tags.isEmpty {
                        Text(station.tags)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 48) {
                    Button(action: {}) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                    }
                    .buttonStyle(.plain)
                    .disabled(true)
                    .foregroundColor(.secondary.opacity(0.3))
                    
                    Button(action: {
                        playbackManager.togglePlayback()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 80, height: 80)
                            Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(backgroundColor)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                    }
                    .buttonStyle(.plain)
                    .disabled(true)
                    .foregroundColor(.secondary.opacity(0.3))
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                    
                    Slider(value: $volume, in: 0...1)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
        } else {
            ContentUnavailableView("Kein Sender ausgewählt", systemImage: "radio")
        }
    }
    
    private var backgroundColor: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return Color(.windowBackgroundColor)
        #endif
    }
}

// MARK: - FAVORITE BUTTON
struct FavoriteButton: View {
    let station: RadioStation
    @Environment(\.modelContext) private var modelContext
    @Query private var favoriteStations: [FavoriteStation]
    
    private var isFavorite: Bool {
        favoriteStations.contains { $0.id == station.id }
    }
    
    var body: some View {
        Button(action: toggleFavorite) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.title3)
                .foregroundColor(isFavorite ? .yellow : .primary)
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
    }
    
    private func toggleFavorite() {
        if isFavorite {
            if let entity = favoriteStations.first(where: { $0.id == station.id }) {
                modelContext.delete(entity)
            }
        } else {
            let newFavorite = FavoriteStation(
                id: station.id,
                name: station.name,
                url: URL(string: station.url) ?? URL(string: "about:blank")!,
                favicon: station.favicon,
                tags: station.tags
            )
            modelContext.insert(newFavorite)
        }
        try? modelContext.save()
    }
}
