import SwiftUI
import SwiftData

struct FavoritesTabView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    @Query(sort: \FavoriteStation.name) private var favorites: [FavoriteStation]

    var body: some View {
        NavigationStack {
            List {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "Keine Favoriten",
                        systemImage: "star.slash",
                        description: Text("Füge Sender über das Menü im Player zu deinen Favoriten hinzu.")
                    )
                } else {
                    ForEach(favorites) { favorite in
                        Button(action: {
                            let station = RadioStation(
                                id: favorite.id,
                                name: favorite.name,
                                url: favorite.url.absoluteString,
                                favicon: favorite.favicon,
                                tags: favorite.tags,
                                clickcount: 0
                            )
                            playbackManager.play(station: station)
                        }) {
                            VStack(alignment: .leading) {
                                Text(favorite.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if !favorite.tags.isEmpty {
                                    Text(favorite.tags)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Favorites")
        }
    }
}

#Preview {
    FavoritesTabView()
        .modelContainer(for: FavoriteStation.self)
        .environment(PlaybackManager())
}
