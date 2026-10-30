import 'package:flutter/material.dart';
import '../utils/status_style.dart';

/// Grup visual untuk 2 sensor gas MQ2 (Sensor 1 dan Sensor 2)
/// Dilengkapi angka ppm besar, label kondisi, dan bar horizontal berzona 0-300, 300-500, 500-1000 dengan penanda titik putih.
class GasGroup extends StatelessWidget {
  final double gas1;
  final double gas2;

  const GasGroup({
    super.key,
    required this.gas1,
    required this.gas2,
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
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_queue_rounded, size: 16, color: Colors.amberAccent),
            ),
            const SizedBox(width: 8),
            const Text(
              'Gas & Asap (MQ2)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
            const Spacer(),
            Text(
              'Satuan: ppm',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Baris Sensor 1
        _buildGasRow('Sensor 1', gas1),

        const SizedBox(height: 12),

        // Baris Sensor 2
        _buildGasRow('Sensor 2', gas2),
      ],
    );
  }

  Widget _buildGasRow(String label, double ppm) {
    final Color color = StatusStyle.getGasColor(ppm);
    final String condition = StatusStyle.getGasCondition(ppm);
    // Normalisasi nilai 0 - 1000 ppm
    final double clampedPpm = ppm.clamp(0.0, 1000.0);
    final double percent = clampedPpm / 1000.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.5), width: 1),
                    ),
                    child: Text(
                      condition,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    ppm.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'ppm',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Horizontal Gauge Bar berzona: 0-300 Hijau, 300-500 Kuning, 500-1000 Merah
          LayoutBuilder(
            builder: (context, constraints) {
              final double barWidth = constraints.maxWidth;
              // Batas posisi titik putih
              final double pointerX = (barWidth * percent).clamp(6.0, barWidth - 6.0);

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Latar Belakang Zona Berwarna (0-300=30%, 300-500=20%, 500-1000=50%)
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white.withOpacity(0.08),
                    ),
                    child: Row(
                      children: [
                        // Zona Hijau (0 - 300 ppm) = 30%
                        Expanded(
                          flex: 30,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                            ),
                          ),
                        ),
                        // Zona Kuning (300 - 500 ppm) = 20%
                        Expanded(
                          flex: 20,
                          child: Container(
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        // Zona Merah (500 - 1000 ppm) = 50%
                        Expanded(
                          flex: 50,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Penanda Titik Putih Posisi Saat Ini
                  Positioned(
                    left: pointerX - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black45, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          // Label rentang zona
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
              Text('300', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
              Text('500', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
              Text('1000 ppm', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
            ],
          ),
        ],
      ),
    );
  }
}
