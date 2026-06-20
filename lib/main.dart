import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/cooler_provider.dart';
import 'services/update_service.dart';
import 'services/ad_service.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CoolerProvider()),
        ChangeNotifierProvider(create: (_) => UpdateService()),
        ChangeNotifierProvider(create: (_) => AdService(), lazy: false),
      ],
      child: const MobileCoolerApp(),
    ),
  );
}

class MobileCoolerApp extends StatelessWidget {
  const MobileCoolerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Cooler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00F2FE),
        scaffoldBackgroundColor: const Color(0xFF090A15),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFF4FACFE),
          surface: Color(0xFF13152A),
          error: Color(0xFFFF4B5C),
        ),
        useMaterial3: true,
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    // Check for updates shortly after launch
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.read<UpdateService>().checkForUpdate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, child) {
        return Stack(
          children: [
            const DashboardScreen(),

            // Update Banner (shown when update is available or downloading)
            if (updateService.isUpdateAvailable || updateService.isDownloading || updateService.isReadyToInstall)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Material(
                  type: MaterialType.transparency,
                  child: _UpdateBanner(updateService: updateService),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  final UpdateService updateService;

  const _UpdateBanner({required this.updateService});

  @override
  Widget build(BuildContext context) {
    final info = updateService.updateInfo;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update_rounded, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        updateService.isReadyToInstall
                            ? 'Update Ready!'
                            : updateService.isDownloading
                                ? 'Downloading Update...'
                                : 'New Update Available',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (info != null && !updateService.isDownloading)
                        Text(
                          'v${info.version} — ${info.releaseNotes}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (updateService.isDownloading)
                        Text(
                          updateService.statusText,
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                // Dismiss button (only when not downloading)
                if (!updateService.isDownloading)
                  IconButton(
                    onPressed: updateService.dismissUpdate,
                    icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            // Download progress bar
            if (updateService.isDownloading) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: updateService.downloadProgress,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                  minHeight: 4,
                ),
              ),
            ],

            if (!updateService.isDownloading) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: updateService.isReadyToInstall
                      ? updateService.installUpdate
                      : updateService.downloadUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  child: Text(
                    updateService.isReadyToInstall ? 'TAP TO INSTALL NOW' : 'DOWNLOAD UPDATE',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
