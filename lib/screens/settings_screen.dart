import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cooler_provider.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A15),
      body: Consumer<CoolerProvider>(
        builder: (context, provider, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.4,
                colors: [
                  Colors.orangeAccent.withOpacity(0.03),
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
                                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: provider.autoCool,
                                      onChanged: (val) => provider.toggleAutoCool(val),
                                      activeColor: Colors.cyanAccent,
                                      activeTrackColor: Colors.cyan.withOpacity(0.3),
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
                                        overlayColor: Colors.redAccent.withOpacity(0.12),
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
                              _buildModeCard(context, provider, 'Smart Cool', Icons.opacity, 'Balanced'),
                              const SizedBox(width: 8),
                              _buildModeCard(context, provider, 'Deep Freeze', Icons.ac_unit, 'Aggressive'),
                              const SizedBox(width: 8),
                              _buildModeCard(context, provider, 'Silent Mode', Icons.volume_mute, 'Quiet'),
                            ],
                          ),
                          const SizedBox(height: 10),
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
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.updateCoolingMode(modeName),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          borderColor: isSelected ? Colors.cyanAccent.withOpacity(0.4) : Colors.white.withOpacity(0.08),
          gradientColors: isSelected
              ? [
                  Colors.cyanAccent.withOpacity(0.06),
                  Colors.white.withOpacity(0.04),
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
                  color: isSelected ? Colors.cyanAccent.withOpacity(0.7) : Colors.white24,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
