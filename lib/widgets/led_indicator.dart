import 'package:flutter/material.dart';

/// Indikator LED bulat dengan efek glow menyala dan animasi berkedip saat mode bahaya.
class LedIndicator extends StatefulWidget {
  final String label;
  final Color activeColor;
  final bool isActive;
  final bool shouldBlink;

  const LedIndicator({
    super.key,
    required this.label,
    required this.activeColor,
    required this.isActive,
    this.shouldBlink = false,
  });

  @override
  State<LedIndicator> createState() => _LedIndicatorState();
}

class _LedIndicatorState extends State<LedIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _opacityAnimation = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    if (widget.isActive && widget.shouldBlink) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LedIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && widget.shouldBlink) {
      if (!_blinkController.isAnimating) {
        _blinkController.repeat(reverse: true);
      }
    } else {
      _blinkController.stop();
      _blinkController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isActive;
    final Color color = widget.activeColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _blinkController,
          builder: (context, child) {
            final double glowOpacity = (widget.shouldBlink && active) ? _opacityAnimation.value : (active ? 1.0 : 0.2);

            return Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? color.withOpacity(glowOpacity) : Colors.white.withOpacity(0.15),
                border: Border.all(
                  color: active ? color : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.6 * glowOpacity),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: color.withOpacity(0.9 * glowOpacity),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
              ),
              child: active
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9 * glowOpacity),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : Colors.white.withOpacity(0.55),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
