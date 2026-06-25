import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cooler_provider.dart';


class StorageManagerScreen extends StatefulWidget {
  const StorageManagerScreen({super.key});

  @override
  State<StorageManagerScreen> createState() => _StorageManagerScreenState();
}

class _StorageManagerScreenState extends State<StorageManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _heavyApps = [];
  bool _isLoadingApps = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Proactively scan files when entering
    final provider = context.read<CoolerProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.scanLargeFiles();
    });

    _loadHeavyApps();
  }

  Future<void> _loadHeavyApps() async {
    setState(() {
      _isLoadingApps = true;
    });
    try {

      
      final provider = Provider.of<CoolerProvider>(context, listen: false);
      final String method = provider.hasUsageStats ? 'getRunningAppsUsage' : 'getInstalledHeavyApps';
      final List<dynamic>? nativeApps = await const MethodChannel('com.cooler/thermal')
          .invokeMethod(method);
      
      if (nativeApps != null) {
        setState(() {
          _heavyApps = nativeApps.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
    setState(() {
      _isLoadingApps = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    final double mb = bytes / (1024 * 1024);
    if (mb > 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
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
              // Custom Header
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
                      'Storage Manager',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.cyanAccent,
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white38,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                dividerColor: Colors.white.withValues(alpha: 0.05),
                tabs: const [
                  Tab(text: 'LARGE FILES (>10MB)'),
                  Tab(text: 'INSTALLED APPS'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Large Files
                    _buildLargeFilesTab(provider),
                    // Tab 2: Apps Optimizer
                    _buildAppsTab(provider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeFilesTab(CoolerProvider provider) {
    if (provider.isScanningLargeFiles) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent)),
            SizedBox(height: 16),
            Text('Scanning storage directories...', style: TextStyle(color: Colors.white60)),
          ],
        ),
      );
    }

    final files = provider.largeFiles;

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_outlined, color: Colors.white30, size: 64),
            const SizedBox(height: 16),
            Text(
              'No files larger than 10MB found.',
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.cyanAccent.withValues(alpha: 0.02),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'Found ${files.length} heavy files. Deleting them will free disk space.',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        file['extension'] ?? 'FILE',
                        style: GoogleFonts.outfit(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatBytes(file['size'] as int),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteFile(provider, file['name'] as String, file['path'] as String),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppsTab(CoolerProvider provider) {
    if (_isLoadingApps) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent)),
      );
    }

    if (_heavyApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apps_outage_rounded, color: Colors.white30, size: 64),
            const SizedBox(height: 16),
            Text(
              'No heavy applications detected.',
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.pinkAccent.withValues(alpha: 0.02),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.pinkAccent, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Apps with high memory background activity. Tap to uninstall.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _heavyApps.length,
            itemBuilder: (context, index) {
              final app = _heavyApps[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _getIconData(app['name'] as String),
                        color: Colors.pinkAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app['name'] as String,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Impact: ${(app['cpuImpact'] as num).toStringAsFixed(1)}% CPU • ${(app['ramImpact'] as num).toStringAsFixed(0)}MB RAM',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () => provider.uninstallApp(app['package'] as String),
                      child: const Text('UNINSTALL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDeleteFile(CoolerProvider provider, String name, String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1020),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete File?', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text('Are you sure you want to permanently delete $name? This action cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white30)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteLargeFile(path);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'facebook': return Icons.facebook;
      case 'instagram': return Icons.camera_alt_outlined;
      case 'tiktok': return Icons.music_note_outlined;
      case 'youtube': return Icons.play_circle_fill_rounded;
      case 'whatsapp': return Icons.chat_rounded;
      case 'google maps': return Icons.map_outlined;
      case 'snapchat': return Icons.photo_camera_outlined;
      case 'netflix': return Icons.tv_rounded;
      case 'spotify': return Icons.music_note_rounded;
      default: return Icons.android_rounded;
    }
  }
}
