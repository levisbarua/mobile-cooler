package com.cooler.mobile_cooler

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.cooler/thermal"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryTemperature" -> {
                    val temp = getBatteryTemperature()
                    result.success(temp)
                }
                "killBackgroundProcesses" -> {
                    val killed = killBackgroundProcesses()
                    result.success(killed)
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
            // Skip our own app and system processes
            if (process.processName != myPackage &&
                process.importance >= ActivityManager.RunningAppProcessInfo.IMPORTANCE_SERVICE
            ) {
                try {
                    activityManager.killBackgroundProcesses(process.processName)
                    killed++
                } catch (e: Exception) {
                    // Skip any that can't be killed
                }
            }
        }
        return killed
    }
}
