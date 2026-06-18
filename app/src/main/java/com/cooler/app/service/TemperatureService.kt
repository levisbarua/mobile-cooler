package com.cooler.app.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import com.cooler.app.MainActivity
import com.cooler.app.R
import com.cooler.app.data.TemperatureLevel
import com.cooler.app.data.TemperatureReader
import com.cooler.app.data.UpdateManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class TemperatureService : Service() {

    private val scope = CoroutineScope(Dispatchers.IO + Job())
    private var monitoringJob: Job? = null

    companion object {
        const val CHANNEL_ID = "temperature_monitor"
        const val NOTIFICATION_ID = 1
        const val HIGH_TEMP_NOTIFICATION_ID = 2

        private val _currentTemp = MutableStateFlow(0f)
        val currentTemp: StateFlow<Float> = _currentTemp

        private val _thermalStatus = MutableStateFlow(PowerManager.THERMAL_STATUS_NONE)
        val thermalStatus: StateFlow<Int> = _thermalStatus

        var isRunning = false
            private set

        fun start(context: Context) {
            val intent = Intent(context, TemperatureService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, TemperatureService::class.java))
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isRunning = true
        val notification = buildNotification(0f)
        startForeground(NOTIFICATION_ID, notification)
        startMonitoring()
        checkForUpdates()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isRunning = false
        monitoringJob?.cancel()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.channel_name),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = getString(R.string.channel_desc)
                setShowBadge(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(temp: Float): Notification {
        val status = TemperatureLevel.fromCelsius(temp).name.lowercase().replaceFirstChar { it.uppercase() }
        val text = getString(R.string.service_notification_text, status)

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.service_notification_title))
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun startMonitoring() {
        monitoringJob?.cancel()
        monitoringJob = scope.launch {
            while (isActive) {
                try {
                    val temp = TemperatureReader.readBatteryTemperature(this@TemperatureService)
                    _currentTemp.value = temp
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        _thermalStatus.value = TemperatureReader.readThermalStatus(this@TemperatureService)
                    }
                    val notification = buildNotification(temp)
                    val nm = getSystemService(NotificationManager::class.java)
                    nm?.notify(NOTIFICATION_ID, notification)

                    if (temp >= TemperatureLevel.HOT.threshold) {
                        showHighTempWarning(temp)
                    }
                } catch (_: Exception) {}
                delay(5000)
            }
        }
    }

    private fun checkForUpdates() {
        scope.launch {
            delay(10000)
            UpdateManager.checkForUpdate(this@TemperatureService)
        }
    }

    private fun showHighTempWarning(temp: Float) {
        val channelId = "high_temp_warning"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "High Temperature Warning",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { setShowBadge(false) }
            val nm = getSystemService(NotificationManager::class.java)
            nm?.createNotificationChannel(channel)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            1,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Device is getting hot!")
            .setContentText("Temperature: ${temp.toInt()}°C. Consider cooling down.")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        val nm = getSystemService(NotificationManager::class.java)
        nm?.notify(HIGH_TEMP_NOTIFICATION_ID, notification)
    }
}
