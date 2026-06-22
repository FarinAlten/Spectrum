//
//  LiquidGlassModifier.swift
//  Spectrum
//
//  Created by Farin  on 6/14/26.
//
import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    @State private var animate = false
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    LinearGradient(
                        colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                        startPoint: animate ? .topLeading : .bottomTrailing,
                        endPoint: animate ? .bottomTrailing : .topLeading
                    )
                    .blur(radius: 30)
                    
                    Circle()
                        .fill(.pink.opacity(0.4))
                        .frame(width: 300, height: 300)
                        .offset(x: animate ? 100 : -100, y: animate ? -100 : 100)
                        .blur(radius: 50)
                    
                    Color.white.opacity(0.15)
                        .background(.ultraThinMaterial)
                }
                .onAppear {
                    withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                        animate.toggle()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}
