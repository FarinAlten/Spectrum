import SwiftUI
import SwiftData

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
                .foregroundColor(isFavorite ? .yellow : .white)
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
