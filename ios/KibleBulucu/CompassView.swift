//
//  CompassView.swift
//  KibleBulucu
//
//  Created by Yunus Elçi on 27.05.2025.
//

import SwiftUI

struct CompassView: View {
    let currentHeading: Double
    let qiblaDirection: Double
    
    // State to track the smooth rotation for animation
    @State private var smoothRotation: Double = 0
    
    private var targetRotation: Double {
        let rotation = qiblaDirection - currentHeading
        return normalizeAngle(rotation)
    }
    
    // Check if phone direction is aligned with qibla direction
    private var isAligned: Bool {
        let angleDifference = abs(normalizeAngle(targetRotation))
        return angleDifference <= 3 // Allow 3 degree tolerance
    }
    
    // Normalize angle to be between -180 and 180
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
        if normalizedAngle > 180 {
            normalizedAngle -= 360
        } else if normalizedAngle < -180 {
            normalizedAngle += 360
        }
        return normalizedAngle
    }
    
    // Calculate the shortest angular distance between two angles
    private func shortestAngularDistance(from: Double, to: Double) -> Double {
        let difference = to - from
        let normalizedDifference = normalizeAngle(difference)
        return normalizedDifference
    }
    
    // Update smooth rotation to avoid large jumps
    private func updateSmoothRotation() {
        let distance = shortestAngularDistance(from: smoothRotation, to: targetRotation)
        smoothRotation += distance
    }

    var body: some View {
        VStack(spacing: 30) {
            // Main rotating arrow
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 120))
                .foregroundColor(isAligned ? .green : .red)
                .rotationEffect(.degrees(smoothRotation))
                .animation(.easeInOut(duration: 0.3), value: smoothRotation)
                .animation(.easeInOut(duration: 0.3), value: isAligned)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .onChange(of: targetRotation) { _ in
                    updateSmoothRotation()
                }
                .onAppear {
                    // Initialize smooth rotation on first appearance
                    smoothRotation = targetRotation
                }
            
            // Direction info
            VStack(spacing: 8) {
                Text("KIBLE")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .tracking(2)
                
                Text("\(Int(qiblaDirection.rounded()))°")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Alignment status
                Text(isAligned ? "HİZALANDI" : "HİZALA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isAligned ? .green : .red)
                    .animation(.easeInOut(duration: 0.3), value: isAligned)
            }
        }
    }
}

#Preview {
    CompassView(currentHeading: 45, qiblaDirection: 136)
        .padding()
} 
