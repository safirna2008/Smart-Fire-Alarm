import 'package:flutter/material.dart';
import '../utils/status_style.dart';

/// Grup sensor suhu DHT22 (Sensor 1 dan Sensor 2).
/// Menampilkan 2 angka °C besar berdampingan dengan warna mengikuti level (hijau <35, kuning 35-45, merah >=45).
class TempGroup extends StatelessWidget {
  final double temp1;
  final double temp2;

  const TempGroup({
    super.key,
    required this.temp1,
    required this.temp2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul Grup
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.thermostat_rounded, size: 16, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 8),
            const Text(
              'Suhu Ruangan (DHT22)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
            const Spacer(),
            Text(
              'Ambang: 35° / 45°C',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2 Angka °C Besar Berdampingan
        Row(
          children: [
            Expanded(child: _buildTempCard('Sensor 1', temp1)),
            const SizedBox(width: 12),
            Expanded(child: _buildTempCard('Sensor 2', temp2)),
          ],
        ),
      ],
    );
  }

  Widget _buildTempCard(String label, double temp) {
    final Color color = StatusStyle.getTempColor(temp);

    String statusText = 'Normal';
    if (temp >= 45) {
      statusText = 'Bahaya';
    } else if (temp >= 35) {
      statusText = 'Waspada';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                temp.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '°C',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
