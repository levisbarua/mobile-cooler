import 'dart:io';
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
  
  List<Map<String, dynamic>> _userApps = [];
  List<Map<String, dynamic>> _systemApps = [];
  bool _isLoadingUserApps = false;
  bool _isLoadingSystemApps = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Proactively scan files when entering
    final provider = context.read<CoolerProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.scanLargeFiles();
    });

    _loadUserApps();
    _loadSystemApps();
  }

  Future<void> _loadUserApps() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUserApps = true;
    });
    try {
      final List<dynamic>? apps = await const MethodChannel('com.cooler/thermal')
          .invokeMethod('getInstalledApps', {'systemOnly': false});
      if (apps != null && mounted) {
        setState(() {
          _userApps = apps.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoadingUserApps = false;
      });
    }
  }

  Future<void> _loadSystemApps() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSystemApps = true;
    });
    try {
      final List<dynamic>? apps = await const MethodChannel('com.cooler/thermal')
          .invokeMethod('getInstalledApps', {'systemOnly': true});
      if (apps != null && mounted) {
        setState(() {
          _systemApps = apps.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoadingSystemApps = false;
      });
    }
  }

  Future<void> _openSystemAppDetails(String packageName) async {
    try {
      await const MethodChannel('com.cooler/thermal')
          .invokeMethod('openAppDetails', {'packageName': packageName});
    } catch (_) {}
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
              Colors.cyan.withOpacity(0.04),
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
                dividerColor: Colors.white.withOpacity(0.05),
                tabs: const [
                  Tab(text: 'LARGE FILES'),
                  Tab(text: 'USER APPS'),
                  Tab(text: 'SYSTEM APPS'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Large Files
                    _buildLargeFilesTab(provider),
                    // Tab 2: User Apps
                    _buildUserAppsTab(provider),
                    // Tab 3: System Apps
                    _buildSystemAppsTab(provider),
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
          color: Colors.cyanAccent.withOpacity(0.02),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'Found ${files.length} heavy files. Tap to preview and manage.',
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
              return GestureDetector(
                onTap: () => _showFilePreviewDialog(provider, file),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
                  ),
                  child: Row(
                    children: [
                      _buildFileThumbnail(file),
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
                                color: Colors.white.withOpacity(0.4),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileThumbnail(Map<String, dynamic> file) {
    final String path = file['path'] ?? '';
    final String ext = (file['extension'] as String? ?? 'FILE').toLowerCase();
    
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext);
    
    if (isImage && path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(path),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon(file['extension'] ?? 'FILE');
          },
        ),
      );
    }
    
    return _buildFallbackIcon(file['extension'] ?? 'FILE');
  }

  Widget _buildFallbackIcon(String extension) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        extension,
        style: GoogleFonts.outfit(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildUserAppsTab(CoolerProvider provider) {
    if (_isLoadingUserApps) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent)),
      );
    }

    if (_userApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apps_outage_rounded, color: Colors.white30, size: 64),
            const SizedBox(height: 16),
            Text(
              'No user applications detected.',
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
          color: Colors.pinkAccent.withOpacity(0.02),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.pinkAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'Found ${_userApps.length} user-installed apps. Tap to uninstall.',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _userApps.length,
            itemBuilder: (context, index) {
              final app = _userApps[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withOpacity(0.06),
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
                            'Package: ${app['package']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () async {
                        await provider.uninstallApp(app['package'] as String);
                        Future.delayed(const Duration(seconds: 3), () {
                          _loadUserApps();
                        });
                      },
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

  Widget _buildSystemAppsTab(CoolerProvider provider) {
    if (_isLoadingSystemApps) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent)),
      );
    }

    if (_systemApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apps_outage_rounded, color: Colors.white30, size: 64),
            const SizedBox(height: 16),
            Text(
              'No system applications detected.',
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
          color: Colors.orangeAccent.withOpacity(0.02),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'Found ${_systemApps.length} pre-installed system apps. Tap to configure.',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _systemApps.length,
            itemBuilder: (context, index) {
              final app = _systemApps[index];
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
                        color: Colors.orangeAccent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _getIconData(app['name'] as String),
                        color: Colors.orangeAccent,
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
                            'Package: ${app['package']}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent.withValues(alpha: 0.1),
                        foregroundColor: Colors.orangeAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.orangeAccent, width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () => _openSystemAppDetails(app['package'] as String),
                      child: const Text('MANAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  void _showFilePreviewDialog(CoolerProvider provider, Map<String, dynamic> file) {
    final String path = file['path'] ?? '';
    final String name = file['name'] ?? '';
    final String ext = (file['extension'] as String? ?? 'FILE').toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1020),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'File Details',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isImage && path.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    width: double.infinity,
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.white30, size: 50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Name:',
                style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Size:',
                style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatBytes(file['size'] as int),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Location:',
                style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                path,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white30)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context); // close preview
              _confirmDeleteFile(provider, name, path);
            },
            child: const Text('DELETE FILE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
