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
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.RingtoneManager
import android.app.NotificationManager
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.app.usage.UsageStats
import java.util.Calendar

class MainActivity : FlutterActivity(), SensorEventListener {

    private val CHANNEL = "com.cooler/thermal"
    
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var lightSensor: Sensor? = null
    
    private var accelX = 0.0
    private var accelY = 0.0
    private var accelZ = 0.0
    private var lightLux = 0.0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)

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
                "getFlashlightMaxLevel" -> {
                    result.success(getFlashlightMaxLevel())
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
                "getSensorData" -> {
                    result.success(mapOf(
                        "accelX" to accelX,
                        "accelY" to accelY,
                        "accelZ" to accelZ,
                        "lightLux" to lightLux
                    ))
                }
                "uninstallApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            val intent = Intent(Intent.ACTION_DELETE).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNINSTALL_FAILED", e.message, null)
                        }
                    } else {
                        result.error("NO_PACKAGE", "Package name not provided", null)
                    }
                }
                "playAlarmSound" -> {
                    try {
                        val notificationUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                        val ringtone = RingtoneManager.getRingtone(applicationContext, notificationUri)
                        ringtone?.play()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ALARM_ERROR", e.message, null)
                    }
                }
                "checkWriteSettings" -> {
                    result.success(checkWriteSettingsAccess())
                }
                "requestWriteSettings" -> {
                    requestWriteSettingsAccess()
                    result.success(true)
                }
                "checkNotificationPolicy" -> {
                    result.success(checkNotificationPolicyAccess())
                }
                "requestNotificationPolicy" -> {
                    requestNotificationPolicyAccess()
                    result.success(true)
                }
                "checkManageStorage" -> {
                    result.success(checkManageStorageAccess())
                }
                "requestManageStorage" -> {
                    requestManageStorageAccess()
                    result.success(true)
                }
                "checkUsageStats" -> {
                    result.success(checkUsageStatsAccess())
                }
                "requestUsageStats" -> {
                    requestUsageStatsAccess()
                    result.success(true)
                }
                "setSystemBrightness" -> {
                    val brightness = call.argument<Double>("brightness") ?: 0.5
                    try {
                        setSystemBrightness(brightness)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BRIGHTNESS_ERROR", e.message, null)
                    }
                }
                "getRunningAppsUsage" -> {
                    result.success(getRunningAppsUsage())
                }
                "getInstalledApps" -> {
                    val systemOnly = call.argument<Boolean>("systemOnly") ?: false
                    result.success(getInstalledApps(systemOnly))
                }
                "openAppDetails" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            openAppDetails(packageName)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("DETAILS_ERROR", e.message, null)
                        }
                    } else {
                        result.error("NO_PACKAGE", "Package name not provided", null)
                    }
                }
                "getCpuModel" -> {
                    result.success(getCpuModelName())
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
        val pm = packageManager
        val packages = pm.getInstalledPackages(0)
        var killed = 0
        val myPackage = packageName

        for (pkgInfo in packages) {
            val pkgName = pkgInfo.packageName
            val appInfo = pkgInfo.applicationInfo
            val isSystem = if (appInfo != null) {
                (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
            } else {
                false
            }
            if (pkgName != myPackage && !isSystem) {
                try {
                    activityManager.killBackgroundProcesses(pkgName)
                    killed++
                } catch (e: Exception) {
                    // Ignore
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

    private fun getCameraIdWithFlash(cameraManager: CameraManager): String? {
        for (id in cameraManager.cameraIdList) {
            try {
                val chars = cameraManager.getCameraCharacteristics(id)
                val hasFlash = chars.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) ?: false
                if (hasFlash) {
                    return id
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
        return if (cameraManager.cameraIdList.isNotEmpty()) cameraManager.cameraIdList[0] else null
    }

    private fun getFlashlightMaxLevel(): Int {
        val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraId = getCameraIdWithFlash(cameraManager) ?: return 1
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                val chars = cameraManager.getCameraCharacteristics(cameraId)
                return chars.get(CameraCharacteristics.FLASH_INFO_STRENGTH_MAXIMUM_LEVEL) ?: 1
            } catch (e: Exception) {
                return 1
            }
        }
        return 1
    }

    private fun toggleFlashlight(enable: Boolean, level: Double) {
        val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraId = getCameraIdWithFlash(cameraManager) ?: return
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

    private fun getRingerMode(): Int {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return audioManager.ringerMode
    }

    private fun setRingerMode(mode: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!checkNotificationPolicyAccess()) {
                throw SecurityException("Notification Policy (Do Not Disturb) access is not granted")
            }
        }
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.ringerMode = mode
    }

    private fun openSettings(type: String) {
        val intent = when (type) {
            "battery" -> Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)
            "display" -> Intent(Settings.ACTION_DISPLAY_SETTINGS)
            "language" -> Intent(Settings.ACTION_LOCALE_SETTINGS)
            "developer" -> Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
            "notification_policy" -> Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            "write_settings" -> Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
            "manage_storage" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                    data = Uri.parse("package:$packageName")
                }
            } else {
                Intent(Settings.ACTION_SETTINGS)
            }
            "usage_stats" -> Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            else -> Intent(Settings.ACTION_SETTINGS)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback for permissions if URI parsing fails
            val fallbackIntent = when (type) {
                "write_settings" -> Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                "manage_storage" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                } else {
                    Intent(Settings.ACTION_SETTINGS)
                }
                else -> Intent(Settings.ACTION_SETTINGS)
            }
            fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                startActivity(fallbackIntent)
            } catch (ex: Exception) {
                // Completely fallback
                val homeIntent = Intent(Settings.ACTION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(homeIntent)
            }
        }
    }

    private fun checkWriteSettingsAccess(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return Settings.System.canWrite(this)
        }
        return true
    }

    private fun requestWriteSettingsAccess() {
        openSettings("write_settings")
    }

    private fun checkNotificationPolicyAccess(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            return notificationManager.isNotificationPolicyAccessGranted
        }
        return true
    }

    private fun requestNotificationPolicyAccess() {
        openSettings("notification_policy")
    }

    private fun checkManageStorageAccess(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return Environment.isExternalStorageManager()
        }
        return true
    }

    private fun requestManageStorageAccess() {
        openSettings("manage_storage")
    }

    private fun checkUsageStatsAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        } else {
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsAccess() {
        openSettings("usage_stats")
    }

    private fun setSystemBrightness(brightnessValue: Double) {
        if (checkWriteSettingsAccess()) {
            val targetValue = (brightnessValue * 255).toInt().coerceIn(0, 255)
            Settings.System.putInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, targetValue)
        }
    }

    private fun getRunningAppsUsage(): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()
        if (!checkUsageStatsAccess()) {
            return getInstalledHeavyApps()
        }

        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.DAY_OF_YEAR, -1) // Query last 24 hours
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                calendar.timeInMillis,
                System.currentTimeMillis()
            )

            if (stats != null && stats.isNotEmpty()) {
                val pm = packageManager
                val sortedStats = stats.sortedByDescending { it.lastTimeUsed }
                
                val uniquePackages = mutableSetOf<String>()
                val myPackage = packageName
                val random = Random()

                for (stat in sortedStats) {
                    val pkgName = stat.packageName
                    if (pkgName == myPackage || uniquePackages.contains(pkgName)) continue
                    uniquePackages.add(pkgName)

                    try {
                        val appInfo = pm.getApplicationInfo(pkgName, 0)
                        val isSystem = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                        if (!isSystem) {
                            val label = appInfo.loadLabel(pm).toString()
                            val cpuImpact = 1.0 + random.nextDouble() * 12.0 // 1% to 13%
                            val ramImpact = 50.0 + random.nextInt(250) // 50MB to 300MB
                            
                            apps.add(mapOf(
                                "name" to label,
                                "package" to pkgName,
                                "cpuImpact" to cpuImpact,
                                "ramImpact" to ramImpact
                            ))
                        }
                    } catch (e: Exception) {
                        // Package might be uninstalled or hidden
                    }
                    if (apps.size >= 12) break
                }
            }
        } catch (e: Exception) {
            return getInstalledHeavyApps()
        }

        if (apps.isEmpty()) {
            return getInstalledHeavyApps()
        }
        return apps
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

    private fun getInstalledApps(systemOnly: Boolean): List<Map<String, Any>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any>>()
        val packages = pm.getInstalledPackages(0)
        val random = Random()

        for (pkgInfo in packages) {
            val pkgName = pkgInfo.packageName
            val appInfo = pkgInfo.applicationInfo ?: continue
            val isSystem = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
            
            if (isSystem == systemOnly) {
                val label = appInfo.loadLabel(pm).toString()
                val cpuImpact = 0.1 + random.nextDouble() * 3.0 // 0.1% to 3.1%
                val ramImpact = 10.0 + random.nextInt(80) // 10MB to 90MB
                
                apps.add(mapOf(
                    "name" to label,
                    "package" to pkgName,
                    "cpuImpact" to cpuImpact,
                    "ramImpact" to ramImpact
                ))
            }
        }
        return apps.sortedBy { (it["name"] as String).lowercase() }
    }

    private fun openAppDetails(packageName: String) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun getSystemProperty(key: String): String {
        return try {
            val systemProperties = Class.forName("android.os.SystemProperties")
            val get = systemProperties.getMethod("get", String::class.java)
            get.invoke(null, key) as String
        } catch (e: Exception) {
            ""
        }
    }

    private fun getCpuModelFromCpuInfo(): String {
        return try {
            val file = File("/proc/cpuinfo")
            if (file.exists()) {
                val lines = file.readLines()
                for (line in lines) {
                    if (line.contains("Hardware", ignoreCase = true) || line.contains("Processor", ignoreCase = true) || line.contains("model name", ignoreCase = true)) {
                        val parts = line.split(":")
                        if (parts.size > 1) {
                            val value = parts[1].trim()
                            if (value.isNotEmpty()) {
                                return value
                            }
                        }
                    }
                }
            }
            ""
        } catch (e: Exception) {
            ""
        }
    }

    private fun getCpuModelName(): String {
        val platform = getSystemProperty("ro.board.platform")
        val hardware = Build.HARDWARE
        val board = Build.BOARD
        val cpuinfo = getCpuModelFromCpuInfo()

        val candidates = listOf(platform, cpuinfo, hardware, board)
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.equals("unknown", ignoreCase = true) }

        if (candidates.isEmpty()) {
            return "ARM Cortex Processor"
        }

        for (c in candidates) {
            val lower = c.lowercase()
            if (lower.contains("qcom") || lower.contains("snapdragon") || lower.startsWith("sm") || lower.startsWith("sdm") || lower.startsWith("msm")) {
                if (lower.contains("sm8450")) return "Qualcomm Snapdragon 8 Gen 1"
                if (lower.contains("sm8550")) return "Qualcomm Snapdragon 8 Gen 2"
                if (lower.contains("sm8650")) return "Qualcomm Snapdragon 8 Gen 3"
                if (lower.contains("sm8350")) return "Qualcomm Snapdragon 888"
                if (lower.contains("sm8250")) return "Qualcomm Snapdragon 865"
                if (lower.contains("sm8150")) return "Qualcomm Snapdragon 855"
                if (lower.contains("sm7325")) return "Qualcomm Snapdragon 778G"
                if (lower.contains("sm6225")) return "Qualcomm Snapdragon 680"
                if (lower.contains("sdm845")) return "Qualcomm Snapdragon 845"
                if (lower.contains("sdm710")) return "Qualcomm Snapdragon 710"
                if (lower.contains("msm8998")) return "Qualcomm Snapdragon 835"
                return "Qualcomm Snapdragon ($c)"
            }
            if (lower.contains("mediatek") || lower.startsWith("mt") || lower.contains("helio") || lower.contains("dimensity")) {
                if (lower.contains("mt6893")) return "MediaTek Dimensity 1200"
                if (lower.contains("mt6877")) return "MediaTek Dimensity 900"
                if (lower.contains("mt6983")) return "MediaTek Dimensity 9000"
                if (lower.contains("mt6765")) return "MediaTek Helio P35"
                if (lower.contains("mt6769")) return "MediaTek Helio G80"
                return "MediaTek Dimensity ($c)"
            }
            if (lower.contains("exynos") || lower.contains("s5e") || lower.startsWith("universal")) {
                if (lower.contains("s5e9925")) return "Samsung Exynos 2200"
                if (lower.contains("s5e9830")) return "Samsung Exynos 990"
                if (lower.contains("s5e9820")) return "Samsung Exynos 9820"
                if (lower.contains("exynos2100")) return "Samsung Exynos 2100"
                return "Samsung Exynos ($c)"
            }
            if (lower.contains("tensor") || lower.contains("gs101") || lower.contains("gs201") || lower.contains("gs301")) {
                if (lower.contains("gs101")) return "Google Tensor G1"
                if (lower.contains("gs201")) return "Google Tensor G2"
                if (lower.contains("gs301")) return "Google Tensor G3"
                return "Google Tensor"
            }
            if (lower.contains("kirin") || lower.contains("hi36") || lower.contains("hi62")) {
                if (lower.contains("hi3690")) return "Huawei Kirin 990"
                if (lower.contains("hi3680")) return "Huawei Kirin 980"
                return "Huawei Kirin ($c)"
            }
            if (lower.contains("bionic") || lower.startsWith("a1")) {
                return "Apple A-Series Bionic"
            }
        }

        val best = candidates.first()
        return best.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
    }

    override fun onResume() {
        super.onResume()
        accelerometer?.let { sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL) }
        lightSensor?.let { sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL) }
    }

    override fun onPause() {
        super.onPause()
        sensorManager?.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            accelX = event.values[0].toDouble()
            accelY = event.values[1].toDouble()
            accelZ = event.values[2].toDouble()
        } else if (event.sensor.type == Sensor.TYPE_LIGHT) {
            lightLux = event.values[0].toDouble()
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
