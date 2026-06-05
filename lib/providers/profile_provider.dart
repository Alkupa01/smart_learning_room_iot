// lib/providers/profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/analytics_provider.dart';

// ── Learned Preference dari sesi historis ─────────────────────────────────────
// TODO: Ganti dengan data dari Firestore saat Firebase terhubung:
// final learnedPrefProvider = FutureProvider<LearnedPreference>((ref) async {
//   final snapshot = await FirebaseFirestore.instance
//       .collection('sessions')
//       .where('feedbackLevel', isGreaterThanOrEqualTo: 3)
//       .get();
//   final goodSessions = snapshot.docs.map((d) => d.data()).toList();
//   return LearnedPreference.fromSessions(goodSessions);
// });

final learnedPrefProvider = Provider<LearnedPreference>((ref) {
  final sessions = ref.watch(sessionsProvider);

  // Ambil sesi dengan feedback "Nyaman" atau "Sangat Nyaman" (level 3–4)
  final goodSessions = sessions
      .where((s) => s.feedbackLevel >= 3)
      .map((s) => {
            'temp':     s.avgTemperature,
            'humidity': s.avgHumidity,
            'lux':      s.avgLux,
            'gas':      (s.avgComfortScore * 0.4).toInt(),
          })
      .toList();

  try {
    return LearnedPreference.fromSessions(goodSessions);
  } catch (e, st) {
    // Prevent provider crash; log the offending data for debugging
    // ignore: avoid_print
    print('LearnedPreference.fromSessions error: $e\n$st\ngoodSessions: $goodSessions');
    return const LearnedPreference();
  }
});

// ── Study Pattern ─────────────────────────────────────────────────────────────
final studyPatternProvider = Provider<StudyPattern>((ref) {
  final sessions = ref.watch(sessionsProvider);
  if (sessions.isEmpty) return const StudyPattern();

  // Jam belajar paling sering dengan comfort tinggi
  final goodSessions = sessions.where((s) => s.avgComfortScore >= 75).toList();
  final hours = goodSessions.map((s) => s.startTime.hour).toList();
  
  // Jam paling sering
  final hourCount = <int, int>{};
  for (final h in hours) {
    hourCount[h] = (hourCount[h] ?? 0) + 1;
  }
  final bestHour = hourCount.isEmpty ? 8
      : hourCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  // Durasi ideal (rata-rata sesi dengan comfort > 80)
  final highSessions = sessions.where((s) => s.avgComfortScore >= 80).toList();
  final avgDuration = highSessions.isEmpty ? 45
      : highSessions.map((s) => s.durationMinutes).reduce((a, b) => a + b) ~/
        highSessions.length;

  // Hari terbaik
  const dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  final dayCount = <int, int>{};
  for (final s in goodSessions) {
    final d = s.startTime.weekday - 1;
    dayCount[d] = (dayCount[d] ?? 0) + 1;
  }
  final bestDayIdx = dayCount.isEmpty ? 3
      : dayCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  // Overall accuracy — naik seiring jumlah sesi
  final accuracy = (sessions.length / 20).clamp(0.0, 1.0);

  return StudyPattern(
    bestHourStart:    bestHour,
    bestHourEnd:      bestHour + 3,
    idealDurationMin: avgDuration.clamp(20, 120),
    totalSessions:    sessions.length,
    overallAccuracy:  accuracy,
    bestDay:          dayNames[bestDayIdx],
  );
});

// ── Feedback history per level ────────────────────────────────────────────────
final feedbackStatsProvider = Provider<Map<int, int>>((ref) {
  final sessions = ref.watch(sessionsProvider);
  final stats = <int, int>{1: 0, 2: 0, 3: 0, 4: 0};
  for (final s in sessions) {
    stats[s.feedbackLevel] = (stats[s.feedbackLevel] ?? 0) + 1;
  }
  return stats;
});