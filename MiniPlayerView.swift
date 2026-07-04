//
//  MiniPlayerView.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
//
import SwiftUI

struct MiniPlayerView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    var action: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Button(action: action) {
                HStack(spacing: 14) {
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
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Spacer()

            HStack(spacing: 24) {
                Button(action: { playbackManager.togglePlayback() }) {
                    Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(LiquidGlassButtonStyle())
                
                Button(action: {}) {
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
            ZStack {
                Color.white.opacity(0.01)
                    .background(.ultraThinMaterial)
                    .scaleEffect(1.02)
                
                Color.white.opacity(0.06)
                
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
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        }
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
