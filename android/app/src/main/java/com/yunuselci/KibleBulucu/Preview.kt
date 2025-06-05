package com.yunuselci.KibleBulucu

import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import com.yunuselci.KibleBulucu.ui.theme.KibleBulucuTheme

@Preview(showBackground = true, showSystemUi = true)
@Composable
fun ContentViewPreview() {
    KibleBulucuTheme {
        // Note: This preview won't show the actual compass functionality
        // since it requires runtime permissions and real location/sensor data
        ContentView(locationManager = null)
    }
}

@Preview(showBackground = true)
@Composable
fun CompassViewPreview() {
    KibleBulucuTheme {
        CompassView(
            currentHeading = 45.0,
            qiblaDirection = 136.0
        )
    }
}

@Preview(showBackground = true)
@Composable
fun CompassViewAlignedPreview() {
    KibleBulucuTheme {
        CompassView(
            currentHeading = 136.0,
            qiblaDirection = 136.0
        )
    }
} 