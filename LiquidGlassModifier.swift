//
//  LiquidGlassModifier.swift
//  Spectrum
//
//  Created by Farin on 6/14/26.
//

import SwiftUI

// MARK: - Liquid Glass Modifier (Rounded Rectangle)
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var tint: Color? = nil
    var material: Material = .ultraThinMaterial
    var borderWidth: CGFloat = 1.0
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(material)
                    
                    if let tint {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(colorScheme == .dark ? 0.16 : 0.08))
                    }
                    
                    // Specular light sheen across top surface
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.14 : 0.28), location: 0.0),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.03 : 0.08), location: 0.35),
                                    .init(color: Color.clear, location: 0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                // High-precision beveled specular rim light
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.75), location: 0.0),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.18 : 0.35), location: 0.28),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.04 : 0.12), location: 0.65),
                                .init(color: Color.clear, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.06),
                radius: 10,
                x: 0,
                y: 5
            )
            .shadow(
                color: (tint ?? Color.accentColor).opacity(colorScheme == .dark ? 0.14 : 0.05),
                radius: 20,
                x: 0,
                y: 10
            )
    }
}

// MARK: - Liquid Glass Circle Modifier
struct LiquidGlassCircleModifier: ViewModifier {
    var tint: Color? = nil
    var material: Material = .ultraThinMaterial
    var borderWidth: CGFloat = 1.0
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Circle()
                        .fill(material)
                    
                    if let tint {
                        Circle()
                            .fill(tint.opacity(colorScheme == .dark ? 0.20 : 0.10))
                    }
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.20 : 0.35), location: 0.0),
                                    .init(color: Color.white.opacity(0.02), location: 0.45),
                                    .init(color: Color.clear, location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.50 : 0.85), location: 0.0),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.15 : 0.30), location: 0.35),
                                .init(color: Color.clear, location: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
            }
            .clipShape(Circle())
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.07),
                radius: 8,
                x: 0,
                y: 4
            )
            .shadow(
                color: (tint ?? Color.accentColor).opacity(colorScheme == .dark ? 0.15 : 0.06),
                radius: 16,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Liquid Glass Capsule Modifier
struct LiquidGlassCapsuleModifier: ViewModifier {
    var tint: Color? = nil
    var material: Material = .ultraThinMaterial
    var borderWidth: CGFloat = 1.0
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Capsule()
                        .fill(material)
                    
                    if let tint {
                        Capsule()
                            .fill(tint.opacity(colorScheme == .dark ? 0.20 : 0.10))
                    }
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.15 : 0.28), location: 0.0),
                                    .init(color: Color.clear, location: 0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.75), location: 0.0),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.12 : 0.25), location: 0.4),
                                .init(color: Color.clear, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
            }
            .clipShape(Capsule())
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.05),
                radius: 6,
                x: 0,
                y: 3
            )
    }
}

// MARK: - Liquid Aurora Background (Living Fluid Mesh)
struct LiquidAuroraBackground: View {
    var primaryColor: Color = .blue
    var secondaryColor: Color = .purple
    var accentColor: Color = .cyan
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let offset1X = CGFloat(sin(t * 0.35) * 60)
            let offset1Y = CGFloat(cos(t * 0.45) * 80)
            
            let offset2X = CGFloat(cos(t * 0.28) * 75)
            let offset2Y = CGFloat(sin(t * 0.38) * 65)
            
            let offset3X = CGFloat(sin(t * 0.22) * 55)
            let offset3Y = CGFloat(cos(t * 0.32) * 70)
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                ZStack {
                    // Base background
                    Color(platformColor: .windowBackground)
                        .ignoresSafeArea()
                    
                    // Fluid orb 1 (Primary top leading)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    primaryColor.opacity(colorScheme == .dark ? 0.38 : 0.28),
                                    primaryColor.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: w * 0.55
                            )
                        )
                        .frame(width: w * 0.95, height: w * 0.95)
                        .offset(x: -w * 0.25 + offset1X, y: -h * 0.20 + offset1Y)
                        .blur(radius: 70)
                    
                    // Fluid orb 2 (Secondary bottom trailing)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    secondaryColor.opacity(colorScheme == .dark ? 0.34 : 0.22),
                                    secondaryColor.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: w * 0.50
                            )
                        )
                        .frame(width: w * 0.90, height: w * 0.90)
                        .offset(x: w * 0.28 + offset2X, y: h * 0.15 + offset2Y)
                        .blur(radius: 80)
                    
                    // Fluid orb 3 (Accent center/bottom)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    accentColor.opacity(colorScheme == .dark ? 0.28 : 0.18),
                                    accentColor.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: w * 0.45
                            )
                        )
                        .frame(width: w * 0.80, height: w * 0.80)
                        .offset(x: offset3X, y: h * 0.38 + offset3Y)
                        .blur(radius: 75)
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Liquid Live Waveform View
struct LiquidLiveWaveformView: View {
    var isPlaying: Bool
    var tint: Color = .red
    var barCount: Int = 4
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { i in
                    let phase = Double(i) * 0.8
                    let scale = isPlaying
                        ? 0.35 + 0.65 * abs(sin(t * 4.5 + phase))
                        : 0.25
                    
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(tint)
                        .frame(width: 3, height: 14)
                        .scaleEffect(y: CGFloat(scale), anchor: .bottom)
                        .animation(.easeOut(duration: 0.15), value: scale)
                }
            }
            .frame(height: 14, alignment: .bottom)
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Applies an Apple-style Liquid Glass frosted material with specular highlights and bevel.
    func liquidGlass(
        cornerRadius: CGFloat = 20,
        tint: Color? = nil,
        material: Material = .ultraThinMaterial,
        borderWidth: CGFloat = 1.0
    ) -> some View {
        self.modifier(
            LiquidGlassModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                material: material,
                borderWidth: borderWidth
            )
        )
    }
    
    /// Applies a circular Liquid Glass style suitable for buttons and controls.
    func liquidGlassCircle(
        tint: Color? = nil,
        material: Material = .ultraThinMaterial,
        borderWidth: CGFloat = 1.0
    ) -> some View {
        self.modifier(
            LiquidGlassCircleModifier(
                tint: tint,
                material: material,
                borderWidth: borderWidth
            )
        )
    }
    
    /// Applies a capsule Liquid Glass style for badges and pills.
    func liquidGlassCapsule(
        tint: Color? = nil,
        material: Material = .ultraThinMaterial,
        borderWidth: CGFloat = 1.0
    ) -> some View {
        self.modifier(
            LiquidGlassCapsuleModifier(
                tint: tint,
                material: material,
                borderWidth: borderWidth
            )
        )
    }
}
