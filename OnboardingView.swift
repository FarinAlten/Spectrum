//
//  OnboardingView.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//
import SwiftUI

enum OnboardingContent {
    static let welcomeTitle = "Willkommen bei Spectrum"
    static let welcomeFeatures = [
        "Globale Suche nach tausenden Sendern weltweit",
        "Intelligente Gruppierung von Regionalstationen",
        "Favoriten-Synchronisation mit SwiftData"
    ]
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "radio.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text(OnboardingContent.welcomeTitle)
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(OnboardingContent.welcomeFeatures, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.body)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Fortfahren")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(minWidth: 340, minHeight: 460)
    }
}

