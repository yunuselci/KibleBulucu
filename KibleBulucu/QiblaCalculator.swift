//
//  QiblaCalculator.swift
//  KibleBulucu
//
//  Created by Yunus Elçi on 27.05.2025.
//

import Foundation
import CoreLocation

struct QiblaCalculator {
    // Kaaba coordinates in Mecca, Saudi Arabia
    static let kaabaLatitude: Double = 21.4225
    static let kaabaLongitude: Double = 39.8262
    
    /// Calculates the Qibla direction from the user's location to the Kaaba
    /// - Parameter userLocation: The user's current location
    /// - Returns: The Qibla direction in degrees (0° = North, 90° = East, etc.)
    static func calculateQiblaDirection(from userLocation: CLLocation) -> Double {
        let userLat = userLocation.coordinate.latitude
        let userLon = userLocation.coordinate.longitude
        
        let deltaLon = kaabaLongitude - userLon
        
        let y = sin(deltaLon * .pi / 180)
        let x = cos(userLat * .pi / 180) * tan(kaabaLatitude * .pi / 180) - sin(userLat * .pi / 180) * cos(deltaLon * .pi / 180)
        
        let qiblaDirection = atan2(y, x) * 180 / .pi
        let normalizedDirection = (qiblaDirection + 360).truncatingRemainder(dividingBy: 360)
        
        return normalizedDirection
    }
    
    /// Calculates the difference between current heading and Qibla direction
    /// - Parameters:
    ///   - currentHeading: Current compass heading in degrees
    ///   - qiblaDirection: Qibla direction in degrees
    /// - Returns: The angle difference (-180 to 180 degrees)
    static func calculateHeadingDifference(currentHeading: Double, qiblaDirection: Double) -> Double {
        var difference = qiblaDirection - currentHeading
        
        // Normalize to -180 to 180 range
        if difference > 180 {
            difference -= 360
        } else if difference < -180 {
            difference += 360
        }
        
        return difference
    }
    
    /// Formats direction as cardinal direction string
    /// - Parameter degrees: Direction in degrees
    /// - Returns: Formatted string like "136° NE"
    static func formatDirection(_ degrees: Double) -> String {
        let cardinalDirections = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((degrees + 22.5) / 45) % 8
        let cardinal = cardinalDirections[index]
        
        return "\(Int(degrees.rounded()))° \(cardinal)"
    }
} 