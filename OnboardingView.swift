//
//  OnboardingView.swift
//  Spectrum
//
//  Created by Farin  on 6/22/26.
//
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    let isUpdate: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: isUpdate ? "sparkles" : "radio.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text(isUpdate ? OnboardingContent.currentUpdate.title : OnboardingContent.welcomeTitle)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                let features = isUpdate ? OnboardingContent.currentUpdate.features : OnboardingContent.welcomeFeatures
                
                ForEach(features, id: \.self) { feature in
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
                Text(isUpdate ? "Loslegen" : "Fortfahren")
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
        .frame(minWidth: 320, minHeight: 450)
    }
}
