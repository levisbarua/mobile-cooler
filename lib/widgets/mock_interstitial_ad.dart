import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_card.dart';

class MockInterstitialAdDialog extends StatefulWidget {
  const MockInterstitialAdDialog({super.key});

  @override
  State<MockInterstitialAdDialog> createState() => _MockInterstitialAdDialogState();
}

class _MockInterstitialAdDialogState extends State<MockInterstitialAdDialog> {
  int _countdown = 3;
  Timer? _timer;
  bool _canClose = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _canClose = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 20,
        borderColor: Colors.cyanAccent.withValues(alpha: 0.2),
        gradientColors: [
          const Color(0xFF0F1123).withValues(alpha: 0.95),
          const Color(0xFF090A15).withValues(alpha: 0.98),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    'SPONSORED SIMULATION',
                    style: GoogleFonts.outfit(
                      color: Colors.cyanAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _canClose
                    ? TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(
                          'Close',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Close in $_countdown...',
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 30),

            // Ad Visual Logo / Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.ac_unit_rounded,
                color: Colors.black,
                size: 40,
              ),
            ),
            const SizedBox(height: 25),

            // Promo Heading
            Text(
              'MOBILE COOLER PREMIUM',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock the Ultimate Cooling Suite',
              style: GoogleFonts.outfit(
                color: Colors.cyanAccent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 25),

            // Benefits list
            _buildBenefitRow(Icons.block, '100% Ad-Free Experience'),
            const SizedBox(height: 12),
            _buildBenefitRow(Icons.offline_bolt_rounded, 'Real-time CPU Temperature Monitor'),
            const SizedBox(height: 12),
            _buildBenefitRow(Icons.speed, 'Advanced 5-Stage Turbo Boost Cooling'),
            const SizedBox(height: 12),
            _buildBenefitRow(Icons.notifications_active, 'Intelligent Smart Guard Alerts'),
            
            const SizedBox(height: 30),

            // Action Button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF13152A),
                    content: Text(
                      'Upgrade to Premium features coming soon!',
                      style: GoogleFonts.outfit(color: Colors.cyanAccent),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                shadowColor: Colors.cyan.withValues(alpha: 0.3),
              ),
              child: Text(
                'UPGRADE NOW - \$1.99',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
