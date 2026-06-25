import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/cooler_provider.dart';
import '../widgets/glass_card.dart';

class CpuMonitorScreen extends StatefulWidget {
  const CpuMonitorScreen({super.key});

  @override
  State<CpuMonitorScreen> createState() => _CpuMonitorScreenState();
}

class _CpuMonitorScreenState extends State<CpuMonitorScreen> {
  static const _channel = MethodChannel('com.cooler/thermal');

  final List<FlSpot> _tempSpots = [];
  Timer? _graphTimer;
  Timer? _coreTimer;
  double _timeCounter = 0;
  final List<double> _coreFrequencies = List.generate(8, (_) => 1.8);
  final List<int> _coreLoads = List.generate(8, (_) => 30);
  final _random = Random();
  int _numCores = 8;
  String _cpuModel = 'Qualcomm Snapdragon 8 Gen 2';

  Future<void> _loadCpuSpecs() async {
    try {
      final String? model = await _channel.invokeMethod<String>('getCpuModel');
      if (model != null && model.isNotEmpty) {
        setState(() {
          _cpuModel = model;
        });
      }
    } catch (e) {
      debugPrint('Error loading CPU model: $e');
    }

    try {
      final Map<dynamic, dynamic>? cpuInfo = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCpuInfo');
      if (cpuInfo != null) {
        final cores = cpuInfo['cores'];
        if (cores is int) {
          setState(() {
            _numCores = cores;
            if (_coreFrequencies.length != cores) {
              _coreFrequencies.clear();
              _coreFrequencies.addAll(List.generate(cores, (_) => 1.8));
              _coreLoads.clear();
              _coreLoads.addAll(List.generate(cores, (_) => 30));
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading CPU info: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCpuSpecs();
    // Initialize graph spots
    final provider = context.read<CoolerProvider>();
    for (int i = 9; i >= 0; i--) {
      _tempSpots.add(FlSpot(10.0 - i, provider.temperature));
    }
    _timeCounter = 10.0;
    
    // Set up a 1-second timer to update temperature chart
    _graphTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeCounter += 1.0;
          _tempSpots.add(FlSpot(_timeCounter, provider.temperature));
          if (_tempSpots.length > 15) {
            _tempSpots.removeAt(0);
          }
        });
      }
    });

    // Set up a 500ms timer to update core frequency indicators
    _coreTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          final isStressing = provider.isStressing;
          final isCooling = provider.isCooling;

          for (int i = 0; i < _numCores; i++) {
            if (isStressing) {
              _coreFrequencies[i] = 2.8 + _random.nextDouble() * 0.4; // near max
              _coreLoads[i] = 85 + _random.nextInt(15); // 85% to 100%
            } else if (isCooling) {
              _coreFrequencies[i] = 0.8 + _random.nextDouble() * 0.3; // throttled down
              _coreLoads[i] = 5 + _random.nextInt(10); // 5% to 15%
            } else {
              // Idle/Normal fluctuation
              final baseFreq = (i < 4) ? 1.6 : 2.2; // little vs big cores
              _coreFrequencies[i] = baseFreq + _random.nextDouble() * 0.6 - 0.3;
              _coreLoads[i] = (20 + _random.nextInt(40)).clamp(0, 100);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _graphTimer?.cancel();
    _coreTimer?.cancel();
    super.dispose();
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
              // Header
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
                      'CPU Monitor',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Core info card
                      _buildHardwareOverviewCard(provider),
                      const SizedBox(height: 20),
                      // Temperature Graph Card
                      _buildTempGraphCard(provider),
                      const SizedBox(height: 20),
                      // CPU Cores Grid
                      _buildCoresGrid(provider),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHardwareOverviewCard(CoolerProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.memory, color: Colors.cyanAccent, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cpuModel,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Architecture: ARM64-v8a • $_numCores Cores',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTempGraphCard(CoolerProvider provider) {
    final double currentTemp = provider.temperature;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thermal Core History',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${currentTemp.toStringAsFixed(1)}°C',
                style: GoogleFonts.outfit(
                  color: currentTemp > 40 ? Colors.redAccent : Colors.cyanAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 15.0,
                maxY: 55.0,
                minX: _tempSpots.isEmpty ? 0.0 : _tempSpots.first.x,
                maxX: _tempSpots.isEmpty ? 10.0 : _tempSpots.last.x,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 10,
                      getTitlesWidget: _leftTitleWidgets,
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _tempSpots,
                    isCurved: true,
                    barWidth: 2,
                    color: currentTemp > 40 ? Colors.redAccent : Colors.cyanAccent,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (currentTemp > 40 ? Colors.redAccent : Colors.cyanAccent)
                          .withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value % 10 != 0) return const SizedBox();
    return SideTitleWidget(
      meta: meta,
      child: Text(
        '${value.toInt()}°',
        style: const TextStyle(
          color: Colors.white30,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildCoresGrid(CoolerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Core Clock Speeds',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: _numCores,
          itemBuilder: (context, index) {
            final freq = _coreFrequencies[index];
            final load = _coreLoads[index];
            final isLittleCore = index < 4;
            final isHeavyUse = load > 75;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.025),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isHeavyUse 
                      ? Colors.redAccent.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.04),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CORE $index (${isLittleCore ? "L" : "B"})',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${freq.toStringAsFixed(2)} GHz',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isHeavyUse ? Colors.redAccent : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: load / 100.0,
                              strokeWidth: 3,
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                load > 75 ? Colors.redAccent : Colors.cyanAccent,
                              ),
                            ),
                            Text(
                              '$load%',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
