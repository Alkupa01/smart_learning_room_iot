// lib/screens/pomodoro_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sensor_provider.dart';
import '../models/sensor_data.dart';
import '../models/study_session.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;

  const PomodoroScreen({super.key, this.onNavigate});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  @override
  Widget build(BuildContext context) {
    final sensorAsync = ref.watch(sensorProvider);
    final sessionActive = ref.watch(sessionActiveProvider);
    final sessionSeconds = ref.watch(sessionSecondsProvider);

    // Memastikan session timer provider aktif memantau detak stopwatch hitung maju
    ref.watch(sessionTimerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar ────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              backgroundColor: const Color(0xFFF4F6FA),
              scrolledUnderElevation: 0,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesi Belajar Aktif',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    'Stopwatch pemantau durasi fokus belajar',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── 1. Warning Kebisingan Kamar dari sensor KY-037 ───────
                  sensorAsync.maybeWhen(
                    data: (s) => _buildSoundWarning(s),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 20),

                  // ── 2. Visual Jam Stopwatch Bulat (Mulai dari 00:00:00) ──
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (sessionActive
                                        ? const Color(0xFF1D9E75)
                                        : Colors.grey)
                                    .withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: sessionActive
                              ? const Color(0xFF1D9E75).withOpacity(0.4)
                              : Colors.grey.shade200,
                          width: 5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            sessionActive
                                ? Icons.hourglass_top_rounded
                                : Icons.hourglass_empty_rounded,
                            color: sessionActive
                                ? const Color(0xFF1D9E75)
                                : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            formatDuration(sessionSeconds),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: sessionActive
                                  ? const Color(0xFF1A1A2E)
                                  : Colors.grey.shade600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sessionActive ? 'SESI BERJALAN' : 'STANDBY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: sessionActive
                                  ? const Color(0xFF1D9E75)
                                  : Colors.grey,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ── 3. Tombol Kendali Utama Sesi (Mulai / Simpan Permanen) ──
                  GestureDetector(
                    onTap: () async {
                      if (!sessionActive) {
                        // NYALAKAN STOPWATCH
                        ref.read(sessionActiveProvider.notifier).state = true;
                      } else {
                        // MATIKAN STOPWATCH DAN KIRIM DATA PERMANEN KE FIREBASE NODE /SESSIONS
                        final totalSecs = ref.read(sessionSecondsProvider);
                        ref.read(sessionActiveProvider.notifier).state = false;

                        // Proteksi simpan: Sesi minimal berjalan 2 detik agar tidak menyimpan entri kosong
                        // lib/screens/pomodoro_screen.dart
                        // Cari baris di dalam tombol onTap penyimpan database, ubah menjadi struktur ini:

                        if (totalSecs >= 2) {
                          final sensorData = ref.read(sensorProvider).value;

                          final newSession = StudySession(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            startTime: DateTime.now().subtract(
                              Duration(seconds: totalSecs),
                            ),

                            // PERBAIKAN: Kirim totalSecs langsung (bukan menit hasil pembulatan lagi)
                            durationMinutes: totalSecs,

                            avgComfortScore:
                                sensorData?.comfortScore.toDouble() ?? 80.0,
                            avgTemperature: sensorData?.temperature ?? 25.0,
                            avgHumidity: sensorData?.humidity ?? 55.0,
                            avgLux: sensorData?.lux ?? 350.0,
                            feedbackLevel: ref.read(feedbackProvider) == 0
                                ? 3
                                : ref.read(feedbackProvider),
                          );

                          await ref
                              .read(firebaseServiceProvider)
                              .saveStudySession(newSession);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sesi belajar tersimpan permanen! Mengalihkan ke Analitik...',
                                ),
                                backgroundColor: Color(0xFF1D9E75),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            // Otomatis lompat ke halaman Analitik (Tab Index 1) untuk melihat grafik historis hari ini
                            widget.onNavigate?.call(1);
                          }
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: sessionActive
                              ? [
                                  const Color(0xFFE8593C),
                                  const Color(0xFFC0392B),
                                ]
                              : [
                                  const Color(0xFF1D9E75),
                                  const Color(0xFF0F6E56),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (sessionActive
                                        ? const Color(0xFFE8593C)
                                        : const Color(0xFF1D9E75))
                                    .withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            sessionActive
                                ? Icons.stop_circle_outlined
                                : Icons.play_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sessionActive
                                ? 'Akhiri Sesi Belajar'
                                : 'Mulai Sesi Belajar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ── 4. Mini Monitor Kondisi Ruangan Saat Ini ───────────
                  sensorAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (s) => _buildLiveMonitor(s),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundWarning(SensorData sensor) {
    if (sensor.soundLevel <= 55) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBA7517).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🔊 ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ruangan Kurang Kondusif',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF854F0B),
                  ),
                ),
                Text(
                  'Tingkat kebisingan kamar mencapai ${sensor.soundLevel}%. Harap kondisikan ruangan agar fokus belajar terjaga.',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF854F0B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMonitor(SensorData s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kondisi Lingkungan Kamar',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniItem(
                Icons.thermostat_outlined,
                '${s.temperature.toStringAsFixed(1)}°C',
                'Suhu',
                const Color(0xFFE8593C),
              ),
              _buildMiniItem(
                Icons.water_drop_outlined,
                '${s.humidity.toStringAsFixed(0)}%',
                'Kelembaban',
                const Color(0xFF378ADD),
              ),
              _buildMiniItem(
                Icons.volume_up_outlined,
                '${s.soundLevel}%',
                'Kebisingan',
                const Color(0xFF1D9E75),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniItem(IconData icon, String val, String title, Color c) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: c, size: 16),
        ),
        const SizedBox(height: 5),
        Text(
          val,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c),
        ),
        Text(title, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }
}
