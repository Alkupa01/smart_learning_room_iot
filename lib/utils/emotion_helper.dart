// lib/utils/emotion_helper.dart
// Utility untuk menentukan emoji emosi berdasarkan comfort score dan sensor data

import '../models/sensor_data.dart';

// ── Enum untuk status emosi ────────────────────────────────────────────────
enum EmotionStatus {
  veryHappy,  // 80-100: Optimal
  happy,      // 65-79: Cukup Nyaman
  neutral,    // 45-64: Kurang Nyaman
  sad,        // 20-44: Tidak Nyaman
  verySad,    // 0-19: Sangat Tidak Nyaman
}

class EmotionHelper {

  // ── Map emoji berdasarkan emotion status ───────────────────────────────
  static const Map<EmotionStatus, String> emotionEmojis = {
    EmotionStatus.veryHappy: '😄',  // Sangat senang
    EmotionStatus.happy: '🙂',      // Biasa (cukup baik)
    EmotionStatus.neutral: '😐',    // Netral (kurang)
    EmotionStatus.sad: '😕',        // Sedih (tidak nyaman)
    EmotionStatus.verySad: '😞',    // Sangat sedih (sangat tidak nyaman)
  };

  // ── Map warna berdasarkan emotion status ───────────────────────────────
  static const Map<EmotionStatus, int> emotionColors = {
    EmotionStatus.veryHappy: 0xFF1D9E75,  // Hijau terang (optimal)
    EmotionStatus.happy: 0xFF7CB342,      // Hijau muda (cukup)
    EmotionStatus.neutral: 0xFFBA7517,    // Orange (kurang)
    EmotionStatus.sad: 0xFFE8593C,        // Red-orange (tidak nyaman)
    EmotionStatus.verySad: 0xFFD32F2F,    // Merah (sangat tidak nyaman)
  };

  // ── Tentukan emotion status dari comfort score ──────────────────────────
  static EmotionStatus getEmotionStatus(int comfortScore) {
    if (comfortScore >= 80) return EmotionStatus.veryHappy;
    if (comfortScore >= 65) return EmotionStatus.happy;
    if (comfortScore >= 45) return EmotionStatus.neutral;
    if (comfortScore >= 20) return EmotionStatus.sad;
    return EmotionStatus.verySad;
  }

  // ── Dapatkan emoji berdasarkan comfort score ────────────────────────────
  static String getEmoji(int comfortScore) {
    return emotionEmojis[getEmotionStatus(comfortScore)] ?? '😐';
  }

  // ── Dapatkan warna berdasarkan comfort score ────────────────────────────
  static int getEmotionColor(int comfortScore) {
    return emotionColors[getEmotionStatus(comfortScore)] ?? 0xFF1D9E75;
  }

  // ── Analisis problem utama dari sensor data untuk konteks AI ─────────────
  static String analyzePrimaryIssue(SensorData sensor) {
    // Cari sensor yang paling tidak ideal
    final issues = <String, double>{
      'temperature': _getTemperatureIssueScore(sensor.temperature),
      'humidity': _getHumidityIssueScore(sensor.humidity),
      'light': _getLightIssueScore(sensor.lux),
      'sound': _getSoundIssueScore(sensor.soundLevel),
    };

    // Urutkan berdasarkan severity (score tertinggi = paling masalah)
    final sorted = issues.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return issue tertinggi
    if (sorted.isNotEmpty && sorted.first.value > 0) {
      return sorted.first.key;
    }
    return 'overall';
  }

  // ── Score untuk setiap sensor (0 = OK, 1 = Problem) ──────────────────────
  static double _getTemperatureIssueScore(double temp) {
    if (temp >= 22 && temp <= 26) return 0; // Optimal
    if (temp > 28 || temp < 18) return 1.0; // Sangat problem
    return 0.5; // Moderate problem
  }

  static double _getHumidityIssueScore(double humidity) {
    if (humidity >= 40 && humidity <= 60) return 0; // Optimal
    if (humidity > 75 || humidity < 30) return 1.0; // Sangat problem
    return 0.5; // Moderate problem
  }

  static double _getLightIssueScore(double lux) {
    if (lux >= 300 && lux <= 500) return 0; // Optimal
    if (lux > 600 || lux < 200) return 1.0; // Sangat problem
    return 0.5; // Moderate problem
  }

  static double _getSoundIssueScore(int soundLevel) {
    if (soundLevel < 40) return 0; // Optimal (Tenang)
    if (soundLevel > 70) return 1.0; // Sangat problem (Bising)
    return 0.5; // Moderate problem (Ramai)
  }

  // ── Dapatkan deskripsi emosi yang detail ────────────────────────────────
  static String getEmotionDescription(int comfortScore, SensorData? sensor) {
    final status = getEmotionStatus(comfortScore);
    final emoji = emotionEmojis[status] ?? '😐';

    String description = '';
    switch (status) {
      case EmotionStatus.veryHappy:
        description = '$emoji Lingkungan belajar sangat optimal!';
        break;
      case EmotionStatus.happy:
        description = '$emoji Kondisi cukup nyaman untuk belajar';
        break;
      case EmotionStatus.neutral:
        description = '$emoji Kurang nyaman, ada beberapa masalah';
        break;
      case EmotionStatus.sad:
        description = '$emoji Tidak nyaman, perlu perbaikan';
        break;
      case EmotionStatus.verySad:
        description = '$emoji Sangat tidak nyaman untuk belajar';
        break;
    }

    // Tambahkan detail masalah jika ada
    if (sensor != null) {
      final issue = analyzePrimaryIssue(sensor);
      switch (issue) {
        case 'temperature':
          description += ' (Suhu tidak ideal)';
        case 'humidity':
          description += ' (Kelembaban kurang tepat)';
        case 'light':
          description += ' (Cahaya tidak optimal)';
        case 'sound':
          description += ' (Suara terlalu bising)';
        default:
          break;
      }
    }

    return description;
  }

  // ── Validasi apakah sound adalah masalah utama ─────────────────────────
  static bool isSoundTheProblem(SensorData sensor) {
    return analyzePrimaryIssue(sensor) == 'sound' && sensor.soundLevel > 70;
  }
}
