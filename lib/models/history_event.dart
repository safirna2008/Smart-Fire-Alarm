/// Model data untuk log perubahan status aktuator (Buzzer & Kipas) dan indikator LED.
/// Mencatat saat nilai berubah, pemicunya, dan durasi sebelum kondisi berganti lagi.
class HistoryEvent {
  final DateTime time;
  final String status; // Contoh: 'NYALA'/'MATI', 'ON'/'OFF', 'HIJAU'/'KUNING'/'MERAH'
  final String trigger; // Contoh: 'Gas Sensor 2 = 520 ppm', 'Api IR 1 terdeteksi', 'Kondisi normal'
  final String duration; // Contoh: '2 mnt 14 dtk' atau 'Sedang berlangsung'
  final Duration? durationValue; // Objek Duration numerik untuk menghitung agregasi total durasi
  final bool isActiveState; // True bila aktuator aktif (NYALA/ON) atau LED waspada/bahaya

  const HistoryEvent({
    required this.time,
    required this.status,
    required this.trigger,
    required this.duration,
    this.durationValue,
    this.isActiveState = false,
  });
}
