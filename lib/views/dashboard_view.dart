import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';
import '../services/sensor_service.dart';
import '../widgets/gradient_background.dart';
import '../widgets/status_card.dart';
import '../widgets/actuator_card.dart';
import '../widgets/sensor_monitor_card.dart';
import '../widgets/top_nav.dart';
import 'history_view.dart';

/// Tampilan utama Dashboard "Smart Fire Alarm" untuk 1 ruangan.
/// Mendukung tata letak responsif desktop 2-kolom seimbang & tata letak mobile 1-kolom.
class DashboardView extends StatefulWidget {
  final SensorService? sensorService;

  const DashboardView({
    super.key,
    this.sensorService,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with SingleTickerProviderStateMixin {
  late final SensorService _service;
  StreamSubscription<SensorData>? _latestSub;
  StreamSubscription<List<SensorData>>? _historySub;

  SensorData _latestData = SensorData(
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

  List<SensorData> _history = [];
  NavTab _activeTab = NavTab.dashboard;

  late AnimationController _pulseDotController;

  @override
  void initState() {
    super.initState();
    _service = widget.sensorService ?? SensorService();

    _pulseDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initStreams();
  }

  void _initStreams() {
    // Ambil riwayat awal
    _service.fetchHistoryData().then((data) {
      if (mounted && data.isNotEmpty) {
        setState(() {
          _history = data;
        });
      }
    });

    // Stream realtime data terbaru
    _latestSub = _service.streamLatestData().listen((data) {
      if (mounted) {
        setState(() {
          _latestData = data;
          // Perbarui juga data terakhir di riwayat jika ada
          if (_history.isNotEmpty) {
            final List<SensorData> updated = List.from(_history);
            if (updated.length >= 20) {
              updated.removeAt(0);
            }
            updated.add(data);
            _history = updated;
          }
        });
      }
    });

    // Stream riwayat realtime
    _historySub = _service.streamHistoryData().listen((list) {
      if (mounted && list.isNotEmpty) {
        setState(() {
          _history = list;
        });
      }
    });
  }

  @override
  void dispose() {
    _latestSub?.cancel();
    _historySub?.cancel();
    _pulseDotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;
    final double horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        status: _latestData.status,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Aplikasi
                    _buildHeader(isMobile),
                    const SizedBox(height: 16),

                    // Menu Navigasi Atas (Top Nav)
                    TopNav(
                      activeTab: _activeTab,
                      onTabSelected: (tab) {
                        setState(() {
                          _activeTab = tab;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Konten: Dashboard Utama atau Riwayat Tabel Per Tab
                    if (_activeTab == NavTab.dashboard)
                      if (isMobile)
                        _buildMobileLayout()
                      else
                        _buildDesktopLayout()
                    else
                      HistoryView(
                        tab: _activeTab,
                        sensorService: _service,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header: Judul "Smart Fire Alarm", chip "Ruangan Utama", chip "REALTIME" + titik hijau
  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Fire Alarm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Deteksi Kebakaran Dini Berbasis IoT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Kanan: Chip Ruangan Utama & Chip REALTIME
        Row(
          children: [
            if (!isMobile) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 14, color: Colors.white.withOpacity(0.85)),
                    const SizedBox(width: 6),
                    const Text(
                      'Ruangan Utama',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Chip "REALTIME" dengan titik hijau animasi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseDotController,
                    builder: (context, child) {
                      return Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4 * _pulseDotController.value),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'REALTIME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF34D399),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Tata letak desktop: 2 Kolom seimbang
  /// Kiri: Status Ruangan + Aktuator Otomatis
  /// Kanan: Monitoring Sensor
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kolom Kiri (Lebar 38%)
        Expanded(
          flex: 40,
          child: Column(
            children: [
              StatusCard(data: _latestData),
              const SizedBox(height: 20),
              ActuatorCard(
                buzzerOn: _latestData.buzzerOn,
                fanOn: _latestData.fanOn,
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Kolom Kanan (Lebar 60%)
        Expanded(
          flex: 60,
          child: SensorMonitorCard(
            latestData: _latestData,
            history: _history,
          ),
        ),
      ],
    );
  }

  /// Tata letak mobile: 1 Kolom
  /// Urutan: Status Ruangan -> Monitoring Sensor -> Aktuator Otomatis
  Widget _buildMobileLayout() {
    return Column(
      children: [
        StatusCard(data: _latestData),
        const SizedBox(height: 16),
        SensorMonitorCard(
          latestData: _latestData,
          history: _history,
        ),
        const SizedBox(height: 16),
        ActuatorCard(
          buzzerOn: _latestData.buzzerOn,
          fanOn: _latestData.fanOn,
        ),
      ],
    );
  }
}
