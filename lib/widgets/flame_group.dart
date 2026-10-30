import 'package:flutter/material.dart';

/// Grup sensor Api IR (Flame Sensor 1 dan Sensor 2).
/// Menampilkan 2 lingkaran ikon api berdampingan dengan animasi denyut merah saat api terdeteksi.
class FlameGroup extends StatefulWidget {
  final bool flame1;
  final bool flame2;

  const FlameGroup({
    super.key,
    required this.flame1,
    required this.flame2,
  });

  @override
  State<FlameGroup> createState() => _FlameGroupState();
}

class _FlameGroupState extends State<FlameGroup> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.flame1 || widget.flame2) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant FlameGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool anyFlame = widget.flame1 || widget.flame2;
    if (anyFlame && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!anyFlame && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.redAccent),
            ),
            const SizedBox(width: 8),
            const Text(
              'Deteksi Api (Infrared Flame)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
            const Spacer(),
            Text(
              'Digital IR',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2 Lingkaran Ikon Api Berdampingan
        Row(
          children: [
            Expanded(
              child: _buildFlameCard('Sensor 1', widget.flame1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFlameCard('Sensor 2', widget.flame2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlameCard(String label, bool isFlameDetected) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double scale = isFlameDetected ? _pulseAnimation.value : 1.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isFlameDetected ? const Color(0xFFEF4444).withOpacity(0.18) : Colors.black.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFlameDetected ? const Color(0xFFEF4444).withOpacity(0.6) : Colors.white.withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: isFlameDetected
                ? [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.35),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 10),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFlameDetected
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981).withOpacity(0.2),
                    boxShadow: isFlameDetected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.7),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isFlameDetected ? Icons.local_fire_department_rounded : Icons.check_circle_outline_rounded,
                    color: isFlameDetected ? Colors.white : const Color(0xFF34D399),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFlameDetected
                      ? const Color(0xFFEF4444).withOpacity(0.3)
                      : const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFlameDetected ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    width: 1,
                  ),
                ),
                child: Text(
                  isFlameDetected ? 'API TERDETEKSI' : 'AMAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isFlameDetected ? Colors.white : const Color(0xFF34D399),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
