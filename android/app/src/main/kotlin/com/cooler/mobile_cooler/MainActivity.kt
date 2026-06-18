package com.cooler.mobile_cooler

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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
                        installApk(path)
                        result.success(true)
                    } else {
                        result.error("NO_PATH", "APK path not provided", null)
                    }
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
}
