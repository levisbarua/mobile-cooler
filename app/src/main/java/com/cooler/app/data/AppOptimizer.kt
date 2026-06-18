package com.cooler.app.data

import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings

data class OptimizationResult(
    val appsKilled: Int = 0,
    val cacheFreed: Long = 0L,
    val isCoolingDown: Boolean = false,
)

object AppOptimizer {

    fun getRunningAppCount(context: Context): Int {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager ?: return 0
        val runningApps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            if (usageStatsManager != null && hasUsageStatsPermission(context)) {
                val currentTime = System.currentTimeMillis()
                val stats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    currentTime - 1000 * 60 * 5,
                    currentTime,
                )
                stats?.filter { it.lastTimeUsed > 0 }?.size ?: 0
            } else 0
        } else {
            @Suppress("DEPRECATION")
            am.getRunningTasks(100).size
        }
        return maxOf(runningApps, 1)
    }

    fun optimize(context: Context): OptimizationResult {
        var killed = 0
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager ?: return OptimizationResult()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            if (usageStatsManager != null && hasUsageStatsPermission(context)) {
                val currentTime = System.currentTimeMillis()
                val stats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    currentTime - 1000 * 60 * 30,
                    currentTime,
                )
                stats?.forEach { usageStats ->
                    val pkg = usageStats.packageName
                    if (pkg != context.packageName && pkg != "android") {
                        try {
                            am.killBackgroundProcesses(pkg)
                            killed++
                        } catch (_: Exception) {}
                    }
                }
            }
        }

        am.killBackgroundProcesses(context.packageName)

        return OptimizationResult(
            appsKilled = killed,
            cacheFreed = 0L,
            isCoolingDown = true,
        )
    }

    fun hasUsageStatsPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP_MR1) return true
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return false
        val currentTime = System.currentTimeMillis()
        try {
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, currentTime - 1000, currentTime)
            return stats != null && stats.isNotEmpty()
        } catch (_: Exception) {
            return false
        }
    }

    fun openUsageStatsSettings(context: Context) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun isBatteryOptimizationDisabled(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = context.getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager ?: return false
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    fun openBatteryOptimizationSettings(context: Context) {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = android.net.Uri.parse("package:${context.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }
}
