import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cooler_provider.dart';
import '../widgets/glass_card.dart';

class OptimizationScreen extends StatelessWidget {
  const OptimizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A15),
      body: Consumer<CoolerProvider>(
        builder: (context, provider, child) {
          final processes = provider.processes;
          final isOptimizing = provider.isCooling || provider.isScanning;
          
          double totalSelectedCpu = 0.0;
          double totalSelectedRam = 0.0;
          int selectedCount = 0;

          for (var process in processes) {
            if (process.isSelected) {
              totalSelectedCpu += process.cpuImpact;
              totalSelectedRam += process.ramImpact;
              selectedCount++;
            }
          }

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.4,
                colors: [
                  Colors.cyan.withValues(alpha: 0.04),
                  const Color(0xFF090A15),
                ],
              ),
            ),
            child: SafeArea(
              child: isOptimizing
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'OPTIMIZING DEVICE',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.coolingStepText,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Custom Header
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
                                'App Optimizer',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Info Summary Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('CPU Impact', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${totalSelectedCpu.toStringAsFixed(1)}%',
                                      style: GoogleFonts.outfit(
                                        color: Colors.redAccent,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(width: 1, height: 35, color: Colors.white12),
                                Column(
                                  children: [
                                    const Text('RAM Impact', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${totalSelectedRam.toStringAsFixed(0)} MB',
                                      style: GoogleFonts.outfit(
                                        color: Colors.orangeAccent,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(width: 1, height: 35, color: Colors.white12),
                                Column(
                                  children: [
                                    const Text('Selected', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$selectedCount / ${processes.length}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.cyanAccent,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 25.0, bottom: 12.0),
                          child: Text(
                            'Active High-Consumption Services',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        // App List or Scan UI
                        Expanded(
                          child: processes.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.cyanAccent.withValues(alpha: 0.08),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.cyanAccent.withValues(alpha: 0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.verified_user_rounded,
                                            color: Colors.cyanAccent,
                                            size: 48,
                                          ),
                                        ),
                                        const SizedBox(height: 25),
                                        Text(
                                          'System fully optimized',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No high-consumption background apps detected on your device.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 35),
                                        ElevatedButton.icon(
                                          onPressed: () => provider.scanProcesses(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(180, 48),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            side: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.12),
                                              width: 1,
                                            ),
                                          ),
                                          icon: const Icon(Icons.search_rounded, size: 18, color: Colors.cyanAccent),
                                          label: const Text('Scan Services'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: processes.length,
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final process = processes[index];
                                    
                                    IconData processIcon;
                                    switch (process.iconName) {
                                      case 'facebook':
                                        processIcon = Icons.facebook;
                                        break;
                                      case 'camera':
                                        processIcon = Icons.camera_alt_rounded;
                                        break;
                                      case 'music_note':
                                        processIcon = Icons.music_note_rounded;
                                        break;
                                      case 'play_circle':
                                        processIcon = Icons.play_circle_fill_rounded;
                                        break;
                                      case 'message':
                                        processIcon = Icons.message_rounded;
                                        break;
                                      case 'photo_camera':
                                        processIcon = Icons.photo_camera_rounded;
                                        break;
                                      case 'music_video':
                                        processIcon = Icons.music_video_rounded;
                                        break;
                                      case 'videogame_asset':
                                        processIcon = Icons.videogame_asset_rounded;
                                        break;
                                      case 'games':
                                        processIcon = Icons.games_rounded;
                                        break;
                                      case 'chat':
                                        processIcon = Icons.chat_bubble_rounded;
                                        break;
                                      case 'share':
                                        processIcon = Icons.share_rounded;
                                        break;
                                      case 'sync':
                                        processIcon = Icons.sync_rounded;
                                        break;
                                      case 'gamepad':
                                        processIcon = Icons.gamepad_rounded;
                                        break;
                                      case 'tv':
                                        processIcon = Icons.tv_rounded;
                                        break;
                                      case 'navigation':
                                        processIcon = Icons.navigation_rounded;
                                        break;
                                      default:
                                        processIcon = Icons.android_rounded;
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: InkWell(
                                        onTap: () => provider.toggleProcess(index),
                                        borderRadius: BorderRadius.circular(16),
                                        child: GlassCard(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          borderRadius: 16,
                                          borderColor: process.isSelected 
                                              ? Colors.cyanAccent.withValues(alpha: 0.3) 
                                              : Colors.white.withValues(alpha: 0.08),
                                          gradientColors: process.isSelected
                                              ? [
                                                  Colors.cyanAccent.withValues(alpha: 0.04),
                                                  Colors.white.withValues(alpha: 0.04),
                                                ]
                                              : null,
                                          child: Row(
                                            children: [
                                              // Left Icon
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: process.isSelected 
                                                      ? Colors.cyanAccent.withValues(alpha: 0.12)
                                                      : Colors.white.withValues(alpha: 0.05),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  processIcon,
                                                  color: process.isSelected ? Colors.cyanAccent : Colors.white54,
                                                  size: 22,
                                                ),
                                              ),
                                              const SizedBox(width: 14),

                                              // App name and Category
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      process.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      process.category,
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.4),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Resource details
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${process.cpuImpact.toStringAsFixed(1)}% CPU',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.redAccent.shade100,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${process.ramImpact} MB',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.orangeAccent.shade100,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 12),

                                              // Checkbox/Selection mark
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: process.isSelected ? Colors.cyanAccent : Colors.white24,
                                                    width: 1.5,
                                                  ),
                                                  color: process.isSelected ? Colors.cyanAccent : Colors.transparent,
                                                ),
                                                child: process.isSelected
                                                    ? const Icon(Icons.check, size: 12, color: Colors.black)
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // Optimize button at the bottom
                        if (processes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: ElevatedButton(
                              onPressed: selectedCount > 0 
                                  ? () {
                                      provider.optimizeApps();
                                    } 
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                                disabledForegroundColor: Colors.white30,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                selectedCount > 0 ? 'OPTIMISE SELECTED ($selectedCount)' : 'SELECT APPS TO OPTIMISE',
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
          );
        },
      ),
    );
  }
}
