// WatchConnectivityManager.swift

import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

final class WatchConnectivityManager {
    static let shared = WatchConnectivityManager()

    /// Called when a remote device (e.g. Apple Watch) requests a playback toggle.
    /// PlaybackManager sets this to allow watch-initiated play/pause.
    var onTogglePlaybackRequest: (() -> Void)?

    #if canImport(WatchConnectivity)
    private let session: WCSession?
    #endif

    private init() {
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        } else {
            session = nil
        }
        #else
        // No WatchConnectivity available on this platform — keep a stub implementation.
        #endif
    }

    /// Send simple playback state to paired devices (e.g. Apple Watch).
    /// stationName may be nil.
    func sendPlaybackState(stationName: String?, isPlaying: Bool) {
        #if canImport(WatchConnectivity)
        guard let session = session else { return }

        let payload: [String: Any] = [
            "type": "playbackState",
            "stationName": stationName ?? "",
            "isPlaying": isPlaying
        ]

        // Prefer sendMessage when reachable, otherwise transferUserInfo as a fallback.
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                // Non-fatal: just log for diagnostics
                #if DEBUG
                print("WatchConnectivity sendMessage error:\n", error)
                #endif
            }
        } else {
            session.transferUserInfo(payload)
        }
        #else
        // No-op on platforms without WatchConnectivity
        #endif
    }

    /// Convenience: let callers send arbitrary payloads if needed.
    func sendMessage(_ payload: [String: Any]) {
        #if canImport(WatchConnectivity)
        guard let session = session else { return }
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: { error in
                #if DEBUG
                print("WatchConnectivity sendMessage error:\n", error)
                #endif
            })
        } else {
            session.transferUserInfo(payload)
        }
        #else
        // No-op
        #endif
    }
}

#if canImport(WatchConnectivity)
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if DEBUG
        if let error = error {
            print("WCSession activation error: ", error)
        } else {
            print("WCSession activated: \(activationState)")
        }
        #endif
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Expect a message like: ["command": "togglePlayback"] or a type "togglePlayback"
        if let command = message["command"] as? String, command == "togglePlayback" {
            Task { @MainActor in
                self.onTogglePlaybackRequest?()
            }
            return
        }

        if let type = message["type"] as? String, type == "togglePlayback" {
            Task { @MainActor in
                self.onTogglePlaybackRequest?()
            }
            return
        }

        // Add other message handling as needed.
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif

    // Optional: handle incoming userInfo as well
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let type = userInfo["type"] as? String, type == "togglePlayback" {
            Task { @MainActor in
                self.onTogglePlaybackRequest?()
            }
        }
    }
}
#endif
