import SwiftUI

struct MiniPlayerView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    var action: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Sender-Logo (Optimierte Größe für Spaltmaße)
            AsyncImage(url: URL(string: playbackManager.currentStation?.favicon ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Color.white.opacity(0.05)
                    Image(systemName: "radio")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            
            // Text-Metadaten
            VStack(alignment: .leading, spacing: 2) {
                Text(playbackManager.currentStation?.name ?? String(localized: "Player_Status_Pause"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(playbackManager.isPlaying ? String(localized: "Player_Status_Live") : " ")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Steuerungselemente mit physischem Feedback
            HStack(spacing: 24) {
                Button(action: { playbackManager.togglePlayback() }) {
                    Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(LiquidGlassButtonStyle())
                
                Button(action: {
                    // Optionale Funktion für Vorwärts
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(LiquidGlassButtonStyle())
                .opacity(0.4)
            }
            .padding(.trailing, 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            // Echtes Liquid Glass Konstrukt (Korrigierte Render-Pipeline)
            ZStack {
                // Lichtbrechungskomponente via nativem VisualEffect-Blur über eine Background-Kapsel
                Color.white.opacity(0.01)
                    .background(.ultraThinMaterial)
                    .scaleEffect(1.02)
                
                // Grundsättigung des gegossenen Glaskörpers
                Color.white.opacity(0.06)
                
                // Specular Highlight (Lichteinfall von oben links)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.25),
                        Color.white.opacity(0.03),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                // Flüssige Kantenreflexion (Gusskante)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.1),
                                Color.black.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            // Absorptions-Schatten zur räumlichen Trennung
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        }
        .onTapGesture {
            action()
        }
    }
}

// Physikalisches Interaktionsverhalten für Liquid Glass Oberflächen
struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

