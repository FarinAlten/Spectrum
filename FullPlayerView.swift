//
//  FullPlayerView.swift
//  Spectrum
//
//  Created by Farin  on 6/19/26.
//
import SwiftUI
import SwiftData

struct FullPlayerView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var favorites: [FavoriteStation]
    
    private var isCurrentStationFavorite: Bool {
        guard let currentId = playbackManager.currentStation?.id else { return false }
        return favorites.contains { $0.id == currentId }
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                AsyncImage(url: URL(string: playbackManager.currentStation?.favicon ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .blur(radius: 60, opaque: true)
                            .opacity(0.5)
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.black.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    #if os(iOS)
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    #endif
                    
                    Spacer()
                    
                    Button(action: toggleFavoriteStatus) {
                        Image(systemName: isCurrentStationFavorite ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isCurrentStationFavorite ? .yellow : .white.opacity(0.8))
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer(minLength: 20)
                
                AsyncImage(url: URL(string: playbackManager.currentStation?.favicon ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "radio")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(width: 220, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 40)
                
                Spacer(minLength: 30)
                
                VStack(spacing: 6) {
                    Text(playbackManager.currentStation?.name ?? String(localized: "Player_Status_Pause"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 32)
                    
                    if playbackManager.isPlaying {
                        Text(String(localized: "Player_Status_Live"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Capsule())
                    } else {
                        Text("Pausiert")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer(minLength: 40)
                
                HStack {
                    Button(action: {
                        playbackManager.togglePlayback()
                    }) {
                        Image(systemName: playbackManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(playbackManager.isPlaying ? Color.accentColor : Color.primary)
                            .symbolEffect(.bounce, value: playbackManager.isPlaying)
                    }
                    .buttonStyle(.plain)
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                }
                
                Spacer(minLength: 40)
            }
        }
        .frame(minWidth: 360, minHeight: 550)
        #if os(iOS)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        #endif
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
}
