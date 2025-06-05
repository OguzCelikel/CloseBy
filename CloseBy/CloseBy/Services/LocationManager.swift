//
//  LocationManager.swift
//  CloseBy
//
//  Created by Omer Oguz Celikel on 4.06.2025.
//

import CoreLocation
import MapKit

struct PlaceInfo {
    var name: String = "Selected Location"
    var coordinate: CLLocationCoordinate2D
    var address: String = "Loading address..."
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784), // Istanbul default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // For the bottom sheet
    @Published var selectedPlace: PlaceInfo?
    @Published var isShowingPlaceSheet = false
    
    // Flag to control automatic region updates
    private var shouldUpdateRegion = true
    
    // Selected location for annotation
    @Published var selectedLocationCoordinate: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkPermission()
    }
    
    func checkPermission() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        
        // Only update region if we're not showing a place sheet
        if shouldUpdateRegion {
            DispatchQueue.main.async {
                self.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
    
    // Handle long press on map
    func handleMapLongPress(at coordinate: CLLocationCoordinate2D) {
        // Set flag to prevent automatic region updates
        shouldUpdateRegion = false
        
        // Set the selected location for annotation
        selectedLocationCoordinate = coordinate
        
        // Update region to center on the long press location
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        // Create a basic place info with just coordinates
        selectedPlace = PlaceInfo(coordinate: coordinate)
        isShowingPlaceSheet = true
        
        // Get the address for the location
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    self.selectedPlace?.address = "Address not available"
                    return
                }
                
                if let placemark = placemarks?.first {
                    // Format the address
                    let address = [
                        placemark.thoroughfare,
                        placemark.subThoroughfare,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.postalCode,
                        placemark.country
                    ]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                    
                    self.selectedPlace?.name = placemark.name ?? "Selected Location"
                    self.selectedPlace?.address = address.isEmpty ? "Address not available" : address
                } else {
                    self.selectedPlace?.address = "Address not available"
                }
            }
        }
    }
    
    func centerOnUserLocation() {
        if let location = lastLocation {
            shouldUpdateRegion = false // Prevent auto-updates briefly
            
            // Clear any selected location
            selectedLocationCoordinate = nil
            
            // Center the map on user location
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            // Allow auto-updates again after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.shouldUpdateRegion = true
            }
        }
    }
    
    // Call this when the sheet is dismissed
    func resetAfterSheetDismissal() {
        shouldUpdateRegion = true
        selectedLocationCoordinate = nil // Clear the selected location
    }
}

