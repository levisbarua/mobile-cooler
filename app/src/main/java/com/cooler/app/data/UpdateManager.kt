package com.cooler.app.data

import android.app.DownloadManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.content.FileProvider
import com.cooler.app.MainActivity
import com.cooler.app.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

data class UpdateInfo(
    val latestVersionCode: Int,
    val latestVersionName: String,
    val downloadUrl: String,
    val releaseNotes: String,
    val forceUpdate: Boolean,
)

sealed class UpdateState {
    data object Idle : UpdateState()
    data object Checking : UpdateState()
    data class Available(val info: UpdateInfo) : UpdateState()
    data object Downloading : UpdateState()
    data class Downloaded(val uri: Uri, val info: UpdateInfo) : UpdateState()
    data class Error(val message: String) : UpdateState()
}

object UpdateManager {

    val UPDATE_URL get() = com.cooler.app.Config.UPDATE_JSON_URL
    const val DOWNLOAD_CHANNEL_ID = "update_download"
    const val DOWNLOAD_NOTIFICATION_ID = 100

    private val scope = CoroutineScope(Dispatchers.IO)
    private val _updateState = MutableStateFlow<UpdateState>(UpdateState.Idle)
    val updateState: StateFlow<UpdateState> = _updateState

    private var downloadId: Long = -1L
    private var pendingUpdateInfo: UpdateInfo? = null
    private var downloadReceiver: BroadcastReceiver? = null

    fun checkForUpdate(context: Context) {
        _updateState.value = UpdateState.Checking
        scope.launch {
            try {
                val info = fetchUpdateInfo()
                val currentVersion = getCurrentVersionCode(context)
                if (info != null && info.latestVersionCode > currentVersion) {
                    _updateState.value = UpdateState.Available(info)
                    pendingUpdateInfo = info
                    showUpdateNotification(context, info)
                } else {
                    _updateState.value = UpdateState.Idle
                }
            } catch (e: Exception) {
                _updateState.value = UpdateState.Error(e.message ?: "Check failed")
            }
        }
    }

    fun downloadUpdate(context: Context) {
        val info = pendingUpdateInfo ?: return
        _updateState.value = UpdateState.Downloading

        val apkDir = File(context.externalCacheDir, "updates").apply { mkdirs() }
        val file = File(apkDir, "cooler-update.apk")
        file.delete()

        val request = DownloadManager.Request(Uri.parse(info.downloadUrl)).apply {
            setTitle("Cooler Update")
            setDescription("Downloading ${info.latestVersionName}...")
            setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            setDestinationUri(Uri.fromFile(file))
            setAllowedOverMetered(true)
            setAllowedOverRoaming(true)
        }

        val dm = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        downloadId = dm.enqueue(request)
        registerDownloadReceiver(context)
    }

    fun installUpdate(context: Context) {
        val info = pendingUpdateInfo ?: return
        val file = File(context.externalCacheDir, "updates/cooler-update.apk")
        if (!file.exists()) {
            _updateState.value = UpdateState.Error("APK file not found")
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !context.packageManager.canRequestPackageInstalls()) {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            _updateState.value = UpdateState.Available(info)
            return
        }

        val apkUri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(intent)
        _updateState.value = UpdateState.Idle
    }

    fun getDownloadProgress(context: Context): Int {
        if (downloadId < 0) return 0
        val dm = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val query = DownloadManager.Query().setFilterById(downloadId)
        var progress = 0
        dm.query(query).use { cursor ->
            if (cursor.moveToFirst()) {
                val downloaded = cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
                val total = cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
                if (total > 0) progress = (downloaded * 100 / total).toInt()
            }
        }
        return progress
    }

    private suspend fun fetchUpdateInfo(): UpdateInfo? {
        return withContext(Dispatchers.IO) {
            try {
                val url = URL(UPDATE_URL)
                val conn = url.openConnection() as HttpURLConnection
                conn.connectTimeout = 10000
                conn.readTimeout = 10000
                val json = conn.inputStream.bufferedReader().readText()
                val obj = JSONObject(json)
                val versionName = obj.getString("versionName")
                UpdateInfo(
                    latestVersionCode = obj.getInt("versionCode"),
                    latestVersionName = versionName,
                    downloadUrl = obj.optString("downloadUrl", com.cooler.app.Config.apkUrl(versionName)),
                    releaseNotes = obj.optString("releaseNotes", ""),
                    forceUpdate = obj.optBoolean("forceUpdate", false),
                )
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun getCurrentVersionCode(context: Context): Int {
        return try {
            val pkg = context.packageManager.getPackageInfo(context.packageName, 0)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pkg.longVersionCode.toInt()
            } else {
                @Suppress("DEPRECATION")
                pkg.versionCode
            }
        } catch (_: Exception) {
            1
        }
    }

    private fun showUpdateNotification(context: Context, info: UpdateInfo) {
        val channelId = "update_available"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                channelId,
                "App Updates",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply { setShowBadge(true) }
            val nm = context.getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setContentTitle("Update Available")
            .setContentText("Cooler ${info.latestVersionName} is ready to install")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(DOWNLOAD_NOTIFICATION_ID, notification)
    }

    private fun registerDownloadReceiver(context: Context) {
        downloadReceiver?.let { context.unregisterReceiver(it) }
        downloadReceiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                val id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1)
                if (id == downloadId) {
                    val info = pendingUpdateInfo
                    if (info != null) {
                        val file = File(ctx.externalCacheDir, "updates/cooler-update.apk")
                        _updateState.value = UpdateState.Downloaded(Uri.fromFile(file), info)
                    }
                }
            }
        }
        context.registerReceiver(
            downloadReceiver,
            IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE),
        )
    }
}
