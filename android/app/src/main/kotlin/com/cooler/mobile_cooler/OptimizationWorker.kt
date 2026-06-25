package com.cooler.mobile_cooler

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import androidx.core.app.NotificationCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.io.File

class OptimizationWorker(context: Context, params: WorkerParameters) : Worker(context, params) {

    override fun doWork(): Result {
        val context = applicationContext

        // 1. Read configuration from FlutterSharedPreferences
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val autoCool = prefs.getBoolean("flutter.auto_cool", false)
        val warningThreshold = try {
            prefs.getFloat("flutter.warning_threshold", 40.0f).toDouble()
        } catch (e: Exception) {
            try {
                prefs.getString("flutter.warning_threshold", "40.0")?.toDoubleOrNull() ?: 40.0
            } catch (ex: Exception) {
                40.0
            }
        }

        if (!autoCool) {
            return Result.success()
        }

        // 2. Fetch battery temperature
        val temp = getBatteryTemperature(context)

        // 3. If temperature exceeds warningThreshold, perform optimization
        if (temp >= warningThreshold) {
            val killed = killBackgroundProcesses(context)
            val bytesFreed = cleanCache(context)
            val freedMB = bytesFreed.toDouble() / (1024.0 * 1024.0)

            // 4. Send notification informing the user
            val message = if (freedMB > 0.1) {
                "Cooled phone down to ${"%.1f".format(temp)}°C, terminated $killed apps, and cleared ${"%.1f".format(freedMB)} MB junk files."
            } else {
                "Cooled phone down to ${"%.1f".format(temp)}°C and terminated $killed apps."
            }
            showNotification(context, "Automatic Thermal Guard Active", message)
        }

        return Result.success()
    }

    private fun getBatteryTemperature(context: Context): Double {
        val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus: Intent? = context.registerReceiver(null, intentFilter)
        val temp = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
        return if (temp != -1) temp / 10.0 else -1.0
    }

    private fun killBackgroundProcesses(context: Context): Int {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val pm = context.packageManager
        val packages = pm.getInstalledPackages(0)
        var killed = 0
        val myPackage = context.packageName

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

    private fun cleanCache(context: Context): Long {
        var bytesFreed = 0L

        // 1. App internal cache
        try {
            val cacheDir = context.cacheDir
            bytesFreed += deleteDirContents(cacheDir)
        } catch (e: Exception) {}

        // 2. App external cache
        try {
            val extCacheDirs = context.externalCacheDirs
            if (extCacheDirs != null) {
                for (dir in extCacheDirs) {
                    if (dir != null) {
                        bytesFreed += deleteDirContents(dir)
                    }
                }
            }
        } catch (e: Exception) {}

        // 3. Shared storage caches (if MANAGE_EXTERNAL_STORAGE is granted)
        if (checkManageStorageAccess(context)) {
            try {
                val rootDir = File("/storage/emulated/0")
                if (rootDir.exists()) {
                    val files = rootDir.listFiles()
                    if (files != null) {
                        for (file in files) {
                            if (file.isDirectory) {
                                bytesFreed += cleanSharedDirRecursively(file)
                            } else {
                                val name = file.name.lowercase()
                                if (name.endsWith(".tmp") || name.endsWith(".temp") || name.endsWith(".log")) {
                                    val size = file.length()
                                    if (file.delete()) {
                                        bytesFreed += size
                                    }
                                }
                            }
                        }
                    }
                }
            } catch (e: Exception) {}
        }

        return bytesFreed
    }

    private fun deleteDirContents(dir: File): Long {
        var bytesFreed = 0L
        val files = dir.listFiles()
        if (files != null) {
            for (file in files) {
                if (file.isDirectory) {
                    bytesFreed += deleteDirContents(file)
                    file.delete()
                } else {
                    val size = file.length()
                    if (file.delete()) {
                        bytesFreed += size
                    }
                }
            }
        }
        return bytesFreed
    }

    private fun cleanSharedDirRecursively(dir: File): Long {
        var bytesFreed = 0L
        val files = dir.listFiles()
        if (files != null) {
            for (file in files) {
                if (file.isDirectory) {
                    bytesFreed += cleanSharedDirRecursively(file)
                } else {
                    val path = file.absolutePath.replace('\\', '/')
                    val name = file.name.lowercase()
                    val isLog = name.endsWith(".log")
                    val isTemp = name.endsWith(".tmp") || name.endsWith(".temp") || name == "thumbs.db" || name == ".ds_store"
                    val isCache = path.contains("/cache/") || path.contains("/.cache/") || path.contains("/.thumbnails/")

                    if (isLog || isTemp || isCache) {
                        val size = file.length()
                        if (file.delete()) {
                            bytesFreed += size
                        }
                    }
                }
            }
        }
        return bytesFreed
    }

    private fun checkManageStorageAccess(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return Environment.isExternalStorageManager()
        }
        return true
    }

    private fun showNotification(context: Context, title: String, message: String) {
        val channelId = "auto_optimization_channel"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Auto Optimization Updates",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for automatic background device optimization and cooling."
            }
            notificationManager.createNotificationChannel(channel)
        }

        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = if (intent != null) {
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            PendingIntent.getActivity(context, 0, intent, flags)
        } else {
            null
        }

        val iconId = context.resources.getIdentifier("launcher_icon", "mipmap", context.packageName)
        val smallIcon = if (iconId != 0) iconId else android.R.drawable.stat_notify_sync

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(smallIcon)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)

        if (pendingIntent != null) {
            builder.setContentIntent(pendingIntent)
        }

        notificationManager.notify(1001, builder.build())
    }
}
