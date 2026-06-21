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
  String _statusText = 'Idle';

  UpdateInfo? get updateInfo => _updateInfo;
  bool get isUpdateAvailable => _isUpdateAvailable;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get isReadyToInstall => _isReadyToInstall;
  String get statusText => _statusText;

  void _setStatus(String status) {
    _statusText = status;
    debugPrint('UpdateService: $status');
    notifyListeners();
  }

  /// Check GitHub for a newer version
  Future<void> checkForUpdate() async {
    _setStatus('Checking for updates...');
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;
      _setStatus('Checking... Local Build: $currentBuildNumber');

      final cacheBusterUrl = '$_versionUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await http
          .get(Uri.parse(cacheBusterUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final info = UpdateInfo.fromJson(data);

        if (info.versionCode > currentBuildNumber) {
          _updateInfo = info;
          _isUpdateAvailable = true;
          _setStatus('Update v${info.version} available! (Remote Code: ${info.versionCode}, Local Code: $currentBuildNumber)');
        } else {
          _setStatus('Up to date (Remote Code: ${info.versionCode}, Local Code: $currentBuildNumber)');
        }
      } else {
        _setStatus('Check failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      _setStatus('Check failed: $e');
    }
  }

  /// Download the APK silently in the background
  Future<void> downloadUpdate() async {
    if (_updateInfo == null || _isDownloading) return;

    _isDownloading = true;
    _downloadProgress = 0.0;
    _isReadyToInstall = false;
    _setStatus('Downloading update...');

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

      late StreamSubscription<List<int>> subscription;
      subscription = response.stream.listen(
        (chunk) async {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          if (totalBytes > 0) {
            _downloadProgress = downloadedBytes / totalBytes;
            _setStatus('Downloading... ${(_downloadProgress * 100).toInt()}%');

            if (downloadedBytes >= totalBytes) {
              await subscription.cancel();
              if (!completer.isCompleted) {
                try {
                  await sink.close();
                  client.close();
                  _downloadedApkPath = savePath;
                  _isDownloading = false;
                  _isReadyToInstall = true;
                  _downloadProgress = 1.0;
                  _setStatus('Update ready to install!');
                  completer.complete();
                } catch (e) {
                  completer.completeError(e);
                }
              }
            }
          }
        },
        onDone: () async {
          if (!completer.isCompleted) {
            try {
              await sink.close();
              client.close();
              _downloadedApkPath = savePath;
              _isDownloading = false;
              _isReadyToInstall = true;
              _downloadProgress = 1.0;
              _setStatus('Update ready to install!');
              completer.complete();
            } catch (e) {
              completer.completeError(e);
            }
          }
        },
        onError: (e) async {
          if (!completer.isCompleted) {
            try {
              await sink.close();
              client.close();
            } catch (_) {}
            completer.completeError(e);
          }
        },
        cancelOnError: true,
      );

      await completer.future;
    } catch (e) {
      _isDownloading = false;
      _isReadyToInstall = false;
      _setStatus('Download failed: $e');
    }
  }

  /// Launch the Android package installer for the downloaded APK
  Future<void> installUpdate() async {
    if (_downloadedApkPath == null || !_isReadyToInstall) return;
    try {
      _setStatus('Installing update...');
      await _channel.invokeMethod('installApk', {'path': _downloadedApkPath});
    } catch (e) {
      _setStatus('Install failed: $e');
    }
  }

  void dismissUpdate() {
    _isUpdateAvailable = false;
    _isReadyToInstall = false;
    _setStatus('Dismissed');
  }
}
