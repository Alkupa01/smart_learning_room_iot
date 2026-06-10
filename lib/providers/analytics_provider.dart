// lib/providers/analytics_provider.dart
// Provider untuk data sesi belajar historis
// TODO: Ganti mockSessions dengan query Firestore saat Firebase terhubung

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/study_session.dart';
import 'sensor_provider.dart';

// ── Filter periode ────────────────────────────────────────────────────────────
enum AnalyticsPeriod { today, week, month }

final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.week);

// ── Data sesi belajar dari Firebase Realtime Database ─────────────────────────
final sessionsStreamProvider = StreamProvider<List<StudySession>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getSessionStream();
});

final sessionsProvider = Provider<List<StudySession>>((ref) {
  return ref.watch(sessionsStreamProvider).maybeWhen(
        data: (sessions) => sessions,
        orElse: () => [],
      );
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