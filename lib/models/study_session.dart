// lib/models/study_session.dart
// Model data sesi belajar — nanti diambil dari Firestore

class StudySession {
  final String id;
  final DateTime startTime;
  final int durationSeconds;
  final double avgComfortScore;
  final double avgTemperature;
  final double avgHumidity;
  final double avgLux;
  final int feedbackLevel; // 1–4

  const StudySession({
    required this.id,
    required this.startTime,
    required this.durationSeconds,
    required this.avgComfortScore,
    required this.avgTemperature,
    required this.avgHumidity,
    required this.avgLux,
    required this.feedbackLevel,
  });

  // Label hari singkat
  String get dayLabel {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[startTime.weekday - 1];
  }

  String get timeLabel {
    final h = startTime.hour.toString().padLeft(2, '0');
    final m = startTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // lib/models/study_session.dart

  // Ganti getter durationLabel lama dengan logika hitungan detik (seconds) ini:
  String get durationLabel {
    if (durationSeconds < 60) {
      return '${durationSeconds}s';
    }
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) {
      return s == 0
          ? '${h}j ${m}m'
          : '${h}j ${m}m ${s}s';
    }
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id:
          map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.parse(map['startTime'] as String),
      durationSeconds: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      avgComfortScore: (map['avgComfortScore'] as num?)?.toDouble() ?? 0.0,
      avgTemperature: (map['avgTemperature'] as num?)?.toDouble() ?? 0.0,
      avgHumidity: (map['avgHumidity'] as num?)?.toDouble() ?? 0.0,
      avgLux: (map['avgLux'] as num?)?.toDouble() ?? 0.0,
      feedbackLevel: (map['feedbackLevel'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationSeconds,
      'avgComfortScore': avgComfortScore,
      'avgTemperature': avgTemperature,
      'avgHumidity': avgHumidity,
      'avgLux': avgLux,
      'feedbackLevel': feedbackLevel,
    };
  }
}
