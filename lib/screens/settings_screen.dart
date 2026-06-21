import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cooler_provider.dart';
import '../services/ad_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/upgrade_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A15),
      body: Consumer<CoolerProvider>(
        builder: (context, provider, child) {
          final adService = context.watch<AdService>();
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.4,
                colors: [
                  Colors.orangeAccent.withValues(alpha: 0.03),
                  const Color(0xFF090A15),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thermal Guard',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          
                          // Pro Upgrade Banner
                          if (!provider.isPro)
                            GestureDetector(
                              onTap: () => UpgradeDialog.show(context),
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                borderColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                gradientColors: [
                                  const Color(0xFF1D1B0F).withValues(alpha: 0.8),
                                  const Color(0xFF090A15).withValues(alpha: 0.9),
                                ],
                                child: Row(
                                  children: [
                                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 24),
                                    const SizedBox(width: 12),
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
                                            'No ads, Auto-cooling, Turbo speeds & more!',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.5),
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFD700), size: 14),
                                  ],
                                ),
                              ),
                            )
                          else
                            GlassCard(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              borderColor: const Color(0xFF00F2FE).withValues(alpha: 0.3),
                              gradientColors: [
                                const Color(0xFF071927).withValues(alpha: 0.8),
                                const Color(0xFF090A15).withValues(alpha: 0.9),
                              ],
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE), size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Premium Pro Mode Active',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'ACTIVE',
                                                style: GoogleFonts.outfit(
                                                  color: const Color(0xFF00F2FE),
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'All features unlocked. Thank you for your support!',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await provider.setPro(false);
                                      adService.updateProStatus(false);
                                    },
                                    icon: const Icon(Icons.refresh, color: Colors.white38, size: 16),
                                    tooltip: 'Reset Pro (Testing)',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          
                          // Thermal Guard Settings
                          const Text(
                            'PROTECTION CONFIGURATION',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),

                          GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                // Auto Cool Toggle
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Automatic Cooling',
                                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cool device automatically if hot',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: provider.autoCool,
                                      onChanged: (val) {
                                        if (!provider.isPro && val) {
                                          UpgradeDialog.show(context);
                                        } else {
                                          provider.toggleAutoCool(val);
                                        }
                                      },
                                      activeThumbColor: Colors.cyanAccent,
                                      activeTrackColor: Colors.cyan.withValues(alpha: 0.3),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white10, height: 24),

                                // Threshold Slider
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Thermal Warning Threshold',
                                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${provider.warningThreshold.toStringAsFixed(0)}°C',
                                          style: GoogleFonts.outfit(
                                            color: Colors.redAccent,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: Colors.redAccent,
                                        inactiveTrackColor: Colors.white10,
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.redAccent.withValues(alpha: 0.12),
                                        valueIndicatorColor: Colors.redAccent,
                                        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                                      ),
                                      child: Slider(
                                        value: provider.warningThreshold,
                                        min: 35.0,
                                        max: 45.0,
                                        divisions: 10,
                                        label: '${provider.warningThreshold.toStringAsFixed(0)}°C',
                                        onChanged: (val) => provider.updateWarningThreshold(val),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('35°C (Conservative)', style: TextStyle(color: Colors.white30, fontSize: 10)),
                                          Text('45°C (Aggressive)', style: TextStyle(color: Colors.white30, fontSize: 10)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Cooling Intensity mode selection
                          const Text(
                            'COOLING INTENSITY PROFILE',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              _buildModeCard(context, provider, 'Auto', Icons.autorenew, 'Smart Select'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildModeCard(context, provider, 'Smart Cool', Icons.opacity, 'Balanced'),
                              const SizedBox(width: 8),
                              _buildModeCard(context, provider, 'Silent Mode', Icons.volume_mute, 'Quiet'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildModeCard(context, provider, 'Deep Freeze', Icons.ac_unit, 'Aggressive'),
                              const SizedBox(width: 8),
                              _buildModeCard(context, provider, 'Turbo Boost', Icons.bolt, 'Ultra Boost'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const SizedBox(height: 20),
                          const Text(
                            'DEVELOPER CONFIGURATION',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Simulated Ads (Mock)',
                                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Force simulated ads for testing',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: adService.useSimulatedAds,
                                  onChanged: (val) => adService.setUseSimulatedAds(val),
                                  activeThumbColor: Colors.cyanAccent,
                                  activeTrackColor: Colors.cyan.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    CoolerProvider provider,
    String modeName,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = provider.coolingMode == modeName;
    final isLocked = !provider.isPro && (modeName == 'Deep Freeze' || modeName == 'Turbo Boost');
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isLocked) {
            UpgradeDialog.show(context);
          } else {
            provider.updateCoolingMode(modeName);
          }
        },
        child: Stack(
          children: [
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              borderColor: isSelected ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
              gradientColors: isSelected
                  ? [
                      Colors.cyanAccent.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : null,
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.cyanAccent : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    modeName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.7) : Colors.white24,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.lock_rounded,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.8), // Gold lock
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
