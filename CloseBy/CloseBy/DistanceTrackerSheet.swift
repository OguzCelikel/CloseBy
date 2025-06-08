//
//  DistanceTrackerSheet.swift
//  CloseBy
//
//  Created by Omer Oguz Celikel on 5.06.2025.
//

import SwiftUI
import MapKit

struct DistanceTrackerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    
    // Store the initial distance when tracking begins
    @State private var initialDistance: Double?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with close button
            HStack {
                VStack(alignment: .leading) {
                    Text("Tracking Distance")
                        .font(.headline)
                    
                    if let destination = locationManager.trackedDestination {
                        Text("To: \(destination.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    locationManager.stopDistanceTracking()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            
            Divider()
            
            // Distance information
            if let distance = locationManager.distanceToDestination {
                // Current distance
                HStack {
                    Image(systemName: "arrow.forward")
                        .foregroundColor(.blue)
                    
                    if distance < 1000 {
                        Text("Distance: \(Int(distance)) meters")
                    } else {
                        Text("Distance: \(String(format: "%.1f", distance / 1000)) km")
                    }
                    
                    Spacer()
                }
                .font(.title3)
                .padding(.vertical, 8)
                
                // Calculate progress percentage
                let progressPercentage = calculateProgressPercentage(currentDistance: distance)
                
                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress to destination: \(Int(progressPercentage * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background bar
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .cornerRadius(5)
                                .frame(height: 8)
                            
                            // Progress bar
                            Rectangle()
                                .fill(progressColor(progress: progressPercentage))
                                .frame(width: geometry.size.width * progressPercentage, height: 8)
                                .cornerRadius(5)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Status message based on percentage
                Text(statusMessage(progressPercentage: progressPercentage))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(progressColor(progress: progressPercentage))
                    .padding(.vertical, 8)
                
                // Map preview
                if let currentLocation = locationManager.lastLocation?.coordinate,
                   let destination = locationManager.trackedDestination?.coordinate {
                    
                    // Show a mini map with a line between points
                    MapPreviewView(currentLocation: currentLocation, destinationLocation: destination)
                        .frame(height: 150)
                        .cornerRadius(10)
                }
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .padding()
                    Text("Calculating distance...")
                }
            }
            
//            Spacer()
//            
//            // Center on route button
//            Button(action: {
//                locationManager.centerOnRoute()
//            }) {
//                HStack {
//                    Image(systemName: "map")
//                    Text("Show on Map")
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color.blue)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//            }
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            // Set initial distance on appear if needed
            if let distance = locationManager.distanceToDestination, initialDistance == nil {
                initialDistance = distance
            }
        }
    }
    
    private func calculateProgressPercentage(currentDistance: Double) -> Double {
        guard let initial = initialDistance, initial > 0 else {
            // If we don't have an initial distance yet, store it
            initialDistance = currentDistance
            return 0.0
        }
        
        // Calculate how much closer we've gotten as a percentage
        let remainingPercentage = currentDistance / initial
        let progressPercentage = 1.0 - remainingPercentage
        
        // Constrain between 0 and 1
        return max(0, min(1, progressPercentage))
    }
    
    private func progressColor(progress: Double) -> Color {
        // Color gradient from red (0%) to yellow (50%) to green (100%)
        if progress < 0.5 {
            return Color(red: 1.0, green: progress * 2, blue: 0) // Red to Yellow
        } else {
            return Color(red: 1.0 - (progress - 0.5) * 2, green: 1.0, blue: 0) // Yellow to Green
        }
    }
    
    private func statusMessage(progressPercentage: Double) -> String {
        if progressPercentage >= 0.95 {
            return "You've arrived at your destination!"
        } else if progressPercentage >= 0.85 {
            return "Almost there! You're very close!"
        } else if progressPercentage >= 0.6 {
            return "Getting closer! Keep going!"
        } else if progressPercentage >= 0.3 {
            return "You're making good progress!"
        } else {
            return "On your way! Keep going!"
        }
    }
}

// A small map preview to show the route
struct MapPreviewView: UIViewRepresentable {
    let currentLocation: CLLocationCoordinate2D
    let destinationLocation: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Clear existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // Add annotations for current location and destination
        let currentAnnotation = MKPointAnnotation()
        currentAnnotation.coordinate = currentLocation
        currentAnnotation.title = "Your Location"
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = destinationLocation
        destinationAnnotation.title = "Destination"
        
        mapView.addAnnotations([currentAnnotation, destinationAnnotation])
        
        // Add a straight line between the points
        let points = [currentLocation, destinationLocation]
        let polyline = MKPolyline(coordinates: points, count: points.count)
        mapView.addOverlay(polyline)
        
        // Set the map region to show both points
        let region = MKCoordinateRegion(
            center: midpointBetween(point1: currentLocation, point2: destinationLocation),
            span: spanToShowBoth(point1: currentLocation, point2: destinationLocation)
        )
        mapView.setRegion(region, animated: false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapPreviewView
        
        init(_ parent: MapPreviewView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
    
    // Helper functions for map region calculations
    private func midpointBetween(point1: CLLocationCoordinate2D, point2: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: (point1.latitude + point2.latitude) / 2,
            longitude: (point1.longitude + point2.longitude) / 2
        )
    }
    
    private func spanToShowBoth(point1: CLLocationCoordinate2D, point2: CLLocationCoordinate2D) -> MKCoordinateSpan {
        // Add some padding
        let latDelta = abs(point1.latitude - point2.latitude) * 1.5
        let lonDelta = abs(point1.longitude - point2.longitude) * 1.5
        
        return MKCoordinateSpan(
            latitudeDelta: max(0.005, latDelta),
            longitudeDelta: max(0.005, lonDelta)
        )
    }
}
