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
        ZStack(alignment: .top) {
            // MapView
            MapView(region: $locationManager.region, userLocation: locationManager.lastLocation)
                .edgesIgnoringSafeArea(.all)
            
            // İzin yoksa uyarı paneli göster
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
            
            // Konum bilgileri paneli
            if let location = locationManager.lastLocation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Location")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Latitude: \(String(format: "%.6f", location.coordinate.latitude))")
                            Text("Longitude: \(String(format: "%.6f", location.coordinate.longitude))")
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Haritayı kullanıcı konumuna merkezle
                            locationManager.region = MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        }) {
                            Image(systemName: "location.fill")
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding()
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            locationManager.checkPermission()
        }
    }
}

#Preview {
    ContentView()
}
