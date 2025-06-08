//
//  MapView.swift
//  CloseBy
//
//  Created by Omer Oguz Celikel on 4.06.2025.
//

import SwiftUI
import MapKit

// Update your MapView to include the route line

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var userLocation: CLLocation?
    var selectedLocation: CLLocationCoordinate2D? // Selected location to show annotation
    var routeLine: MKPolyline? // Add this property
    var onLongPress: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true // This shows the blue circle for user's location
        
        // Add long press gesture recognizer
        let longPressGesture = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        mapView.addGestureRecognizer(longPressGesture)
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.setRegion(region, animated: true)
        
        // Clear existing overlays
        view.removeOverlays(view.overlays)
        
        // Clear all custom annotations
        let annotations = view.annotations.filter { !($0 is MKUserLocation) }
        view.removeAnnotations(annotations)
        
        // Add annotation only for selected location
        if let selectedLocation = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedLocation
            annotation.title = "Selected Location"
            view.addAnnotation(annotation)
        }
        
        // Add route line if tracking is active
        if let routeLine = routeLine {
            view.addOverlay(routeLine)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                let mapView = gesture.view as! MKMapView
                let touchPoint = gesture.location(in: mapView)
                let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                
                // Call the closure with the coordinate
                parent.onLongPress(coordinate)
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Use default blue dot for user location
            if annotation is MKUserLocation {
                return nil
            }
            
            // Custom pin for selected location
            let identifier = "SelectedLocationPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.markerTintColor = .red // Make the pin red
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        // Add this method to render the route line
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
}
