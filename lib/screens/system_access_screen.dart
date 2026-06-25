import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cooler_provider.dart';

class SystemAccessScreen extends StatefulWidget {
  const SystemAccessScreen({super.key});

  @override
  State<SystemAccessScreen> createState() => _SystemAccessScreenState();
}

class _SystemAccessScreenState extends State<SystemAccessScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CoolerProvider>().checkPermissions();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned from settings, check status
      context.read<CoolerProvider>().checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CoolerProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          'System Access Control',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          key: const ValueKey('system_access_content'),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              Text(
                'ADVANCED SYSTEM PERMISSIONS',
                style: GoogleFonts.outfit(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              _buildPermissionTile(
                title: 'Modify System Settings',
                description: 'Allows Eco/Ultra charging profiles to adjust real phone brightness system-wide.',
                icon: Icons.brightness_medium_rounded,
                isGranted: provider.hasWriteSettings,
                onGrant: () => provider.requestWriteSettings(),
              ),
              _buildPermissionTile(
                title: 'Do Not Disturb Access',
                description: 'Allows changing volume/ringer modes programmatically to vibrate or silent.',
                icon: Icons.notifications_active_rounded,
                isGranted: provider.hasNotificationPolicy,
                onGrant: () => provider.requestNotificationPolicy(),
              ),
              _buildPermissionTile(
                title: 'All Files Storage Access',
                description: 'Allows recursively scanning shared directories (Downloads, DCIM) for files >10MB.',
                icon: Icons.folder_shared_rounded,
                isGranted: provider.hasManageStorage,
                onGrant: () => provider.requestManageStorage(),
              ),
              _buildPermissionTile(
                title: 'App Usage Statistics',
                description: 'Allows scanning and listing real active apps to optimize processes and RAM.',
                icon: Icons.analytics_rounded,
                isGranted: provider.hasUsageStats,
                onGrant: () => provider.requestUsageStats(),
              ),
              const SizedBox(height: 20),
              _buildSimulatorModeCard(provider),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.cyanAccent,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Device Access',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grant access settings below to enable full, real-time optimization. Safe, offline, and secure.',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[300],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onGrant,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate Card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? Colors.greenAccent.withOpacity(0.15) : Colors.amberAccent.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGranted ? Colors.greenAccent.withOpacity(0.08) : Colors.amberAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isGranted ? Colors.greenAccent : Colors.amberAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(isGranted),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[300],
                    fontSize: 13,
                  ),
                ),
                if (!isGranted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: onGrant,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(
                        'Grant Access',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isGranted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGranted ? Colors.greenAccent.withOpacity(0.12) : Colors.amberAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isGranted ? Colors.greenAccent : Colors.amberAccent,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isGranted ? 'GRANTED' : 'PENDING',
            style: GoogleFonts.outfit(
              color: isGranted ? Colors.greenAccent : Colors.amberAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorModeCard(CoolerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulation Fallback Mode',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fallback to simulated animations and settings if you choose not to grant system permissions.',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: provider.simulatorMode,
            onChanged: (val) => provider.setSimulatorMode(val),
            activeThumbColor: Colors.cyanAccent,
            activeTrackColor: Colors.cyan[900],
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}
