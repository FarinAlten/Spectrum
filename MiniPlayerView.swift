//
//  MiniPlayerView.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//
import SwiftUI

struct MiniPlayerView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    var action: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Linker Bereich: Album-Art/Logo & Senderelemente
            HStack(spacing: 14) {
                AsyncImage(url: URL(string: playbackManager.currentStation?.favicon ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.primary.opacity(0.05)
                        Image(systemName: "radio")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    // Zeige den Sendernamen oder einen Standard-Platzhaltertext
                    Text(playbackManager.currentStation?.name ?? "Kein Sender ausgewählt")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if playbackManager.isLoadingStation {
                        Text("Wird geladen...")
                            .font(.system(size: 11))
                            .foregroundColor(.accentColor)
                            .lineLimit(1)
                    } else {
                        Text(playbackManager.isPlaying ? String(localized: "Player_Status_Live") : "Bereit")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Rechter Bereich: Play/Pause Button oder Lade-Spinner
            if playbackManager.isLoadingStation {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 28, height: 28)
            } else {
                Button(action: {
                    if playbackManager.currentStation != nil {
                        playbackManager.togglePlayback()
                    }
                }) {
                    Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(playbackManager.currentStation == nil ? .secondary.opacity(0.5) : .primary)
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(playbackManager.currentStation == nil)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            // Das detaillierte Sheet öffnet sich nur, wenn auch wirklich ein Sender aktiv ist
            if playbackManager.currentStation != nil {
                action()
            }
        }
        .background(.bar)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
