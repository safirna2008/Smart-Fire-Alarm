# Smart Fire Alarm - Deteksi Kebakaran Dini Berbasis IoT

Aplikasi pemantauan realtime kebakaran dini untuk 1 ruangan dengan gaya tampilan **Smart Home Glass Dashboard (Glassmorphism)**, backend **Supabase Realtime**, dan multiplatform **Flutter Web & Android (HP)**.

---

## 📁 Struktur File Lengkap
```
lib/
├── main.dart                  # Inisialisasi Supabase, kunci portrait Android, MaterialApp
├── config/
│   └── supabase_config.dart   # URL & anonKey Supabase ('xxx')
├── models/
│   ├── sensor_data_model.dart # Model data, SensorThreshold, getters
│   └── history_event.dart     # Model log perubahan status (pemicu & durasi)
├── services/
│   └── sensor_service.dart    # Stream realtime, fetchHistoryData (20 baris), fetchHistory (500 baris)
├── utils/
│   ├── status_style.dart      # Palet warna, gradien status (Aman, Waspada, Bahaya), teks & ikon
│   └── history_builder.dart   # Ekstraktor transisi status Buzzer, Kipas, & LED beserta durasi
├── views/
│   ├── dashboard_view.dart    # Dashboard responsif dengan TopNav & switch tampilan
│   └── history_view.dart      # Halaman riwayat tabel per komponen (Gas, Flame, Temp, Buzzer, Fan, LED)
└── widgets/
    ├── top_nav.dart           # Menu tab chip horizontal bergaya kaca (scrollable di HP)
    ├── history_summary.dart   # 3 kotak ringkasan kecil bergaya kaca di atas tabel
    ├── history_table.dart     # Tabel riwayat serbaguna (pagination 10 baris, chip status, salin CSV)
    ├── glass_card.dart        # BackdropFilter blur (sigma 16/10), border 1px putih 20%, radius 24
    ├── gradient_background.dart # Gradien diagonal status + lingkaran blur lembut
    ├── status_card.dart       # Kotak kondisi saat ini, 3 LED bulat (Aman/Waspada/Bahaya), pemicu
    ├── led_indicator.dart     # Indikator LED dengan glow effect & animasi kedip pelan saat Bahaya
    ├── actuator_card.dart     # Baris Buzzer (sirine animasi) & Kipas Exhaust (read-only)
    ├── fan_indicator.dart     # Kipas berputar saat ON, berhenti saat OFF
    ├── sensor_monitor_card.dart # Kartu Telemetry Hub gabungan semua sensor + riwayat grafik
    ├── gas_group.dart         # Gas MQ2 (Sensor 1 & 2): angka ppm, gauge 3-zona (0-300, 300-500, 500-1000)
    ├── flame_group.dart       # Api IR (Sensor 1 & 2): 2 lingkaran berdampingan, animasi denyut merah
    ├── temp_group.dart        # Suhu DHT22 (Sensor 1 & 2): 2 angka °C besar berdampingan
    └── history_chart.dart     # Grafik garis area fl_chart (2 garis, tab Gas/Suhu, label waktu)

android/
└── app/src/main/AndroidManifest.xml # Izin INTERNET & portrait orientation lock

test/
└── widget_test.dart           # Unit test SensorThreshold, HistoryBuilder, & Widget smoke test

pubspec.yaml                   # Dependensi: supabase_flutter, fl_chart, intl, google_fonts
supabase_setup.sql             # Skrip SQL tabel, index, RLS aktif, policy SELECT/INSERT anon, & realtime publication
```

---

## 🗄️ Setup Database Supabase
Jalankan skrip `supabase_setup.sql` di SQL Editor Dashboard Supabase Anda:
1. Membuat tabel `sensor_data` (`id`, `gas1`, `gas2`, `flame1`, `flame2`, `temp1`, `temp2`, `status`, `buzzer_on`, `fan_on`, `created_at`).
2. Membuat index pada `created_at DESC`.
3. Mengaktifkan Row Level Security (RLS).
4. Menambahkan policy `SELECT` dan `INSERT` untuk role `anon` (tanpa autentikasi).
5. Mendaftarkan tabel ke publication `supabase_realtime`:
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE public.sensor_data;
   ```

---

## ⚙️ Konfigurasi Kredensial Supabase
Buka file `lib/config/supabase_config.dart` dan masukkan URL serta Anon Key Supabase Anda:
```dart
class SupabaseConfig {
  static const String url = 'https://your-project.supabase.co';
  static const String anonKey = 'your-anon-public-key';
}
```
*Catatan: Selama masih 'xxx', aplikasi otomatis menjalankan telemetri simulasi IoT secara aman tanpa error.*

---

## 🚀 Cara Menjalankan Aplikasi Flutter

### 1. Install Dependensi
```bash
flutter pub get
```

### 2. Jalankan di Web (Browser Chrome)
```bash
flutter run -d chrome
```

### 3. Jalankan di Android (HP)
Pastikan HP Android sudah terhubung via USB Debugging atau emulator berjalan:
```bash
flutter run
```

### 4. Build Release
```bash
# Build untuk Web Hosting
flutter build web

# Build APK Android Release
flutter build apk --release
```

---

## 🚨 Logika Sensor Threshold
- **Bahaya**: `flame1` atau `flame2` true, ATAU `gas1`/`gas2` >= 500 ppm, ATAU `temp1`/`temp2` >= 45 °C
- **Waspada**: `gas1`/`gas2` >= 300 ppm, ATAU `temp1`/`temp2` >= 35 °C
- **Aman**: Selain kondisi di atas
