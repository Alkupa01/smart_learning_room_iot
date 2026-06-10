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

  return sessions.where((s) {
    final diff = now.difference(s.startTime);
    
    // FIX: Eksplisit casting 'as AnalyticsPeriod' agar switch expression bersifat exhaustive
    return switch (period as AnalyticsPeriod) {
      AnalyticsPeriod.today => diff.inDays == 0,
      AnalyticsPeriod.week => diff.inDays <= 6,
      AnalyticsPeriod.month => diff.inDays <= 29,
    };
  }).toList();
});

// Total durasi belajar (menghitung total detik murni secara riil)
final totalMinutesProvider = Provider<int>((ref) {
  return ref
      .watch(filteredSessionsProvider)
      .fold(0, (sum, s) => sum + s.durationMinutes);
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
    (a, b) => (a.avgComfortScore + a.durationMinutes * 0.3) >
            (b.avgComfortScore + b.durationMinutes * 0.3)
        ? a
        : b,
  );
});

// ── PROVIDER GRAFIK ADAPTIF (HARI / MINGGU / BULAN HISTORIS TAHUN 2026) ───────
final weeklyChartDataProvider = Provider<List<({String day, int minutes, double comfort})>>((ref) {
  final sessions = ref.watch(sessionsProvider);
  final period = ref.watch(analyticsPeriodProvider);
  final now = DateTime.now();

  // ───────────────────────────────────────────────────────────────────────────
  // KONDISI 1 & 2: FILTER "HARI INI" ATAU "MINGGU INI" (Tampilan 7 Hari Kerja)
  // ───────────────────────────────────────────────────────────────────────────
  if (period == AnalyticsPeriod.today || period == AnalyticsPeriod.week) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return List.generate(7, (i) {
      final target = now.subtract(Duration(days: 6 - i));
      final daySessions = sessions
          .where(
            (s) =>
                s.startTime.day == target.day &&
                s.startTime.month == target.month &&
                s.startTime.year == target.year,
          )
          .toList();

      final totalSecs = daySessions.fold(0, (sum, s) => sum + s.durationMinutes);
      final avgComfort = daySessions.isEmpty
          ? 0.0
          : daySessions.map((s) => s.avgComfortScore).reduce((a, b) => a + b) /
                daySessions.length;

      return (
        day: days[target.weekday - 1],
        minutes: totalSecs,
        comfort: avgComfort,
      );
    });
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // KONDISI 3: FILTER "BULAN INI" -> AKUMULASI 12 BULAN SECARA REAL (TAHUN 2026)
  // ───────────────────────────────────────────────────────────────────────────
  else {
    return List.generate(12, (i) {
      final targetMonth = i + 1; // 1 = Januari, 12 = Desember

      final monthSessions = sessions
          .where(
            (s) =>
                s.startTime.month == targetMonth &&
                s.startTime.year == now.year,
          )
          .toList();

      final totalSecs = monthSessions.fold(0, (sum, s) => sum + s.durationMinutes);
      final avgComfort = monthSessions.isEmpty
          ? 0.0
          : monthSessions
                    .map((s) => s.avgComfortScore)
                    .reduce((a, b) => a + b) /
                monthSessions.length;

      return (
        day: 'Bulan $targetMonth',
        minutes: totalSecs,
        comfort: avgComfort,
      );
    });
  }
});