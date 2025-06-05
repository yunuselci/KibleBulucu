package com.yunuselci.KibleBulucu

import android.location.Location
import kotlin.math.*

object QiblaCalculator {
    // Kaaba coordinates in Mecca, Saudi Arabia
    const val KAABA_LATITUDE: Double = 21.4225
    const val KAABA_LONGITUDE: Double = 39.8262
    
    /**
     * Calculates the Qibla direction from the user's location to the Kaaba
     * @param userLocation The user's current location
     * @return The Qibla direction in degrees (0° = North, 90° = East, etc.)
     */
    fun calculateQiblaDirection(userLocation: Location): Double {
        val userLat = userLocation.latitude
        val userLon = userLocation.longitude
        
        val deltaLon = KAABA_LONGITUDE - userLon
        
        val y = sin(deltaLon * PI / 180)
        val x = cos(userLat * PI / 180) * tan(KAABA_LATITUDE * PI / 180) - 
                sin(userLat * PI / 180) * cos(deltaLon * PI / 180)
        
        val qiblaDirection = atan2(y, x) * 180 / PI
        val normalizedDirection = (qiblaDirection + 360) % 360
        
        return normalizedDirection
    }
    
    /**
     * Calculates the difference between current heading and Qibla direction
     * @param currentHeading Current compass heading in degrees
     * @param qiblaDirection Qibla direction in degrees
     * @return The angle difference (-180 to 180 degrees)
     */
    fun calculateHeadingDifference(currentHeading: Double, qiblaDirection: Double): Double {
        var difference = qiblaDirection - currentHeading
        
        // Normalize to -180 to 180 range
        if (difference > 180) {
            difference -= 360
        } else if (difference < -180) {
            difference += 360
        }
        
        return difference
    }
    
    /**
     * Formats direction as cardinal direction string
     * @param degrees Direction in degrees
     * @return Formatted string like "136° NE"
     */
    fun formatDirection(degrees: Double): String {
        val cardinalDirections = arrayOf("N", "NE", "E", "SE", "S", "SW", "W", "NW")
        val index = ((degrees + 22.5) / 45).toInt() % 8
        val cardinal = cardinalDirections[index]
        
        return "${degrees.roundToInt()}° $cardinal"
    }
} 