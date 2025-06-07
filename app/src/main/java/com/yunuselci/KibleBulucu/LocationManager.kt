package com.yunuselci.KibleBulucu

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.os.Looper
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.location.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class LocationManager(private val context: Context) : ViewModel(), SensorEventListener {
    
    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)
    
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val magnetometer = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
    private val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    
    private val _location = MutableStateFlow<Location?>(null)
    val location: StateFlow<Location?> = _location.asStateFlow()
    
    private val _heading = MutableStateFlow<Double?>(null)
    val heading: StateFlow<Double?> = _heading.asStateFlow()
    
    private val _hasLocationPermission = MutableStateFlow(false)
    val hasLocationPermission: StateFlow<Boolean> = _hasLocationPermission.asStateFlow()
    
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()
    
    private val _hasCompassSensor = MutableStateFlow(true)
    val hasCompassSensor: StateFlow<Boolean> = _hasCompassSensor.asStateFlow()
    
    // Sensor data
    private var magneticField = FloatArray(3)
    private var gravity = FloatArray(3)
    private var lastAccelerometerUpdate = 0L
    private var lastMagnetometerUpdate = 0L
    
    // For compass smoothing
    private var previousHeading: Double? = null
    private val smoothingFactor = 0.1
    
    private val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000)
        .setWaitForAccurateLocation(false)
        .setMinUpdateIntervalMillis(500)
        .setMaxUpdateDelayMillis(2000)
        .build()
    
    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            locationResult.lastLocation?.let { location ->
                _location.value = location
                _errorMessage.value = null
            }
        }
        
        override fun onLocationAvailability(locationAvailability: LocationAvailability) {
            // Removed the error message for location services unavailable
            // Do not show "Konum servisleri kullanılamıyor" to the user
        }
    }
    
    init {
        checkLocationPermission()
        checkCompassSensorAvailability()
    }
    
    fun checkLocationPermission() {
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        
        _hasLocationPermission.value = hasPermission
        
        if (hasPermission) {
            startLocationUpdates()
        }
    }
    
    fun onPermissionGranted() {
        _hasLocationPermission.value = true
        _errorMessage.value = null
        startLocationUpdates()
    }
    
    fun onPermissionDenied() {
        _hasLocationPermission.value = false
        _errorMessage.value = "Konum erişimi reddedildi. Lütfen Ayarlar'dan konum servislerini etkinleştirin."
    }
    
    @Suppress("MissingPermission")
    private fun startLocationUpdates() {
        viewModelScope.launch {
            try {
                fusedLocationClient.requestLocationUpdates(
                    locationRequest,
                    locationCallback,
                    Looper.getMainLooper()
                )
                startCompassUpdates()
            } catch (e: Exception) {
                _errorMessage.value = "Konum hatası: ${e.localizedMessage}"
            }
        }
    }
    
    private fun startCompassUpdates() {
        magnetometer?.let { mag ->
            sensorManager.registerListener(this, mag, SensorManager.SENSOR_DELAY_GAME)
        }
        accelerometer?.let { acc ->
            sensorManager.registerListener(this, acc, SensorManager.SENSOR_DELAY_GAME)
        }
    }
    
    private fun stopLocationUpdates() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
        sensorManager.unregisterListener(this)
    }
    
    override fun onSensorChanged(event: SensorEvent?) {
        event?.let { sensorEvent ->
            when (sensorEvent.sensor.type) {
                Sensor.TYPE_MAGNETIC_FIELD -> {
                    magneticField = sensorEvent.values.clone()
                    lastMagnetometerUpdate = System.currentTimeMillis()
                }
                Sensor.TYPE_ACCELEROMETER -> {
                    gravity = sensorEvent.values.clone()
                    lastAccelerometerUpdate = System.currentTimeMillis()
                }
            }
            
            // Calculate heading if we have recent data from both sensors
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastAccelerometerUpdate < 1000 && 
                currentTime - lastMagnetometerUpdate < 1000) {
                calculateHeading()
            }
        }
    }
    
    private fun calculateHeading() {
        val rotationMatrix = FloatArray(9)
        val orientationAngles = FloatArray(3)
        
        if (SensorManager.getRotationMatrix(rotationMatrix, null, gravity, magneticField)) {
            SensorManager.getOrientation(rotationMatrix, orientationAngles)
            
            // Convert from radians to degrees and normalize to 0-360
            val azimuthInRadians = orientationAngles[0]
            var azimuthInDegrees = Math.toDegrees(azimuthInRadians.toDouble())
            azimuthInDegrees = (azimuthInDegrees + 360) % 360
            
            // Apply smoothing to reduce jitter
            val smoothedHeading = previousHeading?.let { prev ->
                // Handle circular nature of angles (e.g., 359° to 1°)
                val diff = azimuthInDegrees - prev
                val adjustedDiff = when {
                    diff > 180 -> diff - 360
                    diff < -180 -> diff + 360
                    else -> diff
                }
                
                val smoothed = prev + (adjustedDiff * smoothingFactor)
                (smoothed + 360) % 360
            } ?: azimuthInDegrees
            
            previousHeading = smoothedHeading
            _heading.value = smoothedHeading
        }
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Handle accuracy changes if needed
    }
    
    override fun onCleared() {
        super.onCleared()
        stopLocationUpdates()
    }
    
    private fun checkCompassSensorAvailability() {
        val hasCompass = magnetometer != null && accelerometer != null
        _hasCompassSensor.value = hasCompass
    }
} 