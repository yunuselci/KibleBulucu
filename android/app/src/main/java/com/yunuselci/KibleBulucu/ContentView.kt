package com.yunuselci.KibleBulucu

import android.Manifest
import android.content.Context
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.google.accompanist.permissions.shouldShowRationale
import kotlin.math.abs
import kotlin.math.roundToInt

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun ContentView(
    modifier: Modifier = Modifier,
    locationManager: LocationManager? = null
) {
    val context = LocalContext.current
    val actualLocationManager = locationManager ?: viewModel { LocationManager(context) }
    
    // Permission handling
    val locationPermissionState = rememberPermissionState(
        Manifest.permission.ACCESS_FINE_LOCATION
    ) { isGranted ->
        if (isGranted) {
            actualLocationManager.onPermissionGranted()
        } else {
            actualLocationManager.onPermissionDenied()
        }
    }
    
    // Collect state from LocationManager
    val location by actualLocationManager.location.collectAsStateWithLifecycle()
    val heading by actualLocationManager.heading.collectAsStateWithLifecycle()
    val hasLocationPermission by actualLocationManager.hasLocationPermission.collectAsStateWithLifecycle()
    val errorMessage by actualLocationManager.errorMessage.collectAsStateWithLifecycle()
    
    // Calculate Qibla direction
    val qiblaDirection = remember(location) {
        location?.let { QiblaCalculator.calculateQiblaDirection(it) } ?: 0.0
    }
    
    val currentHeading = heading ?: 0.0
    
    // Check if phone direction is aligned with qibla direction
    val isAligned = remember(qiblaDirection, currentHeading) {
        val rotation = qiblaDirection - currentHeading
        val normalizedRotation = ((rotation % 360) + 360) % 360
        val angleDifference = if (normalizedRotation > 180) {
            360 - normalizedRotation
        } else {
            normalizedRotation
        }
        angleDifference <= 3.0 // Allow 3 degree tolerance
    }
    
    // Track alignment changes for haptic feedback
    var wasAligned by remember { mutableStateOf(false) }
    
    // Haptic feedback when alignment changes
    LaunchedEffect(isAligned) {
        if (isAligned != wasAligned && location != null && heading != null) {
            val vibrator = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            
            if (isAligned) {
                // Success haptic when aligned
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(200)
                }
            } else {
                // Light haptic when losing alignment
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(50)
                }
            }
            wasAligned = isAligned
        }
    }
    
    // Request permission on first composition
    LaunchedEffect(Unit) {
        if (!locationPermissionState.status.isGranted) {
            locationPermissionState.launchPermissionRequest()
        }
    }
    
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(40.dp))
        
        // Header
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Kıble Bulucu",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Text(
                text = "Kıble Yön Bulucu",
                fontSize = 16.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Main content
        Box(
            modifier = Modifier.fillMaxWidth(),
            contentAlignment = Alignment.Center
        ) {
            when {
                !hasLocationPermission -> {
                    // Permission denied message
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            text = "Konum İzni Gerekli",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        
                        Text(
                            text = "Kıble yönünü bulabilmek için konum erişimine ihtiyacımız var.",
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                        
                        Button(
                            onClick = { locationPermissionState.launchPermissionRequest() }
                        ) {
                            Text("İzin Ver")
                        }
                    }
                }
                
                location != null && heading != null -> {
                    // Show compass when we have location and heading
                    CompassView(
                        currentHeading = currentHeading,
                        qiblaDirection = qiblaDirection
                    )
                }
                
                else -> {
                    // Loading state
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(20.dp)
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(48.dp)
                        )
                        
                        Text(
                            text = "Konumunuz bulunuyor...",
                            fontSize = 18.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Location information
        location?.let { loc ->
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.padding(bottom = 40.dp)
            ) {
                Text(
                    text = "Konumunuz",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    letterSpacing = 1.sp
                )
                
                Text(
                    text = String.format("%.4f°, %.4f°", loc.latitude, loc.longitude),
                    fontSize = 16.sp,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontFamily = FontFamily.Monospace
                )
                
                Text(
                    text = "Kıble kuzeyden ${qiblaDirection.roundToInt()}° açıda",
                    fontSize = 16.sp,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }
        }
        
        // Error message
        errorMessage?.let { error ->
            Text(
                text = error,
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.error,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .padding(horizontal = 30.dp)
                    .padding(bottom = 40.dp)
            )
        }
    }
} 