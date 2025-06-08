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
    @Published var isShowingSearchSheet = false
    
    // For distance tracking
    @Published var isDistanceTrackingActive = false
    @Published var trackedDestination: PlaceInfo?
    @Published var distanceToDestination: Double?
    @Published var isShowingDistanceSheet = false
    @Published var routeLine: MKPolyline?
    
    @Published var initialDistanceToDestination: Double?

    
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
    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
//        lastLocation = location
//        
//        // Only update region if we're not showing a place sheet
//        if shouldUpdateRegion {
//            DispatchQueue.main.async {
//                self.region = MKCoordinateRegion(
//                    center: location.coordinate,
//                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//                )
//            }
//        }
//    }
    

    
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
    
    // Set selected place from search results
    func setSelectedPlace(_ place: PlaceInfo) {
        // Set flag to prevent automatic region updates
        shouldUpdateRegion = false
        
        // Set the selected location for annotation
        selectedLocationCoordinate = place.coordinate
        
        // Update region to center on the selected location
        region = MKCoordinateRegion(
            center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        // Update selected place and show place sheet
        selectedPlace = place
        isShowingPlaceSheet = true
        
        // Hide search sheet
        isShowingSearchSheet = false
    }
    
    
    // Modify the startDistanceTracking function
    func startDistanceTracking(to destination: PlaceInfo) {
        trackedDestination = destination
        isDistanceTrackingActive = true
        
        // Calculate and store initial distance
        updateDistanceToDestination()
        if let distance = distanceToDestination {
            initialDistanceToDestination = distance
        }
        
        isShowingDistanceSheet = true
        
        // Draw a line on the map between current location and destination
        updateRouteLine()
    }

    // Modify the stopDistanceTracking function
    func stopDistanceTracking() {
        trackedDestination = nil
        isDistanceTrackingActive = false
        distanceToDestination = nil
        initialDistanceToDestination = nil
        routeLine = nil
        isShowingDistanceSheet = false
        selectedLocationCoordinate = nil
    }

    // Update the distance calculation
    private func updateDistanceToDestination() {
        guard let destination = trackedDestination?.coordinate,
              let currentLocation = lastLocation?.coordinate else {
            distanceToDestination = nil
            return
        }
        
        // Create CLLocation objects for distance calculation
        let destLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        
        // Calculate distance in meters
        distanceToDestination = userLocation.distance(from: destLocation)
        
        // Update route line
        updateRouteLine()
    }

    // Update the line shown on the map
    private func updateRouteLine() {
        guard let destination = trackedDestination?.coordinate,
              let currentLocation = lastLocation?.coordinate else {
            routeLine = nil
            return
        }
        
        let points = [currentLocation, destination]
        routeLine = MKPolyline(coordinates: points, count: points.count)
        
        // If needed, adjust map to show both points
        if isDistanceTrackingActive {
            // Calculate midpoint and span to show both points
            let midLat = (currentLocation.latitude + destination.latitude) / 2
            let midLon = (currentLocation.longitude + destination.longitude) / 2
            
            let latDelta = abs(currentLocation.latitude - destination.latitude) * 1.5
            let lonDelta = abs(currentLocation.longitude - destination.longitude) * 1.5
            
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
                span: MKCoordinateSpan(latitudeDelta: max(0.005, latDelta), longitudeDelta: max(0.005, lonDelta))
            )
            
            // Update region
            DispatchQueue.main.async {
                self.shouldUpdateRegion = false
                self.region = region
            }
        }
    }

    // Center the map on the route
    func centerOnRoute() {
        guard let destination = trackedDestination?.coordinate,
              let currentLocation = lastLocation?.coordinate else { return }
        
        // Calculate midpoint and span to show both points
        let midLat = (currentLocation.latitude + destination.latitude) / 2
        let midLon = (currentLocation.longitude + destination.longitude) / 2
        
        let latDelta = abs(currentLocation.latitude - destination.latitude) * 1.5
        let lonDelta = abs(currentLocation.longitude - destination.longitude) * 1.5
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
            span: MKCoordinateSpan(latitudeDelta: max(0.005, latDelta), longitudeDelta: max(0.005, lonDelta))
        )
        
        // Update region
        DispatchQueue.main.async {
            self.shouldUpdateRegion = false
            self.region = region
        }
    }
    
    // Update the existing locationManager delegate method to call this
    // Add this to your locationManager(_:didUpdateLocations:) method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        
        // Update distance if tracking is active
        if isDistanceTrackingActive {
            updateDistanceToDestination()
        }
        
        // Only update region if we're not showing a place sheet or tracking distance
        if shouldUpdateRegion && !isDistanceTrackingActive {
            DispatchQueue.main.async {
                self.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
}

