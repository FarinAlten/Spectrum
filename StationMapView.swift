//
//  StationMapView.swift
//  Spectrum
//
//  Created by Farin on 7/12/26.
//
import SwiftUI
import MapKit
import CoreLocation

@Observable
class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestPermission() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

struct StationMapView: View {
    var apiClient: RadioAPIClient
    @Environment(PlaybackManager.self) private var playbackManager
    @State private var permissionManager = LocationPermissionManager()
    
    @State private var isSatelliteMode = false
    
    @State private var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.0, longitude: 10.0),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
    )
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.0, longitude: 10.0),
            span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
        )
    )
    
    var body: some View {
        Map(position: $position) {
            ForEach(apiClient.searchResults.isEmpty ? apiClient.stations : apiClient.searchResults) { station in
                if let lat = station.latitude, let lon = station.longitude, lat != 0, lon != 0 {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    
                    Annotation(station.name, coordinate: coordinate, anchor: .bottom) {
                        Button(action: {
                            playbackManager.play(station: station)
                        }) {
                            VStack(spacing: 4) {
                                if playbackManager.currentStation?.id == station.id && playbackManager.isPlaying {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .symbolEffect(.variableColor.iterative, options: .repeating)
                                } else {
                                    Image(systemName: "radio.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                        .background(Color.white.clipShape(Circle()))
                                }
                                
                                Text(truncate(station.name, length: 8))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .fixedSize()
                                    .modifier(MapLabelStyle())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(isSatelliteMode ? .hybrid(elevation: .realistic) : .standard)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapPitchToggle()
        }
        .onMapCameraChange { context in
            self.currentRegion = context.region
            triggerRegionFetch(region: context.region)
        }
        .navigationTitle("Map_Title_Main")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation { isSatelliteMode.toggle() }
                }) {
                    Image(systemName: isSatelliteMode ? "map" : "globe.europe.africa")
                }
                .help("Toggle satellite map style")
            }
        }
        .task {
            permissionManager.requestPermission()
        }
    }
    
    private func triggerRegionFetch(region: MKCoordinateRegion) {
        Task {
            await apiClient.fetchStationsInRegion(
                latitude: region.center.latitude,
                longitude: region.center.longitude,
                latDelta: region.span.latitudeDelta,
                lonDelta: region.span.longitudeDelta
            )
        }
    }
    
    private func truncate(_ text: String, length: Int) -> String {
        if text.count > length {
            return String(text.prefix(length)) + "…"
        }
        return text
    }
}

struct MapLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        let bgColor = Color(.windowBackgroundColor).opacity(0.95)
        #else
        let bgColor = Color(.systemBackground).opacity(0.95)
        #endif
        
        return content
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
    }
}
