import 'package:flutter/material.dart';

/// Helper style & warna status sistem Smart Fire Alarm
class StatusStyle {
  static const Color safeGreen = Color(0xFF10B981);
  static const Color safeGreenLight = Color(0xFF34D399);
  static const Color safeGreenDark = Color(0xFF065F46);

  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberLight = Color(0xFFFBBF24);
  static const Color warningAmberDark = Color(0xFF78350F);

  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerRedLight = Color(0xFFF87171);
  static const Color dangerRedDark = Color(0xFF7F1D1D);

  // Gradient Background Sesuai Status
  static const List<Color> bgAman = [
    Color(0xFF2E3B55),
    Color(0xFF505C7B),
    Color(0xFF7C86A8),
  ];

  static const List<Color> bgWaspada = [
    Color(0xFF3B2E1E),
    Color(0xFF6B4D2C),
    Color(0xFF9E7745),
  ];

  static const List<Color> bgBahaya = [
    Color(0xFF45141C),
    Color(0xFF751E2B),
    Color(0xFFA63445),
  ];

  /// Mengambil palet gradien latar belakang berdasarkan status
  static List<Color> getBackgroundGradient(String status) {
    switch (status.toLowerCase()) {
      case 'bahaya':
        return bgBahaya;
      case 'waspada':
        return bgWaspada;
      case 'aman':
      default:
        return bgAman;
    }
  }

  /// Warna aksen utama berdasarkan status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'bahaya':
        return dangerRed;
      case 'waspada':
        return warningAmber;
      case 'aman':
      default:
        return safeGreen;
    }
  }

  /// Judul kondisi ruangan
  static String getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'bahaya':
        return 'SANGAT BAHAYA';
      case 'waspada':
        return 'WASPADA';
      case 'aman':
      default:
        return 'AMAN';
    }
  }

  /// Deskripsi singkat kondisi
  static String getStatusSubtitle(String status) {
    switch (status.toLowerCase()) {
      case 'bahaya':
        return 'Deteksi potensi kebakaran aktif! Evakuasi & periksa ruangan segera.';
      case 'waspada':
        return 'Anomali terdeteksi melebihi ambang batas normal. Tetap pantau.';
      case 'aman':
      default:
        return 'Kondisi ruangan stabil, tidak terdeteksi asap pekat atau api.';
    }
  }

  /// Ikon perisai status
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'bahaya':
        return Icons.warning_rounded;
      case 'waspada':
        return Icons.error_outline_rounded;
      case 'aman':
      default:
        return Icons.verified_user_rounded;
    }
  }

  /// Warna sensor gas berdasarkan nilai ppm (0-300: Hijau, 300-500: Kuning, >=500: Merah)
  static Color getGasColor(double ppm) {
    if (ppm >= 500) return dangerRed;
    if (ppm >= 300) return warningAmber;
    return safeGreen;
  }

  /// Teks kondisi sensor gas
  static String getGasCondition(double ppm) {
    if (ppm >= 500) return 'Bahaya';
    if (ppm >= 300) return 'Waspada';
    return 'Normal';
  }

  /// Warna sensor suhu berdasarkan °C (<35: Hijau, 35-45: Kuning, >=45: Merah)
  static Color getTempColor(double temp) {
    if (temp >= 45) return dangerRed;
    if (temp >= 35) return warningAmber;
    return safeGreen;
  }
}
