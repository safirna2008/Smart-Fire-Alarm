import 'dart:ui';
import 'package:flutter/material.dart';

/// Komponen dasar GlassCard dengan efek glassmorphism:
/// BackdropFilter blur, semi-transparan, border tipis, dan bayangan lembut.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final BoxBorder? customBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 24.0,
    this.blurSigma = 16.0,
    this.backgroundColor,
    this.borderColor,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    // Kurangi blur sigma pada layar sempit / mobile untuk efisiensi render
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    final double effectiveBlur = isMobile ? 10.0 : blurSigma;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(borderRadius),
              border: customBorder ??
                  Border.all(
                    color: borderColor ?? Colors.white.withOpacity(0.20),
                    width: 1.0,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
