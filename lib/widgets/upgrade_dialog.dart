import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cooler_provider.dart';
import '../services/ad_service.dart';
import 'glass_card.dart';

class UpgradeDialog extends StatelessWidget {
  const UpgradeDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const UpgradeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoolerProvider>();
    final adService = context.watch<AdService>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        borderColor: const Color(0xFFFFD700).withValues(alpha: 0.35), // Golden Border
        gradientColors: [
          const Color(0xFF1D1B0F).withValues(alpha: 0.96), // Gold-tinted dark background
          const Color(0xFF090A15).withValues(alpha: 0.98),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            // Crown Icon / Badge
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Gold to Orange gradient
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.black,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'MOBILE COOLER PRO',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unlock 24/7 Intelligent Thermal Control',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFFD700),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 25),

            // Benefits Grid
            _buildBenefitRow(Icons.block, '100% Ad-Free Experience', 'All banner and interstitial ads are removed.'),
            const SizedBox(height: 14),
            _buildBenefitRow(Icons.bolt, 'Turbo Boost & Deep Freeze', 'Unlock aggressive cooling profiles for heavy usage.'),
            const SizedBox(height: 14),
            _buildBenefitRow(Icons.security, 'Intelligent Auto-Cooling', 'Let Guard monitor and cool device in the background.'),
            const SizedBox(height: 14),
            _buildBenefitRow(Icons.notifications_active, 'Smart Temperature Alerts', 'Get instantly notified when CPU temp spikes.'),

            const SizedBox(height: 30),

            // Upgrade Button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF1D1B0F),
                    content: Text(
                      'Store purchase integration coming soon! Use the simulation button below to test Pro mode.',
                      style: TextStyle(color: Color(0xFFFFD700)),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.25),
              ),
              child: Text(
                'UNLOCK ALL FEATURES - \$1.99',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Simulate Purchase Option (For testing)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await provider.setPro(true);
                adService.updateProStatus(true);
                
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF13152A),
                      title: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFFFFD700)),
                          const SizedBox(width: 10),
                          Text(
                            'Premium Unlocked!',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Purchase simulation successful. Welcome to Mobile Cooler Premium Pro!',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('GET STARTED', style: TextStyle(color: Color(0xFFFFD700))),
                        ),
                      ],
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFD700).withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                'SIMULATE PRO PURCHASE (TESTING)',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFFFD700), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
