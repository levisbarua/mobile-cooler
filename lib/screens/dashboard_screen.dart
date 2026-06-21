import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/cooler_provider.dart';
import '../services/update_service.dart';
import '../services/ad_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/fan_animator.dart';
import '../widgets/mock_banner_ad.dart';
import '../widgets/upgrade_dialog.dart';

import 'optimization_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoolerProvider>();
    final updateService = context.watch<UpdateService>();
    final adService = context.watch<AdService>();
    final showBanner = updateService.isUpdateAvailable ||
        updateService.isDownloading ||
        updateService.isReadyToInstall;
    final temp = provider.temperature;
    final isHot = temp >= provider.warningThreshold;
    final isWarm = temp >= 35.0 && temp < provider.warningThreshold;
    
    Color statusColor;
    String statusText;
    String descriptionText;

    if (isHot) {
      statusColor = const Color(0xFFFF4B5C); // Coral Red
      statusText = 'OVERHEATING';
      descriptionText = 'Close background apps immediately to reduce CPU load!';
    } else if (isWarm) {
      statusColor = const Color(0xFFFF9F43); // Orange
      statusText = 'WARM';
      descriptionText = 'Device temperature rising. System optimization recommended.';
    } else {
      statusColor = const Color(0xFF00F2FE); // Cyan/Ice Blue
      statusText = 'COOL & HEALTHY';
      descriptionText = 'Your device is operating at optimal temperature.';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090A15),
      body: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.4,
                colors: [
                  statusColor.withValues(alpha: 0.08),
                  const Color(0xFF090A15),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 15.0,
                  bottom: showBanner ? 160.0 : 15.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Glassmorphic App Logo
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MOBILE COOLER',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Thermal Center',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (provider.isPro) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'PRO',
                                          style: GoogleFonts.outfit(
                                            color: Colors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Heat Stress simulator button (hidden inside custom tool item)
                            IconButton(
                              onPressed: () {
                                provider.toggleStressTest();
                              },
                              icon: Icon(
                                provider.isStressing ? Icons.flash_on : Icons.flash_off,
                                color: provider.isStressing ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.4),
                              ),
                              tooltip: 'Toggle CPU Stress Test Simulation',
                            ),
                            const SizedBox(width: 8),
                            // Settings Button
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                );
                              },
                              icon: const Icon(Icons.settings_outlined, color: Colors.white),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Cooling Fan Circular Display Card
                    Center(
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                        child: Column(
                          children: [
                            // Animated Fan Widget
                            const FanAnimator(size: 190),
                            const SizedBox(height: 25),

                            // Temperature and Label Display
                            Text(
                              '${temp.toStringAsFixed(1)}°C',
                              style: GoogleFonts.outfit(
                                fontSize: 48,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.outfit(
                                  color: statusColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Status description
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                provider.isCooling ? provider.coolingStepText : descriptionText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // COOL DOWN BUTTON
                            provider.isCooling
                                ? Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(26),
                                          child: Stack(
                                            children: [
                                              // Progress track
                                              Container(
                                                color: Colors.cyan.withValues(alpha: 0.12),
                                              ),
                                              // Progress bar
                                              FractionallySizedBox(
                                                widthFactor: provider.coolingProgress,
                                                child: Container(
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Progress text
                                              Center(
                                                child: Text(
                                                  'COOLING ${(provider.coolingProgress * 100).toInt()}%',
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      GlassCard(
                                        padding: const EdgeInsets.all(16),
                                        borderRadius: 16,
                                        borderColor: Colors.cyanAccent.withValues(alpha: 0.2),
                                        gradientColors: [
                                          Colors.cyanAccent.withValues(alpha: 0.05),
                                          const Color(0xFF090A15).withValues(alpha: 0.8),
                                        ],
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'PHYSICAL COOLING TIPS',
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.cyanAccent,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            _buildTipRow(Icons.phone_android_rounded, 'Remove phone case/cover to release trapped heat.'),
                                            const SizedBox(height: 8),
                                            _buildTipRow(Icons.power_off_rounded, 'Avoid charging the phone (charging generates intense heat).'),
                                            const SizedBox(height: 8),
                                            _buildTipRow(Icons.air_rounded, 'Place the device in a cool environment or near a fan.'),
                                            const SizedBox(height: 8),
                                            _buildTipRow(Icons.phonelink_erase_rounded, 'Lock the device and turn off screen for maximum heat decay.'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(26),
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor.withValues(alpha: 0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await provider.startCooling();
                                        if (context.mounted) {
                                          context.read<AdService>().showInterstitialAd(context);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: statusColor,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(double.infinity, 52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(26),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'COOL DOWN NOW',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick status information grid (CPU, RAM, Battery)
                    Row(
                      children: [
                        // CPU Card
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.memory, 
                                        color: Colors.purpleAccent, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('CPU', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${provider.cpuUsage.toStringAsFixed(0)}%',
                                  style: GoogleFonts.outfit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: provider.cpuUsage / 100,
                                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      provider.cpuUsage > 80 ? Colors.redAccent : Colors.purpleAccent,
                                    ),
                                    minHeight: 4,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // RAM Card
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.memory_outlined, color: Colors.orangeAccent, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('RAM', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${provider.ramUsage.toStringAsFixed(0)}%',
                                  style: GoogleFonts.outfit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  provider.totalRamMB > 0
                                      ? '${(provider.usedRamMB / 1024).toStringAsFixed(1)}G / ${(provider.totalRamMB / 1024).toStringAsFixed(1)}G'
                                      : 'Optimized',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: provider.ramUsage / 100,
                                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                                    minHeight: 4,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Battery Detail Card
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    provider.batteryState == BatteryState.charging
                                        ? Icons.battery_charging_full_rounded
                                        : Icons.battery_std_rounded,
                                    color: provider.batteryState == BatteryState.charging ? Colors.greenAccent : Colors.tealAccent,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Battery Level',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${provider.batteryLevel}% (${provider.batteryPlugged != "Battery" ? "Charging via ${provider.batteryPlugged}" : "Discharging"})',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (provider.batteryHealth == 'Good' ? Colors.tealAccent : Colors.redAccent).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  provider.batteryHealth.toUpperCase(),
                                  style: TextStyle(
                                    color: provider.batteryHealth == 'Good' ? Colors.tealAccent : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          ),
                          if (provider.batteryVoltage > 0) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white12, height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Voltage: ${(provider.batteryVoltage / 1000).toStringAsFixed(1)}V',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                                ),
                                Text(
                                  'Tech: ${provider.batteryTechnology}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                                ),
                                Text(
                                  provider.isPowerSaveMode ? 'Power Saver: ON' : 'Power Saver: OFF',
                                  style: TextStyle(
                                    color: provider.isPowerSaveMode ? Colors.greenAccent : Colors.white.withValues(alpha: 0.5),
                                    fontSize: 11,
                                    fontWeight: provider.isPowerSaveMode ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Storage & Memory Optimization Card
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.storage_rounded, color: Colors.cyanAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Internal Storage',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(color: Colors.cyanAccent),
                                    ),
                                  );
                                  final double freed = await provider.cleanCache();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    final freedMB = freed / (1024.0 * 1024.0);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(0xFF0F1123),
                                        content: Text(
                                          freedMB > 0.05
                                              ? 'Cache optimized! Freed ${freedMB.toStringAsFixed(1)} MB'
                                              : 'System cache is already clean and optimized.',
                                          style: GoogleFonts.outfit(color: Colors.cyanAccent),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15),
                                  foregroundColor: Colors.cyanAccent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.clean_hands_rounded, size: 14),
                                label: const Text('CLEAN CACHE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (provider.totalStorageGB > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${provider.usedStorageGB.toStringAsFixed(1)} GB used of ${provider.totalStorageGB.toStringAsFixed(0)} GB',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                ),
                                Text(
                                  '${provider.storagePercent.toStringAsFixed(0)}%',
                                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: provider.storagePercent / 100,
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                                minHeight: 6,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Analyzing storage details...',
                              style: TextStyle(color: Colors.white30, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Hardware Controls (Control Hub) Section
                    Text(
                      'DEVICE CONTROL HUB',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                            borderColor: provider.flashlightActive
                                ? const Color(0xFF00F2FE).withValues(alpha: 0.5)
                                : null,
                            gradientColors: provider.flashlightActive
                                ? [
                                    const Color(0xFF00F2FE).withValues(alpha: 0.15),
                                    const Color(0xFF090A15).withValues(alpha: 0.8),
                                  ]
                                : null,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => provider.toggleFlashlight(),
                                  behavior: HitTestBehavior.opaque,
                                  child: Column(
                                    children: [
                                      Icon(
                                        provider.flashlightActive ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                                        color: provider.flashlightActive ? const Color(0xFF00F2FE) : Colors.white60,
                                        size: 26,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Flashlight',
                                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        provider.flashlightActive ? 'ACTIVE' : 'OFF',
                                        style: TextStyle(
                                          color: provider.flashlightActive ? const Color(0xFF00F2FE) : Colors.white38,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (provider.flashlightActive) ...[
                                  const SizedBox(height: 10),
                                  if (provider.isFlashlightLevelSupported) ...[
                                    GestureDetector(
                                      onTap: () {},
                                      child: SliderTheme(
                                        data: SliderThemeData(
                                          trackHeight: 2,
                                          activeTrackColor: const Color(0xFF00F2FE),
                                          inactiveTrackColor: Colors.white10,
                                          thumbColor: const Color(0xFF00F2FE),
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                        ),
                                        child: Slider(
                                          value: provider.flashlightLevel,
                                          min: 0.1,
                                          max: 1.0,
                                          onChanged: (val) {
                                            provider.setFlashlightLevel(val);
                                          },
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Intensity: ${(provider.flashlightLevel * 100).toInt()}%',
                                      style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Intensity control not supported by your hardware',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        fontSize: 9,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => provider.toggleRingerMode(),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                              borderColor: provider.ringerMode == 1
                                  ? Colors.orangeAccent.withValues(alpha: 0.5)
                                  : null,
                              gradientColors: provider.ringerMode == 1
                                  ? [
                                      Colors.orangeAccent.withValues(alpha: 0.12),
                                      const Color(0xFF090A15).withValues(alpha: 0.8),
                                    ]
                                  : null,
                              child: Column(
                                children: [
                                  Icon(
                                    provider.ringerMode == 2 ? Icons.volume_up_rounded : Icons.vibration_rounded,
                                    color: provider.ringerMode == 2 ? Colors.cyanAccent : Colors.orangeAccent,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Sound Profile',
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    provider.ringerMode == 2 ? 'SOUND' : 'VIBRATE',
                                    style: TextStyle(
                                      color: provider.ringerMode == 2 ? Colors.cyanAccent : Colors.orangeAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Quick Settings shortcuts section
                    Text(
                      'SYSTEM SHORTCUTS',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildShortcutItem(
                            icon: Icons.battery_saver_rounded,
                            color: Colors.greenAccent,
                            label: 'Battery',
                            onTap: () => provider.openSystemSettings('battery'),
                          ),
                          _buildShortcutItem(
                            icon: Icons.brightness_medium_rounded,
                            color: Colors.amberAccent,
                            label: 'Display',
                            onTap: () => provider.openSystemSettings('display'),
                          ),
                          _buildShortcutItem(
                            icon: Icons.translate_rounded,
                            color: Colors.indigoAccent,
                            label: 'Language',
                            onTap: () => provider.openSystemSettings('language'),
                          ),
                          _buildShortcutItem(
                            icon: Icons.developer_mode_rounded,
                            color: Colors.purpleAccent,
                            label: 'Dev Tools',
                            onTap: () => provider.openSystemSettings('developer'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Upgrade to Pro Dashboard Banner
                    if (!provider.isPro) ...[
                      GestureDetector(
                        onTap: () => UpgradeDialog.show(context),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          borderColor: const Color(0xFFFFD700).withValues(alpha: 0.35),
                          gradientColors: [
                            const Color(0xFF1D1B0F).withValues(alpha: 0.7),
                            const Color(0xFF090A15).withValues(alpha: 0.9),
                          ],
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upgrade to Premium Pro',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Remove ads, unlock background auto-cooling and turbo speeds!',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFD700), size: 14),
                            ],
                          ),
                        ),
                      ),
                     const SizedBox(height: 15),

                    // Junk Cleaner and Speed Booster quick controls
                    Row(
                      children: [
                        // Speed Booster Card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showSpeedBoosterDialog(context, provider),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              borderColor: Colors.cyanAccent.withValues(alpha: 0.15),
                              gradientColors: [
                                Colors.cyanAccent.withValues(alpha: 0.05),
                                const Color(0xFF090A15).withValues(alpha: 0.8),
                              ],
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.speed_rounded, color: Colors.cyanAccent, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Speed Boost',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Boost RAM',
                                          style: TextStyle(color: Colors.white38, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Junk Cleaner Card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showJunkCleanerDialog(context, provider),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              borderColor: Colors.greenAccent.withValues(alpha: 0.15),
                              gradientColors: [
                                Colors.greenAccent.withValues(alpha: 0.05),
                                const Color(0xFF090A15).withValues(alpha: 0.8),
                              ],
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.greenAccent, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Junk Clean',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          provider.junkSizeMB > 0
                                              ? '${provider.junkSizeMB.toStringAsFixed(1)} MB'
                                              : 'Optimized',
                                          style: TextStyle(
                                            color: provider.junkSizeMB > 0 ? Colors.greenAccent : Colors.white38,
                                            fontSize: 10,
                                            fontWeight: provider.junkSizeMB > 0 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ],

                    // Quick Navigation shortcuts
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const OptimizationScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.bolt, size: 18, color: Colors.cyanAccent),
                            label: const Text('Optimize Apps', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.shield_outlined, size: 18, color: Colors.orangeAccent),
                            label: const Text('Thermal Guard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (adService.isMockAd && adService.isBannerLoaded)
                      MockBannerAd(
                        onDismiss: () {
                          adService.dismissMockBanner();
                        },
                      )
                    else if (adService.isBannerLoaded && adService.bannerAd != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        alignment: Alignment.center,
                        width: adService.bannerAd!.size.width.toDouble(),
                        height: adService.bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: adService.bannerAd!),
                      ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  'v${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ads SDK - Init: ${adService.initStatus}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Banner: ${adService.bannerStatus} | Interstitial: ${adService.interstitialStatus}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update Status: ${updateService.statusText.isEmpty ? "Idle" : updateService.statusText}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 10,
                            ),
                          ),
                          if (adService.lastError != null) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                '${adService.lastError}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.redAccent.withValues(alpha: 0.8),
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
        ),
      );
    }

  Widget _buildShortcutItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedBoosterDialog(BuildContext context, CoolerProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SpeedBoosterDialogContent(provider: provider),
    );
  }

  void _showJunkCleanerDialog(BuildContext context, CoolerProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _JunkCleanerDialogContent(provider: provider),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
          ),
        ),
      ],
    );
  }
}

class _SpeedBoosterDialogContent extends StatefulWidget {
  final CoolerProvider provider;
  const _SpeedBoosterDialogContent({required this.provider});

  @override
  State<_SpeedBoosterDialogContent> createState() => _SpeedBoosterDialogContentState();
}

class _SpeedBoosterDialogContentState extends State<_SpeedBoosterDialogContent> {
  String _statusText = 'Analyzing memory...';
  double _progress = 0.0;
  bool _isFinished = false;
  int _killedCount = 0;
  double _freedMB = 0.0;
  double _oldPercent = 0.0;
  double _newPercent = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startBoost();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startBoost() async {
    int steps = 15;
    int currentStep = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) async {
      currentStep++;
      if (mounted) {
        setState(() {
          _progress = currentStep / steps;
          if (currentStep < 5) {
            _statusText = 'Analyzing RAM allocations...';
          } else if (currentStep < 10) {
            _statusText = 'Locating inactive background services...';
          } else {
            _statusText = 'Preparing speed optimization...';
          }
        });
      }

      if (currentStep >= steps) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _statusText = 'Boosting device performance...';
          });
        }
        
        final results = await widget.provider.boostSpeed();
        
        if (mounted) {
          setState(() {
            _killedCount = results['killed'] ?? 0;
            _freedMB = results['freed'] ?? 0.0;
            _oldPercent = results['oldPercent'] ?? 0.0;
            _newPercent = results['newPercent'] ?? 0.0;
            _statusText = 'Boost Completed!';
            _isFinished = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = Colors.cyanAccent;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        borderColor: statusColor.withValues(alpha: 0.35),
        gradientColors: [
          statusColor.withValues(alpha: 0.12),
          const Color(0xFF090A15).withValues(alpha: 0.98),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isFinished) ...[
              Text(
                'SPEED BOOSTER',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      backgroundColor: Colors.white10,
                    ),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ] else ...[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(Icons.rocket_launch_rounded, color: statusColor, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'RAM BOOSTED SUCCESSFULLY!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20),
              // Results info box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                ),
                child: Column(
                  children: [
                    _buildResultRow('Apps Terminated', '$_killedCount apps'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _buildResultRow('Memory Recovered', '${_freedMB.toStringAsFixed(1)} MB'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _buildResultRow('RAM Usage', '${_oldPercent.toStringAsFixed(0)}% → ${_newPercent.toStringAsFixed(0)}%'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'GREAT',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _JunkCleanerDialogContent extends StatefulWidget {
  final CoolerProvider provider;
  const _JunkCleanerDialogContent({required this.provider});

  @override
  State<_JunkCleanerDialogContent> createState() => _JunkCleanerDialogContentState();
}

class _JunkCleanerDialogContentState extends State<_JunkCleanerDialogContent> {
  String _statusText = 'Scanning system files...';
  double _progress = 0.0;
  bool _isCleaning = false;
  bool _isFinished = false;
  double _freedMB = 0.0;
  Map<String, double> _junkDetails = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startScan() async {
    final details = await widget.provider.scanJunkFiles();
    
    int steps = 15;
    int currentStep = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      currentStep++;
      if (mounted) {
        setState(() {
          _progress = currentStep / steps;
          if (currentStep < 5) {
            _statusText = 'Scanning cache files...';
          } else if (currentStep < 10) {
            _statusText = 'Checking system logs...';
          } else {
            _statusText = 'Calculating temporary space...';
          }
        });
      }

      if (currentStep >= steps) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _junkDetails = details;
          });
        }
        _startClean();
      }
    });
  }

  void _startClean() async {
    if (mounted) {
      setState(() {
        _isCleaning = true;
        _statusText = 'Clearing junk files...';
        _progress = 0.0;
      });
    }

    int steps = 10;
    int currentStep = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) async {
      currentStep++;
      if (mounted) {
        setState(() {
          _progress = currentStep / steps;
        });
      }

      if (currentStep >= steps) {
        timer.cancel();
        
        final bytesFreed = await widget.provider.cleanJunks();
        
        if (mounted) {
          setState(() {
            _freedMB = bytesFreed / (1024.0 * 1024.0);
            _isCleaning = false;
            _isFinished = true;
            _statusText = 'System cleaned!';
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = Colors.greenAccent;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        borderColor: statusColor.withValues(alpha: 0.35),
        gradientColors: [
          statusColor.withValues(alpha: 0.12),
          const Color(0xFF090A15).withValues(alpha: 0.98),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isFinished) ...[
              Text(
                _isCleaning ? 'CLEANING JUNKS' : 'SCANNING JUNKS',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      backgroundColor: Colors.white10,
                    ),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ] else ...[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(Icons.check_circle_outline_rounded, color: statusColor, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                'DEVICE FULLY OPTIMIZED!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20),
              // Results info box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                ),
                child: Column(
                  children: [
                    _buildResultRow('System Cache', '${(_junkDetails['cache'] ?? 0.0).toStringAsFixed(1)} MB'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _buildResultRow('Log Files', '${(_junkDetails['logs'] ?? 0.0).toStringAsFixed(1)} MB'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _buildResultRow('Temp Files', '${(_junkDetails['temp'] ?? 0.0).toStringAsFixed(1)} MB'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _buildResultRow('Total Cleaned', '${_freedMB.toStringAsFixed(1)} MB', isTotal: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'EXCELLENT',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String title, String val, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isTotal ? Colors.greenAccent : Colors.white54,
            fontSize: 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.outfit(
            color: isTotal ? Colors.greenAccent : Colors.white,
            fontSize: isTotal ? 14 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
