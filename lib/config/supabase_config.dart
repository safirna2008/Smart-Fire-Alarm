/// Konfigurasi Supabase untuk aplikasi Smart Fire Alarm.
/// Ganti 'xxx' dengan URL dan Anon Key proyek Supabase Anda.
class SupabaseConfig {
  static const String url = 'xxx';
  static const String anonKey = 'xxx';

  /// Cek apakah konfigurasi sudah diisi oleh pengguna
  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      url != 'xxx' &&
      anonKey != 'xxx';
}
