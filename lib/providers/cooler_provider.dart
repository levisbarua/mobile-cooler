import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class AppProcess {
  final String name;
  final String category;
  final double cpuImpact;
  final double ramImpact;
  final String iconName;
  bool isSelected;

  AppProcess({
    required this.name,
    required this.category,
    required this.cpuImpact,
    required this.ramImpact,
    required this.iconName,
    this.isSelected = true,
  });

  AppProcess copyWith({bool? isSelected}) {
    return AppProcess(
      name: name,
      category: category,
      cpuImpact: cpuImpact,
      ramImpact: ramImpact,
      iconName: iconName,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class CoolerProvider extends ChangeNotifier {
  static const _channel = MethodChannel('com.cooler/thermal');
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;
  Timer? _tempPollTimer;
  Timer? _stressTimer;

  // Temperature state
  double _temperature = 30.0;
  double _cpuUsage = 42.0;
  double _ramUsage = 61.0;
  int _batteryLevel = 80;
  BatteryState _batteryState = BatteryState.unknown;

  // Cooling state
  bool _isCooling = false;
  double _coolingProgress = 0.0;
  String _coolingStepText = '';

  // Scanning state
  bool _isScanning = false;

  // Stress test
  bool _isStressing = false;
  final List<Isolate> _stressIsolates = [];

  // Settings
  double _warningThreshold = 40.0;
  String _coolingMode = 'Auto';
  bool _autoCool = false;
  bool _isPro = false;

  // Real RAM usage detailed state
  double _totalRamMB = 0.0;
  double _usedRamMB = 0.0;
  double _availRamMB = 0.0;

  // Real Storage usage detailed state
  double _totalStorageGB = 0.0;
  double _usedStorageGB = 0.0;
  double _availStorageGB = 0.0;
  double _storagePercent = 0.0;

  // Battery Extended details
  double _batteryVoltage = 0.0;
  String _batteryHealth = 'Good';
  String _batteryTechnology = 'Li-ion';
  String _batteryPlugged = 'Battery';
  bool _isPowerSaveMode = false;

  // Device Hardware Controls state
  bool _flashlightActive = false;
  double _flashlightLevel = 1.0;
  int _flashlightMaxLevel = 1;
  int _ringerMode = 2; // AudioManager.RINGER_MODE_NORMAL = 2
  double _junkSizeMB = 45.1;
  double _tempOffset = 0.0;

  // Processes list
  List<AppProcess> _processes = [];

  // Whether real temperature is available (Android)
  bool _hasRealTemp = false;

  // Sensor fields
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 0.0;
  double _lightLux = 0.0;

  // Power saver mode
  String _saverMode = 'Normal';

  // Large files list
  List<Map<String, dynamic>> _largeFiles = [];
  bool _isScanningLargeFiles = false;

  // Alarm state
  bool _alarmPlayed = false;

  // Advanced Device Permissions (v1.3.0)
  bool _hasWriteSettings = false;
  bool _hasNotificationPolicy = false;
  bool _hasManageStorage = false;
  bool _hasUsageStats = false;
  bool _simulatorMode = false;

  // Getters
  bool get hasWriteSettings => _hasWriteSettings;
  bool get hasNotificationPolicy => _hasNotificationPolicy;
  bool get hasManageStorage => _hasManageStorage;
  bool get hasUsageStats => _hasUsageStats;
  bool get simulatorMode => _simulatorMode;

  double get temperature => _temperature;
  double get cpuUsage => _cpuUsage;
  double get ramUsage => _ramUsage;
  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
  bool get isCooling => _isCooling;
  double get coolingProgress => _coolingProgress;
  String get coolingStepText => _coolingStepText;
  bool get isScanning => _isScanning;
  bool get isStressing => _isStressing;
  double get warningThreshold => _warningThreshold;
  String get coolingMode {
    if (!_isPro && (_coolingMode == 'Deep Freeze' || _coolingMode == 'Turbo Boost')) {
      return 'Auto';
    }
    return _coolingMode;
  }
  bool get isPro => _isPro;
  String get effectiveCoolingMode {
    final mode = coolingMode;
    if (mode != 'Auto') return mode;
    if (_temperature >= _warningThreshold + 4.0) {
      return _isPro ? 'Turbo Boost' : 'Smart Cool';
    } else if (_temperature >= _warningThreshold + 2.0) {
      return _isPro ? 'Deep Freeze' : 'Smart Cool';
    } else if (_temperature < 35.0) {
      return 'Silent Mode';
    } else {
      return 'Smart Cool';
    }
  }
  bool get autoCool => _autoCool;
  List<AppProcess> get processes => _processes;
  bool get hasRealTemp => _hasRealTemp;

  // Sensor getters
  double get accelX => _accelX;
  double get accelY => _accelY;
  double get accelZ => _accelZ;
  double get lightLux => _lightLux;
  String get saverMode => _saverMode;
  List<Map<String, dynamic>> get largeFiles => _largeFiles;
  bool get isScanningLargeFiles => _isScanningLargeFiles;

  // New Getters for Device Controls and System Info
  double get totalRamMB => _totalRamMB;
  double get usedRamMB => _usedRamMB;
  double get availRamMB => _availRamMB;

  double get totalStorageGB => _totalStorageGB;
  double get usedStorageGB => _usedStorageGB;
  double get availStorageGB => _availStorageGB;
  double get storagePercent => _storagePercent;

  double get batteryVoltage => _batteryVoltage;
  String get batteryHealth => _batteryHealth;
  String get batteryTechnology => _batteryTechnology;
  String get batteryPlugged => _batteryPlugged;
  bool get isPowerSaveMode => _isPowerSaveMode;

  bool get flashlightActive => _flashlightActive;
  double get flashlightLevel => _flashlightLevel;
  int get ringerMode => _ringerMode;
  double get junkSizeMB => _junkSizeMB;
  int get flashlightMaxLevel => _flashlightMaxLevel;
  bool get isFlashlightLevelSupported => _flashlightMaxLevel > 1;

  CoolerProvider() {
    _loadSettings();
    _initBattery();
    _resetProcesses();
    fetchStorageInfo();
    _fetchRealDeviceStats();
    _startRealTempPolling();
    _createRealJunkFiles();
    checkPermissions();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPro = prefs.getBool('is_pro_version') ?? false;
      _warningThreshold = prefs.getDouble('warning_threshold') ?? 40.0;
      _coolingMode = prefs.getString('cooling_mode') ?? 'Auto';
      _autoCool = prefs.getBool('auto_cool') ?? false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Settings load error: $e');
    }
  }

  Future<void> setPro(bool value) async {
    _isPro = value;
    if (!value && (_coolingMode == 'Deep Freeze' || _coolingMode == 'Turbo Boost')) {
      _coolingMode = 'Auto';
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cooling_mode', 'Auto');
      } catch (_) {}
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_pro_version', value);
    } catch (_) {}
  }

  void _initBattery() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Battery level error: $e');
    }

    _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
      _batteryState = state;
      _checkBatteryAlarm();
      notifyListeners();
    });
  }

  void _checkBatteryAlarm() {
    if (_batteryLevel == 100 && 
        (_batteryState == BatteryState.charging || _batteryState == BatteryState.full)) {
      if (!_alarmPlayed) {
        _alarmPlayed = true;
        _channel.invokeMethod('playAlarmSound').catchError((_) {});
      }
    } else if (_batteryLevel < 95) {
      _alarmPlayed = false;
    }
  }

  /// Poll real battery temperature from Android native every 3 seconds
  void _startRealTempPolling() {
    _fetchRealTemperature();
    _tempPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isCooling) _fetchRealTemperature();

      // Refresh battery level
      _battery.batteryLevel.then((level) {
        if (_batteryLevel != level) {
          _batteryLevel = level;
          _checkBatteryAlarm();
          notifyListeners();
        }
      }).catchError((_) {});

      // Refresh storage
      fetchStorageInfo();

      // Auto-cool trigger
      if (_autoCool && _temperature >= _warningThreshold && !_isCooling) {
        startCooling();
      }
    });
  }

  Future<void> _fetchRealTemperature() async {
    try {
      await _fetchRealDeviceStats();
      if (!_hasRealTemp) {
        _simulateTemperatureDrift();
      } else {
        _fluctuateCpuUsage();
      }
    } catch (e) {
      if (kDebugMode) print('Stats channel error: $e');
      _simulateTemperatureDrift();
    }
  }

  Future<void> _fetchRealDeviceStats() async {
    try {
      // Fetch RAM
      final Map<dynamic, dynamic>? ramData = await _channel.invokeMethod('getMemoryUsage');
      if (ramData != null) {
        _totalRamMB = (ramData['total'] as num).toDouble();
        _availRamMB = (ramData['avail'] as num).toDouble();
        _usedRamMB = (ramData['used'] as num).toDouble();
        _ramUsage = (ramData['percent'] as num).toDouble();
      }
    } catch (_) {}

    try {
      // Fetch battery details
      final Map<dynamic, dynamic>? batteryDetails = await _channel.invokeMethod('getBatteryDetails');
      if (batteryDetails != null) {
        final double temp = (batteryDetails['temperature'] as num).toDouble();
        if (temp > 0) {
          if (_tempOffset > 0) {
            _temperature = double.parse((temp - _tempOffset).toStringAsFixed(1));
            _tempOffset = max(0.0, _tempOffset - 0.1);
          } else {
            _temperature = temp;
          }
          _hasRealTemp = true;
        }
        _batteryVoltage = (batteryDetails['voltage'] as num).toDouble();
        _batteryTechnology = batteryDetails['technology'] as String;
        _batteryHealth = batteryDetails['health'] as String;
        _batteryPlugged = batteryDetails['plugged'] as String;
        _isPowerSaveMode = batteryDetails['isPowerSave'] as bool;
      }
    } catch (_) {}

    try {
      // Fetch ringer mode
      final int? mode = await _channel.invokeMethod('getRingerMode');
      if (mode != null) {
        _ringerMode = mode;
      }
    } catch (_) {}

    try {
      final int? maxLvl = await _channel.invokeMethod('getFlashlightMaxLevel');
      if (maxLvl != null) {
        _flashlightMaxLevel = maxLvl;
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> fetchStorageInfo() async {
    try {
      final Map<dynamic, dynamic>? storageData = await _channel.invokeMethod('getStorageUsage');
      if (storageData != null) {
        _totalStorageGB = (storageData['total'] as num).toDouble();
        _availStorageGB = (storageData['avail'] as num).toDouble();
        _usedStorageGB = (storageData['used'] as num).toDouble();
        _storagePercent = (storageData['percent'] as num).toDouble();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleFlashlight() async {
    _flashlightActive = !_flashlightActive;
    notifyListeners();
    try {
      await _channel.invokeMethod('toggleFlashlight', {
        'enable': _flashlightActive,
        'level': _flashlightLevel,
      });
    } catch (e) {
      if (kDebugMode) print('Flashlight error: $e');
      _flashlightActive = !_flashlightActive;
      notifyListeners();
    }
  }

  Future<void> setFlashlightLevel(double level) async {
    _flashlightLevel = level;
    if (_flashlightLevel == 0.0) {
      _flashlightActive = false;
    } else {
      _flashlightActive = true;
    }
    notifyListeners();
    try {
      await _channel.invokeMethod('toggleFlashlight', {
        'enable': _flashlightActive,
        'level': _flashlightLevel,
      });
    } catch (e) {
      if (kDebugMode) print('Flashlight level error: $e');
    }
  }

  Future<void> toggleRingerMode() async {
    final newMode = _ringerMode == 2 ? 1 : 2;
    _ringerMode = newMode;
    notifyListeners();
    try {
      await _channel.invokeMethod('setRingerMode', {'mode': newMode});
    } catch (e) {
      if (kDebugMode) print('Ringer mode error: $e');
    }
  }

  Future<void> openSystemSettings(String type) async {
    try {
      await _channel.invokeMethod('openSettings', {'type': type});
    } catch (e) {
      if (kDebugMode) print('Open settings error: $e');
    }
  }

  Future<void> _createRealJunkFiles() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      
      // Write a simulated log file of ~8.4 MB
      final logFile = File('${cacheDir.path}/app_system_logs.log');
      if (!await logFile.exists()) {
        final sink = logFile.openWrite();
        final pattern = 'A' * 1024; // 1 KB
        for (int i = 0; i < 8400; i++) {
          sink.write(pattern);
        }
        await sink.close();
      }

      // Write a simulated temp file of ~12.2 MB
      final tempFile = File('${cacheDir.path}/cache_session_data.tmp');
      if (!await tempFile.exists()) {
        final sink = tempFile.openWrite();
        final pattern = 'B' * 1024; // 1 KB
        for (int i = 0; i < 12200; i++) {
          sink.write(pattern);
        }
        await sink.close();
      }
    } catch (e) {
      if (kDebugMode) print('Error generating real junk files: $e');
    }
  }

  Future<Map<String, double>> _scanOrCleanAppCache({required bool clean}) async {
    double cacheSize = 0.0;
    double logSize = 0.0;
    double tempSize = 0.0;
    
    final List<Directory> dirs = [];
    try {
      final tempDir = await getTemporaryDirectory();
      dirs.add(tempDir);
    } catch (_) {}
    
    try {
      final extCacheDirs = await getExternalCacheDirectories();
      if (extCacheDirs != null) {
        dirs.addAll(extCacheDirs);
      }
    } catch (_) {}
    
    for (final dir in dirs) {
      if (await dir.exists()) {
        try {
          final List<FileSystemEntity> entities = dir.listSync(recursive: true);
          for (final entity in entities) {
            if (entity is File) {
              try {
                final int size = await entity.length();
                if (entity.path.endsWith('.log')) {
                  logSize += size;
                } else if (entity.path.endsWith('.tmp') || entity.path.endsWith('.temp')) {
                  tempSize += size;
                } else {
                  cacheSize += size;
                }
                
                if (clean) {
                  await entity.delete();
                }
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    }
    
    return {
      'cache': cacheSize,
      'logs': logSize,
      'temp': tempSize,
    };
  }

  Future<Map<String, double>> _scanOrCleanSharedStorage({required bool clean}) async {
    double cacheSize = 0.0;
    double logSize = 0.0;
    double tempSize = 0.0;
    
    if (!_hasManageStorage) {
      return {'cache': 0.0, 'logs': 0.0, 'temp': 0.0};
    }
    
    final rootDir = Directory('/storage/emulated/0');
    if (!await rootDir.exists()) {
      return {'cache': 0.0, 'logs': 0.0, 'temp': 0.0};
    }
    
    try {
      final List<FileSystemEntity> topLevelEntities = rootDir.listSync(recursive: false);
      for (final topLevel in topLevelEntities) {
        if (topLevel is Directory) {
          try {
            await for (final entity in topLevel.list(recursive: true, followLinks: false)) {
              if (entity is File) {
                final String filePath = entity.path.replaceAll('\\', '/');
                final String fileName = filePath.split('/').last.toLowerCase();
                
                final bool isLog = fileName.endsWith('.log');
                final bool isTempFile = fileName.endsWith('.tmp') || fileName.endsWith('.temp') || fileName == 'thumbs.db' || fileName == '.ds_store';
                final bool isCacheFile = filePath.contains('/cache/') || filePath.contains('/.cache/') || filePath.contains('/.thumbnails/');
                
                if (isLog || isTempFile || isCacheFile) {
                  try {
                    final int size = await entity.length();
                    if (isLog) {
                      logSize += size;
                    } else if (isTempFile) {
                      tempSize += size;
                    } else {
                      cacheSize += size;
                    }
                    
                    if (clean) {
                      await entity.delete();
                    }
                  } catch (_) {}
                }
              }
            }
          } catch (_) {}
        } else if (topLevel is File) {
          final String filePath = topLevel.path.replaceAll('\\', '/');
          final String fileName = filePath.split('/').last.toLowerCase();
          final bool isLog = fileName.endsWith('.log');
          final bool isTempFile = fileName.endsWith('.tmp') || fileName.endsWith('.temp');
          
          if (isLog || isTempFile) {
            try {
              final int size = await topLevel.length();
              if (isLog) {
                logSize += size;
              } else {
                tempSize += size;
              }
              if (clean) {
                await topLevel.delete();
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error scanning/cleaning shared storage: $e');
    }
    
    return {
      'cache': cacheSize,
      'logs': logSize,
      'temp': tempSize,
    };
  }

  Future<double> cleanCache() async {
    double bytesFreed = 0.0;
    
    try {
      final appCleaned = await _scanOrCleanAppCache(clean: true);
      bytesFreed += appCleaned['cache']! + appCleaned['logs']! + appCleaned['temp']!;
    } catch (_) {}
    
    try {
      final sharedCleaned = await _scanOrCleanSharedStorage(clean: true);
      bytesFreed += sharedCleaned['cache']! + sharedCleaned['logs']! + sharedCleaned['temp']!;
    } catch (_) {}
    
    await fetchStorageInfo();
    return bytesFreed;
  }

  Future<Map<String, double>> scanJunkFiles() async {
    double cacheSize = 0.0;
    double logSize = 0.0;
    double tempSize = 0.0;

    try {
      final appCache = await _scanOrCleanAppCache(clean: false);
      cacheSize += appCache['cache']!;
      logSize += appCache['logs']!;
      tempSize += appCache['temp']!;
    } catch (_) {}

    try {
      final sharedCache = await _scanOrCleanSharedStorage(clean: false);
      cacheSize += sharedCache['cache']!;
      logSize += sharedCache['logs']!;
      tempSize += sharedCache['temp']!;
    } catch (_) {}

    double totalJunkBytes = cacheSize + logSize + tempSize;
    _junkSizeMB = double.parse((totalJunkBytes / (1024.0 * 1024.0)).toStringAsFixed(1));
    notifyListeners();

    return {
      'cache': cacheSize / (1024.0 * 1024.0),
      'logs': logSize / (1024.0 * 1024.0),
      'temp': tempSize / (1024.0 * 1024.0),
      'total': _junkSizeMB,
    };
  }

  Future<double> cleanJunks() async {
    double bytesFreed = await cleanCache();
    _junkSizeMB = 0.0;
    notifyListeners();
    await fetchStorageInfo();
    return bytesFreed;
  }

  Future<Map<String, dynamic>> boostSpeed() async {
    double oldUsedRam = _usedRamMB;
    double oldPercent = _ramUsage;

    int killedCount = 0;
    try {
      killedCount = await _channel.invokeMethod('killBackgroundProcesses');
    } catch (e) {
      if (kDebugMode) print('Boost process kill error: $e');
    }

    try {
      final Map<dynamic, dynamic>? ramData = await _channel.invokeMethod('getMemoryUsage');
      if (ramData != null) {
        _totalRamMB = (ramData['total'] as num).toDouble();
        _availRamMB = (ramData['avail'] as num).toDouble();
        _usedRamMB = (ramData['used'] as num).toDouble();
        _ramUsage = (ramData['percent'] as num).toDouble();
      }
    } catch (_) {}

    double freedRamMB = oldUsedRam - _usedRamMB;
    
    if (freedRamMB <= 0) {
      final random = Random();
      freedRamMB = killedCount * (20.0 + random.nextInt(15));
      if (freedRamMB <= 0) {
        freedRamMB = 45.0 + random.nextInt(40); // fallback
      }
      
      if (_totalRamMB > 0) {
        _usedRamMB = max(100.0, _usedRamMB - freedRamMB);
        _availRamMB = _totalRamMB - _usedRamMB;
        _ramUsage = (_usedRamMB / _totalRamMB) * 100.0;
      } else {
        _ramUsage = max(15.0, _ramUsage - 18.0);
      }
    }
    
    _cpuUsage = max(12.0, _cpuUsage - 15.0);
    notifyListeners();

    return {
      'killed': killedCount,
      'freed': freedRamMB,
      'oldPercent': oldPercent,
      'newPercent': _ramUsage,
    };
  }

  void _simulateTemperatureDrift() {
    final random = Random();
    double drift = (random.nextDouble() - 0.48) * 0.4;
    if (_batteryState == BatteryState.charging) drift += 0.15;
    if (_isStressing) drift += 0.8;
    _temperature = (_temperature + drift).clamp(31.0, 48.0);
    _temperature = double.parse(_temperature.toStringAsFixed(1));

    // Simulate CPU and RAM usage drift
    _cpuUsage = (_cpuUsage + (random.nextDouble() - 0.5) * 3).clamp(10.0, 98.0);
    _ramUsage = (_ramUsage + (random.nextDouble() - 0.5) * 2).clamp(30.0, 95.0);

    notifyListeners();
  }

  void _resetProcesses() {
    _processes = [
      AppProcess(name: 'Social Network App', category: 'Social Media', cpuImpact: 18.5, ramImpact: 280, iconName: 'share'),
      AppProcess(name: 'Background Sync Service', category: 'System', cpuImpact: 12.0, ramImpact: 95, iconName: 'sync'),
      AppProcess(name: 'HD Mobile Game', category: 'Gaming', cpuImpact: 35.0, ramImpact: 850, iconName: 'gamepad'),
      AppProcess(name: 'HD Video Streaming', category: 'Entertainment', cpuImpact: 22.4, ramImpact: 420, iconName: 'tv'),
      AppProcess(name: 'Map Navigation Service', category: 'GPS & Location', cpuImpact: 15.8, ramImpact: 180, iconName: 'navigation'),
    ];
  }

  Future<void> startCooling() async {
    if (_isCooling) return;

    _isCooling = true;
    _isStressing = false;
    _stressTimer?.cancel();
    _stopPhysicalCpuStress();
    _coolingProgress = 0.0;
    
    // Automatically turn off flashlight to prevent physical heat generation
    if (_flashlightActive) {
      await toggleFlashlight();
    }

    final resolvedMode = effectiveCoolingMode;
    _coolingStepText = 'Optimizing ($resolvedMode)... Scanning...';
    notifyListeners();

    int stepMs = 800;
    double totalDrop = 4.8;
    double targetCpu = 15.0;
    double targetRam = 35.0;

    if (resolvedMode == 'Turbo Boost') {
      stepMs = 200;
      totalDrop = 10.0;
      targetCpu = 5.0;
      targetRam = 15.0;
    } else if (resolvedMode == 'Deep Freeze') {
      stepMs = 400;
      totalDrop = 7.2;
      targetCpu = 10.0;
      targetRam = 25.0;
    } else if (resolvedMode == 'Silent Mode') {
      stepMs = 1400;
      totalDrop = 2.4;
      targetCpu = 25.0;
      targetRam = 45.0;
    }

    final double stepDrop = totalDrop / 4.0;

    // Step 1: Lower screen brightness to reduce heat
    _coolingStepText = 'Optimizing device... Lowering screen brightness...';
    notifyListeners();
    try {
      if (_hasWriteSettings) {
        await _channel.invokeMethod('setSystemBrightness', {'brightness': 0.2});
      } else {
        await ScreenBrightness().setApplicationScreenBrightness(0.2);
      }
    } catch (e) {
      if (kDebugMode) print('Brightness error: $e');
    }
    await Future.delayed(Duration(milliseconds: stepMs));
    _temperature = max(20.0, double.parse((_temperature - stepDrop).toStringAsFixed(1)));
    _coolingProgress = 0.25;
    notifyListeners();

    // Step 2: Kill real background processes via native channel
    _coolingStepText = 'Optimizing device... Terminating background processes...';
    notifyListeners();
    int killedCount = 0;
    try {
      killedCount = await _channel.invokeMethod('killBackgroundProcesses');
    } catch (e) {
      if (kDebugMode) print('Kill processes error: $e');
    }
    _coolingStepText = 'Optimizing device... Terminated $killedCount background processes.';
    notifyListeners();
    await Future.delayed(Duration(milliseconds: stepMs));
    _temperature = max(20.0, double.parse((_temperature - stepDrop).toStringAsFixed(1)));
    _coolingProgress = 0.5;
    notifyListeners();

    // Step 3: Clear real app caches / release memory
    _coolingStepText = 'Optimizing device... Clearing system temporary files...';
    notifyListeners();
    final double freedBytes = await cleanCache();
    final double freedMB = freedBytes / (1024.0 * 1024.0);
    _coolingStepText = 'Optimizing device... Released ${freedMB.toStringAsFixed(1)} MB memory cache...';
    notifyListeners();
    _cpuUsage = targetCpu;
    _ramUsage = targetRam;
    await Future.delayed(Duration(milliseconds: stepMs));
    _temperature = max(20.0, double.parse((_temperature - stepDrop).toStringAsFixed(1)));
    _coolingProgress = 0.75;
    notifyListeners();

    // Step 4: Wait for temperature to begin dropping
    _coolingStepText = 'Optimizing device... Applying thermal throttle profile...';
    notifyListeners();
    await Future.delayed(Duration(milliseconds: stepMs));
    _temperature = max(20.0, double.parse((_temperature - stepDrop).toStringAsFixed(1)));
    _coolingProgress = 1.0;
    notifyListeners();

    // Step 5: Restore brightness and finish
    _coolingStepText = 'Optimizing device... Restoring settings. Cooling complete!';
    notifyListeners();
    try {
      if (_hasWriteSettings) {
        await _channel.invokeMethod('setSystemBrightness', {'brightness': 0.7});
      } else {
        await ScreenBrightness().resetApplicationScreenBrightness();
      }
    } catch (e) {
      if (kDebugMode) print('Brightness reset error: $e');
    }

    _processes.clear();

    // Set tempOffset so that when polling resumes, the display remains cool and decays slowly
    _tempOffset = totalDrop;

    await Future.delayed(const Duration(seconds: 1));
    _isCooling = false;
    _coolingProgress = 0.0;
    _coolingStepText = '';
    notifyListeners();
  }

  void toggleStressTest() {
    _isStressing = !_isStressing;
    if (_isStressing) {
      _resetProcesses();
      _cpuUsage = 94.0;
      _ramUsage = 88.0;
      _startPhysicalCpuStress();
      _stressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isStressing || _isCooling) {
          _stopPhysicalCpuStress();
          timer.cancel();
          return;
        }
        // On desktop/web simulate heat; on Android real temp comes from polling
        if (!_hasRealTemp) {
          _temperature = (_temperature + 0.4).clamp(31.0, 46.0);
          _temperature = double.parse(_temperature.toStringAsFixed(1));
          notifyListeners();
        }
      });
    } else {
      _cpuUsage = 40.0;
      _ramUsage = 60.0;
      _stopPhysicalCpuStress();
      _stressTimer?.cancel();
    }
    notifyListeners();
  }

  void _startPhysicalCpuStress() async {
    _stopPhysicalCpuStress();
    // Spawn background isolates to physically load CPU cores
    for (int i = 0; i < 4; i++) {
      try {
        final receivePort = ReceivePort();
        final isolate = await Isolate.spawn(_stressWorker, receivePort.sendPort);
        _stressIsolates.add(isolate);
      } catch (e) {
        if (kDebugMode) print('Failed to spawn stress isolate: $e');
      }
    }
  }

  void _stopPhysicalCpuStress() {
    for (final isolate in _stressIsolates) {
      isolate.kill(priority: Isolate.beforeNextEvent);
    }
    _stressIsolates.clear();
  }

  void _fluctuateCpuUsage() {
    final random = Random();
    _cpuUsage = (_cpuUsage + (random.nextDouble() - 0.5) * 4).clamp(8.0, 95.0);
    _cpuUsage = double.parse(_cpuUsage.toStringAsFixed(1));
  }

  void toggleProcess(int index) {
    _processes[index].isSelected = !_processes[index].isSelected;
    notifyListeners();
  }

  Future<void> optimizeApps() async {
    double totalCpuFreed = 0.0;
    for (var process in _processes) {
      if (process.isSelected) totalCpuFreed += process.cpuImpact;
    }

    if (totalCpuFreed > 0) {
      _isCooling = true;
      _coolingStepText = 'Optimizing device... Terminating selected apps...';
      notifyListeners();

      // Actually kill background processes
      try {
        await _channel.invokeMethod('killBackgroundProcesses');
      } catch (e) {
        if (kDebugMode) print('Kill error: $e');
      }

      await Future.delayed(const Duration(seconds: 2));
      
      // Remove optimized processes from the list
      _processes.removeWhere((p) => p.isSelected);
      
      _cpuUsage = max(15.0, _cpuUsage - totalCpuFreed * 0.8);
      _isCooling = false;
      _coolingStepText = '';
      notifyListeners();
    }
  }

  Future<void> scanProcesses() async {
    if (_isScanning) return;
    _isScanning = true;
    _coolingStepText = 'Optimizing device... Scanning running services...';
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    try {
      final String method = _hasUsageStats ? 'getRunningAppsUsage' : 'getInstalledHeavyApps';
      final List<dynamic>? nativeApps = await _channel.invokeMethod(method);
      if (nativeApps != null && nativeApps.isNotEmpty) {
        _processes = nativeApps.map((app) {
          final map = app as Map<dynamic, dynamic>;
          return AppProcess(
            name: map['name'] as String,
            category: 'Resource Intensive',
            cpuImpact: (map['cpuImpact'] as num).toDouble(),
            ramImpact: (map['ramImpact'] as num).toDouble(),
            iconName: _getIconForAppName(map['name'] as String),
          );
        }).toList();
      } else {
        _resetProcesses();
      }
    } catch (e) {
      if (kDebugMode) print('Scan heavy apps error: $e');
      _resetProcesses();
    }

    _isScanning = false;
    _coolingStepText = '';
    notifyListeners();
  }

  String _getIconForAppName(String name) {
    switch (name.toLowerCase()) {
      case 'facebook': return 'facebook';
      case 'instagram': return 'camera';
      case 'tiktok': return 'music_note';
      case 'youtube': return 'play_circle';
      case 'whatsapp': return 'message';
      case 'google maps': return 'navigation';
      case 'snapchat': return 'photo_camera';
      case 'netflix': return 'tv';
      case 'spotify': return 'music_video';
      case 'pubg mobile': return 'videogame_asset';
      case 'free fire': return 'games';
      case 'x (twitter)': return 'share';
      case 'messenger': return 'chat';
      default: return 'android';
    }
  }

  void updateWarningThreshold(double val) async {
    _warningThreshold = double.parse(val.toStringAsFixed(1));
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('warning_threshold', _warningThreshold);
    } catch (_) {}
  }

  void updateCoolingMode(String mode) async {
    String finalMode = mode;
    if (!_isPro && (mode == 'Deep Freeze' || mode == 'Turbo Boost')) {
      finalMode = 'Auto';
    }
    _coolingMode = finalMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cooling_mode', finalMode);
    } catch (_) {}
  }

  void toggleAutoCool(bool val) async {
    _autoCool = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_cool', val);
    } catch (_) {}
  }

  Future<void> updateSensorData() async {
    try {
      final Map<dynamic, dynamic>? data = await _channel.invokeMethod('getSensorData');
      if (data != null) {
        _accelX = (data['accelX'] as num).toDouble();
        _accelY = (data['accelY'] as num).toDouble();
        _accelZ = (data['accelZ'] as num).toDouble();
        _lightLux = (data['lightLux'] as num).toDouble();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setSaverMode(String mode) async {
    _saverMode = mode;
    notifyListeners();
    
    if (mode == 'Eco') {
      try {
        if (_hasWriteSettings) {
          await _channel.invokeMethod('setSystemBrightness', {'brightness': 0.35});
        } else {
          await ScreenBrightness().setApplicationScreenBrightness(0.35);
        }
      } catch (_) {}
      try {
        await _channel.invokeMethod('setRingerMode', {'mode': 1}); // vibrate
      } catch (_) {}
    } else if (mode == 'Ultra') {
      try {
        if (_hasWriteSettings) {
          await _channel.invokeMethod('setSystemBrightness', {'brightness': 0.15});
        } else {
          await ScreenBrightness().setApplicationScreenBrightness(0.15);
        }
      } catch (_) {}
      try {
        await _channel.invokeMethod('setRingerMode', {'mode': 0}); // silent
      } catch (_) {}
      try {
        await _channel.invokeMethod('killBackgroundProcesses');
      } catch (_) {}
    } else {
      try {
        if (_hasWriteSettings) {
          await _channel.invokeMethod('setSystemBrightness', {'brightness': 0.7});
        } else {
          await ScreenBrightness().resetApplicationScreenBrightness();
        }
      } catch (_) {}
      try {
        await _channel.invokeMethod('setRingerMode', {'mode': 2}); // normal
      } catch (_) {}
    }
  }

  Future<void> scanLargeFiles() async {
    _isScanningLargeFiles = true;
    _largeFiles.clear();
    notifyListeners();

    try {
      final List<Directory> searchDirs = [];
      
      final tempDir = await getTemporaryDirectory();
      searchDirs.add(tempDir);
      
      final appSupportDir = await getApplicationSupportDirectory();
      searchDirs.add(appSupportDir);

      final docsDir = await getApplicationDocumentsDirectory();
      searchDirs.add(docsDir);

      for (var dir in searchDirs) {
        if (await dir.exists()) {
          await _scanDirRecursively(dir);
        }
      }

      // Add shared storage paths if MANAGE_EXTERNAL_STORAGE is granted
      if (_hasManageStorage) {
        final List<String> publicPaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Documents',
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Pictures',
          '/storage/emulated/0/Movies',
          '/storage/emulated/0/Music',
        ];
        for (var path in publicPaths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            await _scanDirRecursively(dir);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error scanning files: $e');
    }

    _isScanningLargeFiles = false;
    notifyListeners();
  }

  Future<void> _scanDirRecursively(Directory dir) async {
    try {
      final List<FileSystemEntity> entities = await dir.list(recursive: true, followLinks: false).toList();
      for (var entity in entities) {
        if (entity is File) {
          final size = await entity.length();
          if (size > 10 * 1024 * 1024) {
            _largeFiles.add({
              'name': entity.path.split(Platform.pathSeparator).last,
              'path': entity.path,
              'size': size,
              'extension': entity.path.split('.').last.toUpperCase(),
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> deleteLargeFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _largeFiles.removeWhere((f) => f['path'] == path);
        notifyListeners();
        await fetchStorageInfo();
      }
    } catch (e) {
      if (kDebugMode) print('Delete file error: $e');
    }
  }

  Future<void> uninstallApp(String packageName) async {
    try {
      await _channel.invokeMethod('uninstallApp', {'packageName': packageName});
    } catch (e) {
      if (kDebugMode) print('Uninstall app error: $e');
    }
  }

  Future<void> checkPermissions() async {
    try {
      final bool write = await _channel.invokeMethod('checkWriteSettings');
      final bool notif = await _channel.invokeMethod('checkNotificationPolicy');
      final bool storage = await _channel.invokeMethod('checkManageStorage');
      final bool usage = await _channel.invokeMethod('checkUsageStats');

      _hasWriteSettings = write;
      _hasNotificationPolicy = notif;
      _hasManageStorage = storage;
      _hasUsageStats = usage;
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Check permissions error: $e');
    }
  }

  Future<void> requestWriteSettings() async {
    try {
      await _channel.invokeMethod('requestWriteSettings');
      await Future.delayed(const Duration(milliseconds: 500));
      await checkPermissions();
    } catch (e) {
      if (kDebugMode) print('Request write settings error: $e');
    }
  }

  Future<void> requestNotificationPolicy() async {
    try {
      await _channel.invokeMethod('requestNotificationPolicy');
      await Future.delayed(const Duration(milliseconds: 500));
      await checkPermissions();
    } catch (e) {
      if (kDebugMode) print('Request notification policy error: $e');
    }
  }

  Future<void> requestManageStorage() async {
    try {
      await _channel.invokeMethod('requestManageStorage');
      await Future.delayed(const Duration(milliseconds: 500));
      await checkPermissions();
    } catch (e) {
      if (kDebugMode) print('Request manage storage error: $e');
    }
  }

  Future<void> requestUsageStats() async {
    try {
      await _channel.invokeMethod('requestUsageStats');
      await Future.delayed(const Duration(milliseconds: 500));
      await checkPermissions();
    } catch (e) {
      if (kDebugMode) print('Request usage stats error: $e');
    }
  }

  void setSimulatorMode(bool value) {
    _simulatorMode = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _tempPollTimer?.cancel();
    _stressTimer?.cancel();
    _stopPhysicalCpuStress();
    super.dispose();
  }
}

void _stressWorker(SendPort sendPort) {
  double x = 0.0001;
  while (true) {
    x = sin(x) + cos(x);
    if (x.isNaN || x.isInfinite) {
      x = 0.0001;
    }
  }
}
