package com.cooler.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.cooler.app.ui.screens.HomeScreen
import com.cooler.app.ui.theme.CoolerTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            CoolerTheme {
                HomeScreen()
            }
        }
    }
}
