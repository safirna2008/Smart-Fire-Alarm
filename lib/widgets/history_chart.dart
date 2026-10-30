import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';

enum ChartMetric { gas, temp }

/// Grafik riwayat 20 data terakhir menggunakan fl_chart.
/// Menampilkan garis area Sensor 1 & Sensor 2, tab pemilihan metrik (Gas/Suhu),
/// penanda bulat titik terakhir, legenda, dan penanda waktu (-5 mnt lalu & Saat Ini).
class HistoryChart extends StatefulWidget {
  final List<SensorData> history;

  const HistoryChart({
    super.key,
    required this.history,
  });

  @override
  State<HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends State<HistoryChart> {
  ChartMetric _selectedMetric = ChartMetric.gas;

  @override
  Widget build(BuildContext context) {
    final List<SensorData> data = widget.history;
    final bool isGas = _selectedMetric == ChartMetric.gas;

    final Color line1Color = isGas ? const Color(0xFF38BDF8) : const Color(0xFF34D399);
    final Color line2Color = isGas ? const Color(0xFFFBBF24) : const Color(0xFFA78BFA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Riwayat: Judul, Legenda, & Tab Switcher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Telemetri',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
                Text(
                  '20 data terakhir',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),

            // Tab Switcher Gas vs Suhu
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
              ),
              child: Row(
                children: [
                  _buildTabButton('Gas (ppm)', ChartMetric.gas),
                  const SizedBox(width: 4),
                  _buildTabButton('Suhu (°C)', ChartMetric.temp),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Legenda Sensor 1 & Sensor 2
        Row(
          children: [
            _buildLegendItem('Sensor 1', line1Color),
            const SizedBox(width: 16),
            _buildLegendItem('Sensor 2', line2Color),
          ],
        ),

        const SizedBox(height: 12),

        // Area Grafik fl_chart
        SizedBox(
          height: 140,
          child: data.isEmpty
              ? Center(
                  child: Text(
                    'Menunggu data riwayat...',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                )
              : LineChart(
                  _buildChartData(data, isGas, line1Color, line2Color),
                  duration: const Duration(milliseconds: 300),
                ),
        ),

        const SizedBox(height: 6),

        // Label Waktu: "-5 mnt lalu" dan "Saat Ini"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '-5 mnt lalu',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
            Text(
              'Saat Ini',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, ChartMetric metric) {
    final bool isSelected = _selectedMetric == metric;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMetric = metric;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(
    List<SensorData> data,
    bool isGas,
    Color line1Color,
    Color line2Color,
  ) {
    final List<FlSpot> spots1 = [];
    final List<FlSpot> spots2 = [];

    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < data.length; i++) {
      final double x = i.toDouble();
      final double val1 = isGas ? data[i].gas1 : data[i].temp1;
      final double val2 = isGas ? data[i].gas2 : data[i].temp2;

      spots1.add(FlSpot(x, val1));
      spots2.add(FlSpot(x, val2));

      if (val1 < minY) minY = val1;
      if (val2 < minY) minY = val2;
      if (val1 > maxY) maxY = val1;
      if (val2 > maxY) maxY = val2;
    }

    if (minY == double.infinity) minY = 0;
    if (maxY == -double.infinity) maxY = isGas ? 300 : 50;

    final double paddingY = (maxY - minY) * 0.2;
    minY = (minY - paddingY).clamp(0.0, double.infinity);
    maxY = maxY + paddingY;

    final int lastIndex = data.length - 1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: isGas ? 100 : 10,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withOpacity(0.06),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: const FlTitlesData(
        show: false,
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (data.length - 1).toDouble().clamp(1.0, 19.0),
      minY: minY,
      maxY: maxY,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final String label = barSpot.barIndex == 0 ? 'Sensor 1' : 'Sensor 2';
              final String unit = isGas ? 'ppm' : '°C';
              return LineTooltipItem(
                '$label: ${barSpot.y.toStringAsFixed(1)} $unit',
                const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        // Garis Sensor 1
        LineChartBarData(
          spots: spots1,
          isCurved: true,
          curveSmoothness: 0.35,
          color: line1Color,
          barWidth: 2.2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, barData) => spot.x == lastIndex,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4.5,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: line1Color,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                line1Color.withOpacity(0.25),
                line1Color.withOpacity(0.0),
              ],
            ),
          ),
        ),

        // Garis Sensor 2
        LineChartBarData(
          spots: spots2,
          isCurved: true,
          curveSmoothness: 0.35,
          color: line2Color,
          barWidth: 2.2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, barData) => spot.x == lastIndex,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4.5,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: line2Color,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                line2Color.withOpacity(0.20),
                line2Color.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
