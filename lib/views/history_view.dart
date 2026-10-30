import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_event.dart';
import '../models/sensor_data_model.dart';
import '../services/sensor_service.dart';
import '../utils/history_builder.dart';
import '../utils/status_style.dart';
import '../widgets/history_summary.dart';
import '../widgets/history_table.dart';
import '../widgets/top_nav.dart';

/// Halaman Riwayat (History View) untuk tab Gas MQ2, Api IR, Suhu DHT22, Buzzer, Kipas, dan LED Status.
/// Menampilkan 3 kartu ringkasan di atas dan tabel riwayat serbaguna di bawahnya.
class HistoryView extends StatefulWidget {
  final NavTab tab;
  final SensorService sensorService;

  const HistoryView({
    super.key,
    required this.tab,
    required this.sensorService,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  bool _isLoading = true;
  List<SensorData> _rawData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant HistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab != oldWidget.tab) {
      // Jika data sudah ada, tidak perlu fetch ulang kecuali jika kosong
      if (_rawData.isEmpty) {
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await widget.sensorService.fetchHistory(limit: 500);
      if (mounted) {
        setState(() {
          _rawData = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3 Kotak Ringkasan
        HistorySummary(items: _buildSummaryItems()),

        const SizedBox(height: 16),

        // Tabel Riwayat
        _buildTable(),
      ],
    );
  }

  // ==========================================
  // RINGKASAN 3 KOTAK SESUAI TAB AKTIF
  // ==========================================
  List<SummaryItem> _buildSummaryItems() {
    if (_rawData.isEmpty) {
      return [
        const SummaryItem(title: 'Total Data', value: '0', subtitle: 'Memuat data...', icon: Icons.data_usage_rounded),
        const SummaryItem(title: 'Status', value: '-', subtitle: 'Tidak ada data', icon: Icons.info_outline),
        const SummaryItem(title: 'Kondisi', value: '-', subtitle: 'Siaga', icon: Icons.shield_outlined),
      ];
    }

    switch (widget.tab) {
      case NavTab.gas:
        double totalG1 = 0, totalG2 = 0, maxG = 0;
        for (final d in _rawData) {
          totalG1 += d.gas1;
          totalG2 += d.gas2;
          if (d.gasMax > maxG) maxG = d.gasMax;
        }
        final double avgG = (totalG1 + totalG2) / (_rawData.length * 2);
        final String latestSt = _rawData.first.status.toUpperCase();
        final Color stColor = StatusStyle.getStatusColor(_rawData.first.status);

        return [
          SummaryItem(
            title: 'Rata-rata Gas',
            value: '${avgG.toStringAsFixed(0)} ppm',
            subtitle: 'Dari ${_rawData.length} sampel',
            icon: Icons.cloud_queue_rounded,
            accentColor: const Color(0xFF38BDF8),
          ),
          SummaryItem(
            title: 'Puncak Tertinggi',
            value: '${maxG.toStringAsFixed(0)} ppm',
            subtitle: maxG >= 500 ? 'Bahaya asap pekat' : (maxG >= 300 ? 'Waspada kebocoran' : 'Batas aman'),
            icon: Icons.trending_up_rounded,
            accentColor: maxG >= 500 ? const Color(0xFFEF4444) : (maxG >= 300 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
          ),
          SummaryItem(
            title: 'Status Terkini',
            value: latestSt,
            subtitle: 'Gas Sensor 1: ${_rawData.first.gas1.toStringAsFixed(0)} ppm',
            icon: Icons.verified_user_rounded,
            accentColor: stColor,
          ),
        ];

      case NavTab.flame:
        int flameCount = 0;
        DateTime? lastFlameTime;
        for (final d in _rawData) {
          if (d.flameAny) {
            flameCount++;
            lastFlameTime ??= d.createdAt;
          }
        }
        final bool currentlyDetected = _rawData.first.flameAny;

        return [
          SummaryItem(
            title: 'Total Deteksi Api',
            value: '$flameCount kali',
            subtitle: 'Sensor IR 1 & 2',
            icon: Icons.local_fire_department_rounded,
            accentColor: flameCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          ),
          SummaryItem(
            title: 'Deteksi Terakhir',
            value: lastFlameTime != null ? DateFormat('HH:mm:ss').format(lastFlameTime) : 'Nihil',
            subtitle: lastFlameTime != null ? DateFormat('dd/MM/yyyy').format(lastFlameTime) : 'Tidak ada api',
            icon: Icons.history_toggle_off_rounded,
            accentColor: lastFlameTime != null ? const Color(0xFFF59E0B) : const Color(0xFF34D399),
          ),
          SummaryItem(
            title: 'Status Terkini',
            value: currentlyDetected ? 'API TERDETEKSI' : 'AMAN',
            subtitle: currentlyDetected ? 'Sirine aktif!' : 'Ruangan bebas api',
            icon: currentlyDetected ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            accentColor: currentlyDetected ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          ),
        ];

      case NavTab.temp:
        double totalT1 = 0, totalT2 = 0, maxT = 0;
        for (final d in _rawData) {
          totalT1 += d.temp1;
          totalT2 += d.temp2;
          if (d.tempMax > maxT) maxT = d.tempMax;
        }
        final double avgT = (totalT1 + totalT2) / (_rawData.length * 2);
        final double currentTemp = _rawData.first.tempMax;

        return [
          SummaryItem(
            title: 'Rata-rata Suhu',
            value: '${avgT.toStringAsFixed(1)} °C',
            subtitle: 'DHT22 Sensor 1 & 2',
            icon: Icons.thermostat_rounded,
            accentColor: const Color(0xFF38BDF8),
          ),
          SummaryItem(
            title: 'Suhu Tertinggi',
            value: '${maxT.toStringAsFixed(1)} °C',
            subtitle: maxT >= 45 ? 'Suhu kritis kebakaran' : (maxT >= 35 ? 'Di atas ambang normal' : 'Suhu ruangan normal'),
            icon: Icons.wb_sunny_outlined,
            accentColor: maxT >= 45 ? const Color(0xFFEF4444) : (maxT >= 35 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
          ),
          SummaryItem(
            title: 'Suhu Terkini',
            value: '${currentTemp.toStringAsFixed(1)} °C',
            subtitle: 'Sensor 1: ${_rawData.first.temp1.toStringAsFixed(1)} °C | S2: ${_rawData.first.temp2.toStringAsFixed(1)} °C',
            icon: Icons.ac_unit_rounded,
            accentColor: StatusStyle.getTempColor(currentTemp),
          ),
        ];

      case NavTab.buzzer:
        final events = HistoryBuilder.buildBuzzerHistory(_rawData);
        final nyalaEvents = events.where((e) => e.isActiveState).toList();
        final int totalNyala = nyalaEvents.length;

        Duration totalDuration = Duration.zero;
        for (final e in nyalaEvents) {
          if (e.durationValue != null) {
            totalDuration += e.durationValue!;
          }
        }

        final bool currentlyOn = _rawData.first.buzzerOn;

        return [
          SummaryItem(
            title: 'Total NYALA',
            value: '$totalNyala kali',
            subtitle: 'Log aktivasi sirine',
            icon: Icons.volume_up_rounded,
            accentColor: totalNyala > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          ),
          SummaryItem(
            title: 'Total Durasi NYALA',
            value: totalDuration.inSeconds > 0 ? HistoryBuilder.formatDuration(totalDuration) : '0 dtk',
            subtitle: 'Akumulasi waktu berbunyi',
            icon: Icons.timer_outlined,
            accentColor: const Color(0xFFF59E0B),
          ),
          SummaryItem(
            title: 'Kondisi Terkini',
            value: currentlyOn ? 'NYALA' : 'MATI',
            subtitle: currentlyOn ? 'Sedang berbunyi!' : 'Siaga otomatis',
            icon: currentlyOn ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
            accentColor: currentlyOn ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          ),
        ];

      case NavTab.fan:
        final events = HistoryBuilder.buildFanHistory(_rawData);
        final onEvents = events.where((e) => e.isActiveState).toList();
        final int totalON = onEvents.length;

        Duration totalDuration = Duration.zero;
        for (final e in onEvents) {
          if (e.durationValue != null) {
            totalDuration += e.durationValue!;
          }
        }

        final bool currentlyOn = _rawData.first.fanOn;

        return [
          SummaryItem(
            title: 'Total ON',
            value: '$totalON kali',
            subtitle: 'Aktivasi buang gas/asap',
            icon: Icons.mode_fan_off_rounded,
            accentColor: const Color(0xFF38BDF8),
          ),
          SummaryItem(
            title: 'Total Durasi ON',
            value: totalDuration.inSeconds > 0 ? HistoryBuilder.formatDuration(totalDuration) : '0 dtk',
            subtitle: 'Akumulasi waktu kipas berputar',
            icon: Icons.timer_outlined,
            accentColor: const Color(0xFF38BDF8),
          ),
          SummaryItem(
            title: 'Kondisi Terkini',
            value: currentlyOn ? 'ON' : 'OFF',
            subtitle: currentlyOn ? 'Kipas sedang berputar' : 'Mati siaga',
            icon: Icons.rotate_right_rounded,
            accentColor: currentlyOn ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
          ),
        ];

      case NavTab.led:
        final events = HistoryBuilder.buildLedHistory(_rawData);
        final int bahayaCount = events.where((e) => e.status == 'MERAH').length;
        final int waspadaCount = events.where((e) => e.status == 'KUNING').length;

        String currentLed = 'HIJAU';
        Color currentLedColor = const Color(0xFF10B981);
        if (_rawData.first.status == 'bahaya') {
          currentLed = 'MERAH';
          currentLedColor = const Color(0xFFEF4444);
        } else if (_rawData.first.status == 'waspada') {
          currentLed = 'KUNING';
          currentLedColor = const Color(0xFFF59E0B);
        }

        return [
          SummaryItem(
            title: 'Total Bahaya (Merah)',
            value: '$bahayaCount kali',
            subtitle: 'LED merah berkedip',
            icon: Icons.lightbulb_rounded,
            accentColor: const Color(0xFFEF4444),
          ),
          SummaryItem(
            title: 'Total Waspada (Kuning)',
            value: '$waspadaCount kali',
            subtitle: 'LED kuning menyala',
            icon: Icons.lightbulb_outline_rounded,
            accentColor: const Color(0xFFF59E0B),
          ),
          SummaryItem(
            title: 'Status LED Terkini',
            value: currentLed,
            subtitle: 'Indikator aktif saat ini',
            icon: Icons.circle,
            accentColor: currentLedColor,
          ),
        ];

      case NavTab.dashboard:
      default:
        return [];
    }
  }

  // ==========================================
  // TABEL SESUAI SPESIFIKASI TAB AKTIF
  // ==========================================
  Widget _buildTable() {
    switch (widget.tab) {
      case NavTab.gas:
        return _buildGasTable();
      case NavTab.flame:
        return _buildFlameTable();
      case NavTab.temp:
        return _buildTempTable();
      case NavTab.buzzer:
        return _buildBuzzerTable();
      case NavTab.fan:
        return _buildFanTable();
      case NavTab.led:
        return _buildLedTable();
      case NavTab.dashboard:
      default:
        return const SizedBox.shrink();
    }
  }

  // TABEL 1: GAS MQ2
  // Kolom: Waktu | Gas Sensor 1 (ppm) | Gas Sensor 2 (ppm) | Status
  Widget _buildGasTable() {
    final columns = const [
      HistoryTableColumn(title: 'Waktu', alignment: Alignment.centerLeft),
      HistoryTableColumn(title: 'Gas Sensor 1 (ppm)', alignment: Alignment.center),
      HistoryTableColumn(title: 'Gas Sensor 2 (ppm)', alignment: Alignment.center),
      HistoryTableColumn(title: 'Status', alignment: Alignment.centerRight),
    ];

    final rows = _rawData.map((d) {
      final String st = d.status.toUpperCase();
      final Color stColor = StatusStyle.getStatusColor(d.status);

      return HistoryTableRow(cells: [
        HistoryTableCell(text: _dateFormat.format(d.createdAt)),
        HistoryTableCell(text: '${d.gas1.toStringAsFixed(0)} ppm'),
        HistoryTableCell(text: '${d.gas2.toStringAsFixed(0)} ppm'),
        HistoryTableCell(text: st, isChip: true, chipColor: stColor),
      ]);
    }).toList();

    final StringBuffer csv = StringBuffer();
    csv.writeln('Waktu,Gas Sensor 1 (ppm),Gas Sensor 2 (ppm),Status');
    for (final d in _rawData) {
      csv.writeln('${_dateFormat.format(d.createdAt)},${d.gas1},${d.gas2},${d.status}');
    }

    return HistoryTable(
      title: 'Riwayat Gas & Asap (MQ2)',
      subtitle: 'Semua pembacaan telemetri ppm sensor gas',
      columns: columns,
      rows: rows,
      onRefresh: _loadData,
      isLoading: _isLoading,
      csvContent: csv.toString(),
    );
  }

  // TABEL 2: API IR
  // Kolom: Waktu | IR Sensor 1 | IR Sensor 2 | Status (isi: AMAN / API TERDETEKSI)
  Widget _buildFlameTable() {
    final columns = const [
      HistoryTableColumn(title: 'Waktu', alignment: Alignment.centerLeft),
      HistoryTableColumn(title: 'IR Sensor 1', alignment: Alignment.center),
      HistoryTableColumn(title: 'IR Sensor 2', alignment: Alignment.center),
      HistoryTableColumn(title: 'Status', alignment: Alignment.centerRight),
    ];

    final rows = _rawData.map((d) {
      final bool detected = d.flameAny;
      final Color stColor = detected ? const Color(0xFFEF4444) : const Color(0xFF10B981);
      final String stText = detected ? 'API TERDETEKSI' : 'AMAN';

      return HistoryTableRow(cells: [
        HistoryTableCell(text: _dateFormat.format(d.createdAt)),
        HistoryTableCell(
          text: d.flame1 ? 'API TERDETEKSI' : 'AMAN',
          isChip: true,
          chipColor: d.flame1 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        ),
        HistoryTableCell(
          text: d.flame2 ? 'API TERDETEKSI' : 'AMAN',
          isChip: true,
          chipColor: d.flame2 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        ),
        HistoryTableCell(text: stText, isChip: true, chipColor: stColor),
      ]);
    }).toList();

    final StringBuffer csv = StringBuffer();
    csv.writeln('Waktu,IR Sensor 1,IR Sensor 2,Status');
    for (final d in _rawData) {
      csv.writeln('${_dateFormat.format(d.createdAt)},${d.flame1 ? "API TERDETEKSI" : "AMAN"},${d.flame2 ? "API TERDETEKSI" : "AMAN"},${d.flameAny ? "API TERDETEKSI" : "AMAN"}');
    }

    return HistoryTable(
      title: 'Riwayat Deteksi Api (Infrared Flame)',
      subtitle: 'Catatan sensor optik pendeteksi api terbuka',
      columns: columns,
      rows: rows,
      onRefresh: _loadData,
      isLoading: _isLoading,
      csvContent: csv.toString(),
    );
  }

  // TABEL 3: SUHU DHT22
  // Kolom: Waktu | Suhu Sensor 1 (°C) | Suhu Sensor 2 (°C) | Status
  Widget _buildTempTable() {
    final columns = const [
      HistoryTableColumn(title: 'Waktu', alignment: Alignment.centerLeft),
      HistoryTableColumn(title: 'Suhu Sensor 1 (°C)', alignment: Alignment.center),
      HistoryTableColumn(title: 'Suhu Sensor 2 (°C)', alignment: Alignment.center),
      HistoryTableColumn(title: 'Status', alignment: Alignment.centerRight),
    ];

    final rows = _rawData.map((d) {
      final String st = d.status.toUpperCase();
      final Color stColor = StatusStyle.getStatusColor(d.status);

      return HistoryTableRow(cells: [
        HistoryTableCell(text: _dateFormat.format(d.createdAt)),
        HistoryTableCell(text: '${d.temp1.toStringAsFixed(1)} °C'),
        HistoryTableCell(text: '${d.temp2.toStringAsFixed(1)} °C'),
        HistoryTableCell(text: st, isChip: true, chipColor: stColor),
      ]);
    }).toList();

    final StringBuffer csv = StringBuffer();
    csv.writeln('Waktu,Suhu Sensor 1 (°C),Suhu Sensor 2 (°C),Status');
    for (final d in _rawData) {
      csv.writeln('${_dateFormat.format(d.createdAt)},${d.temp1},${d.temp2},${d.status}');
    }

    return HistoryTable(
      title: 'Riwayat Suhu Ruangan (DHT22)',
      subtitle: 'Semua pembacaan sensor suhu ruangan',
      columns: columns,
      rows: rows,
      onRefresh: _loadData,
      isLoading: _isLoading,
      csvContent: csv.toString(),
    );
  }

  // TABEL 4: BUZZER ALARM (LOG PERUBAHAN)
  // Kolom: Waktu | Status (NYALA / MATI) | Pemicu | Durasi
  Widget _buildBuzzerTable() {
    final columns = const [
      HistoryTableColumn(title: 'Waktu', alignment: Alignment.centerLeft),
      HistoryTableColumn(title: 'Status', alignment: Alignment.center),
      HistoryTableColumn(title: 'Pemicu', alignment: Alignment.centerLeft),
      HistoryTableColumn(title: 'Durasi', alignment: Alignment.centerRight),
    ];

    final List<HistoryEvent> events = HistoryBuilder.buildBuzzerHistory(_rawData);

    final rows = events.map((e) {
      final Color chipColor = e.isActiveState ? const Color(0xFFEF4444) : const Color(0xFF10B981);

      return HistoryTableRow(cells: [
        HistoryTableCell(text: _dateFormat.format(e.time)),
        HistoryTableCell(text: e.status, isChip: true, chipColor: chipColor),
        HistoryTableCell(text: e.trigger),
        HistoryTableCell(text: e.duration),
      ]);
    }).toList();

    final StringBuffer csv = StringBuffer();
    csv.writeln('Waktu,Status,Pemicu,Durasi');
    for (final e in events) {
      csv.writeln('${_dateFormat.format(e.time)},${e.status},"${e.trigger}",${e.duration}');
    }

    return HistoryTable(
      title: 'Log Perubahan Buzzer Alarm',
      subtitle: 'Hanya mencatat transisi status saat Buzzer berbunyi atau mati',
      columns: columns,
      rows: rows,
      onRefresh: _loadData,
      isLoading: _isLoading,
      csvContent: csv.toString(),
    );
  }

  // TABEL 5: KIPAS EXHAUST (LOG PERUBAHAN)
  // Kolom: Waktu | Status (ON / OFF) | Pemicu | Durasi
  Widget _buildFanTable() {
    final columns = const [
      HistoryTableColumn(title: 'Waktu', alignment: Alignment.centerLeft),
      HistoryTableColumn(title: 'Status', alignment: Alignment.center),
      HistoryTableColumn(title: 'Pemicu', alignment: Alignment.centerLeft),
      HistoryTableColumn(title: 'Durasi', alignment: Alignment.centerRight),
    ];

    final List<HistoryEvent> events = HistoryBuilder.buildFanHistory(_rawData);

    final rows = events.map((e) {
      final Color chipColor = e.isActiveState ? const Color(0xFF38BDF8) : const Color(0xFF10B981);

      return HistoryTableRow(cells: [
        HistoryTableCell(text: _dateFormat.format(e.time)),
        HistoryTableCell(text: e.status, isChip: true, chipColor: chipColor),
        HistoryTableCell(text: e.trigger),
        HistoryTableCell(text: e.duration),
      ]);
    }).toList();

    final StringBuffer csv = StringBuffer();
    csv.writeln('Waktu,Status,Pemicu,Durasi');
    for (final e in events) {
      csv.writeln('${_dateFormat.format(e.time)},${e.status},"${e.trigger}",${e.duration}');
    }

    return HistoryTable(
      title: 'Log Perubahan Kipas Exhaust',
      subtitle: 'Hanya mencatat transisi status saat Kipas ON atau OFF',
      columns: columns,
      rows: rows,
      onRefresh: _loadData,
      isLoading: _isLoading,
      csvContent: csv.toString(),
    );
  }

  // TABEL 6: LED STATUS (LOG PERUBAHAN)
  // Kolom: Waktu | Warna LED (HIJAU / KUNING / MERAH) | Pemicu | Durasi
  Widget _buildLedTable() {
    final columns = const [
      HistoryTableColumn(title: 'Waktu', alignment: Alignment.centerLeft),
      HistoryTableColumn(title: 'Warna LED', alignment: Alignment.center),
      HistoryTableColumn(title: 'Pemicu', alignment: Alignment.centerLeft),
      HistoryTableColumn(title: 'Durasi', alignment: Alignment.centerRight),
    ];

    final List<HistoryEvent> events = HistoryBuilder.buildLedHistory(_rawData);

    final rows = events.map((e) {
      Color chipColor = const Color(0xFF10B981);
      if (e.status == 'MERAH') {
        chipColor = const Color(0xFFEF4444);
      } else if (e.status == 'KUNING') {
        chipColor = const Color(0xFFF59E0B);
      }

      return HistoryTableRow(cells: [
        HistoryTableCell(text: _dateFormat.format(e.time)),
        HistoryTableCell(text: e.status, isChip: true, chipColor: chipColor),
        HistoryTableCell(text: e.trigger),
        HistoryTableCell(text: e.duration),
      ]);
    }).toList();

    final StringBuffer csv = StringBuffer();
    csv.writeln('Waktu,Warna LED,Pemicu,Durasi');
    for (final e in events) {
      csv.writeln('${_dateFormat.format(e.time)},${e.status},"${e.trigger}",${e.duration}');
    }

    return HistoryTable(
      title: 'Log Perubahan LED Status',
      subtitle: 'Hanya mencatat transisi warna indikator LED (HIJAU, KUNING, MERAH)',
      columns: columns,
      rows: rows,
      onRefresh: _loadData,
      isLoading: _isLoading,
      csvContent: csv.toString(),
    );
  }
}
