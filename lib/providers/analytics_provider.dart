// lib/providers/analytics_provider.dart
// Provider untuk data sesi belajar historis
// TODO: Ganti mockSessions dengan query Firestore saat Firebase terhubung

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/study_session.dart';

// ── Filter periode ────────────────────────────────────────────────────────────
enum AnalyticsPeriod { today, week, month }

final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.week);

// ── Mock data sesi ────────────────────────────────────────────────────────────
final sessionsProvider = Provider<List<StudySession>>((ref) {
  final now = DateTime.now();

  // TODO: Ganti dengan Firestore query:
  // final snapshot = await FirebaseFirestore.instance
  //   .collection('sessions')
  //   .orderBy('startTime', descending: true)
  //   .limit(30)
  //   .get();
  // return snapshot.docs.map((d) => StudySession.fromMap(d.data())).toList();

  return [
    StudySession(id: '1', startTime: now.subtract(const Duration(days: 0, hours: 3)),  durationMinutes: 45, avgComfortScore: 82, avgTemperature: 25.2, avgHumidity: 58, avgLux: 360, feedbackLevel: 3),
    StudySession(id: '2', startTime: now.subtract(const Duration(days: 0, hours: 6)),  durationMinutes: 30, avgComfortScore: 74, avgTemperature: 26.8, avgHumidity: 65, avgLux: 290, feedbackLevel: 2),
    StudySession(id: '3', startTime: now.subtract(const Duration(days: 1, hours: 2)),  durationMinutes: 60, avgComfortScore: 89, avgTemperature: 24.5, avgHumidity: 54, avgLux: 380, feedbackLevel: 4),
    StudySession(id: '4', startTime: now.subtract(const Duration(days: 1, hours: 5)),  durationMinutes: 50, avgComfortScore: 78, avgTemperature: 25.8, avgHumidity: 61, avgLux: 340, feedbackLevel: 3),
    StudySession(id: '5', startTime: now.subtract(const Duration(days: 2, hours: 3)),  durationMinutes: 35, avgComfortScore: 65, avgTemperature: 27.5, avgHumidity: 70, avgLux: 260, feedbackLevel: 2),
    StudySession(id: '6', startTime: now.subtract(const Duration(days: 3, hours: 4)),  durationMinutes: 90, avgComfortScore: 91, avgTemperature: 24.0, avgHumidity: 52, avgLux: 410, feedbackLevel: 4),
    StudySession(id: '7', startTime: now.subtract(const Duration(days: 3, hours: 8)),  durationMinutes: 25, avgComfortScore: 70, avgTemperature: 26.2, avgHumidity: 63, avgLux: 300, feedbackLevel: 3),
    StudySession(id: '8', startTime: now.subtract(const Duration(days: 4, hours: 2)),  durationMinutes: 55, avgComfortScore: 85, avgTemperature: 25.0, avgHumidity: 57, avgLux: 370, feedbackLevel: 4),
    StudySession(id: '9', startTime: now.subtract(const Duration(days: 5, hours: 3)),  durationMinutes: 40, avgComfortScore: 77, avgTemperature: 25.5, avgHumidity: 60, avgLux: 320, feedbackLevel: 3),
    StudySession(id: '10',startTime: now.subtract(const Duration(days: 6, hours: 4)),  durationMinutes: 70, avgComfortScore: 88, avgTemperature: 24.2, avgHumidity: 55, avgLux: 395, feedbackLevel: 4),
  ];
});

// ── Derived providers ─────────────────────────────────────────────────────────

// Sesi yang sudah difilter berdasarkan periode
final filteredSessionsProvider = Provider<List<StudySession>>((ref) {
  final sessions = ref.watch(sessionsProvider);
  final period   = ref.watch(analyticsPeriodProvider);
  final now      = DateTime.now();

  return sessions.where((s) {
    final diff = now.difference(s.startTime);
    return switch (period) {
      AnalyticsPeriod.today => diff.inDays == 0,
      AnalyticsPeriod.week  => diff.inDays <= 6,
      AnalyticsPeriod.month => diff.inDays <= 29,
    };
  }).toList();
});

// Total durasi belajar (menit)
final totalMinutesProvider = Provider<int>((ref) {
  return ref.watch(filteredSessionsProvider)
      .fold(0, (sum, s) => sum + s.durationMinutes);
});

// Rata-rata comfort score
final avgComfortProvider = Provider<double>((ref) {
  final sessions = ref.watch(filteredSessionsProvider);
  if (sessions.isEmpty) return 0;
  return sessions.map((s) => s.avgComfortScore).reduce((a, b) => a + b) / sessions.length;
});

// Sesi terbaik (comfort tertinggi + durasi terpanjang)
final bestSessionProvider = Provider<StudySession?>((ref) {
  final sessions = ref.watch(filteredSessionsProvider);
  if (sessions.isEmpty) return null;
  return sessions.reduce((a, b) =>
      (a.avgComfortScore + a.durationMinutes * 0.3) >
      (b.avgComfortScore + b.durationMinutes * 0.3) ? a : b);
});

// Data untuk bar chart mingguan (durasi per hari, 7 hari terakhir)
final weeklyChartDataProvider = Provider<List<({String day, int minutes, double comfort})>>((ref) {
  final sessions = ref.watch(sessionsProvider);
  final now      = DateTime.now();
  const days     = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  return List.generate(7, (i) {
    final target = now.subtract(Duration(days: 6 - i));
    final daySessions = sessions.where((s) =>
        s.startTime.day   == target.day &&
        s.startTime.month == target.month &&
        s.startTime.year  == target.year).toList();

    final totalMin = daySessions.fold(0, (sum, s) => sum + s.durationMinutes);
    final avgComfort = daySessions.isEmpty
        ? 0.0
        : daySessions.map((s) => s.avgComfortScore).reduce((a, b) => a + b) /
          daySessions.length;

    return (day: days[target.weekday - 1], minutes: totalMin, comfort: avgComfort);
  });
});