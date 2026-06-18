package com.cooler.app.data

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
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
import java.io.FileOutputStream
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

    val UPDATE_URL get() = API_URL
    val API_URL get() = com.cooler.app.Config.GITHUB_API_LATEST_RELEASE
    const val DOWNLOAD_CHANNEL_ID = "update_download"
    const val DOWNLOAD_NOTIFICATION_ID = 100

    private val scope = CoroutineScope(Dispatchers.IO)
    private val _updateState = MutableStateFlow<UpdateState>(UpdateState.Idle)
    val updateState: StateFlow<UpdateState> = _updateState
    private val _downloadProgress = MutableStateFlow(0)
    val downloadProgress: StateFlow<Int> = _downloadProgress

    private var pendingUpdateInfo: UpdateInfo? = null

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

    fun dismissUpdate() {
        _updateState.value = UpdateState.Idle
        pendingUpdateInfo = null
    }

    fun downloadUpdate(context: Context) {
        val info = pendingUpdateInfo ?: return
        _updateState.value = UpdateState.Downloading
        _downloadProgress.value = 0

        scope.launch {
            try {
                val cacheDir = context.externalCacheDir ?: context.cacheDir
                val apkDir = File(cacheDir, "updates").apply { mkdirs() }
                val file = File(apkDir, "cooler-update.apk")

                val url = URL(info.downloadUrl)
                val conn = url.openConnection() as HttpURLConnection
                conn.connectTimeout = 15000
                conn.readTimeout = 15000
                conn.connect()

                val totalBytes = conn.contentLengthLong
                val inputStream = conn.inputStream
                val outputStream = FileOutputStream(file)
                val buffer = ByteArray(8192)
                var downloaded: Long = 0
                var bytesRead: Int

                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    outputStream.write(buffer, 0, bytesRead)
                    downloaded += bytesRead
                    if (totalBytes > 0) {
                        val pct = (downloaded * 100 / totalBytes).toInt()
                        _downloadProgress.value = pct
                    }
                }

                outputStream.close()
                inputStream.close()

                _updateState.value = UpdateState.Downloaded(Uri.fromFile(file), info)
            } catch (e: Exception) {
                _updateState.value = UpdateState.Error(e.message ?: "Download failed")
            }
        }
    }

    fun installUpdate(context: Context) {
        val info = pendingUpdateInfo ?: return
        val cacheDir = context.externalCacheDir ?: context.cacheDir
        val file = File(cacheDir, "updates/cooler-update.apk")
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

    private suspend fun fetchUpdateInfo(): UpdateInfo? {
        return withContext(Dispatchers.IO) {
            try {
                val url = URL(API_URL)
                val conn = url.openConnection() as HttpURLConnection
                conn.setRequestProperty("Accept", "application/vnd.github.v3+json")
                conn.connectTimeout = 10000
                conn.readTimeout = 10000
                val json = conn.inputStream.bufferedReader().readText()
                val release = JSONObject(json)

                val tagName = release.getString("tag_name")
                val versionName = tagName.removePrefix("v")
                val body = release.optString("body", "")

                var versionCode = 0
                val lines = body.split("\n")
                for (line in lines) {
                    val trimmed = line.trim()
                    if (trimmed.startsWith("vc=")) {
                        versionCode = trimmed.removePrefix("vc=").trim().toIntOrNull() ?: 0
                        break
                    }
                }
                if (versionCode == 0) versionCode = parseVersionCode(versionName)

                val assets = release.getJSONArray("assets")
                var downloadUrl = ""
                var releaseNotes = body
                for (i in 0 until assets.length()) {
                    val asset = assets.getJSONObject(i)
                    val name = asset.getString("name")
                    if (name == "app-release.apk" || name == "app-debug.apk") {
                        downloadUrl = asset.getString("browser_download_url")
                    }
                    if (name == "latest.json") {
                        val noteUrl = asset.getString("browser_download_url")
                        try {
                            val noteConn = URL(noteUrl).openConnection() as HttpURLConnection
                            noteConn.connectTimeout = 5000
                            noteConn.readTimeout = 5000
                            val noteJson = noteConn.inputStream.bufferedReader().readText()
                            val noteObj = JSONObject(noteJson)
                            if (noteObj.has("releaseNotes")) {
                                releaseNotes = noteObj.getString("releaseNotes")
                            }
                        } catch (_: Exception) {}
                    }
                }

                UpdateInfo(
                    latestVersionCode = versionCode,
                    latestVersionName = versionName,
                    downloadUrl = downloadUrl,
                    releaseNotes = releaseNotes,
                    forceUpdate = false,
                )
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun parseVersionCode(versionName: String): Int {
        val parts = versionName.split(".")
        var code = 0
        for (part in parts) {
            val num = part.toIntOrNull() ?: return 0
            code = code * 100 + num
        }
        return code
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

}
