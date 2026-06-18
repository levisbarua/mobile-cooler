package com.cooler.app.data

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import java.io.File

data class TemperatureData(
    val batteryTemp: Float = 0f,
    val cpuTemp: Float = 0f,
    val thermalStatus: Int = PowerManager.THERMAL_STATUS_NONE,
)

enum class TemperatureLevel(val threshold: Float) {
    NORMAL(35f),
    WARM(40f),
    HOT(45f),
    CRITICAL(50f);

    companion object {
        fun fromCelsius(temp: Float): TemperatureLevel {
            return when {
                temp >= CRITICAL.threshold -> CRITICAL
                temp >= HOT.threshold -> HOT
                temp >= WARM.threshold -> WARM
                else -> NORMAL
            }
        }
    }
}

object TemperatureReader {

    private const val THERMAL_BASE_PATH = "/sys/class/thermal"

    fun readBatteryTemperature(context: Context): Float {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        if (intent != null) {
            try {
                val temp = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0)
                if (temp > 0) return temp / 10f
            } catch (_: Exception) {}
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                val bm = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
                val temp = bm?.getIntProperty(8) ?: 0
                if (temp > 0) return temp / 10f
            } catch (_: Exception) {}
        }
        return readThermalZoneBattery()
    }

    fun readCpuTemperature(): Float {
        val thermalZones = File(THERMAL_BASE_PATH)
        if (!thermalZones.exists() || !thermalZones.isDirectory) return 0f

        val zoneFiles = thermalZones.listFiles { f ->
            f.isDirectory && f.name.startsWith("thermal_zone")
        } ?: return 0f

        var cpuTemp = 0f
        for (zone in zoneFiles) {
            val typeFile = File(zone, "type")
            val tempFile = File(zone, "temp")
            if (typeFile.exists() && tempFile.exists()) {
                try {
                    val type = typeFile.readText().trim().lowercase()
                    if (type.contains("cpu") || type.contains("core")) {
                        val raw = tempFile.readText().trim()
                        val temp = raw.toFloat() / 1000f
                        if (temp > cpuTemp) cpuTemp = temp
                    }
                } catch (_: Exception) {}
            }
        }
        return cpuTemp
    }

    fun readThermalStatus(context: Context): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return PowerManager.THERMAL_STATUS_NONE
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return PowerManager.THERMAL_STATUS_NONE
        return try {
            pm.currentThermalStatus
        } catch (_: Exception) {
            PowerManager.THERMAL_STATUS_NONE
        }
    }

    fun read(context: Context): TemperatureData {
        return TemperatureData(
            batteryTemp = readBatteryTemperature(context),
            cpuTemp = readCpuTemperature(),
            thermalStatus = readThermalStatus(context),
        )
    }

    private fun readThermalZoneBattery(): Float {
        val thermalZones = File(THERMAL_BASE_PATH)
        if (!thermalZones.exists() || !thermalZones.isDirectory) return 0f
        val zoneFiles = thermalZones.listFiles { f ->
            f.isDirectory && f.name.startsWith("thermal_zone")
        } ?: return 0f
        for (zone in zoneFiles) {
            val typeFile = File(zone, "type")
            val tempFile = File(zone, "temp")
            if (typeFile.exists() && tempFile.exists()) {
                try {
                    val type = typeFile.readText().trim().lowercase()
                    if (type.contains("battery") || type.contains("bat")) {
                        val raw = tempFile.readText().trim()
                        return raw.toFloat() / 1000f
                    }
                } catch (_: Exception) {}
            }
        }
        return 0f
    }
}
