//
//  ContentView.swift
//  CloseBy
//
//  Created by Omer Oguz Celikel on 4.06.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var locationManager = LocationManager()
    @State private var showLocationInfo = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button(action: {
                locationManager.requestPermission()
            }) {
                Text("Konum İzni İste")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if locationManager.locationStatus == .authorizedWhenInUse ||
               locationManager.locationStatus == .authorizedAlways {
                
                Button(action: {
                    locationManager.startUpdatingLocation()
                    showLocationInfo = true
                }) {
                    Text("Konumu Göster")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            if showLocationInfo, let location = locationManager.lastLocation {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Konumunuz:")
                        .font(.headline)
                    Text("Enlem: \(location.coordinate.latitude)")
                    Text("Boylam: \(location.coordinate.longitude)")
                    if let altitude = locationManager.lastLocation?.altitude {
                        Text("Yükseklik: \(altitude) metre")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .padding()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
