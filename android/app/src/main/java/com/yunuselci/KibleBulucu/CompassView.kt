package com.yunuselci.KibleBulucu

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.abs
import kotlin.math.roundToInt

@Composable
fun CompassView(
    currentHeading: Double,
    qiblaDirection: Double,
    modifier: Modifier = Modifier
) {
    // State to track the smooth rotation for animation
    var smoothRotation by remember { mutableDoubleStateOf(0.0) }
    
    val targetRotation = remember(qiblaDirection, currentHeading) {
        val rotation = qiblaDirection - currentHeading
        normalizeAngle(rotation)
    }
    
    // Check if phone direction is aligned with qibla direction
    val isAligned = remember(targetRotation) {
        val angleDifference = abs(normalizeAngle(targetRotation))
        angleDifference <= 3.0 // Allow 3 degree tolerance
    }
    
    // Update smooth rotation to avoid large jumps
    LaunchedEffect(targetRotation) {
        val distance = shortestAngularDistance(smoothRotation, targetRotation)
        smoothRotation += distance
    }
    
    // Initialize smooth rotation on first appearance
    LaunchedEffect(Unit) {
        smoothRotation = targetRotation
    }
    
    // Animated values
    val animatedRotation by animateFloatAsState(
        targetValue = smoothRotation.toFloat(),
        animationSpec = tween(durationMillis = 150),
        label = "rotation"
    )
    
    val arrowColor by animateColorAsState(
        targetValue = if (isAligned) Color(0xFF4CAF50) else Color(0xFFF44336),
        animationSpec = tween(durationMillis = 200),
        label = "color"
    )
    
    val statusColor by animateColorAsState(
        targetValue = if (isAligned) Color(0xFF4CAF50) else Color(0xFFF44336),
        animationSpec = tween(durationMillis = 200),
        label = "statusColor"
    )
    
    // Theme-aware shadow color for better blending in light mode
    val shadowColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)
    
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(30.dp)
    ) {
        // Main rotating arrow with filled circle background (like iOS)
        Box(
            modifier = Modifier
                .size(120.dp)
                .rotate(animatedRotation)
                .shadow(
                    elevation = 1.dp,
                    spotColor = shadowColor,
                    ambientColor = shadowColor,
                    shape = CircleShape
                )
                .clip(CircleShape)
                .background(arrowColor),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Filled.ArrowUpward,
                contentDescription = "Qibla Direction Arrow",
                modifier = Modifier.size(60.dp),
                tint = Color.White
            )
        }
        
        // Direction info
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "KIBLE",
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                letterSpacing = 2.sp
            )
            
            Text(
                text = "${qiblaDirection.roundToInt()}°",
                fontSize = 20.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            // Alignment status
            Text(
                text = if (isAligned) "HİZALANDI" else "HİZALA",
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                color = statusColor,
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
}

// Normalize angle to be between -180 and 180
private fun normalizeAngle(angle: Double): Double {
    var normalizedAngle = angle % 360
    if (normalizedAngle > 180) {
        normalizedAngle -= 360
    } else if (normalizedAngle < -180) {
        normalizedAngle += 360
    }
    return normalizedAngle
}

// Calculate the shortest angular distance between two angles
private fun shortestAngularDistance(from: Double, to: Double): Double {
    val difference = to - from
    return normalizeAngle(difference)
} 