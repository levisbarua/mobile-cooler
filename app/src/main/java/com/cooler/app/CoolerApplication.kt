package com.cooler.app

import android.app.Application
import com.cooler.app.service.TemperatureService

class CoolerApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        TemperatureService.start(this)
    }
}
