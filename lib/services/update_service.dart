import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

class UpdateInfo {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '1.0.0',
      versionCode: json['version_code'] ?? 1,
      downloadUrl: json['download_url'] ?? '',
      releaseNotes: json['release_notes'] ?? '',
    );
  }
}

class UpdateService extends ChangeNotifier {
  static const _channel = MethodChannel('com.cooler/thermal');
  static const _versionUrl =
      'https://raw.githubusercontent.com/levisbarua/mobile-cooler/main/version.json';

  UpdateInfo? _updateInfo;
  bool _isUpdateAvailable = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isReadyToInstall = false;
  String? _downloadedApkPath;
  String _statusText = '';

  UpdateInfo? get updateInfo => _updateInfo;
  bool get isUpdateAvailable => _isUpdateAvailable;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get isReadyToInstall => _isReadyToInstall;
  String get statusText => _statusText;

  /// Check GitHub for a newer version
  Future<void> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final info = UpdateInfo.fromJson(data);

        if (info.versionCode > currentBuildNumber) {
          _updateInfo = info;
          _isUpdateAvailable = true;
          _statusText = 'Update v${info.version} available!';
          if (kDebugMode) {
            print('Update available: ${info.version} (current: ${packageInfo.version})');
          }
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Update check failed: $e');
    }
  }

  /// Download the APK silently in the background
  Future<void> downloadUpdate() async {
    if (_updateInfo == null || _isDownloading) return;

    _isDownloading = true;
    _downloadProgress = 0.0;
    _isReadyToInstall = false;
    _statusText = 'Downloading update...';
    notifyListeners();

    try {
      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/cooler_update.apk';

      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_updateInfo!.downloadUrl));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      int downloadedBytes = 0;
      final sink = file.openWrite();
      
      final completer = Completer<void>();

      response.stream.listen(
        (chunk) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          if (totalBytes > 0) {
            _downloadProgress = downloadedBytes / totalBytes;
            _statusText = 'Downloading... ${(_downloadProgress * 100).toInt()}%';
            notifyListeners();
          }
        },
        onDone: () async {
          try {
            await sink.close();
            client.close();
            _downloadedApkPath = savePath;
            _isDownloading = false;
            _isReadyToInstall = true;
            _downloadProgress = 1.0;
            _statusText = 'Update ready to install!';
            notifyListeners();
            completer.complete();
          } catch (e) {
            completer.completeError(e);
          }
        },
        onError: (e) async {
          try {
            await sink.close();
            client.close();
          } catch (_) {}
          completer.completeError(e);
        },
        cancelOnError: true,
      );

      await completer.future;
    } catch (e) {
      _isDownloading = false;
      _isReadyToInstall = false;
      _statusText = 'Download failed: $e';
      notifyListeners();
    }
  }

  /// Launch the Android package installer for the downloaded APK
  Future<void> installUpdate() async {
    if (_downloadedApkPath == null || !_isReadyToInstall) return;
    try {
      await _channel.invokeMethod('installApk', {'path': _downloadedApkPath});
    } catch (e) {
      _statusText = 'Install failed: $e';
      if (kDebugMode) print('Install error: $e');
      notifyListeners();
    }
  }

  void dismissUpdate() {
    _isUpdateAvailable = false;
    _isReadyToInstall = false;
    _statusText = '';
    notifyListeners();
  }
}
