//
//  MiniPlayerView.swift
//  Spectrum
//
//  Created by Farin on 6/19/26.
//

import SwiftUI

struct MiniPlayerView: View {
    @Environment(PlaybackManager.self) private var playbackManager
    var action: () -> Void
    var animation: Namespace.ID? = nil
    var isExpanded = false

    private let cornerRadius: CGFloat = 22

    private var currentStation: RadioStation? {
        playbackManager.currentStation
    }

    private var isPlaying: Bool {
        playbackManager.isPlaying
    }

    private var isLoading: Bool {
        playbackManager.isLoadingStation
    }

    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Station Favicon
            ZStack {
                AsyncImage(url: URL(string: currentStation?.favicon ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_), .empty:
                        ZStack {
                            Color.secondary.opacity(0.12)
                            Image(systemName: "radio")
                                .font(.system(size: 20))
                                .foregroundStyle(.primary.opacity(0.7))
                        }
                    @unknown default:
                        Image(systemName: "radio")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .modifier(PlayerArtworkMatch(animation: animation, isSource: !isExpanded))
            }

            // MARK: - Station Details & Status
            VStack(alignment: .leading, spacing: 3) {
                if let animation {
                    Text(currentStation?.name ?? String(localized: "Player_Status_Pause"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "playerTitle", in: animation, isSource: !isExpanded)
                } else {
                    Text(currentStation?.name ?? String(localized: "Player_Status_Pause"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Wird geladen...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if isPlaying {
                        HStack(spacing: 5) {
                            Image(systemName: "waveform")
                                .symbolEffect(.variableColor.iterative, options: .repeating)
                            Text(String(localized: "Player_Status_Live"))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                    } else {
                        Text("Bereit")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 8)

            // MARK: - Play / Pause Control
            if isLoading {
                ProgressView()
                    .frame(width: 38, height: 38)
            } else {
                Button {
                    guard currentStation != nil else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        playbackManager.togglePlayback()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(currentStation == nil)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            #if os(iOS)
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.bar)
                    .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 7)
            }
            #else
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.bar)
            #endif
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onTapGesture {
            guard currentStation != nil else { return }
            action()
        }
        .animation(.snappy(duration: 0.25), value: isPlaying)
        .animation(.snappy(duration: 0.25), value: isLoading)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
