// lib/models/user_profile.dart

import 'dart:math';

class LearnedPreference {
  final double minTemp;
  final double maxTemp;
  final double minHumidity;
  final double maxHumidity;
  final double minLux;
  final double maxLux;
  final int maxGasLevel;
  final double tempAccuracy;
  final double humidAccuracy;
  final double luxAccuracy;
  final double gasAccuracy;

  const LearnedPreference({
    this.minTemp      = 24.0,
    this.maxTemp      = 26.5,
    this.minHumidity  = 50.0,
    this.maxHumidity  = 62.0,
    this.minLux       = 310.0,
    this.maxLux       = 420.0,
    this.maxGasLevel  = 45,
    this.tempAccuracy  = 0.0,
    this.humidAccuracy = 0.0,
    this.luxAccuracy   = 0.0,
    this.gasAccuracy   = 0.0,
  });

  // Hitung dari data sesi feedback
  factory LearnedPreference.fromSessions(List<Map<String, dynamic>> goodSessions) {
    if (goodSessions.isEmpty) return const LearnedPreference();

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final temps = goodSessions.map((s) => toDouble(s['temp'])).toList();
    final humids = goodSessions.map((s) => toDouble(s['humidity'])).toList();
    final luxes = goodSessions.map((s) => toDouble(s['lux'])).toList();
    final gasLevels = goodSessions.map((s) => toDouble(s['gas'])).toList();

    double avg(Iterable<double> vals) {
      if (vals.isEmpty) return 0.0;
      final sum = vals.fold<double>(0.0, (acc, v) => acc + v);
      return sum / vals.length;
    }

    double stdDev(Iterable<double> vals) {
      if (vals.isEmpty) return 0.0;
      final mean = avg(vals);
      final variance = vals
              .map((v) => (v - mean) * (v - mean))
              .fold<double>(0.0, (acc, v) => acc + v) /
          vals.length;
      return sqrt(variance);
    }

    try {
      return LearnedPreference(
        minTemp:      avg(temps)    - stdDev(temps),
        maxTemp:      avg(temps)    + stdDev(temps),
        minHumidity:  avg(humids)   - stdDev(humids),
        maxHumidity:  avg(humids)   + stdDev(humids),
        minLux:       avg(luxes)    - stdDev(luxes),
        maxLux:       avg(luxes)    + stdDev(luxes),
        maxGasLevel:  toInt(avg(gasLevels) + stdDev(gasLevels)),
        tempAccuracy:  (goodSessions.length / 20).clamp(0.0, 1.0),
        humidAccuracy: (goodSessions.length / 22).clamp(0.0, 1.0),
        luxAccuracy:   (goodSessions.length / 25).clamp(0.0, 1.0),
        gasAccuracy:   (goodSessions.length / 18).clamp(0.0, 1.0),
      );
    } catch (_) {
      return const LearnedPreference();
    }
  }
}

class StudyPattern {
  final int bestHourStart; // jam 0–23
  final int bestHourEnd;
  final int idealDurationMin;
  final int totalSessions;
  final double overallAccuracy;
  final String bestDay;

  const StudyPattern({
    this.bestHourStart     = 8,
    this.bestHourEnd       = 11,
    this.idealDurationMin  = 50,
    this.totalSessions     = 0,
    this.overallAccuracy   = 0.0,
    this.bestDay           = 'Kamis',
  });
}