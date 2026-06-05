// lib/models/sensor_data.dart
// Model data sensor dari ESP32-S3
// TODO: Swap fromMap() factory dengan data dari Firebase Realtime DB

class SensorData {
  final double temperature; // °C dari BME280
  final double humidity;    // % RH dari BME280 / DHT11
  final double lux;         // lux dari LDR
  final int gasLevel;       // 0–100 dari sensor MQ (proxy CO₂)
  final bool presence;      // true/false dari PIR HC-SR501
  final double distance;    // cm dari HC-SR04
  final int comfortScore;   // dihitung otomatis 0–100
  final String comfortStatus;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.lux,
    required this.gasLevel,
    required this.presence,
    required this.distance,
    required this.comfortScore,
    required this.comfortStatus,
    required this.timestamp,
  });

  // ── Comfort Index Engine ──────────────────────────────────────────────────
  // Formula: Score = W1×NormSuhu + W2×NormRH + W3×NormLux + W4×NormGas
  // Bobot: W1=0.35, W2=0.25, W3=0.25, W4=0.15
  static int calculateComfort({
    required double temp,
    required double humidity,
    required double lux,
    required int gas,
  }) {
    final normTemp    = _normalize(temp,     min: 18, max: 32, idealMin: 22, idealMax: 26);
    final normRH      = _normalize(humidity, min: 20, max: 90, idealMin: 40, idealMax: 60);
    final normLux     = _normalize(lux,      min: 0,  max: 800, idealMin: 300, idealMax: 500);
    final normGas     = 1.0 - (gas / 100.0); // lebih rendah = lebih baik

    final score = (0.35 * normTemp + 0.25 * normRH + 0.25 * normLux + 0.15 * normGas) * 100;
    return score.clamp(0, 100).round();
  }

  static double _normalize(
    double val, {
    required double min,
    required double max,
    required double idealMin,
    required double idealMax,
  }) {
    if (val >= idealMin && val <= idealMax) return 1.0;
    if (val < idealMin) return ((val - min) / (idealMin - min)).clamp(0, 1);
    return (1.0 - (val - idealMax) / (max - idealMax)).clamp(0, 1);
  }

  static String scoreToStatus(int score) {
    if (score >= 80) return 'Optimal';
    if (score >= 65) return 'Cukup Nyaman';
    if (score >= 45) return 'Kurang Nyaman';
    return 'Tidak Nyaman';
  }

  // ── Factory dari Firebase ─────────────────────────────────────────────────
  // TODO: Aktifkan ini saat Firebase sudah terhubung
  // factory SensorData.fromMap(Map<String, dynamic> map) {
  //   final temp     = (map['temperature'] as num?)?.toDouble() ?? 25.0;
  //   final humidity = (map['humidity'] as num?)?.toDouble() ?? 60.0;
  //   final lux      = (map['lux'] as num?)?.toDouble() ?? 300.0;
  //   final gas      = (map['gas'] as num?)?.toInt() ?? 30;
  //   final score    = calculateComfort(temp: temp, humidity: humidity, lux: lux, gas: gas);
  //   return SensorData(
  //     temperature: temp, humidity: humidity, lux: lux, gasLevel: gas,
  //     presence: map['pir'] as bool? ?? false,
  //     distance: (map['distance'] as num?)?.toDouble() ?? 0,
  //     comfortScore: score, comfortStatus: scoreToStatus(score),
  //     timestamp: DateTime.now(),
  //   );
  // }

  // ── Copy with (untuk simulasi perubahan nilai) ────────────────────────────
  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? lux,
    int? gasLevel,
    bool? presence,
    double? distance,
  }) {
    final t  = temperature ?? this.temperature;
    final rh = humidity ?? this.humidity;
    final l  = lux ?? this.lux;
    final g  = gasLevel ?? this.gasLevel;
    final score = calculateComfort(temp: t, humidity: rh, lux: l, gas: g);
    return SensorData(
      temperature: t, humidity: rh, lux: l, gasLevel: g,
      presence: presence ?? this.presence,
      distance: distance ?? this.distance,
      comfortScore: score, comfortStatus: scoreToStatus(score),
      timestamp: DateTime.now(),
    );
  }
}
