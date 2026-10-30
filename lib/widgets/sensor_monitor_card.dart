import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';
import 'glass_card.dart';
import 'gas_group.dart';
import 'flame_group.dart';
import 'temp_group.dart';
import 'history_chart.dart';

/// Kartu besar "Monitoring Sensor" (chip "Telemetry Hub") yang memuat 3 grup sensor
/// (Gas MQ2, Api IR, Suhu DHT22) dan riwayat grafik 20 data terakhir di bagian bawah.
class SensorMonitorCard extends StatelessWidget {
  final SensorData latestData;
  final List<SensorData> history;

  const SensorMonitorCard({
    super.key,
    required this.latestData,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Kartu: Judul + Chip "Telemetry Hub"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monitoring Sensor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sensors_rounded, size: 13, color: Colors.cyanAccent.shade200),
                    const SizedBox(width: 4),
                    const Text(
                      'Telemetry Hub',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Grup 1: Gas MQ2 (Sensor 1 & Sensor 2)
          GasGroup(
            gas1: latestData.gas1,
            gas2: latestData.gas2,
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.12), height: 1),
          const SizedBox(height: 16),

          // Grup 2: Api IR (Sensor 1 & Sensor 2)
          FlameGroup(
            flame1: latestData.flame1,
            flame2: latestData.flame2,
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.12), height: 1),
          const SizedBox(height: 16),

          // Grup 3: Suhu DHT22 (Sensor 1 & Sensor 2)
          TempGroup(
            temp1: latestData.temp1,
            temp2: latestData.temp2,
          ),

          const SizedBox(height: 18),
          Divider(color: Colors.white.withOpacity(0.15), height: 1),
          const SizedBox(height: 16),

          // Bagian Bawah: Riwayat Grafik 20 Data Terakhir
          HistoryChart(
            history: history,
          ),
        ],
      ),
    );
  }
}
