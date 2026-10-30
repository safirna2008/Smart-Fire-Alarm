import '../models/history_event.dart';
import '../models/sensor_data_model.dart';

/// Utilitas pembentuk log perubahan status (Buzzer, Kipas, dan LED Status)
/// Membandingkan baris berurutan secara kronologis untuk mencatat transisi status,
/// pemicu spesifik, dan durasi kondisi tersebut.
class HistoryBuilder {
  /// Format durasi ke format mudah dibaca, contoh: "2 mnt 14 dtk", "45 dtk", atau "1 jam 12 mnt"
  static String formatDuration(Duration d) {
    if (d.inSeconds < 60) {
      return '${d.inSeconds} dtk';
    } else if (d.inHours < 1) {
      final int mnt = d.inMinutes;
      final int dtk = d.inSeconds % 60;
      return dtk > 0 ? '$mnt mnt $dtk dtk' : '$mnt mnt';
    } else {
      final int jam = d.inHours;
      final int mnt = d.inMinutes % 60;
      return mnt > 0 ? '$jam jam $mnt mnt' : '$jam jam';
    }
  }

  /// Ekstraksi pemicu utama berdasarkan data sensor pada saat transisi
  static String extractTrigger(SensorData data, {required bool isDeactivation}) {
    if (isDeactivation) {
      return 'Kondisi ruangan kembali normal & aman';
    }

    if (data.flame1 && data.flame2) {
      return 'Api terdeteksi di Sensor 1 & 2';
    } else if (data.flame1) {
      return 'Api IR 1 terdeteksi';
    } else if (data.flame2) {
      return 'Api IR 2 terdeteksi';
    }

    if (data.gas1 >= 500) {
      return 'Gas Sensor 1 = ${data.gas1.toStringAsFixed(0)} ppm';
    }
    if (data.gas2 >= 500) {
      return 'Gas Sensor 2 = ${data.gas2.toStringAsFixed(0)} ppm';
    }

    if (data.temp1 >= 45) {
      return 'Suhu Sensor 1 = ${data.temp1.toStringAsFixed(1)} °C';
    }
    if (data.temp2 >= 45) {
      return 'Suhu Sensor 2 = ${data.temp2.toStringAsFixed(1)} °C';
    }

    if (data.gas1 >= 300) {
      return 'Gas Sensor 1 = ${data.gas1.toStringAsFixed(0)} ppm';
    }
    if (data.gas2 >= 300) {
      return 'Gas Sensor 2 = ${data.gas2.toStringAsFixed(0)} ppm';
    }

    if (data.temp1 >= 35) {
      return 'Suhu Sensor 1 = ${data.temp1.toStringAsFixed(1)} °C';
    }
    if (data.temp2 >= 35) {
      return 'Suhu Sensor 2 = ${data.temp2.toStringAsFixed(1)} °C';
    }

    return 'Ambang batas tercapai';
  }

  /// Membangun log riwayat perubahan status BUZZER ALARM (NYALA / MATI)
  static List<HistoryEvent> buildBuzzerHistory(List<SensorData> rawDescending) {
    if (rawDescending.isEmpty) return [];

    // Urutkan kronologis dari terlama ke terbaru untuk melacak perubahan
    final List<SensorData> chronological = rawDescending.reversed.toList();
    final List<_StateInterval<bool>> intervals = [];

    bool? currentVal;
    DateTime? startTime;
    SensorData? startData;

    for (int i = 0; i < chronological.length; i++) {
      final d = chronological[i];
      if (currentVal == null || d.buzzerOn != currentVal) {
        if (currentVal != null && startTime != null && startData != null) {
          intervals.add(_StateInterval(
            value: currentVal,
            startTime: startTime,
            endTime: d.createdAt,
            sampleData: startData,
          ));
        }
        currentVal = d.buzzerOn;
        startTime = d.createdAt;
        startData = d;
      }
    }

    // Interval terakhir yang masih aktif / berlangsung
    if (currentVal != null && startTime != null && startData != null) {
      intervals.add(_StateInterval(
        value: currentVal,
        startTime: startTime,
        endTime: null, // Masih berlangsung
        sampleData: startData,
      ));
    }

    // Ubah ke model HistoryEvent dan urutkan newest di atas (descending)
    final List<HistoryEvent> events = intervals.reversed.map((interval) {
      final bool isNyala = interval.value;
      final String statusStr = isNyala ? 'NYALA' : 'MATI';
      final String trigger = extractTrigger(interval.sampleData, isDeactivation: !isNyala);

      String durationStr;
      Duration? dur;
      if (interval.endTime == null) {
        durationStr = 'Sedang berlangsung';
      } else {
        dur = interval.endTime!.difference(interval.startTime);
        if (dur.isNegative) dur = Duration(seconds: dur.inSeconds.abs());
        durationStr = formatDuration(dur);
      }

      return HistoryEvent(
        time: interval.startTime,
        status: statusStr,
        trigger: trigger,
        duration: durationStr,
        durationValue: dur,
        isActiveState: isNyala,
      );
    }).toList();

    return events;
  }

  /// Membangun log riwayat perubahan status KIPAS EXHAUST (ON / OFF)
  static List<HistoryEvent> buildFanHistory(List<SensorData> rawDescending) {
    if (rawDescending.isEmpty) return [];

    final List<SensorData> chronological = rawDescending.reversed.toList();
    final List<_StateInterval<bool>> intervals = [];

    bool? currentVal;
    DateTime? startTime;
    SensorData? startData;

    for (int i = 0; i < chronological.length; i++) {
      final d = chronological[i];
      if (currentVal == null || d.fanOn != currentVal) {
        if (currentVal != null && startTime != null && startData != null) {
          intervals.add(_StateInterval(
            value: currentVal,
            startTime: startTime,
            endTime: d.createdAt,
            sampleData: startData,
          ));
        }
        currentVal = d.fanOn;
        startTime = d.createdAt;
        startData = d;
      }
    }

    if (currentVal != null && startTime != null && startData != null) {
      intervals.add(_StateInterval(
        value: currentVal,
        startTime: startTime,
        endTime: null,
        sampleData: startData,
      ));
    }

    final List<HistoryEvent> events = intervals.reversed.map((interval) {
      final bool isON = interval.value;
      final String statusStr = isON ? 'ON' : 'OFF';
      final String trigger = extractTrigger(interval.sampleData, isDeactivation: !isON);

      String durationStr;
      Duration? dur;
      if (interval.endTime == null) {
        durationStr = 'Sedang berlangsung';
      } else {
        dur = interval.endTime!.difference(interval.startTime);
        if (dur.isNegative) dur = Duration(seconds: dur.inSeconds.abs());
        durationStr = formatDuration(dur);
      }

      return HistoryEvent(
        time: interval.startTime,
        status: statusStr,
        trigger: trigger,
        duration: durationStr,
        durationValue: dur,
        isActiveState: isON,
      );
    }).toList();

    return events;
  }

  /// Membangun log riwayat perubahan status INDIKATOR LED (HIJAU / KUNING / MERAH)
  static List<HistoryEvent> buildLedHistory(List<SensorData> rawDescending) {
    if (rawDescending.isEmpty) return [];

    final List<SensorData> chronological = rawDescending.reversed.toList();
    final List<_StateInterval<String>> intervals = [];

    String? currentVal;
    DateTime? startTime;
    SensorData? startData;

    for (int i = 0; i < chronological.length; i++) {
      final d = chronological[i];
      final String st = d.status.toLowerCase();
      if (currentVal == null || st != currentVal) {
        if (currentVal != null && startTime != null && startData != null) {
          intervals.add(_StateInterval(
            value: currentVal,
            startTime: startTime,
            endTime: d.createdAt,
            sampleData: startData,
          ));
        }
        currentVal = st;
        startTime = d.createdAt;
        startData = d;
      }
    }

    if (currentVal != null && startTime != null && startData != null) {
      intervals.add(_StateInterval(
        value: currentVal,
        startTime: startTime,
        endTime: null,
        sampleData: startData,
      ));
    }

    final List<HistoryEvent> events = intervals.reversed.map((interval) {
      String statusStr;
      bool isActive = false;
      if (interval.value == 'bahaya') {
        statusStr = 'MERAH';
        isActive = true;
      } else if (interval.value == 'waspada') {
        statusStr = 'KUNING';
        isActive = true;
      } else {
        statusStr = 'HIJAU';
        isActive = false;
      }

      final String trigger = extractTrigger(interval.sampleData, isDeactivation: !isActive);

      String durationStr;
      Duration? dur;
      if (interval.endTime == null) {
        durationStr = 'Sedang berlangsung';
      } else {
        dur = interval.endTime!.difference(interval.startTime);
        if (dur.isNegative) dur = Duration(seconds: dur.inSeconds.abs());
        durationStr = formatDuration(dur);
      }

      return HistoryEvent(
        time: interval.startTime,
        status: statusStr,
        trigger: trigger,
        duration: durationStr,
        durationValue: dur,
        isActiveState: isActive,
      );
    }).toList();

    return events;
  }
}

class _StateInterval<T> {
  final T value;
  final DateTime startTime;
  final DateTime? endTime;
  final SensorData sampleData;

  _StateInterval({
    required this.value,
    required this.startTime,
    required this.endTime,
    required this.sampleData,
  });
}
