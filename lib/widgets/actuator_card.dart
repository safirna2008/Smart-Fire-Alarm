import 'package:flutter/material.dart';
import 'glass_card.dart';
import 'fan_indicator.dart';

/// Kartu "Aktuator Otomatis" untuk menampilkan status Buzzer Alarm dan Kipas Exhaust.
/// Tampilan read-only (tidak dapat diklik manual, hanya mencerminkan perintah IoT).
class ActuatorCard extends StatefulWidget {
  final bool buzzerOn;
  final bool fanOn;

  const ActuatorCard({
    super.key,
    required this.buzzerOn,
    required this.fanOn,
  });

  @override
  State<ActuatorCard> createState() => _ActuatorCardState();
}

class _ActuatorCardState extends State<ActuatorCard> with SingleTickerProviderStateMixin {
  late AnimationController _soundWaveController;

  @override
  void initState() {
    super.initState();
    _soundWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.buzzerOn) {
      _soundWaveController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ActuatorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.buzzerOn && !_soundWaveController.isAnimating) {
      _soundWaveController.repeat(reverse: true);
    } else if (!widget.buzzerOn && _soundWaveController.isAnimating) {
      _soundWaveController.stop();
      _soundWaveController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _soundWaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Judul + Chip "Relay IoT"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktuator Otomatis',
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
                    Icon(Icons.bolt_rounded, size: 13, color: Colors.amber.shade300),
                    const SizedBox(width: 4),
                    const Text(
                      'Relay IoT',
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

          // Baris 1: Buzzer Alarm
          _buildActuatorRow(
            title: 'Buzzer Alarm',
            subtitle: widget.buzzerOn ? 'Sirine peringatan aktif bersuara' : 'Mode siaga nonaktif',
            leadingWidget: _buildBuzzerIcon(),
            statusLabel: widget.buzzerOn ? 'NYALA' : 'MATI',
            statusColor: widget.buzzerOn ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.35),
            badgeBgColor: widget.buzzerOn ? const Color(0xFFEF4444).withOpacity(0.25) : Colors.white.withOpacity(0.08),
            badgeBorderColor: widget.buzzerOn ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.2),
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 12),

          // Baris 2: Kipas Exhaust
          _buildActuatorRow(
            title: 'Kipas Exhaust',
            subtitle: widget.fanOn ? 'Membuang asap & gas keluar' : 'Mati / Siaga otomatis',
            leadingWidget: FanIndicator(
              isOn: widget.fanOn,
              size: 32,
              activeColor: const Color(0xFF38BDF8),
            ),
            statusLabel: widget.fanOn ? 'ON' : 'OFF',
            statusColor: widget.fanOn ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.35),
            badgeBgColor: widget.fanOn ? const Color(0xFF38BDF8).withOpacity(0.22) : Colors.white.withOpacity(0.08),
            badgeBorderColor: widget.fanOn ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildBuzzerIcon() {
    return AnimatedBuilder(
      animation: _soundWaveController,
      builder: (context, child) {
        final double scale = widget.buzzerOn ? 1.0 + (_soundWaveController.value * 0.18) : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.buzzerOn ? const Color(0xFFEF4444).withOpacity(0.25) : Colors.white.withOpacity(0.08),
              boxShadow: widget.buzzerOn
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.4 * _soundWaveController.value),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.buzzerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: widget.buzzerOn ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActuatorRow({
    required String title,
    required String subtitle,
    required Widget leadingWidget,
    required String statusLabel,
    required Color statusColor,
    required Color badgeBgColor,
    required Color badgeBorderColor,
  }) {
    return Row(
      children: [
        leadingWidget,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
        // Pil Status (Read-Only)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: badgeBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeBorderColor, width: 1.2),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusColor,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}
