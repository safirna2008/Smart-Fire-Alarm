import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Indikator visual kipas exhaust yang berputar halus saat status ON dan diam saat OFF.
class FanIndicator extends StatefulWidget {
  final bool isOn;
  final double size;
  final Color activeColor;

  const FanIndicator({
    super.key,
    required this.isOn,
    this.size = 28.0,
    this.activeColor = const Color(0xFF38BDF8),
  });

  @override
  State<FanIndicator> createState() => _FanIndicatorState();
}

class _FanIndicatorState extends State<FanIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.isOn) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant FanIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isOn && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.isOn ? widget.activeColor : Colors.white.withOpacity(0.35);

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.isOn ? _rotationController.value * 2 * math.pi : 0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isOn ? widget.activeColor.withOpacity(0.15) : Colors.transparent,
              boxShadow: widget.isOn
                  ? [
                      BoxShadow(
                        color: widget.activeColor.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.mode_fan_off_rounded,
              size: widget.size * 0.85,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
