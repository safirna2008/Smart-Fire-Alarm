import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data_model.dart';
import '../utils/status_style.dart';
import 'glass_card.dart';
import 'led_indicator.dart';

/// Kartu "Status Ruangan" menampilkan kondisi saat ini, LED indikator 3 warna,
/// update timestamp, dan penyebab/pemicu status.
class StatusCard extends StatelessWidget {
  final SensorData data;

  const StatusCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final status = data.status.toLowerCase();
    final statusColor = StatusStyle.getStatusColor(status);
    final statusTitle = StatusStyle.getStatusTitle(status);
    final statusIcon = StatusStyle.getStatusIcon(status);

    final String formattedTime = DateFormat('HH:mm:ss').format(data.createdAt);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Kartu: Judul + Chip "Smart Guard"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Ruangan',
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
                    Icon(Icons.shield_outlined, size: 13, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 4),
                    const Text(
                      'Smart Guard',
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

          // Kotak Besar "KONDISI SAAT INI"
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: statusColor.withOpacity(0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'KONDISI SAAT INI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 36),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        statusTitle,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  StatusStyle.getStatusSubtitle(status),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 3 LED Bulat Indikator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                LedIndicator(
                  label: 'Aman',
                  activeColor: StatusStyle.safeGreen,
                  isActive: status == 'aman',
                ),
                LedIndicator(
                  label: 'Waspada',
                  activeColor: StatusStyle.warningAmber,
                  isActive: status == 'waspada',
                ),
                LedIndicator(
                  label: 'Bahaya',
                  activeColor: StatusStyle.dangerRed,
                  isActive: status == 'bahaya',
                  shouldBlink: status == 'bahaya',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.15), height: 1),
          const SizedBox(height: 14),

          // Footer: Waktu Update Terakhir & Keterangan Pemicu
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                'Update terakhir: $formattedTime',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  status == 'aman' ? Icons.check_circle_outline : Icons.info_outline,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.penyebabStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
