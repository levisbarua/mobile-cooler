import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cooler_provider.dart';

class FanAnimator extends StatefulWidget {
  final double size;

  const FanAnimator({Key? key, this.size = 180.0}) : super(key: key);

  @override
  State<FanAnimator> createState() => _FanAnimatorState();
}

class _FanAnimatorState extends State<FanAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous rotation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // base speed
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoolerProvider>(
      builder: (context, provider, child) {
        // Adjust duration (speed) dynamically
        double speedFactor = 1.0;

        if (provider.isCooling) {
          // Spin based on selected cooling mode
          if (provider.coolingMode == 'Deep Freeze') {
            speedFactor = 12.0 - (provider.coolingProgress * 7.0); // starts ultra fast (12x), slows to 5x
          } else if (provider.coolingMode == 'Silent Mode') {
            speedFactor = 3.0 - (provider.coolingProgress * 1.8); // starts quiet (3x), slows to 1.2x
          } else {
            // Default or Smart Cool
            speedFactor = 8.0 - (provider.coolingProgress * 5.0); // starts fast (8x), slows to 3x
          }
        } else if (provider.isStressing) {
          // Rapid spin due to hot CPU
          speedFactor = 5.0;
        } else {
          // Spin based on current temp
          double temp = provider.temperature;
          if (temp > 40.0) {
            speedFactor = 4.0;
          } else if (temp > 35.0) {
            speedFactor = 2.0;
          } else {
            speedFactor = 0.8; // quiet mode
          }
        }

        // Apply speed scale by modifying the duration dynamically
        int baseMilliseconds = 3000;
        int targetMilliseconds = (baseMilliseconds / speedFactor).round();
        
        // Only update if change is significant to avoid stuttering
        if (_controller.duration?.inMilliseconds != targetMilliseconds) {
          _controller.duration = Duration(milliseconds: targetMilliseconds);
          if (_controller.isAnimating) {
            _controller.repeat();
          }
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glowing ring
            Container(
              width: widget.size + 15,
              height: widget.size + 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: provider.isCooling
                      ? Colors.cyan.withOpacity(0.3)
                      : (provider.temperature > 40.0
                          ? Colors.red.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.15)),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: provider.isCooling
                        ? Colors.cyan.withOpacity(0.25)
                        : (provider.temperature > 40.0
                            ? Colors.red.withOpacity(0.25)
                            : Colors.blue.withOpacity(0.1)),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            
            // Rotating fan body
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * pi,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: FanPainter(
                      color: provider.isCooling
                          ? Colors.cyan.shade300
                          : (provider.temperature > 40.0
                              ? Colors.red.shade400
                              : Colors.blue.shade300),
                    ),
                  ),
                );
              },
            ),

            // Inner fan grill lines (static, on top of blades)
            SizedBox(
              width: widget.size - 5,
              height: widget.size - 5,
              child: CustomPaint(
                painter: FanGrillPainter(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class FanPainter extends CustomPainter {
  final Color color;

  FanPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Center hub shadow and fill
    final hubPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.grey.shade700,
          Colors.grey.shade900,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.22))
      ..style = PaintingStyle.fill;
    
    // 2. Draw blades (5 blades)
    final numBlades = 5;
    final bladePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.95),
          color.withOpacity(0.35),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < numBlades; i++) {
      final angle = (i * 2 * pi / numBlades);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final bladePath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(radius * 0.15, -radius * 0.1, radius * 0.35, -radius * 0.35)
        ..cubicTo(radius * 0.75, -radius * 0.75, radius * 0.95, -radius * 0.45, radius * 0.9, -radius * 0.1)
        ..quadraticBezierTo(radius * 0.45, radius * 0.1, 0, 0)
        ..close();

      canvas.drawPath(bladePath, bladePaint);
      
      // Add a metallic highlight ridge line on the blade
      final ridgePaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      
      final ridgePath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(radius * 0.3, -radius * 0.2, radius * 0.75, -radius * 0.38);
      canvas.drawPath(ridgePath, ridgePaint);

      canvas.restore();
    }

    // 3. Draw metallic center hub
    canvas.drawCircle(center, radius * 0.22, hubPaint);
    
    // Core metallic cap ring
    final capPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.22, capPaint);
    
    // Small inner cap
    final innerCapPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.08, innerCapPaint);
  }

  @override
  bool shouldRepaint(covariant FanPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class FanGrillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final grillPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Outer ring
    canvas.drawCircle(center, radius, grillPaint);
    
    // Concentric grill rings
    canvas.drawCircle(center, radius * 0.75, grillPaint);
    canvas.drawCircle(center, radius * 0.5, grillPaint);

    // Radiating spokes
    final numSpokes = 8;
    for (int i = 0; i < numSpokes; i++) {
      final angle = i * 2 * pi / numSpokes;
      final start = Offset(
        center.dx + cos(angle) * (radius * 0.22),
        center.dy + sin(angle) * (radius * 0.22),
      );
      final end = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      canvas.drawLine(start, end, grillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
