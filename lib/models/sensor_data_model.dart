import 'dart:math' as math;

/// Standar ambang batas sensor untuk klasifikasi status kebakaran
class SensorThreshold {
  static const double gasWaspada = 300.0;
  static const double gasBahaya = 500.0;
  static const double gasMaxScale = 1000.0;

  static const double tempWaspada = 35.0;
  static const double tempBahaya = 45.0;
  static const double tempMaxScale = 80.0;

  /// Menghitung status berdasarkan nilai terburuk dari semua sensor
  static String calculateStatus({
    required double gas1,
    required double gas2,
    required bool flame1,
    required bool flame2,
    required double temp1,
    required double temp2,
  }) {
    if (flame1 || flame2 || gas1 >= gasBahaya || gas2 >= gasBahaya || temp1 >= tempBahaya || temp2 >= tempBahaya) {
      return 'bahaya';
    }
    if (gas1 >= gasWaspada || gas2 >= gasWaspada || temp1 >= tempWaspada || temp2 >= tempWaspada) {
      return 'waspada';
    }
    return 'aman';
  }
}

/// Model data sensor yang merepresentasikan baris di tabel `sensor_data`
class SensorData {
  final int? id;
  final double gas1;
  final double gas2;
  final bool flame1;
  final bool flame2;
  final double temp1;
  final double temp2;
  final String status;
  final bool buzzerOn;
  final bool fanOn;
  final DateTime createdAt;

  SensorData({
    this.id,
    required this.gas1,
    required this.gas2,
    required this.flame1,
    required this.flame2,
    required this.temp1,
    required this.temp2,
    required this.status,
    required this.buzzerOn,
    required this.fanOn,
    required this.createdAt,
  });

  /// Nilai gas tertinggi di antara kedua sensor MQ2
  double get gasMax => math.max(gas1, gas2);

  /// Nilai suhu tertinggi di antara kedua sensor DHT22
  double get tempMax => math.max(temp1, temp2);

  /// Bernilai true jika ada salah satu sensor IR/Flame yang mendeteksi api
  bool get flameAny => flame1 || flame2;

  /// Keterangan penyebab/pemicu status saat ini
  String get penyebabStatus {
    final List<String> reasons = [];

    // Cek Api IR
    if (flame1 && flame2) {
      reasons.add('Api terdeteksi di Sensor 1 & Sensor 2');
    } else if (flame1) {
      reasons.add('Api terdeteksi di Sensor 1');
    } else if (flame2) {
      reasons.add('Api terdeteksi di Sensor 2');
    }

    // Cek Gas MQ2
    if (gas1 >= SensorThreshold.gasBahaya) {
      reasons.add('Gas Sensor 1 = ${gas1.toStringAsFixed(0)} ppm');
    }
    if (gas2 >= SensorThreshold.gasBahaya) {
      reasons.add('Gas Sensor 2 = ${gas2.toStringAsFixed(0)} ppm');
    } else if (gas1 < SensorThreshold.gasBahaya && gas1 >= SensorThreshold.gasWaspada) {
      reasons.add('Gas Sensor 1 = ${gas1.toStringAsFixed(0)} ppm');
    } else if (gas2 < SensorThreshold.gasBahaya && gas2 >= SensorThreshold.gasWaspada) {
      reasons.add('Gas Sensor 2 = ${gas2.toStringAsFixed(0)} ppm');
    }

    // Cek Suhu DHT22
    if (temp1 >= SensorThreshold.tempBahaya) {
      reasons.add('Suhu Sensor 1 = ${temp1.toStringAsFixed(1)} °C');
    }
    if (temp2 >= SensorThreshold.tempBahaya) {
      reasons.add('Suhu Sensor 2 = ${temp2.toStringAsFixed(1)} °C');
    } else if (temp1 < SensorThreshold.tempBahaya && temp1 >= SensorThreshold.tempWaspada) {
      reasons.add('Suhu Sensor 1 = ${temp1.toStringAsFixed(1)} °C');
    } else if (temp2 < SensorThreshold.tempBahaya && temp2 >= SensorThreshold.tempWaspada) {
      reasons.add('Suhu Sensor 2 = ${temp2.toStringAsFixed(1)} °C');
    }

    if (reasons.isEmpty) {
      return 'Semua sensor dalam batas normal & aman';
    }
    return 'Pemicu: ${reasons.join(', ')}';
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final double g1 = (json['gas1'] as num?)?.toDouble() ?? 0.0;
    final double g2 = (json['gas2'] as num?)?.toDouble() ?? 0.0;
    final bool f1 = json['flame1'] == true;
    final bool f2 = json['flame2'] == true;
    final double t1 = (json['temp1'] as num?)?.toDouble() ?? 0.0;
    final double t2 = (json['temp2'] as num?)?.toDouble() ?? 0.0;

    // Jika kolom status kosong / null, hitung dari sensor threshold
    String calculatedStatus = (json['status'] as String?)?.toLowerCase().trim() ?? '';
    if (calculatedStatus.isEmpty) {
      calculatedStatus = SensorThreshold.calculateStatus(
        gas1: g1,
        gas2: g2,
        flame1: f1,
        flame2: f2,
        temp1: t1,
        temp2: t2,
      );
    }

    DateTime parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return SensorData(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      gas1: g1,
      gas2: g2,
      flame1: f1,
      flame2: f2,
      temp1: t1,
      temp2: t2,
      status: calculatedStatus,
      buzzerOn: json['buzzer_on'] == true,
      fanOn: json['fan_on'] == true,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'gas1': gas1,
      'gas2': gas2,
      'flame1': flame1,
      'flame2': flame2,
      'temp1': temp1,
      'temp2': temp2,
      'status': status,
      'buzzer_on': buzzerOn,
      'fan_on': fanOn,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SensorData copyWith({
    int? id,
    double? gas1,
    double? gas2,
    bool? flame1,
    bool? flame2,
    double? temp1,
    double? temp2,
    String? status,
    bool? buzzerOn,
    bool? fanOn,
    DateTime? createdAt,
  }) {
    return SensorData(
      id: id ?? this.id,
      gas1: gas1 ?? this.gas1,
      gas2: gas2 ?? this.gas2,
      flame1: flame1 ?? this.flame1,
      flame2: flame2 ?? this.flame2,
      temp1: temp1 ?? this.temp1,
      temp2: temp2 ?? this.temp2,
      status: status ?? this.status,
      buzzerOn: buzzerOn ?? this.buzzerOn,
      fanOn: fanOn ?? this.fanOn,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
