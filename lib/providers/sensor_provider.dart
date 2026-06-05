// lib/providers/sensor_provider.dart
// Semua Riverpod providers untuk Smart Learning Room
// Saat ini pakai mock stream — ganti dengan Firebase stream saat siap

import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/sensor_data.dart';

// ── SENSOR PROVIDER ───────────────────────────────────────────────────────────
// Untuk switch ke Firebase, ganti isi provider ini dengan:
//
// final sensorProvider = StreamProvider<SensorData>((ref) {
//   return FirebaseDatabase.instance
//       .ref('smartlearningroom/sensors')
//       .onValue
//       .map((event) => SensorData.fromMap(
//           Map<String, dynamic>.from(event.snapshot.value as Map)));
// });

final sensorProvider = StreamProvider<SensorData>((ref) {
  return _mockSensorStream();
});

Stream<SensorData> _mockSensorStream() async* {
  final rng = Random();

  // Nilai awal mendekati kondisi nyata ruangan
  double temp     = 25.4;
  double humidity = 62.0;
  double lux      = 340.0;
  int gas         = 35;

  while (true) {
    // Simulasi fluktuasi kecil setiap 3 detik (seperti sensor nyata)
    temp     = (temp     + (rng.nextDouble() - 0.48) * 0.5).clamp(21.0, 32.0);
    humidity = (humidity + (rng.nextDouble() - 0.45) * 1.5).clamp(35.0, 85.0);
    lux      = (lux      + (rng.nextDouble() - 0.5)  * 25).clamp(50.0, 700.0);
    gas      = (gas      + (rng.nextInt(5) - 2)).clamp(10, 90);

    final score = SensorData.calculateComfort(
      temp: temp, humidity: humidity, lux: lux, gas: gas,
    );

    yield SensorData(
      temperature:   temp,
      humidity:      humidity,
      lux:           lux,
      gasLevel:      gas,
      presence:      true,
      distance:      45.0 + rng.nextDouble() * 10,
      comfortScore:  score,
      comfortStatus: SensorData.scoreToStatus(score),
      timestamp:     DateTime.now(),
    );

    await Future.delayed(const Duration(seconds: 3));
  }
}

// ── SESSION PROVIDER ──────────────────────────────────────────────────────────
final sessionActiveProvider = StateProvider<bool>((ref) => false);

// Timer sesi dalam detik
final sessionSecondsProvider = StateProvider<int>((ref) => 0);

// Provider yang jalankan timer saat sesi aktif
final sessionTimerProvider = Provider<void>((ref) {
  ref.listen<bool>(sessionActiveProvider, (prev, next) {
    if (next) {
      // Reset dan mulai timer
      ref.read(sessionSecondsProvider.notifier).state = 0;
      Timer.periodic(const Duration(seconds: 1), (t) {
        if (!ref.read(sessionActiveProvider)) {
          t.cancel();
          return;
        }
        ref.read(sessionSecondsProvider.notifier).state++;
      });
    }
  });
});

// ── ACTUATOR PROVIDER ─────────────────────────────────────────────────────────
class ActuatorState {
  final bool fan;
  final bool light;
  final double servoAngle; // 0–90 derajat
  final String mode; // 'auto' atau 'manual'

  const ActuatorState({
    this.fan = true,
    this.light = true,
    this.servoAngle = 45,
    this.mode = 'auto',
  });

  ActuatorState copyWith({bool? fan, bool? light, double? servoAngle, String? mode}) {
    return ActuatorState(
      fan: fan ?? this.fan,
      light: light ?? this.light,
      servoAngle: servoAngle ?? this.servoAngle,
      mode: mode ?? this.mode,
    );
  }
}

class ActuatorNotifier extends StateNotifier<ActuatorState> {
  ActuatorNotifier() : super(const ActuatorState());

  // TODO: Saat Firebase terhubung, tambahkan write ke Firebase di setiap method:
  // await FirebaseDatabase.instance.ref('smartlearningroom/control/fan').set(value);

  void toggleFan()   => state = state.copyWith(fan: !state.fan);
  void toggleLight() => state = state.copyWith(light: !state.light);
  void setServo(double angle) => state = state.copyWith(servoAngle: angle);
  void setMode(String mode)   => state = state.copyWith(mode: mode);

  // AI Rule Engine: update aktuator otomatis berdasarkan data sensor
  void applyAiRules(SensorData sensor) {
    if (state.mode != 'auto') return;
    state = state.copyWith(
      fan:   sensor.temperature > 27 || sensor.gasLevel > 60,
      light: sensor.lux < 250,
    );
  }
}

final actuatorProvider = StateNotifierProvider<ActuatorNotifier, ActuatorState>(
  (ref) => ActuatorNotifier(),
);

// ── FEEDBACK PROVIDER ─────────────────────────────────────────────────────────
// 0 = belum ada, 1–4 = level feedback (1=sangat tidak nyaman, 4=sangat nyaman)
final feedbackProvider = StateProvider<int>((ref) => 0);

// Helper: format detik ke string MM:SS
String formatDuration(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
