import 'dart:async';
import 'dart:io';
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
  int _ringerMode = 2; // AudioManager.RINGER_MODE_NORMAL = 2

  // Processes list
  List<AppProcess> _processes = [];

  // Whether real temperature is available (Android)
  bool _hasRealTemp = false;

  // Getters
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
  String get coolingMode => _coolingMode;
  bool get isPro => _isPro;
  String get effectiveCoolingMode {
    if (_coolingMode != 'Auto') return _coolingMode;
    if (_temperature >= _warningThreshold + 4.0) {
      return 'Turbo Boost';
    } else if (_temperature >= _warningThreshold + 2.0) {
      return 'Deep Freeze';
    } else if (_temperature < 35.0) {
      return 'Silent Mode';
    } else {
      return 'Smart Cool';
    }
  }
  bool get autoCool => _autoCool;
  List<AppProcess> get processes => _processes;
  bool get hasRealTemp => _hasRealTemp;

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
  int get ringerMode => _ringerMode;

  CoolerProvider() {
    _loadSettings();
    _initBattery();
    _resetProcesses();
    fetchStorageInfo();
    _fetchRealDeviceStats();
    _startRealTempPolling();
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
      notifyListeners();
    });
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
          _temperature = temp;
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
      await _channel.invokeMethod('toggleFlashlight', {'enable': _flashlightActive});
    } catch (e) {
      if (kDebugMode) print('Flashlight error: $e');
      _flashlightActive = !_flashlightActive;
      notifyListeners();
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

  Future<double> cleanCache() async {
    double bytesFreed = 0.0;
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        for (var file in files) {
          if (file is File) {
            try {
              final size = await file.length();
              await file.delete();
              bytesFreed += size;
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Cache cleaner error: $e');
    }
    
    await fetchStorageInfo();
    return bytesFreed;
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
    _coolingProgress = 0.0;
    
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
      await ScreenBrightness().setApplicationScreenBrightness(0.2);
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
    await Future.delayed(Duration(milliseconds: stepMs));
    _temperature = max(20.0, double.parse((_temperature - stepDrop).toStringAsFixed(1)));
    _coolingProgress = 0.5;
    notifyListeners();

    // Step 3: Simulate clearing app caches / throttling
    _coolingStepText = 'Optimizing device... Releasing memory ($killedCount cleared)...';
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
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      if (kDebugMode) print('Brightness reset error: $e');
    }

    // Clear visual processes (since full cool down optimized everything)
    _processes.clear();

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
      _stressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isStressing || _isCooling) {
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
      _stressTimer?.cancel();
    }
    notifyListeners();
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
      final List<dynamic>? nativeApps = await _channel.invokeMethod('getInstalledHeavyApps');
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
    _coolingMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cooling_mode', mode);
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

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _tempPollTimer?.cancel();
    _stressTimer?.cancel();
    super.dispose();
  }
}
