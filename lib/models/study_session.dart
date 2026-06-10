// lib/models/study_session.dart
// Model data sesi belajar — nanti diambil dari Firestore

class StudySession {
  final String id;
  final DateTime startTime;
  final int durationMinutes;
  final double avgComfortScore;
  final double avgTemperature;
  final double avgHumidity;
  final double avgLux;
  final int feedbackLevel; // 1–4

  const StudySession({
    required this.id,
    required this.startTime,
    required this.durationMinutes,
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

  String get durationLabel {
    if (durationMinutes < 60) return '${durationMinutes}m';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}j' : '${h}j ${m}m';
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.parse(map['startTime'] as String),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
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
      'durationMinutes': durationMinutes,
      'avgComfortScore': avgComfortScore,
      'avgTemperature': avgTemperature,
      'avgHumidity': avgHumidity,
      'avgLux': avgLux,
      'feedbackLevel': feedbackLevel,
    };
  }
}