import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fire_alarm/models/sensor_data_model.dart';
import 'package:smart_fire_alarm/main.dart';

void main() {
  testWidgets('Smoke test: Smart Fire Alarm dashboard launches and renders header', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartFireAlarmApp());

    // Verifikasi bahwa teks judul "Smart Fire Alarm" muncul di layar
    expect(find.text('Smart Fire Alarm'), findsOneWidget);
    expect(find.text('REALTIME'), findsOneWidget);
  });

  test('SensorThreshold calculateStatus logic verification', () {
    // Kondisi Normal / Aman
    final statusAman = SensorThreshold.calculateStatus(
      gas1: 150,
      gas2: 180,
      flame1: false,
      flame2: false,
      temp1: 28,
      temp2: 29,
    );
    expect(statusAman, 'aman');

    // Kondisi Waspada karena gas >= 300
    final statusWaspadaGas = SensorThreshold.calculateStatus(
      gas1: 320,
      gas2: 180,
      flame1: false,
      flame2: false,
      temp1: 28,
      temp2: 29,
    );
    expect(statusWaspadaGas, 'waspada');

    // Kondisi Waspada karena suhu >= 35
    final statusWaspadaTemp = SensorThreshold.calculateStatus(
      gas1: 150,
      gas2: 180,
      flame1: false,
      flame2: false,
      temp1: 36,
      temp2: 29,
    );
    expect(statusWaspadaTemp, 'waspada');

    // Kondisi Bahaya karena api terdeteksi
    final statusBahayaFlame = SensorThreshold.calculateStatus(
      gas1: 150,
      gas2: 180,
      flame1: true,
      flame2: false,
      temp1: 28,
      temp2: 29,
    );
    expect(statusBahayaFlame, 'bahaya');

    // Kondisi Bahaya karena gas >= 500
    final statusBahayaGas = SensorThreshold.calculateStatus(
      gas1: 520,
      gas2: 180,
      flame1: false,
      flame2: false,
      temp1: 28,
      temp2: 29,
    );
    expect(statusBahayaGas, 'bahaya');

    // Kondisi Bahaya karena suhu >= 45
    final statusBahayaTemp = SensorThreshold.calculateStatus(
      gas1: 150,
      gas2: 180,
      flame1: false,
      flame2: false,
      temp1: 46.5,
      temp2: 29,
    );
    expect(statusBahayaTemp, 'bahaya');
  });

  test('HistoryBuilder detects state transitions and formats durations', () {
    final t0 = DateTime(2026, 10, 30, 9, 0, 0);
    final t1 = DateTime(2026, 10, 30, 9, 2, 14); // + 2m 14s
    final t2 = DateTime(2026, 10, 30, 9, 5, 0); // + 2m 46s

    final rows = [
      SensorData(
        id: 3,
        gas1: 150,
        gas2: 140,
        flame1: false,
        flame2: false,
        temp1: 28,
        temp2: 28,
        status: 'aman',
        buzzerOn: false,
        fanOn: false,
        createdAt: t2,
      ),
      SensorData(
        id: 2,
        gas1: 520,
        gas2: 140,
        flame1: false,
        flame2: false,
        temp1: 28,
        temp2: 28,
        status: 'bahaya',
        buzzerOn: true,
        fanOn: true,
        createdAt: t1,
      ),
      SensorData(
        id: 1,
        gas1: 150,
        gas2: 140,
        flame1: false,
        flame2: false,
        temp1: 28,
        temp2: 28,
        status: 'aman',
        buzzerOn: false,
        fanOn: false,
        createdAt: t0,
      ),
    ];

    // Buzzer history log
    final buzzerEvents = HistoryBuilder.buildBuzzerHistory(rows);
    expect(buzzerEvents.isNotEmpty, true);
    // Newest is on top
    expect(buzzerEvents.first.status, 'MATI');
    expect(buzzerEvents[1].status, 'NYALA');
    expect(buzzerEvents[1].trigger, contains('Gas Sensor 1 = 520 ppm'));
    expect(buzzerEvents[1].duration, '2 mnt 46 dtk');

    // Fan history log
    final fanEvents = HistoryBuilder.buildFanHistory(rows);
    expect(fanEvents.isNotEmpty, true);

    // LED history log
    final ledEvents = HistoryBuilder.buildLedHistory(rows);
    expect(ledEvents.isNotEmpty, true);
    expect(ledEvents[1].status, 'MERAH');
  });
}
