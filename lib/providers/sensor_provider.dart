// lib/providers/sensor_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';

// Provider untuk menginisialisasi FirebaseService
final firebaseServiceProvider = Provider<FirebaseService>(
  (ref) => FirebaseService(),
);

// ── SENSOR PROVIDER (REAL FROM FIREBASE) ──────────────────────────────────────
final sensorProvider = StreamProvider<SensorData>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getSensorStream();
});

// ── SESSION ACTIVE PROVIDER (Riverpod 3.x Style) ──────────────────────────────
class SessionActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false; // Nilai awal: false

  set state(bool value) =>
      super.state = value; // Mempertahankan fungsi pencatatan .state di UI
}

final sessionActiveProvider = NotifierProvider<SessionActiveNotifier, bool>(() {
  return SessionActiveNotifier();
});

// ── SESSION SECONDS PROVIDER (Riverpod 3.x Style) ─────────────────────────────
class SessionSecondsNotifier extends Notifier<int> {
  @override
  int build() => 0; // Nilai awal: 0 detik3

  set state(int value) => super.state = value;
}

final sessionSecondsProvider = NotifierProvider<SessionSecondsNotifier, int>(
  () {
    return SessionSecondsNotifier();
  },
);

// ── SESSION TIMER PROVIDER ────────────────────────────────────────────────────
// lib/providers/sensor_provider.dart
// ── RECONFIQ: SESSION TIMER PROVIDER (STOPWATCH COUNT-UP STYLE) ──────────────
final sessionTimerProvider = Provider<void>((ref) {
  Timer? periodicTimer;

  ref.listen<bool>(sessionActiveProvider, (bool? prev, bool next) {
    if (next) {
      // Jika tombol "Mulai Sesi" ditekan, set stopwatch mulai dari 0 detik lagi
      ref.read(sessionSecondsProvider.notifier).state = 0;
      periodicTimer?.cancel();

      periodicTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!ref.read(sessionActiveProvider)) {
          t.cancel();
          return;
        }
        // Ditambah terus (Hitung Maju / Count-up)
        ref.read(sessionSecondsProvider.notifier).state++;
      });
    } else {
      periodicTimer?.cancel();
    }
  });
});

// ── ACTUATOR STATE MODEL ──────────────────────────────────────────────────────
class ActuatorState {
  final bool fan;
  final bool light;
  final double servoAngle;
  final String mode;

  const ActuatorState({
    this.fan = true,
    this.light = true,
    this.servoAngle = 45,
    this.mode = 'auto',
  });

  ActuatorState copyWith({
    bool? fan,
    bool? light,
    double? servoAngle,
    String? mode,
  }) {
    return ActuatorState(
      fan: fan ?? this.fan,
      light: light ?? this.light,
      servoAngle: servoAngle ?? this.servoAngle,
      mode: mode ?? this.mode,
    );
  }
}

// ── ACTUATOR NOTIFIER (Gaya Riverpod 3.x Modern & Sinkron Database) ───────────
class ActuatorNotifier extends Notifier<ActuatorState> {
  FirebaseService get _firebaseService => ref.read(firebaseServiceProvider);
  StreamSubscription? _subscription;

  @override
  ActuatorState build() {
    // Jalankan sinkronisasi pasif: Dengar perubahan dari Firebase node 'control'
    // Jika data control di Firebase berubah (atau baru dibuat), UI Flutter langsung update otomatis
    _subscription?.cancel();

    // Kita manfaatkan referensi instance database Firebase
    final dbRef = FirebaseDatabase.instance.ref('smartlearningroom/control');

    _subscription = dbRef.onValue.listen((event) {
      final snapshotValue = event.snapshot.value;
      if (snapshotValue != null) {
        final Map<dynamic, dynamic> map = snapshotValue as Map;

        state = ActuatorState(
          fan: map['fan'] as bool? ?? false,
          light: map['light'] as bool? ?? false,
          servoAngle: (map['servoAngle'] as num?)?.toDouble() ?? 45.0,
          mode: map['mode'] as String? ?? 'auto',
        );
      }
    });

    // Nilai awal cadangan sebelum stream mendarat
    return const ActuatorState(
      fan: false,
      light: false,
      servoAngle: 45,
      mode: 'auto',
    );
  }

  void toggleFan() {
    final nextValue = !state.fan;
    // Cukup kirim ke Firebase, biar listener di fungsi build() yang merubah state UI kita
    _firebaseService.updateActuatorState(fan: nextValue);
  }

  void toggleLight() {
    final nextValue = !state.light;
    _firebaseService.updateActuatorState(light: nextValue);
  }

  void setServo(double angle) {
    _firebaseService.updateActuatorState(servoAngle: angle);
  }

  void setMode(String mode) {
    _firebaseService.updateActuatorState(mode: mode);
  }

  void applyAiRules(SensorData sensor) {
    if (state.mode != 'auto') return;

    // AI LOGIC UPDATE: Kipas aktif jika suhu > 27°C ATAU tingkat kebisingan ruangan > 50%
    final targetFan = sensor.temperature > 27 || sensor.soundLevel > 50;
    final targetLight = sensor.lux < 250;

    if (targetFan != state.fan || targetLight != state.light) {
      _firebaseService.updateActuatorState(fan: targetFan, light: targetLight);
    }
  }
}

final actuatorProvider = NotifierProvider<ActuatorNotifier, ActuatorState>(() {
  return ActuatorNotifier();
});

// ── FEEDBACK PROVIDER (Riverpod 3.x Style) ────────────────────────────────────
class FeedbackNotifier extends Notifier<int> {
  @override
  int build() => 0; // Nilai awal: 0

  set state(int value) => super.state = value;
}

final feedbackProvider = NotifierProvider<FeedbackNotifier, int>(() {
  return FeedbackNotifier();
});

// ── RECONFIQ: FORMAT UTAMA STOPWATCH (HH:MM:SS) ──────────────────────────────
String formatDuration(int totalSeconds) {
  final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
  final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
