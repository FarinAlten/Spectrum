import SwiftUI
import SwiftData

struct FavoritesTabView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(\.modelContext) private var modelContext
    
    // Sortierung hinzufügen, um die Liste bei Änderungen zur Aktualisierung zu zwingen
    @Query(sort: \FavoriteStation.name) private var favoriteStations: [FavoriteStation]
    
    var body: some View {
        NavigationStack {
            List {
                if favoriteStations.isEmpty {
                    ContentUnavailableView(
                        "Keine Favoriten",
                        systemImage: "star.slash",
                        description: Text("Füge Sender über das Menü im Player zu deinen Favoriten hinzu.")
                    )
                } else {
                    ForEach(favoriteStations, id: \.id) { favorite in
                        Button(action: {
                            let stationToPlay = RadioStation(
                                id: favorite.id,
                                name: favorite.name,
                                url: favorite.url.absoluteString,
                                favicon: favorite.favicon,
                                tags: favorite.tags,
                                clickcount: 0
                            )
                            playbackManager.play(station: stationToPlay)
                        }) {
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: favorite.favicon)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "radio")
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(favorite.name)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    
                                    if !favorite.tags.isEmpty {
                                        Text(favorite.tags)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { @MainActor in
                                    modelContext.delete(favorite)
                                    try? modelContext.save()
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favoriten")
        }
    }
}
