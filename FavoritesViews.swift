import SwiftUI
import SwiftData

struct FavoritesTabView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    @Query(sort: \FavoriteStation.name) private var favorites: [FavoriteStation]

    @AppStorage("preferredDisplayMode") private var preferredDisplayMode = "grid"
    @AppStorage("maxGridColumns") private var maxGridColumns = 1

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: maxGridColumns)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "Keine Favoriten",
                        systemImage: "star.slash",
                        description: Text("Füge Sender über das Menü im Player zu deinen Favoriten hinzu.")
                    )
                    .padding(.top, 40)
                } else {
                    if preferredDisplayMode == "grid" {
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            favoriteListContent
                        }
                        .padding(.horizontal, 16)
                    } else {
                        LazyVStack(spacing: 0) {
                            favoriteListContent
                        }
                        .background(Color(platformColor: .controlBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 12)
            .background(Color(platformColor: .windowBackground))
            .navigationTitle("Favorites")
        }
    }

    @ViewBuilder
    private var favoriteListContent: some View {
        ForEach(Array(favorites.enumerated()), id: \.element.id) { index, favorite in
            StationRow(station: RadioStation(
                id: favorite.id,
                name: favorite.name,
                url: favorite.url.absoluteString,
                favicon: favorite.favicon,
                tags: favorite.tags
            ))
            
            if preferredDisplayMode == "list" && index < favorites.count - 1 {
                Divider().padding(.leading, 68)
            }
        }
    }
}

#Preview {
    FavoritesTabView()
        .modelContainer(for: FavoriteStation.self)
        .environment(PlaybackManager())
}
