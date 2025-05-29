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
    
    private var arrowRotation: Double {
        let rotation = qiblaDirection - currentHeading
        return rotation
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Main rotating arrow
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 120))
                .foregroundColor(.green)
                .rotationEffect(.degrees(arrowRotation))
                .animation(.easeInOut(duration: 0.3), value: arrowRotation)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
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
            }
        }
    }
}

#Preview {
    CompassView(currentHeading: 45, qiblaDirection: 136)
        .padding()
} 