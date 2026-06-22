import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import '../providers/cooler_provider.dart';
import '../widgets/glass_card.dart';

class BatteryChargingScreen extends StatefulWidget {
  final VoidCallback? onDismiss;
  const BatteryChargingScreen({super.key, this.onDismiss});

  @override
  State<BatteryChargingScreen> createState() => _BatteryChargingScreenState();
}

class _BatteryChargingScreenState extends State<BatteryChargingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoolerProvider>();
    final isCharging = provider.batteryState == BatteryState.charging ||
        provider.batteryState == BatteryState.full;

    return Scaffold(
      backgroundColor: const Color(0xFF090A15),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.4,
            colors: [
              isCharging
                  ? Colors.greenAccent.withValues(alpha: 0.04)
                  : Colors.cyan.withValues(alpha: 0.04),
              const Color(0xFF090A15),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => widget.onDismiss != null ? widget.onDismiss!() : Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Battery & Power Saver',
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Charging Wave Section or Circular Meter
                      if (isCharging)
                        _buildChargingWaveSection(provider)
                      else
                        _buildBatteryCircularMeter(provider),

                      const SizedBox(height: 25),
                      // Battery Saver Profiles
                      _buildSaverProfiles(provider),

                      const SizedBox(height: 20),
                      // Battery Details Card
                      _buildBatteryDetails(provider),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChargingWaveSection(CoolerProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Text(
            'FAST CHARGING ACTIVE',
            style: GoogleFonts.outfit(
              color: Colors.greenAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              // The Wave container
              ClipOval(
                child: Container(
                  width: 170,
                  height: 170,
                  color: Colors.greenAccent.withValues(alpha: 0.05),
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WavePainter(
                          progress: _waveController.value,
                          fillLevel: provider.batteryLevel / 100.0,
                          waveColor: Colors.greenAccent.withValues(alpha: 0.3),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Floating Bubbles on top
              SizedBox(
                width: 170,
                height: 170,
                child: _buildBubbles(),
              ),
              // Battery Level Display
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${provider.batteryLevel}%',
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    provider.batteryPlugged == 'Battery' ? 'USB Port' : '${provider.batteryPlugged} Source',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Voltage', '${(provider.batteryVoltage / 1000).toStringAsFixed(1)}V', Icons.bolt),
              _buildMiniStat('Health', provider.batteryHealth, Icons.favorite),
              _buildMiniStat('Temp', '${provider.temperature.toStringAsFixed(1)}°C', Icons.thermostat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryCircularMeter(CoolerProvider provider) {
    final double percent = provider.batteryLevel / 100.0;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Text(
            'BATTERY STATUS',
            style: GoogleFonts.outfit(
              color: Colors.cyanAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 25),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    provider.batteryLevel <= 20
                        ? Colors.redAccent
                        : (provider.batteryLevel <= 50 ? Colors.orangeAccent : Colors.cyanAccent),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${provider.batteryLevel}%',
                    style: GoogleFonts.outfit(
                      fontSize: 38,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    provider.saverMode == 'Normal'
                        ? 'Standard Mode'
                        : '${provider.saverMode} Saver',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Voltage', '${(provider.batteryVoltage / 1000).toStringAsFixed(1)}V', Icons.bolt),
              _buildMiniStat('Health', provider.batteryHealth, Icons.favorite),
              _buildMiniStat('Tech', provider.batteryTechnology, Icons.memory),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSaverProfiles(CoolerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
          child: Text(
            'Power Saving Profiles',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            _buildProfileCard(provider, 'Normal', 'Standard power settings', Colors.blueAccent, Icons.bolt),
            const SizedBox(width: 10),
            _buildProfileCard(provider, 'Eco', 'Mute ringer, dim screen', Colors.cyanAccent, Icons.eco_outlined),
            const SizedBox(width: 10),
            _buildProfileCard(provider, 'Ultra', 'Dim screen, kill apps', Colors.redAccent, Icons.power_outlined),
          ],
        )
      ],
    );
  }

  Widget _buildProfileCard(CoolerProvider provider, String mode, String sub, Color accent, IconData icon) {
    final isSelected = provider.saverMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setSaverMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accent.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isSelected ? accent : Colors.white.withValues(alpha: 0.5), size: 24),
              const SizedBox(height: 12),
              Text(
                mode,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 9,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryDetails(CoolerProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Power Saver Diagnostics',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Active Profile', provider.saverMode, Icons.settings),
          _buildDetailRow('System Power Saver Mode', provider.isPowerSaveMode ? 'ON' : 'OFF', Icons.battery_saver),
          _buildDetailRow('Ringer Profile Mode', provider.ringerMode == 0 ? 'Silent' : (provider.ringerMode == 1 ? 'Vibrate' : 'Normal'), Icons.volume_up),
          _buildDetailRow('Battery Technology', provider.batteryTechnology, Icons.developer_board),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbles() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final random = Random();
        return Stack(
          children: List.generate(10, (index) {
            final double left = random.nextDouble() * constraints.maxWidth;
            final double durationSec = 2.0 + random.nextDouble() * 2.0;
            final double delaySec = random.nextDouble() * 2.0;
            final double size = 4.0 + random.nextDouble() * 6.0;

            return _Bubble(
              left: left,
              duration: Duration(milliseconds: (durationSec * 1000).toInt()),
              delay: Duration(milliseconds: (delaySec * 1000).toInt()),
              size: size,
              maxHeight: constraints.maxHeight,
            );
          }),
        );
      },
    );
  }
}

class _Bubble extends StatefulWidget {
  final double left;
  final Duration duration;
  final Duration delay;
  final double size;
  final double maxHeight;

  const _Bubble({
    required this.left,
    required this.duration,
    required this.delay,
    required this.size,
    required this.maxHeight,
  });

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with SingleTickerProviderStateMixin {
  late AnimationController _bubbleController;
  late Animation<double> _yAnimation;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _yAnimation = Tween<double>(begin: widget.maxHeight, end: -20.0).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _bubbleController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bubbleController,
      builder: (context, child) {
        return Positioned(
          left: widget.left,
          top: _yAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent.withValues(alpha: 0.35),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  final double fillLevel;
  final Color waveColor;

  WavePainter({
    required this.progress,
    required this.fillLevel,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final double waveHeight = 6.0; // wave amplitude
    final double targetY = size.height * (1.0 - fillLevel);

    path.moveTo(0, size.height);
    path.lineTo(0, targetY);

    for (double x = 0; x <= size.width; x++) {
      final double y = targetY +
          sin((x / size.width * 2 * pi) + (progress * 2 * pi)) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.fillLevel != fillLevel;
  }
}
