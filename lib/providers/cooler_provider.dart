import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';

class AppProcess {
  final String name;
  final String category;
  final double cpuImpact; // Percentage
  final double ramImpact; // MB
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
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;

  // Real-time sensor / simulation states
  double _temperature = 34.2;
  double _cpuUsage = 42.0;
  double _ramUsage = 61.0;
  int _batteryLevel = 80;
  BatteryState _batteryState = BatteryState.unknown;

  // Cooling state
  bool _isCooling = false;
  double _coolingProgress = 0.0;
  String _coolingStepText = 'Initializing cooling system...';

  // Stress test state (simulates gaming/heavy tasks to test the app)
  bool _isStressing = false;
  Timer? _stressTimer;

  // History for charts
  final List<double> _tempHistory = [32.5, 33.0, 33.8, 34.5, 35.2, 34.8, 34.2];

  // Settings
  double _warningThreshold = 40.0;
  String _coolingMode = 'Deep Freeze'; // 'Smart Cool', 'Deep Freeze', 'Silent Mode'
  bool _autoCool = false;

  // List of running background processes
  List<AppProcess> _processes = [];

  // Log messages
  final List<String> _coolingLogs = [];

  // Getters
  double get temperature => _temperature;
  double get cpuUsage => _cpuUsage;
  double get ramUsage => _ramUsage;
  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
  bool get isCooling => _isCooling;
  double get coolingProgress => _coolingProgress;
  String get coolingStepText => _coolingStepText;
  bool get isStressing => _isStressing;
  List<double> get tempHistory => _tempHistory;
  double get warningThreshold => _warningThreshold;
  String get coolingMode => _coolingMode;
  bool get autoCool => _autoCool;
  List<AppProcess> get processes => _processes;
  List<String> get coolingLogs => _coolingLogs;

  CoolerProvider() {
    _initBattery();
    _resetProcesses();
    _startBackgroundTicker();
  }

  void _initBattery() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _batteryState = await _battery.onBatteryStateChanged.first;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Battery API error: $e');
    }

    _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
      _batteryState = state;
      // Charging heats up the battery
      if (state == BatteryState.charging && _temperature < 38.0) {
        _temperature += 1.5;
        _addLog('Device connected to charger. Temperature rising slightly.');
      }
      notifyListeners();
    });
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

  // A light background ticker to simulate ambient temperature drift
  void _startBackgroundTicker() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isCooling) return;

      // Read real battery level in background if possible
      _battery.batteryLevel.then((level) {
        if (_batteryLevel != level) {
          _batteryLevel = level;
          notifyListeners();
        }
      }).catchError((_) {});

      final random = Random();
      double drift = (random.nextDouble() - 0.48) * 0.4; // Slightly positive drift

      // If charging, tend to heat up
      if (_batteryState == BatteryState.charging) {
        drift += 0.15;
      }

      // If stressing, heat up significantly
      if (_isStressing) {
        drift += 0.8;
      }

      _temperature = double.parse((_temperature + drift).toStringAsFixed(1));
      
      // Bound temperatures realistically
      if (_temperature < 31.0) _temperature = 31.0;
      if (_temperature > 48.0) _temperature = 48.0;

      // Update history
      _tempHistory.add(_temperature);
      if (_tempHistory.length > 15) {
        _tempHistory.removeAt(0);
      }

      // Handle Auto Cooling if enabled
      if (_autoCool && _temperature >= _warningThreshold) {
        _addLog('Auto-cool triggered. Temperature (${_temperature}°C) exceeded threshold.');
        startCooling();
      }

      notifyListeners();
    });
  }

  // Start Cooling operation (visual flow + state reduction)
  void startCooling() {
    if (_isCooling) return;

    _isCooling = true;
    _isStressing = false;
    _coolingProgress = 0.0;
    _coolingStepText = 'Scanning running applications...';
    _addLog('Started manual cooling sequence in $coolingMode mode.');
    notifyListeners();

    int ticks = 40; // 5 ticks per second (200ms interval)
    int currentTick = 0;

    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      currentTick++;
      _coolingProgress = currentTick / ticks;

      if (currentTick <= 10) {
        _coolingStepText = 'Scanning CPU core frequencies...';
      } else if (currentTick <= 20) {
        _coolingStepText = 'Closing heavy background applications...';
      } else if (currentTick <= 30) {
        _coolingStepText = 'Purging cached application memory...';
        // Simulating clearing processes
        if (currentTick == 25) {
          _processes = _processes.map((p) => p.isSelected ? p.copyWith(isSelected: false) : p).toList();
        }
      } else if (currentTick <= 38) {
        _coolingStepText = 'Applying thermal cooling profile...';
      } else {
        _coolingStepText = 'Cooling complete! Temperature stabilized.';
      }

      // Dynamically drop temperature during cooling
      double tempDropScale = 0.0;
      if (_coolingMode == 'Smart Cool') {
        tempDropScale = 0.08;
      } else if (_coolingMode == 'Deep Freeze') {
        tempDropScale = 0.12;
      } else if (_coolingMode == 'Silent Mode') {
        tempDropScale = 0.05;
      }

      _temperature = double.parse((_temperature - tempDropScale).toStringAsFixed(1));
      if (_temperature < 32.5) _temperature = 32.5;

      // Drop CPU and RAM loads
      _cpuUsage = max(12.0, _cpuUsage - 1.2);
      _ramUsage = max(35.0, _ramUsage - 0.8);

      if (currentTick >= ticks) {
        timer.cancel();
        _isCooling = false;
        _coolingProgress = 0.0;
        _addLog('Cooling complete. Stabilized temperature at ${_temperature}°C.');
        _resetProcesses();
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  // Stress test: heats up the phone for demonstration purposes
  void toggleStressTest() {
    _isStressing = !_isStressing;
    if (_isStressing) {
      _addLog('Stress test started: Simulating high CPU load.');
      _cpuUsage = 94.0;
      _ramUsage = 88.0;
      // Faster temperature rise timer
      _stressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isStressing || _isCooling) {
          timer.cancel();
          return;
        }
        _temperature = double.parse((_temperature + 0.4).toStringAsFixed(1));
        if (_temperature > 46.0) _temperature = 46.0;
        notifyListeners();
      });
    } else {
      _addLog('Stress test stopped.');
      _cpuUsage = 40.0;
      _ramUsage = 60.0;
      _stressTimer?.cancel();
    }
    notifyListeners();
  }

  // Toggle app check status in the app optimizer list
  void toggleProcess(int index) {
    _processes[index].isSelected = !_processes[index].isSelected;
    notifyListeners();
  }

  // Optimize only the selected apps
  void optimizeApps() {
    double totalCpuFreed = 0.0;
    double totalRamFreed = 0.0;

    for (var process in _processes) {
      if (process.isSelected) {
        totalCpuFreed += process.cpuImpact;
        totalRamFreed += process.ramImpact;
      }
    }

    if (totalCpuFreed > 0) {
      _isCooling = true;
      _coolingStepText = 'Optimizing selected apps...';
      notifyListeners();

      Future.delayed(const Duration(seconds: 2), () {
        _processes = _processes.map((p) => p.isSelected ? p.copyWith(isSelected: false) : p).toList();
        _cpuUsage = max(15.0, _cpuUsage - totalCpuFreed * 0.8);
        _ramUsage = max(38.0, _ramUsage - (totalRamFreed / 10)); // simulated load drop
        _temperature = double.parse((_temperature - (totalCpuFreed * 0.05)).toStringAsFixed(1));
        if (_temperature < 32.5) _temperature = 32.5;

        _isCooling = false;
        _addLog('Optimized apps. Recovered CPU load: ${totalCpuFreed.toStringAsFixed(1)}%.');
        _resetProcesses();
        notifyListeners();
      });
    }
  }

  // Log updater helper
  void _addLog(String message) {
    final time = DateTime.now();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    _coolingLogs.insert(0, '[$timeStr] $message');
    if (_coolingLogs.length > 50) _coolingLogs.removeLast();
  }

  // Settings update
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
    _stressTimer?.cancel();
    super.dispose();
  }
}
