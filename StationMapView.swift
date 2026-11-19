//
//  StationMapView.swift
//  Spectrum
//
//  Created by Farin on 7/12/26.
//
import SwiftUI
import MapKit
import CoreLocation

#if !os(watchOS)

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
    @State private var selectedStationID: String?
    @State private var isMapActive = false
    
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
        Group {
            if isMapActive {
                mapContent
            } else {
                Color.clear
            }
        }
        .onAppear {
            isMapActive = true
            permissionManager.requestPermission()
            if apiClient.mapStations.isEmpty {
                triggerRegionFetch(region: currentRegion)
            }
        }
        .onDisappear {
            isMapActive = false
            selectedStationID = nil
            apiClient.clearMapStations()
        }
    }

    private var mapContent: some View {
        Map(position: $position, selection: $selectedStationID) {
            ForEach(apiClient.mapStations) { station in
                if let lat = station.latitude, let lon = station.longitude, lat != 0, lon != 0 {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

                    Marker(
                        station.name,
                        systemImage: "dot.radiowaves.left.and.right",
                        coordinate: coordinate
                    )
                    .tag(station.id)
                    .tint(playbackManager.currentStation?.id == station.id ? .red : .blue)
                }
            }
        }
        .mapStyle(isSatelliteMode ? .hybrid(elevation: .realistic) : .standard)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapPitchToggle()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            self.currentRegion = context.region
            triggerRegionFetch(region: context.region)
        }
        .onChange(of: selectedStationID) { _, newID in
            guard let newID,
                  let station = apiClient.mapStations.first(where: { $0.id == newID }) else { return }
            playbackManager.play(station: station)
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
    
}

#endif

