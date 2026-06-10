// lib/providers/analytics_provider.dart
// Provider untuk data sesi belajar historis terintegrasi Firebase Realtime DB
// Tim: Alkupa, Danniel, Nicholas — Universitas Ciputra Surabaya

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/study_session.dart';
import 'sensor_provider.dart';

// ── Filter periode ────────────────────────────────────────────────────────────
enum AnalyticsPeriod { today, week, month }

// ── FIX Riverpod 3.x: Mengganti StateProvider dengan Notifier Modern ──────────
class AnalyticsPeriodNotifier extends Notifier<AnalyticsPeriod> {
  @override
  AnalyticsPeriod build() => AnalyticsPeriod.today;

  set state(AnalyticsPeriod value) => super.state = value;
}

final analyticsPeriodProvider = NotifierProvider<AnalyticsPeriodNotifier, AnalyticsPeriod>(() {
  return AnalyticsPeriodNotifier();
});

// ── Data sesi belajar dari Firebase Realtime Database ─────────────────────────
final sessionsStreamProvider = StreamProvider<List<StudySession>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getSessionStream();
});

final sessionsProvider = Provider<List<StudySession>>((ref) {
  return ref
      .watch(sessionsStreamProvider)
      .maybeWhen(data: (sessions) => sessions, orElse: () => []);
});

// ── Derived providers ─────────────────────────────────────────────────────────

// Sesi yang sudah difilter berdasarkan periode aktif
final filteredSessionsProvider = Provider<List<StudySession>>((ref) {
  final sessions = ref.watch(sessionsProvider);
  final period = ref.watch(analyticsPeriodProvider);
  final now = DateTime.now();

  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
  final startOfMonth = DateTime(now.year, now.month, 1);

  return sessions.where((s) {
    final startTime = s.startTime;

    return switch (period) {
      AnalyticsPeriod.today =>
        startTime.isAfter(startOfToday.subtract(const Duration(milliseconds: 1))) &&
            startTime.isBefore(startOfToday.add(const Duration(days: 1))),
      AnalyticsPeriod.week =>
        startTime.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) &&
            startTime.isBefore(startOfWeek.add(const Duration(days: 7))),
      AnalyticsPeriod.month =>
        startTime.isAfter(startOfMonth.subtract(const Duration(milliseconds: 1))) &&
            startTime.isBefore(DateTime(now.year, now.month + 1, 1)),
    };
  }).toList();
});

// Total durasi belajar (menghitung total detik murni secara riil)
final totalSecondsProvider = Provider<int>((ref) {
  return ref
      .watch(filteredSessionsProvider)
      .fold(0, (sum, s) => sum + s.durationSeconds);
});

// Rata-rata comfort score
final avgComfortProvider = Provider<double>((ref) {
  final sessions = ref.watch(filteredSessionsProvider);
  if (sessions.isEmpty) return 0;
  return sessions.map((s) => s.avgComfortScore).reduce((a, b) => a + b) /
      sessions.length;
});

// Sesi terbaik (comfort tertinggi + durasi terpanjang)
final bestSessionProvider = Provider<StudySession?>((ref) {
  final sessions = ref.watch(filteredSessionsProvider);
  if (sessions.isEmpty) return null;
  return sessions.reduce(
    (a, b) => (a.avgComfortScore + a.durationSeconds * 0.02) >
            (b.avgComfortScore + b.durationSeconds * 0.02)
        ? a
        : b,
  );
});

// ── PROVIDER GRAFIK ADAPTIF (HARI / MINGGU / BULAN HISTORIS TAHUN 2026) ───────
final weeklyChartDataProvider = Provider<List<({String day, int durationSeconds, double comfort})>>((ref) {
  final sessions = ref.watch(sessionsProvider);
  final period = ref.watch(analyticsPeriodProvider);
  final now = DateTime.now();

  // ───────────────────────────────────────────────────────────────────────────
  // KONDISI 1: FILTER "HARI INI" (Tampilan per jam / interval 2 jam)
  // ───────────────────────────────────────────────────────────────────────────
  if (period == AnalyticsPeriod.today) {
    const slotLabels = [
      '00-01', '02-03', '04-05', '06-07', '08-09', '10-11',
      '12-13', '14-15', '16-17', '18-19', '20-21', '22-23',
    ];

    return List.generate(12, (i) {
      final startHour = i * 2;
      final endHour = startHour + 1;
      final bucketSessions = sessions.where((s) {
        final time = s.startTime;
        return time.year == now.year &&
            time.month == now.month &&
            time.day == now.day &&
            time.hour >= startHour &&
            time.hour <= endHour;
      }).toList();

      final totalSecs = bucketSessions.fold(0, (sum, s) => sum + s.durationSeconds);
      final avgComfort = bucketSessions.isEmpty
          ? 0.0
          : bucketSessions.map((s) => s.avgComfortScore).reduce((a, b) => a + b) /
                bucketSessions.length;

      return (
        day: slotLabels[i],
        durationSeconds: totalSecs,
        comfort: avgComfort,
      );
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // KONDISI 2: FILTER "MINGGU INI" (Tampilan per hari)
  // ───────────────────────────────────────────────────────────────────────────
  if (period == AnalyticsPeriod.week) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (i) {
      final target = startOfWeek.add(Duration(days: i));
      final daySessions = sessions
          .where(
            (s) =>
                s.startTime.day == target.day &&
                s.startTime.month == target.month &&
                s.startTime.year == target.year,
          )
          .toList();

      final totalSecs = daySessions.fold(0, (sum, s) => sum + s.durationSeconds);
      final avgComfort = daySessions.isEmpty
          ? 0.0
          : daySessions.map((s) => s.avgComfortScore).reduce((a, b) => a + b) /
                daySessions.length;

      return (
        day: days[target.weekday - 1],
        durationSeconds: totalSecs,
        comfort: avgComfort,
      );
    });
  }

  final currentMonthEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
  final totalDays = currentMonthEnd.day;
  final weekCount = (totalDays / 7).ceil();

  return List.generate(weekCount, (i) {
    final weekStartDay = i * 7 + 1;
    final weekEndDay = (i + 1) * 7 > totalDays ? totalDays : (i + 1) * 7;

    final weekSessions = sessions
        .where(
          (s) =>
              s.startTime.year == now.year &&
              s.startTime.month == now.month &&
              s.startTime.day >= weekStartDay &&
              s.startTime.day <= weekEndDay,
        )
        .toList();

    final totalSecs = weekSessions.fold(0, (sum, s) => sum + s.durationSeconds);
    final avgComfort = weekSessions.isEmpty
        ? 0.0
        : weekSessions.map((s) => s.avgComfortScore).reduce((a, b) => a + b) /
              weekSessions.length;

    return (
      day: 'Minggu ${i + 1}',
      durationSeconds: totalSecs,
      comfort: avgComfort,
    );
  });
});