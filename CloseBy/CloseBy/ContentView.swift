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
        ZStack(alignment: .bottom) {
            // MapView with long press handler and selected location annotation
            MapView(
                region: $locationManager.region,
                userLocation: locationManager.lastLocation,
                selectedLocation: locationManager.selectedLocationCoordinate,
                routeLine: locationManager.routeLine,
                onLongPress: { coordinate in
                    locationManager.handleMapLongPress(at: coordinate)
                }
            )
            .edgesIgnoringSafeArea(.all)
            
            // Search button (Apple Maps style)
            Button(action: {
                locationManager.isShowingSearchSheet = true
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.gray)
                    Text("Search in map")
                        .fontWeight(.medium)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.primary)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            
            // Floating location button (top right)
            VStack {
                HStack {
                    Spacer()
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
                    .opacity(locationManager.lastLocation != nil ? 1.0 : 0.0)
                }
                .padding(.top, 60) // Position below status bar
                
                Spacer()
            }
            
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
                .zIndex(1) // Make sure this appears above other elements
            }
        }
        .onAppear {
            locationManager.checkPermission()
        }
        .sheet(
            isPresented: $locationManager.isShowingPlaceSheet,
            onDismiss: {
                locationManager.resetAfterSheetDismissal()
            },
            content: {
                if let selectedPlace = locationManager.selectedPlace {
                    PlaceInfoSheet(locationManager: locationManager, placeInfo: selectedPlace)
                        .presentationDetents([.height(250), .medium])
                }
            }
        )
        .sheet(
            isPresented: $locationManager.isShowingSearchSheet,
            content: {
                SearchBottomSheetView(locationManager: locationManager)
                    .presentationDetents([.height(300), .medium, .large])
                    .presentationDragIndicator(.visible)
            }
        )
        .sheet(
            isPresented: $locationManager.isShowingDistanceSheet,
            onDismiss: {
                locationManager.stopDistanceTracking()
            },
            content: {
                DistanceTrackerSheet(locationManager: locationManager)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        )
    }
}

#Preview {
    ContentView()
}
