import 'dart:async';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/sensor_data_model.dart';

/// Service untuk komunikasi data sensor dengan Supabase Realtime & REST API.
/// Dilengkapi fallback data simulasi jika kredensial Supabase masih 'xxx'.
class SensorService {
  final SupabaseClient? _supabase;

  SensorService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? (SupabaseConfig.isConfigured ? Supabase.instance.client : null);

  /// Stream data sensor terbaru (1 record terakhir).
  Stream<SensorData> streamLatestData() {
    if (_supabase != null && SupabaseConfig.isConfigured) {
      try {
        return _supabase!
            .from('sensor_data')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .map((List<Map<String, dynamic>> rows) {
              if (rows.isNotEmpty) {
                return SensorData.fromJson(rows.first);
              }
              return _getFallbackData();
            })
            .handleError((error) {
              // Jika terjadi error koneksi realtime, beralih ke simulasi fallback
              return _createSimulatedStream();
            });
      } catch (_) {
        return _createSimulatedStream();
      }
    }
    return _createSimulatedStream();
  }

  /// Mengambil 20 data sensor terakhir untuk riwayat grafik (ascending)
  Future<List<SensorData>> fetchHistoryData() async {
    if (_supabase != null && SupabaseConfig.isConfigured) {
      try {
        final List<dynamic> response = await _supabase!
            .from('sensor_data')
            .select()
            .order('created_at', ascending: false)
            .limit(20);

        if (response.isNotEmpty) {
          final list = response
              .map((row) => SensorData.fromJson(row as Map<String, dynamic>))
              .toList();
          // Urutkan ascending agar grafik berjalan dari masa lalu ke saat ini
          return list.reversed.toList();
        }
      } catch (_) {
        // Fallback jika database belum ada atau terjadi error jaringan
      }
    }
    return _generateInitialHistory();
  }

  /// Mengambil hingga 500 baris terbaru dari sensor_data (order created_at desc) untuk tabel riwayat
  Future<List<SensorData>> fetchHistory({int limit = 500}) async {
    if (_supabase != null && SupabaseConfig.isConfigured) {
      try {
        final List<dynamic> response = await _supabase!
            .from('sensor_data')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);

        if (response.isNotEmpty) {
          return response
              .map((row) => SensorData.fromJson(row as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // Fallback jika database belum ada atau terjadi error jaringan
      }
    }
    return _generateExtendedHistory(limit);
  }

  /// Stream riwayat 20 data terakhir
  Stream<List<SensorData>> streamHistoryData() {
    if (_supabase != null && SupabaseConfig.isConfigured) {
      try {
        return _supabase!
            .from('sensor_data')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .limit(20)
            .map((List<Map<String, dynamic>> rows) {
              final list = rows.map((r) => SensorData.fromJson(r)).toList();
              return list.reversed.toList();
            })
            .handleError((_) => Stream.value(_generateInitialHistory()));
      } catch (_) {
        return Stream.value(_generateInitialHistory());
      }
    }
    return Stream.periodic(const Duration(seconds: 4), (_) => _generateSimulatedHistory());
  }

  // ==========================================
  // SIMULASI TELEMETRI UNTUK DEMO & TESTING
  // ==========================================
  static SensorData _getFallbackData() {
    return SensorData(
      id: 1,
      gas1: 145.0,
      gas2: 138.0,
      flame1: false,
      flame2: false,
      temp1: 28.5,
      temp2: 28.8,
      status: 'aman',
      buzzerOn: false,
      fanOn: false,
      createdAt: DateTime.now(),
    );
  }

  static final math.Random _random = math.Random();
  static double _currentGas1 = 150.0;
  static double _currentGas2 = 142.0;
  static double _currentTemp1 = 28.6;
  static double _currentTemp2 = 28.9;

  static Stream<SensorData> _createSimulatedStream() {
    return Stream.periodic(const Duration(seconds: 3), (count) {
      // Fluktuasi kecil normal
      _currentGas1 = (_currentGas1 + (_random.nextDouble() * 14 - 7)).clamp(50.0, 850.0);
      _currentGas2 = (_currentGas2 + (_random.nextDouble() * 12 - 6)).clamp(50.0, 850.0);
      _currentTemp1 = (_currentTemp1 + (_random.nextDouble() * 0.4 - 0.2)).clamp(20.0, 60.0);
      _currentTemp2 = (_currentTemp2 + (_random.nextDouble() * 0.4 - 0.2)).clamp(20.0, 60.0);

      const bool flame1 = false;
      const bool flame2 = false;

      final status = SensorThreshold.calculateStatus(
        gas1: _currentGas1,
        gas2: _currentGas2,
        flame1: flame1,
        flame2: flame2,
        temp1: _currentTemp1,
        temp2: _currentTemp2,
      );

      final bool buzzer = status == 'bahaya';
      final bool fan = status == 'bahaya' || status == 'waspada';

      return SensorData(
        id: count,
        gas1: double.parse(_currentGas1.toStringAsFixed(1)),
        gas2: double.parse(_currentGas2.toStringAsFixed(1)),
        flame1: flame1,
        flame2: flame2,
        temp1: double.parse(_currentTemp1.toStringAsFixed(1)),
        temp2: double.parse(_currentTemp2.toStringAsFixed(1)),
        status: status,
        buzzerOn: buzzer,
        fanOn: fan,
        createdAt: DateTime.now(),
      );
    });
  }

  static List<SensorData> _generateInitialHistory() {
    final now = DateTime.now();
    final List<SensorData> items = [];
    for (int i = 19; i >= 0; i--) {
      final time = now.subtract(Duration(minutes: i));
      final g1 = 120.0 + (i * 2.5) + (_random.nextDouble() * 10 - 5);
      final g2 = 115.0 + (i * 2.2) + (_random.nextDouble() * 8 - 4);
      final t1 = 27.5 + (i * 0.1) + (_random.nextDouble() * 0.2 - 0.1);
      final t2 = 27.8 + (i * 0.1) + (_random.nextDouble() * 0.2 - 0.1);
      items.add(
        SensorData(
          id: 100 - i,
          gas1: double.parse(g1.toStringAsFixed(1)),
          gas2: double.parse(g2.toStringAsFixed(1)),
          flame1: false,
          flame2: false,
          temp1: double.parse(t1.toStringAsFixed(1)),
          temp2: double.parse(t2.toStringAsFixed(1)),
          status: 'aman',
          buzzerOn: false,
          fanOn: false,
          createdAt: time,
        ),
      );
    }
    return items;
  }

  static List<SensorData> _generateSimulatedHistory() {
    return _generateInitialHistory();
  }

  static List<SensorData> _generateExtendedHistory(int limit) {
    final now = DateTime.now();
    final List<SensorData> items = [];
    final int count = limit > 60 ? 60 : limit;

    for (int i = 0; i < count; i++) {
      final time = now.subtract(Duration(minutes: i * 2));
      double g1 = 130.0 + (_random.nextDouble() * 30 - 15);
      double g2 = 125.0 + (_random.nextDouble() * 25 - 12);
      bool f1 = false;
      bool f2 = false;
      double t1 = 28.0 + (_random.nextDouble() * 2 - 1);
      double t2 = 28.3 + (_random.nextDouble() * 2 - 1);

      // Selipkan beberapa peristiwa waspada dan bahaya agar log bervariasi
      if (i >= 8 && i <= 11) {
        // Episode bahaya gas
        g1 = 540.0 + (i * 5);
        g2 = 490.0 + (i * 3);
      } else if (i >= 22 && i <= 24) {
        // Episode api IR
        f1 = true;
      } else if (i >= 35 && i <= 38) {
        // Episode waspada suhu
        t1 = 37.5;
        t2 = 36.8;
      } else if (i >= 48 && i <= 51) {
        // Episode waspada gas
        g2 = 380.0;
      }

      final st = SensorThreshold.calculateStatus(
        gas1: g1,
        gas2: g2,
        flame1: f1,
        flame2: f2,
        temp1: t1,
        temp2: t2,
      );

      final bool buzzer = st == 'bahaya';
      final bool fan = st == 'bahaya' || st == 'waspada';

      items.add(
        SensorData(
          id: 1000 - i,
          gas1: double.parse(g1.toStringAsFixed(1)),
          gas2: double.parse(g2.toStringAsFixed(1)),
          flame1: f1,
          flame2: f2,
          temp1: double.parse(t1.toStringAsFixed(1)),
          temp2: double.parse(t2.toStringAsFixed(1)),
          status: st,
          buzzerOn: buzzer,
          fanOn: fan,
          createdAt: time,
        ),
      );
    }
    return items;
  }
}
