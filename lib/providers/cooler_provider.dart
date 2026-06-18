import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';

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
  String _coolingMode = 'Deep Freeze';
  bool _autoCool = false;

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
  bool get autoCool => _autoCool;
  List<AppProcess> get processes => _processes;
  bool get hasRealTemp => _hasRealTemp;

  CoolerProvider() {
    _initBattery();
    _resetProcesses();
    _startRealTempPolling();
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

      // Auto-cool trigger
      if (_autoCool && _temperature >= _warningThreshold && !_isCooling) {
        startCooling();
      }
    });
  }

  Future<void> _fetchRealTemperature() async {
    try {
      final double temp = await _channel.invokeMethod('getBatteryTemperature');
      if (temp > 0) {
        _hasRealTemp = true;
        _temperature = temp;

        // Simulate CPU / RAM drift alongside real temp
        final random = Random();
        _cpuUsage = (_cpuUsage + (random.nextDouble() - 0.5) * 3).clamp(10.0, 98.0);
        _ramUsage = (_ramUsage + (random.nextDouble() - 0.5) * 2).clamp(30.0, 95.0);

        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Temperature channel error: $e');
      // Fallback: simulate if real temp not available (web/desktop)
      _simulateTemperatureDrift();
    }
  }

  void _simulateTemperatureDrift() {
    final random = Random();
    double drift = (random.nextDouble() - 0.48) * 0.4;
    if (_batteryState == BatteryState.charging) drift += 0.15;
    if (_isStressing) drift += 0.8;
    _temperature = (_temperature + drift).clamp(31.0, 48.0);
    _temperature = double.parse(_temperature.toStringAsFixed(1));
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
    _coolingStepText = 'Optimizing device... Scanning processes...';
    notifyListeners();

    // Step 1: Lower screen brightness to reduce heat
    _coolingStepText = 'Optimizing device... Lowering screen brightness...';
    notifyListeners();
    try {
      await ScreenBrightness().setApplicationScreenBrightness(0.2);
    } catch (e) {
      if (kDebugMode) print('Brightness error: $e');
    }
    await Future.delayed(const Duration(milliseconds: 800));
    _coolingProgress = 0.25;

    // Step 2: Kill real background processes via native channel
    _coolingStepText = 'Optimizing device... Terminating background processes...';
    notifyListeners();
    int killedCount = 0;
    try {
      killedCount = await _channel.invokeMethod('killBackgroundProcesses');
    } catch (e) {
      if (kDebugMode) print('Kill processes error: $e');
    }
    await Future.delayed(const Duration(milliseconds: 800));
    _coolingProgress = 0.5;

    // Step 3: Simulate clearing app caches / throttling
    _coolingStepText = 'Optimizing device... Releasing memory ($killedCount cleared)...';
    notifyListeners();
    _cpuUsage = max(12.0, _cpuUsage - 30.0);
    _ramUsage = max(30.0, _ramUsage - 20.0);
    await Future.delayed(const Duration(milliseconds: 800));
    _coolingProgress = 0.75;

    // Step 4: Wait for temperature to begin dropping
    _coolingStepText = 'Optimizing device... Applying thermal throttle profile...';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    _coolingProgress = 1.0;

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

    _resetProcesses();
    _isScanning = false;
    _coolingStepText = '';
    notifyListeners();
  }

  void updateWarningThreshold(double val) {
    _warningThreshold = double.parse(val.toStringAsFixed(1));
    notifyListeners();
  }

  void updateCoolingMode(String mode) {
    _coolingMode = mode;
    notifyListeners();
  }

  void toggleAutoCool(bool val) {
    _autoCool = val;
    notifyListeners();
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _tempPollTimer?.cancel();
    _stressTimer?.cancel();
    super.dispose();
  }
}
