package com.cooler.app.ui.screens

import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AcUnit
import androidx.compose.material.icons.filled.BatteryFull
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Memory
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SystemUpdate
import androidx.compose.material.icons.filled.Thermostat
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.cooler.app.data.AppOptimizer
import com.cooler.app.data.OptimizationResult
import com.cooler.app.data.TemperatureLevel
import com.cooler.app.data.TemperatureReader
import com.cooler.app.data.UpdateManager
import com.cooler.app.data.UpdateState
import com.cooler.app.service.TemperatureService
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.TextButton
import com.cooler.app.ui.components.TemperatureCard
import com.cooler.app.ui.components.ThermometerGauge
import com.cooler.app.ui.theme.CoolCyan
import com.cooler.app.ui.theme.HotRed
import com.cooler.app.ui.theme.SurfaceVariantDark
import com.cooler.app.ui.theme.WarmOrange
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen() {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    val temp by TemperatureService.currentTemp.collectAsState()
    val thermalStatus by TemperatureService.thermalStatus.collectAsState()
    val updateState by UpdateManager.updateState.collectAsState()
    val downloadProgress by UpdateManager.downloadProgress.collectAsState()

    var batteryTemp by remember { mutableStateOf(0f) }
    var cpuTemp by remember { mutableStateOf(0f) }
    var runningApps by remember { mutableStateOf(0) }
    var isCooling by remember { mutableStateOf(false) }
    var coolingResult by remember { mutableStateOf<OptimizationResult?>(null) }
    var showCoolingEffect by remember { mutableStateOf(false) }
    val tempToUse = if (temp > 0f) temp else batteryTemp
    val level = TemperatureLevel.fromCelsius(tempToUse)

    val coolingProgress by animateFloatAsState(
        targetValue = if (isCooling) 1f else 0f,
        animationSpec = tween(3000),
        label = "cooling",
    )

    fun readTemps() {
        val data = TemperatureReader.read(context)
        batteryTemp = data.batteryTemp
        cpuTemp = data.cpuTemp
        runningApps = AppOptimizer.getRunningAppCount(context)
    }

    LaunchedEffect(Unit) {
        readTemps()
        UpdateManager.checkForUpdate(context)
    }

    val updateInfo = (updateState as? UpdateState.Available)?.info
    if (updateInfo != null) {
        AlertDialog(
            onDismissRequest = { UpdateManager.dismissUpdate() },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.SystemUpdate, contentDescription = null, tint = CoolCyan)
                    Spacer(Modifier.width(8.dp))
                    Text("Update Available", fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column {
                    Text("Cooler ${updateInfo.latestVersionName} is ready to install.")
                    if (updateInfo.releaseNotes.isNotBlank()) {
                        Spacer(Modifier.height(8.dp))
                        Text(
                            updateInfo.releaseNotes,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = { UpdateManager.downloadUpdate(context) },
                    colors = ButtonDefaults.buttonColors(containerColor = CoolCyan),
                ) {
                    Icon(Icons.Default.Download, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("Download")
                }
            },
            dismissButton = {
                TextButton(onClick = { UpdateManager.dismissUpdate() }) {
                    Text("Maybe Later")
                }
            },
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Cooler", fontWeight = FontWeight.Bold) },
                actions = {
                    IconButton(onClick = {
                        context.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = android.net.Uri.parse("package:${context.packageName}")
                        })
                    }) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                ),
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(8.dp))

            ThermometerGauge(
                temperature = tempToUse,
                modifier = Modifier.align(Alignment.CenterHorizontally),
            )

            Spacer(Modifier.height(4.dp))

            Text(
                text = when (level) {
                    TemperatureLevel.NORMAL -> "Temperature is normal"
                    TemperatureLevel.WARM -> "Phone is warming up"
                    TemperatureLevel.HOT -> "Phone is hot!"
                    TemperatureLevel.CRITICAL -> "CRITICAL — cool down immediately!"
                },
                style = MaterialTheme.typography.titleLarge,
                color = when (level) {
                    TemperatureLevel.NORMAL -> CoolCyan
                    TemperatureLevel.WARM -> WarmOrange
                    TemperatureLevel.HOT -> HotRed
                    TemperatureLevel.CRITICAL -> MaterialTheme.colorScheme.error
                },
                textAlign = TextAlign.Center,
            )

            Spacer(Modifier.height(24.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                TemperatureCard(
                    label = "Battery",
                    temperature = batteryTemp,
                    icon = Icons.Default.BatteryFull,
                    modifier = Modifier.weight(1f),
                )
                TemperatureCard(
                    label = "CPU",
                    temperature = cpuTemp,
                    icon = Icons.Default.Memory,
                    modifier = Modifier.weight(1f),
                )
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && thermalStatus != PowerManager.THERMAL_STATUS_NONE) {
                Spacer(Modifier.height(8.dp))
                ThermalStatusBadge(thermalStatus)
            }

            Spacer(Modifier.height(12.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = SurfaceVariantDark),
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Memory, contentDescription = null, tint = CoolCyan)
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = "Running Apps: $runningApps",
                            style = MaterialTheme.typography.bodyLarge,
                        )
                    }
                }
            }

            Spacer(Modifier.height(12.dp))

            UpdateBanner(
                state = updateState,
                progress = downloadProgress,
                onDownload = { UpdateManager.downloadUpdate(context) },
                onInstall = { UpdateManager.installUpdate(context) },
            )

            Spacer(Modifier.height(12.dp))

            Button(
                onClick = {
                    if (!isCooling) {
                        isCooling = true
                        showCoolingEffect = true
                        scope.launch {
                            val result = AppOptimizer.optimize(context)
                            coolingResult = result
                            delay(3000)
                            readTemps()
                            isCooling = false
                            delay(2000)
                            showCoolingEffect = false
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = !isCooling,
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (level >= TemperatureLevel.HOT) HotRed else CoolCyan,
                ),
            ) {
                Icon(
                    imageVector = if (isCooling) Icons.Default.AcUnit else Icons.Default.Thermostat,
                    contentDescription = null,
                )
                Spacer(Modifier.width(8.dp))
                Text(
                    text = if (isCooling) "Cooling..." else "Start Cooling",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                )
            }

            if (isCooling) {
                Spacer(Modifier.height(12.dp))
                LinearProgressIndicator(
                    progress = { coolingProgress },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(6.dp)
                        .clip(RoundedCornerShape(3.dp)),
                    color = CoolCyan,
                    trackColor = SurfaceVariantDark,
                    strokeCap = StrokeCap.Round,
                )
            }

            if (showCoolingEffect && coolingResult != null) {
                Spacer(Modifier.height(16.dp))
                CoolingEffectCard(coolingResult!!)
            }

            if (!AppOptimizer.hasUsageStatsPermission(context)) {
                Spacer(Modifier.height(12.dp))
                PermissionCard(
                    title = "Usage Stats Access",
                    description = "Allow Cooler to detect background apps for better cooling.",
                    onGrant = { AppOptimizer.openUsageStatsSettings(context) },
                )
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun UpdateBanner(
    state: UpdateState,
    progress: Int,
    onDownload: () -> Unit,
    onInstall: () -> Unit,
) {
    AnimatedVisibility(visible = state !is UpdateState.Idle) {
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = when (state) {
                    is UpdateState.Available -> WarmOrange.copy(alpha = 0.15f)
                    is UpdateState.Downloading -> CoolCyan.copy(alpha = 0.15f)
                    is UpdateState.Downloaded -> CoolCyan.copy(alpha = 0.15f)
                    is UpdateState.Error -> HotRed.copy(alpha = 0.15f)
                    else -> SurfaceVariantDark
                },
            ),
        ) {
            Row(
                modifier = Modifier.padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    imageVector = when (state) {
                        is UpdateState.Checking -> Icons.Default.Build
                        is UpdateState.Available -> Icons.Default.SystemUpdate
                        is UpdateState.Downloading -> Icons.Default.Download
                        is UpdateState.Downloaded -> Icons.Default.CheckCircle
                        is UpdateState.Error -> Icons.Default.Error
                        else -> Icons.Default.SystemUpdate
                    },
                    contentDescription = null,
                    tint = when (state) {
                        is UpdateState.Error -> HotRed
                        else -> CoolCyan
                    },
                    modifier = Modifier.size(28.dp),
                )
                Spacer(Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = when (state) {
                            is UpdateState.Checking -> "Checking for updates..."
                            is UpdateState.Available -> "Update ${state.info.latestVersionName} available"
                            is UpdateState.Downloading -> "Downloading... $progress%"
                            is UpdateState.Downloaded -> "Download complete"
                            is UpdateState.Error -> state.message
                            else -> ""
                        },
                        style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold),
                    )
                    if (state is UpdateState.Available && state.info.releaseNotes.isNotBlank()) {
                        Text(
                            text = state.info.releaseNotes,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
                when (state) {
                    is UpdateState.Available -> {
                        Spacer(Modifier.width(8.dp))
                        Button(
                            onClick = onDownload,
                            shape = RoundedCornerShape(8.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = CoolCyan),
                        ) {
                            Text("Download", color = MaterialTheme.colorScheme.onPrimary)
                        }
                    }
                    is UpdateState.Downloading -> {
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = "$progress%",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            color = CoolCyan,
                        )
                    }
                    is UpdateState.Downloaded -> {
                        Spacer(Modifier.width(8.dp))
                        Button(
                            onClick = onInstall,
                            shape = RoundedCornerShape(8.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = CoolCyan),
                        ) {
                            Text("Install", color = MaterialTheme.colorScheme.onPrimary)
                        }
                    }
                    else -> {}
                }
            }
        }
    }
}

@Composable
private fun ThermalStatusBadge(status: Int) {
    val color: Color
    val label: String
    when (status) {
        PowerManager.THERMAL_STATUS_NONE,
        PowerManager.THERMAL_STATUS_LIGHT -> {
            color = CoolCyan; label = "None"
        }
        PowerManager.THERMAL_STATUS_MODERATE -> {
            color = WarmOrange; label = "Moderate"
        }
        PowerManager.THERMAL_STATUS_SEVERE -> {
            color = HotRed; label = "Severe"
        }
        PowerManager.THERMAL_STATUS_CRITICAL -> {
            color = HotRed; label = "Critical"
        }
        PowerManager.THERMAL_STATUS_EMERGENCY -> {
            color = MaterialTheme.colorScheme.error; label = "Emergency"
        }
        else -> {
            color = CoolCyan; label = "Unknown"
        }
    }

    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = SurfaceVariantDark),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(10.dp)
                    .clip(CircleShape)
                    .background(color),
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = "Thermal: $label",
                style = MaterialTheme.typography.bodyMedium,
            )
        }
    }
}

@Composable
private fun CoolingEffectCard(result: OptimizationResult) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CoolCyan.copy(alpha = 0.1f)),
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                Icons.Default.AcUnit,
                contentDescription = null,
                tint = CoolCyan,
                modifier = Modifier.size(24.dp),
            )
            Spacer(Modifier.width(12.dp))
            Column {
                Text(
                    text = "Cooling Complete",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                    color = CoolCyan,
                )
                Text(
                    text = "Closed ${result.appsKilled} background app(s)",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun PermissionCard(
    title: String,
    description: String,
    onGrant: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = SurfaceVariantDark),
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Default.Warning, contentDescription = null, tint = WarmOrange)
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                )
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Spacer(Modifier.width(8.dp))
            Button(
                onClick = onGrant,
                shape = RoundedCornerShape(8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = CoolCyan),
            ) {
                Text("Grant", color = MaterialTheme.colorScheme.onPrimary)
            }
        }
    }
}
