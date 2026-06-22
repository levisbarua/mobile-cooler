import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cooler_provider.dart';
import '../widgets/glass_card.dart';

class HardwareDiagnosticsScreen extends StatefulWidget {
  const HardwareDiagnosticsScreen({super.key});

  @override
  State<HardwareDiagnosticsScreen> createState() => _HardwareDiagnosticsScreenState();
}

class _HardwareDiagnosticsScreenState extends State<HardwareDiagnosticsScreen> {
  Timer? _sensorTimer;

  @override
  void initState() {
    super.initState();
    // Fetch sensors at 150ms interval while the screen is visible
    final provider = context.read<CoolerProvider>();
    _sensorTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      provider.updateSensorData();
    });
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoolerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF090A15),
      body: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hardware Diagnostics',
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    // Diagnostics Intro Card
                    _buildIntroCard(),
                    const SizedBox(height: 25),

                    // Test Launch Cards
                    _buildTestLauncherCard(
                      title: 'Screen Pixel Test',
                      description: 'Cycle full-screen colors to locate dead pixels or screen burn-in.',
                      icon: Icons.aspect_ratio_rounded,
                      accent: Colors.cyanAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DeadPixelTestScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildTestLauncherCard(
                      title: 'Multi-Touch Tracer',
                      description: 'Verify digitizer accuracy by tracking multiple touch coordinate points simultaneously.',
                      icon: Icons.fingerprint_rounded,
                      accent: Colors.pinkAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MultiTouchTracerScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 25),

                    // Sensor Readings Panel
                    _buildSensorsPanel(provider),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Colors.cyanAccent, size: 38),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hardware Diagnostics',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Test hardware elements and read native sensor streams to evaluate device status.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTestLauncherCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorsPanel(CoolerProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Native Sensor Streams',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Accelerometer X Y Z
          Row(
            children: [
              const Icon(Icons.screen_rotation_rounded, size: 18, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              Text(
                'Accelerometer Tilt',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSensorAxisStat('X-Axis', '${provider.accelX.toStringAsFixed(2)} m/s²'),
              const SizedBox(width: 8),
              _buildSensorAxisStat('Y-Axis', '${provider.accelY.toStringAsFixed(2)} m/s²'),
              const SizedBox(width: 8),
              _buildSensorAxisStat('Z-Axis', '${provider.accelZ.toStringAsFixed(2)} m/s²'),
            ],
          ),
          const Divider(color: Colors.white10, height: 25),
          // Ambient Light sensor Lux
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, size: 18, color: Colors.amberAccent),
              const SizedBox(width: 8),
              Text(
                'Ambient Light Level',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${provider.lightLux.toStringAsFixed(0)} LUX',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (provider.lightLux / 1000.0).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
              minHeight: 6,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSensorAxisStat(String axis, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.015),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 1),
        ),
        child: Column(
          children: [
            Text(
              axis,
              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 4),
            Text(
              val,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );
  }
}

// 1. DEAD PIXEL TEST SCREEN
class DeadPixelTestScreen extends StatefulWidget {
  const DeadPixelTestScreen({super.key});

  @override
  State<DeadPixelTestScreen> createState() => _DeadPixelTestScreenState();
}

class _DeadPixelTestScreenState extends State<DeadPixelTestScreen> {
  final List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.black,
    Colors.white,
  ];
  int _colorIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_colorIndex < _colors.length - 1) {
            _colorIndex++;
          } else {
            Navigator.pop(context);
          }
        });
      },
      child: Scaffold(
        backgroundColor: _colors[_colorIndex],
        body: Stack(
          children: [
            if (_colorIndex == 0)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Text(
                    'Screen Pixel Check\nTap to cycle RGBW-Black colors.\nLook closely for dead pixels.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, height: 1.4),
                  ),
                ),
              ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. MULTI TOUCH TRACER SCREEN
class MultiTouchTracerScreen extends StatefulWidget {
  const MultiTouchTracerScreen({super.key});

  @override
  State<MultiTouchTracerScreen> createState() => _MultiTouchTracerScreenState();
}

class _MultiTouchTracerScreenState extends State<MultiTouchTracerScreen> {
  // Map of active pointers and their coordinates
  final Map<int, Offset> _pointerPositions = {};

  final List<Color> _pointerColors = [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.greenAccent,
    Colors.amberAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.blueAccent,
    Colors.redAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060B),
      body: Listener(
        onPointerDown: (event) {
          setState(() {
            _pointerPositions[event.pointer] = event.position;
          });
        },
        onPointerMove: (event) {
          setState(() {
            _pointerPositions[event.pointer] = event.position;
          });
        },
        onPointerUp: (event) {
          setState(() {
            _pointerPositions.remove(event.pointer);
          });
        },
        onPointerCancel: (event) {
          setState(() {
            _pointerPositions.remove(event.pointer);
          });
        },
        child: Stack(
          children: [
            // Instructions
            Center(
              child: Opacity(
                opacity: _pointerPositions.isEmpty ? 0.4 : 0.05,
                child: Text(
                  'Place multiple fingers on the screen\nto trace touch tracking accuracy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            // Custom Painter to draw trails
            CustomPaint(
              size: Size.infinite,
              painter: MultiTouchPainter(
                positions: _pointerPositions,
                colors: _pointerColors,
              ),
            ),
            // Close Button
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MultiTouchPainter extends CustomPainter {
  final Map<int, Offset> positions;
  final List<Color> colors;

  MultiTouchPainter({required this.positions, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    int colorIndex = 0;
    
    positions.forEach((pointerId, offset) {
      final paintColor = colors[colorIndex % colors.length];
      colorIndex++;

      // Glow effect paint
      final glowPaint = Paint()
        ..color = paintColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      // Core paint
      final corePaint = Paint()
        ..color = paintColor
        ..style = PaintingStyle.fill;

      // Coordinate lines paint
      final linePaint = Paint()
        ..color = paintColor.withValues(alpha: 0.1)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      // Draw horizontal & vertical crosshairs
      canvas.drawLine(Offset(0, offset.dy), Offset(size.width, offset.dy), linePaint);
      canvas.drawLine(Offset(offset.dx, 0), Offset(offset.dx, size.height), linePaint);

      // Draw glows and circles
      canvas.drawCircle(offset, 65, glowPaint);
      canvas.drawCircle(offset, 14, corePaint);
      
      // Draw touch coordinate text
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'P$pointerId (${offset.dx.toInt()}, ${offset.dy.toInt()})',
          style: GoogleFonts.outfit(
            color: paintColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(offset.dx + 20, offset.dy - 35));
    });
  }

  @override
  bool shouldRepaint(covariant MultiTouchPainter oldDelegate) {
    return true; // continuously repaint coordinates
  }
}
