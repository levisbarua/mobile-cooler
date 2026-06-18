import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/cooler_provider.dart';

class TempChart extends StatelessWidget {
  const TempChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CoolerProvider>(
      builder: (context, provider, child) {
        final history = provider.tempHistory;
        if (history.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Generate coordinates
        final spots = <FlSpot>[];
        for (int i = 0; i < history.length; i++) {
          spots.add(FlSpot(i.toDouble(), history[i]));
        }

        // Auto-scale Y axis
        double minTemp = history.reduce(min);
        double maxTemp = history.reduce(max);
        
        // Pad Y axis slightly
        double minY = max(20.0, (minTemp - 1.5).floorToDouble());
        double maxY = (maxTemp + 1.5).ceilToDouble();

        // Ensure we have some range
        if (maxY - minY < 4.0) {
          minY = max(20.0, minY - 2.0);
          maxY = maxY + 2.0;
        }

        final isHot = provider.temperature >= 40.0;
        final latestColor = isHot
            ? Colors.redAccent.shade400
            : (provider.temperature >= 35.0
                ? Colors.orangeAccent
                : Colors.cyanAccent);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thermal History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: latestColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: latestColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: latestColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live Track',
                        style: TextStyle(
                          color: latestColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: 0,
                  maxX: (history.length - 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((maxY - minY) / 3).clamp(1.0, 10.0),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.04),
                        strokeWidth: 1.0,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: ((maxY - minY) / 3).clamp(1.0, 10.0),
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Text(
                              '${value.toInt()}°',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          latestColor,
                          latestColor.withOpacity(0.5),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          // Only draw a dot for the latest point
                          if (index == spots.length - 1) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: latestColor,
                              strokeColor: Colors.white,
                              strokeWidth: 2,
                            );
                          }
                          return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            latestColor.withOpacity(0.25),
                            latestColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
