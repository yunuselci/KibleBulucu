//
//  ContentView.swift
//  KibleBulucu
//
//  Created by Yunus Elçi on 27.05.2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    private var qiblaDirection: Double {
        guard let location = locationManager.location else { return 0 }
        return QiblaCalculator.calculateQiblaDirection(from: location)
    }
    
    private var currentHeading: Double {
        locationManager.heading?.magneticHeading ?? 0
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            // Header
            VStack(spacing: 8) {
                Text("Kıble Bulucu")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Kıble Yön Bulucu")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Main arrow view
            if locationManager.location != nil && locationManager.heading != nil {
                CompassView(
                    currentHeading: currentHeading,
                    qiblaDirection: qiblaDirection
                )
            } else {
                // Loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Konumunuz bulunuyor...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Location information
            if let location = locationManager.location {
                VStack(spacing: 12) {
                    Text("Konumunuz")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .tracking(1)
                    
                    Text(String(format: "%.4f°, %.4f°", 
                              location.coordinate.latitude,
                              location.coordinate.longitude))
                        .font(.body)
                        .foregroundColor(.primary)
                        .monospaced()
                    
                    Text("Kıble kuzeyden \(Int(qiblaDirection.rounded()))° açıda")
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            
            // Error message
            if let errorMessage = locationManager.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
}

#Preview {
    ContentView()
}
