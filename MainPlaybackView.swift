import SwiftUI

struct MainPlaybackView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    
    @State private var dynamicColors: [Color] = [.gray, .black]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Cover/Favicon-Anzeige
            AsyncImage(url: URL(string: playbackManager.currentStation?.favicon ?? "")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "radio")
                        .font(.system(size: 80))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: dynamicColors.first?.opacity(0.3) ?? Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            
            Spacer()
            
            // Sendungsinformationen
            VStack(spacing: 8) {
                Text(playbackManager.currentStation?.name ?? String(localized: "Player_Status_Pause"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if playbackManager.isPlaying {
                    Text(String(localized: "Player_Status_Live"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Steuerungselemente
            HStack(spacing: 40) {
                Button(action: {
                    playbackManager.togglePlayback()
                }) {
                    Image(systemName: playbackManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 72))
                        .symbolEffect(.bounce, value: playbackManager.isPlaying)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [dynamicColors.first?.opacity(0.2) ?? .clear, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onChange(of: playbackManager.currentStation?.favicon) { _, newValue in
            if let faviconUrl = newValue, !faviconUrl.isEmpty {
                fetchColorsFromURL(faviconUrl)
            } else {
                dynamicColors = [.gray, .black]
            }
        }
        .onAppear {
            if let faviconUrl = playbackManager.currentStation?.favicon, !faviconUrl.isEmpty {
                fetchColorsFromURL(faviconUrl)
            }
        }
    }
    
    // Lädt das Bild im Hintergrund und stößt die Farbegewinnung an
    private func fetchColorsFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let nativeImage = nativeImageConvert(data: data) else { return }
            
            DispatchQueue.mainAsync {
                let extractedColors = extractColors(from: nativeImage)
                self.dynamicColors = extractedColors
            }
        }
        .resume()
    }
    
    // Extrahiert Farben plattformunabhängig mittels SwiftUI ImageRenderer
    private func extractColors(from image: Image) -> [Color] {
        let viewToRender = image.frame(width: 10, height: 10)
        let renderer = ImageRenderer(content: viewToRender)
        
        guard let cgImage = renderer.cgImage else { return [.gray, .black] }
        
        let width = 10
        let height = 10
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [.gray, .black] }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let topLeftColor = Color(
            red: Double(pixelData[0]) / 255.0,
            green: Double(pixelData[1]) / 255.0,
            blue: Double(pixelData[2]) / 255.0
        )
        
        let centerColor = Color(
            red: Double(pixelData[(width * height / 2) * 4]) / 255.0,
            green: Double(pixelData[(width * height / 2) * 4 + 1]) / 255.0,
            blue: Double(pixelData[(width * height / 2) * 4 + 2]) / 255.0
        )
        
        let bottomRightColor = Color(
            red: Double(pixelData[pixelData.count - 4]) / 255.0,
            green: Double(pixelData[pixelData.count - 3]) / 255.0,
            blue: Double(pixelData[pixelData.count - 2]) / 255.0
        )
        
        return [topLeftColor, centerColor, bottomRightColor]
    }
}

// MARK: - Helper

// Konvertiert die geladenen Data-Pakete im Hintergrund plattformspezifisch in ein SwiftUI Image
func nativeImageConvert(data: Data) -> Image? {
    #if os(iOS)
    if let uiImage = UIImage(data: data) {
        return Image(uiImage: uiImage)
    }
    #else
    if let nsImage = NSImage(data: data) {
        return Image(nsImage: nsImage)
    }
    #endif
    return nil
}

#if os(iOS)
import UIKit
#else
import AppKit
#endif

extension DispatchQueue {
    static func mainAsync(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
