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

import 'optimization_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A15),
      body: Consumer<CoolerProvider>(
        builder: (context, provider, child) {
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

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.4,
                colors: [
                  statusColor.withOpacity(0.08),
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
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F2FE).withOpacity(0.15),
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
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Thermal Center',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                                color: provider.isStressing ? Colors.orangeAccent : Colors.white.withOpacity(0.4),
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
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
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
                                  color: Colors.white.withOpacity(0.7),
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
                                                color: Colors.cyan.withOpacity(0.12),
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
                                    ],
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(26),
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor.withOpacity(0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await provider.startCooling();
                                        if (context.mounted) {
                                          context.read<AdService>().showInterstitialAd();
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
                                    backgroundColor: Colors.white.withOpacity(0.08),
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
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: provider.ramUsage / 100,
                                    backgroundColor: Colors.white.withOpacity(0.08),
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
                      child: Row(
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
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${provider.batteryLevel}% (${provider.batteryState == BatteryState.charging ? "Charging" : "Discharging"})',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.tealAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'HEALTHY',
                              style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),



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
                              backgroundColor: Colors.white.withOpacity(0.05),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
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
                              backgroundColor: Colors.white.withOpacity(0.05),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.shield_outlined, size: 18, color: Colors.orangeAccent),
                            label: const Text('Thermal Guard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (adService.isBannerLoaded && adService.bannerAd != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        alignment: Alignment.center,
                        width: adService.bannerAd!.size.width.toDouble(),
                        height: adService.bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: adService.bannerAd!),
                      ),
                    Center(
                      child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              'v${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.25),
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
