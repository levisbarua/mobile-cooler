package com.cooler.mobile_cooler

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraCharacteristics
import android.media.AudioManager
import android.os.Environment
import android.os.StatFs
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Random

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.cooler/thermal"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryTemperature" -> {
                    result.success(getBatteryTemperature())
                }
                "killBackgroundProcesses" -> {
                    result.success(killBackgroundProcesses())
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            installApk(path)
                            result.success(true)
                        } catch (e: Exception) {
                            android.util.Log.e("ThermalUpdate", "Install failed", e)
                            result.error("INSTALL_FAILED", e.message, e.toString())
                        }
                    } else {
                        result.error("NO_PATH", "APK path not provided", null)
                    }
                }
                "getMemoryUsage" -> {
                    result.success(getMemoryUsage())
                }
                "getStorageUsage" -> {
                    result.success(getStorageUsage())
                }
                "getCpuInfo" -> {
                    result.success(getCpuInfo())
                }
                "getBatteryDetails" -> {
                    result.success(getBatteryDetails())
                }
                "toggleFlashlight" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    val level = call.argument<Double>("level") ?: 1.0
                    try {
                        toggleFlashlight(enable, level)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("FLASHLIGHT_ERROR", e.message, null)
                    }
                }
                "getRingerMode" -> {
                    result.success(getRingerMode())
                }
                "setRingerMode" -> {
                    val mode = call.argument<Int>("mode") ?: AudioManager.RINGER_MODE_NORMAL
                    try {
                        setRingerMode(mode)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("RINGER_ERROR", e.message, null)
                    }
                }
                "openSettings" -> {
                    val type = call.argument<String>("type") ?: ""
                    openSettings(type)
                    result.success(true)
                }
                "getInstalledHeavyApps" -> {
                    result.success(getInstalledHeavyApps())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getBatteryTemperature(): Double {
        val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus: Intent? = registerReceiver(null, intentFilter)
        val temp = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
        return if (temp != -1) temp / 10.0 else -1.0
    }

    private fun killBackgroundProcesses(): Int {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningApps = activityManager.runningAppProcesses ?: return 0
        var killed = 0
        val myPackage = packageName

        for (process in runningApps) {
            if (process.processName != myPackage &&
                process.importance >= ActivityManager.RunningAppProcessInfo.IMPORTANCE_SERVICE
            ) {
                try {
                    activityManager.killBackgroundProcesses(process.processName)
                    killed++
                } catch (e: Exception) {
                    // Skip processes that can't be killed
                }
            }
        }
        return killed
    }

    private fun installApk(apkPath: String) {
        val file = File(apkPath)
        val intent = Intent(Intent.ACTION_VIEW)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val uri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                file
            )
            intent.setDataAndType(uri, "application/vnd.android.package-archive")
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } else {
            intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive")
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun getMemoryUsage(): Map<String, Any> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        val total = memoryInfo.totalMem.toDouble() / (1024.0 * 1024.0) // MB
        val avail = memoryInfo.availMem.toDouble() / (1024.0 * 1024.0) // MB
        val used = total - avail
        val percent = (used / total) * 100.0
        
        return mapOf(
            "total" to total,
            "avail" to avail,
            "used" to used,
            "percent" to percent
        )
    }

    private fun getStorageUsage(): Map<String, Any> {
        val path = Environment.getDataDirectory().path
        val stat = StatFs(path)
        val totalBytes = stat.blockSizeLong * stat.blockCountLong
        val availBytes = stat.blockSizeLong * stat.availableBlocksLong
        val usedBytes = totalBytes - availBytes
        
        val totalGB = totalBytes.toDouble() / (1024.0 * 1024.0 * 1024.0)
        val availGB = availBytes.toDouble() / (1024.0 * 1024.0 * 1024.0)
        val usedGB = usedBytes.toDouble() / (1024.0 * 1024.0 * 1024.0)
        val percent = (usedBytes.toDouble() / totalBytes.toDouble()) * 100.0
        
        return mapOf(
            "total" to totalGB,
            "avail" to availGB,
            "used" to usedGB,
            "percent" to percent
        )
    }

    private fun getCpuInfo(): Map<String, Any> {
        val cores = Runtime.getRuntime().availableProcessors()
        val model = Build.HARDWARE ?: "Unknown"
        val board = Build.BOARD ?: "Unknown"
        val abis = Build.SUPPORTED_ABIS?.firstOrNull() ?: "Unknown"
        
        return mapOf(
            "cores" to cores,
            "model" to model,
            "board" to board,
            "abi" to abis
        )
    }

    private fun getBatteryDetails(): Map<String, Any> {
        val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus: Intent? = registerReceiver(null, intentFilter)
        
        val temp = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
        val voltage = batteryStatus?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
        val technology = batteryStatus?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY) ?: "Unknown"
        
        val healthInt = batteryStatus?.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN) ?: BatteryManager.BATTERY_HEALTH_UNKNOWN
        val health = when (healthInt) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Failure"
            BatteryManager.BATTERY_HEALTH_COLD -> "Cold"
            else -> "Unknown"
        }
        
        val pluggedInt = batteryStatus?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1) ?: -1
        val plugged = when (pluggedInt) {
            BatteryManager.BATTERY_PLUGGED_AC -> "AC"
            BatteryManager.BATTERY_PLUGGED_USB -> "USB"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
            else -> "Battery"
        }
        
        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        val isPowerSave = powerManager?.isPowerSaveMode ?: false
        
        return mapOf(
            "temperature" to (if (temp != -1) temp / 10.0 else -1.0),
            "voltage" to voltage.toDouble(),
            "technology" to technology,
            "health" to health,
            "plugged" to plugged,
            "isPowerSave" to isPowerSave
        )
    }

    private fun toggleFlashlight(enable: Boolean, level: Double) {
        val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraIdList = cameraManager.cameraIdList
        if (cameraIdList.isNotEmpty()) {
            val cameraId = cameraIdList[0]
            if (!enable) {
                cameraManager.setTorchMode(cameraId, false)
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    try {
                        val chars = cameraManager.getCameraCharacteristics(cameraId)
                        val maxLevel = chars.get(CameraCharacteristics.FLASH_INFO_STRENGTH_MAXIMUM_LEVEL) ?: 1
                        if (maxLevel > 1) {
                            val targetStrength = (level * maxLevel).toInt().coerceAtLeast(1).coerceAtMost(maxLevel)
                            cameraManager.turnOnTorchWithStrengthLevel(cameraId, targetStrength)
                        } else {
                            cameraManager.setTorchMode(cameraId, true)
                        }
                    } catch (e: Exception) {
                        cameraManager.setTorchMode(cameraId, true)
                    }
                } else {
                    cameraManager.setTorchMode(cameraId, true)
                }
            }
        }
    }

    private fun getRingerMode(): Int {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return audioManager.ringerMode
    }

    private fun setRingerMode(mode: Int) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.ringerMode = mode
    }

    private fun openSettings(type: String) {
        val intent = when (type) {
            "battery" -> Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)
            "display" -> Intent(Settings.ACTION_DISPLAY_SETTINGS)
            "language" -> Intent(Settings.ACTION_LOCALE_SETTINGS)
            "developer" -> Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
            else -> Intent(Settings.ACTION_SETTINGS)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun getInstalledHeavyApps(): List<Map<String, Any>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any>>()
        
        val heavyAppsList = listOf(
            "com.facebook.katana" to "Facebook",
            "com.instagram.android" to "Instagram",
            "com.zhiliaoapp.musically" to "TikTok",
            "com.google.android.youtube" to "YouTube",
            "com.whatsapp" to "WhatsApp",
            "com.google.android.apps.maps" to "Google Maps",
            "com.snapchat.android" to "Snapchat",
            "com.netflix.mediaclient" to "Netflix",
            "com.spotify.music" to "Spotify",
            "com.tencent.ig" to "PUBG Mobile",
            "com.dts.freefireth" to "Free Fire",
            "com.twitter.android" to "X (Twitter)",
            "com.facebook.orca" to "Messenger"
        )
        
        val random = Random()
        for ((packageName, appName) in heavyAppsList) {
            try {
                pm.getPackageInfo(packageName, 0)
                // App is installed!
                val cpuImpact = 5.0 + random.nextDouble() * 15.0 // 5% to 20%
                val ramImpact = 120.0 + random.nextInt(380) // 120MB to 500MB
                
                apps.add(mapOf(
                    "name" to appName,
                    "package" to packageName,
                    "cpuImpact" to cpuImpact,
                    "ramImpact" to ramImpact
                ))
            } catch (e: Exception) {
                // Not installed, ignore
            }
        }
        return apps
    }
}
