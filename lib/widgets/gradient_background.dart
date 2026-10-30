import 'package:flutter/material.dart';
import '../utils/status_style.dart';

/// Latar belakang aplikasi dengan efek gradien diagonal dinamis sesuai status,
/// serta beberapa ornamen lingkaran blur lembut di belakang kaca.
class GradientBackground extends StatelessWidget {
  final String status;
  final Widget child;

  const GradientBackground({
    super.key,
    required this.status,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = StatusStyle.getBackgroundGradient(status);

    Color orbColor1;
    Color orbColor2;
    Color orbColor3;

    switch (status.toLowerCase()) {
      case 'bahaya':
        orbColor1 = const Color(0xFFEF4444).withOpacity(0.25);
        orbColor2 = const Color(0xFFB91C1C).withOpacity(0.35);
        orbColor3 = const Color(0xFFF87171).withOpacity(0.18);
        break;
      case 'waspada':
        orbColor1 = const Color(0xFFF59E0B).withOpacity(0.22);
        orbColor2 = const Color(0xFFD97706).withOpacity(0.30);
        orbColor3 = const Color(0xFFFBBF24).withOpacity(0.18);
        break;
      case 'aman':
      default:
        orbColor1 = const Color(0xFF60A5FA).withOpacity(0.20);
        orbColor2 = const Color(0xFF818CF8).withOpacity(0.25);
        orbColor3 = const Color(0xFF38BDF8).withOpacity(0.18);
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Lingkaran blur dekoratif 1 (kiri atas)
          Positioned(
            top: -60,
            left: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    orbColor1,
                    orbColor1.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Lingkaran blur dekoratif 2 (kanan tengah)
          Positioned(
            top: 180,
            right: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    orbColor2,
                    orbColor2.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Lingkaran blur dekoratif 3 (bawah kiri)
          Positioned(
            bottom: -50,
            left: 100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    orbColor3,
                    orbColor3.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Konten Utama
          child,
        ],
      ),
    );
  }
}
