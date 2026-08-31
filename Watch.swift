//
//  Watch.swift
//  Spectrum
//
//  Created by Farin  on 8/11/26.
//
import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity
import Observation

@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    var isReachable: Bool = false
    var iPhoneStationName: String? = nil
    var isPhonePlaying: Bool = false
    
    var onTogglePlaybackRequest: (() -> Void)?
    var onPlayStationRequest: ((String) -> Void)?
    
    override private init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func sendPlaybackState(stationName: String?, isPlaying: Bool) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        let context: [String: Any] = [
            "stationName": stationName ?? "",
            "isPlaying": isPlaying
        ]
        try? WCSession.default.updateApplicationContext(context)
    }
    
    func sendCommand(_ command: String, stationID: String? = nil) {
        guard WCSession.default.isReachable else { return }
        var message: [String: Any] = ["command": command]
        if let stationID = stationID { message["stationID"] = stationID }
        WCSession.default.sendMessage(message, replyHandler: nil)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let name = applicationContext["stationName"] as? String {
                self.iPhoneStationName = name.isEmpty ? nil : name
            }
            if let playing = applicationContext["isPlaying"] as? Bool {
                self.isPhonePlaying = playing
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let command = message["command"] as? String {
                if command == "togglePlayback" {
                    self.onTogglePlaybackRequest?()
                }
            }
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif
}

#else
import Observation

@Observable
final class WatchConnectivityManager {
    static let shared = WatchConnectivityManager()
    
    var isReachable: Bool = false
    var iPhoneStationName: String? = nil
    var isPhonePlaying: Bool = false
    
    var onTogglePlaybackRequest: (() -> Void)?
    var onPlayStationRequest: ((String) -> Void)?
    
    private init() {}
    
    func sendPlaybackState(stationName: String?, isPlaying: Bool) { }
    func sendCommand(_ command: String, stationID: String? = nil) { }
}
#endif
