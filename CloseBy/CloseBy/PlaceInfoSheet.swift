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
    let placeInfo: PlaceInfo
    var onStartNavigation: () -> Void
    
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
            
            Button(action: onStartNavigation) {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    Text("Start Navigation")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
