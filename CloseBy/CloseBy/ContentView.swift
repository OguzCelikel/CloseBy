//
//  ContentView.swift
//  CloseBy
//
//  Created by Omer Oguz Celikel on 4.06.2025.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject var locationManager = LocationManager()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // MapView with long press handler and selected location annotation
            MapView(
                region: $locationManager.region,
                userLocation: locationManager.lastLocation,
                selectedLocation: locationManager.selectedLocationCoordinate,
                onLongPress: { coordinate in
                    locationManager.handleMapLongPress(at: coordinate)
                }
            )
            .edgesIgnoringSafeArea(.all)
            
            // Floating location button (Apple Maps style)
            Button(action: {
                if let location = locationManager.lastLocation {
                    locationManager.centerOnUserLocation()
                }
            }) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.trailing, 16)
            .padding(.top, 60) // Positioned below status bar
            .opacity(locationManager.lastLocation != nil ? 1.0 : 0.0) // Only show when location is available
            
            // Permission denied warning panel
            if locationManager.locationStatus == .denied || locationManager.locationStatus == .restricted {
                VStack {
                    Text("Location Permission Denied")
                        .font(.headline)
                    Text("To view your location on the map, you need to enable location permissions in settings.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                    Button("Go to Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top, 10)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding()
            }
        }
        .onAppear {
            locationManager.checkPermission()
        }
        .sheet(
            isPresented: $locationManager.isShowingPlaceSheet,
            onDismiss: {
                // Reset after sheet is dismissed
                locationManager.resetAfterSheetDismissal()
            },
            content: {
                if let selectedPlace = locationManager.selectedPlace {
                    PlaceInfoSheet(placeInfo: selectedPlace) {
                        // Handle "Start Navigation" button tap
                        print("Starting navigation to: \(selectedPlace.name)")
                        
                        // Use Apple Maps to navigate to the location
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: selectedPlace.coordinate))
                        mapItem.name = selectedPlace.name
                        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    }
                    .presentationDetents([.height(250), .medium])
                }
            }
        )
    }
}

#Preview {
    ContentView()
}
