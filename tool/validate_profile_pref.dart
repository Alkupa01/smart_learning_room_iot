import 'package:smart_learning_room/models/study_session.dart';
import 'package:smart_learning_room/models/user_profile.dart';

void main() {
  final now = DateTime.now();
  final sessions = [
    StudySession(
      id: '1',
      startTime: now,
      durationMinutes: 45,
      avgComfortScore: 82,
      avgTemperature: 25.2,
      avgHumidity: 58,
      avgLux: 360,
      feedbackLevel: 3,
    ),
    StudySession(
      id: '2',
      startTime: now,
      durationMinutes: 30,
      avgComfortScore: 74,
      avgTemperature: 26.8,
      avgHumidity: 65,
      avgLux: 290,
      feedbackLevel: 2,
    ),
    StudySession(
      id: '3',
      startTime: now,
      durationMinutes: 60,
      avgComfortScore: 89,
      avgTemperature: 24.5,
      avgHumidity: 54,
      avgLux: 380,
      feedbackLevel: 4,
    ),
  ];

  final goodSessions = sessions
      .where((s) => s.feedbackLevel >= 3)
      .map((s) => {
            'temp': s.avgTemperature,
            'humidity': s.avgHumidity,
            'lux': s.avgLux,
            'gas': (s.avgComfortScore * 0.4).toInt(),
          })
      .toList();

  final pref = LearnedPreference.fromSessions(goodSessions);
  print('fromSessions succeeded: $pref');
}
