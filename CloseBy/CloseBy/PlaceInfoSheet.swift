//
//  PlaceInfoSheet.swift
//  CloseBy
//
//  Created by Omer Oguz Celikel on 5.06.2025.
//

import SwiftUI
import MapKit

struct PlaceInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    let placeInfo: PlaceInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(placeInfo.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text(placeInfo.address)
                    .font(.subheadline)
            }
            
            Divider()
            
            HStack {
                Text("Coordinates:")
                    .fontWeight(.medium)
                Spacer()
                Text("\(String(format: "%.6f", placeInfo.coordinate.latitude)), \(String(format: "%.6f", placeInfo.coordinate.longitude))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Navigation button
                Button(action: {
                    startNavigation()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Navigate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Track Distance button
                Button(action: {
                    startDistanceTracking()
                }) {
                    HStack {
                        Image(systemName: "location.north.line.fill")
                        Text("Track Distance")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func startNavigation() {
        // Handle "Start Navigation" button tap
        print("Starting navigation to: \(placeInfo.name)")
        
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: placeInfo.coordinate))
        mapItem.name = placeInfo.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func startDistanceTracking() {
        // Start tracking distance to selected location
        locationManager.startDistanceTracking(to: placeInfo)
        dismiss() // Dismiss this sheet to start showing tracking UI
    }
}
