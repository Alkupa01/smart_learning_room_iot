// lib/models/sensor_data.dart
// Model data sensor dari ESP32-S3 dengan Integrasi KY-037 Sound Sensor

import '../utils/emotion_helper.dart';

class SensorData {
  final double temperature;
  final double humidity;
  final double lux;
  final int soundLevel; // Pengganti gasLevel total
  final bool presence;
  final double distance;
  final String timestamp;
  final int comfortScore;      // Menyimpan hasil kalkulasi score
  final String comfortStatus;  // Menyimpan label status kenyamanan
  final String emotionEmoji;   // Emoji berdasarkan comfort score
  final String emotionDescription; // Deskripsi emosi detail

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.lux,
    required this.soundLevel,
    required this.presence,
    required this.distance,
    required this.timestamp,
    required this.comfortScore,
    required this.comfortStatus,
    required this.emotionEmoji,
    required this.emotionDescription,
  });

  // ── Comfort Index Engine (Diadaptasi untuk Polusi Suara KY-037) ──────────────
  // Bobot: Temp=0.35, Kelembaban=0.25, Lux=0.25, Kebisingan Suara=0.15
  static int calculateComfort({
    required double temp,
    required double humidity,
    required double lux,
    required int sound,
  }) {
    final normTemp = _normalize(
      temp,
      min: 18,
      max: 32,
      idealMin: 22,
      idealMax: 26,
    );
    final normRH = _normalize(
      humidity,
      min: 20,
      max: 90,
      idealMin: 40,
      idealMax: 60,
    );
    final normLux = _normalize(
      lux,
      min: 0,
      max: 800,
      idealMin: 300,
      idealMax: 500,
    );
    
    // Suara makin tinggi (bising) = nilai kenyamanan makin rendah
    final normSound = 1.0 - (sound / 100.0); 

    final score =
        (0.35 * normTemp + 0.25 * normRH + 0.25 * normLux + 0.15 * normSound) *
        100;
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

  // Label status kenyamanan berdasarkan tingkat kebisingan suara KY-037
  String get soundStatus {
    if (soundLevel > 70) return 'Bising';
    if (soundLevel > 40) return 'Ramai';
    return 'Tenang';
  }

  // ── Factory untuk Mapping data dari Firebase Realtime DB ──────────────────
  factory SensorData.fromMap(Map<String, dynamic> map) {
    final temp = (map['temperature'] as num?)?.toDouble() ?? 25.0;
    final humidity = (map['humidity'] as num?)?.toDouble() ?? 60.0;
    final lux = (map['lux'] as num?)?.toDouble() ?? 300.0;
    
    // Menangkap data suara baru dari ESP32 (mendukung fallback nama jika ada tipe lama)
    final sound = (map['soundLevel'] as num?)?.toInt() ?? 
                  (map['gasLevel'] as num?)?.toInt() ?? 
                  20; 

    final score = calculateComfort(
      temp: temp,
      humidity: humidity,
      lux: lux,
      sound: sound,
    );

    // Inisialisasi sementara untuk mendapatkan SensorData
    final sensorData = SensorData(
      temperature: temp,
      humidity: humidity,
      lux: lux,
      soundLevel: sound,
      presence: map['presence'] as bool? ?? map['pir'] as bool? ?? false,
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      comfortScore: score,
      comfortStatus: scoreToStatus(score),
      emotionEmoji: EmotionHelper.getEmoji(score),
      emotionDescription: '', // Akan diisi ulang di bawah
      timestamp: map['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );

    return SensorData(
      temperature: temp,
      humidity: humidity,
      lux: lux,
      soundLevel: sound,
      presence: sensorData.presence,
      distance: sensorData.distance,
      comfortScore: score,
      comfortStatus: scoreToStatus(score),
      emotionEmoji: EmotionHelper.getEmoji(score),
      emotionDescription: EmotionHelper.getEmotionDescription(score, sensorData),
      timestamp: sensorData.timestamp,
    );
  }

  // ── Copy with (Sintaks Bersih Bebas Eror) ──────────────────────────────────
  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? lux,
    int? soundLevel,
    bool? presence,
    double? distance,
  }) {
    final t = temperature ?? this.temperature;
    final rh = humidity ?? this.humidity;
    final l = lux ?? this.lux;
    final s = soundLevel ?? this.soundLevel;
    final score = calculateComfort(temp: t, humidity: rh, lux: l, sound: s);

    final updatedSensor = SensorData(
      temperature: t,
      humidity: rh,
      lux: l,
      soundLevel: s,
      presence: presence ?? this.presence,
      distance: distance ?? this.distance,
      comfortScore: score,
      comfortStatus: scoreToStatus(score),
      emotionEmoji: EmotionHelper.getEmoji(score),
      emotionDescription: '', // Placeholder
      timestamp: timestamp,
    );

    return SensorData(
      temperature: t,
      humidity: rh,
      lux: l,
      soundLevel: s,
      presence: presence ?? this.presence,
      distance: distance ?? this.distance,
      comfortScore: score,
      comfortStatus: scoreToStatus(score),
      emotionEmoji: EmotionHelper.getEmoji(score),
      emotionDescription: EmotionHelper.getEmotionDescription(score, updatedSensor),
      timestamp: timestamp,
    );
  }
}