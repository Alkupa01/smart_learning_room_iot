// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/analytics_provider.dart';
import '../models/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref    = ref.watch(learnedPrefProvider);
    final pattern = ref.watch(studyPatternProvider);
    final fbStats = ref.watch(feedbackStatsProvider);
    final sessions = ref.watch(sessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar ─────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              backgroundColor: const Color(0xFFF4F6FA),
              scrolledUnderElevation: 0,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profil AI',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E)),
                  ),
                  Text('Kondisi optimal yang dipelajari dari kebiasaanmu',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── 1. Profile Header Card ──────────────────────────
                  _ProfileHeader(pattern: pattern),
                  const SizedBox(height: 16),

                  // ── 2. Model Accuracy ───────────────────────────────
                  _ModelAccuracyCard(pref: pref, sessions: sessions.length),
                  const SizedBox(height: 16),

                  // ── 3. Learned Preferences ──────────────────────────
                  _SectionLabel(label: 'Kondisi Optimal (Dipelajari AI)'),
                  const SizedBox(height: 8),
                  _LearnedPrefsCard(pref: pref, hasData: sessions.isNotEmpty),
                  const SizedBox(height: 16),

                  // ── 4. Study Pattern ────────────────────────────────
                  _SectionLabel(label: 'Pola Belajar Terbaikmu'),
                  const SizedBox(height: 8),
                  _StudyPatternCard(pattern: pattern),
                  const SizedBox(height: 16),

                  // ── 5. Feedback History ─────────────────────────────
                  _SectionLabel(label: 'Riwayat Feedback'),
                  const SizedBox(height: 8),
                  _FeedbackHistoryCard(stats: fbStats, total: sessions.length),
                  const SizedBox(height: 16),

                  // ── 6. How AI learns ────────────────────────────────
                  _HowAiLearnsCard(),
                  const SizedBox(height: 16),

                  // ── 7. Reset button ─────────────────────────────────
                  _ResetCard(
                    onReset: () => _showResetDialog(context, ref),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Profil AI?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Semua preferensi yang sudah dipelajari AI akan dihapus. '
          'Sistem mulai belajar dari awal setelah ini.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8593C)),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Hapus data profil dari Firebase
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Profil AI direset — mulai belajar dari awal'),
                  backgroundColor: const Color(0xFFE8593C),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final StudyPattern pattern;
  const _ProfileHeader({required this.pattern});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF534AB7), Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: const Color(0xFF534AB7).withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('A',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alkupa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text('${pattern.totalSessions} sesi tercatat',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                // Accuracy bar
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: pattern.overallAccuracy),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(pattern.overallAccuracy * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ]),
                const SizedBox(height: 2),
                const Text('Akurasi model keseluruhan',
                  style: TextStyle(fontSize: 9, color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Model Accuracy Card ───────────────────────────────────────────────────────
class _ModelAccuracyCard extends StatelessWidget {
  final LearnedPreference pref;
  final int sessions;
  const _ModelAccuracyCard({required this.pref, required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Akurasi Prediksi per Parameter',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('✦ AI',
                style: TextStyle(fontSize: 9, color: Color(0xFF534AB7),
                    fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            sessions < 5
                ? 'Butuh minimal 5 sesi untuk akurasi optimal — baru $sessions sesi'
                : 'Dilatih dari $sessions sesi feedback',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          _AccuracyBar(
            label: 'Suhu',
            icon:  Icons.thermostat_outlined,
            color: const Color(0xFFE8593C),
            value: pref.tempAccuracy,
          ),
          const SizedBox(height: 10),
          _AccuracyBar(
            label: 'Kelembaban',
            icon:  Icons.water_drop_outlined,
            color: const Color(0xFF378ADD),
            value: pref.humidAccuracy,
          ),
          const SizedBox(height: 10),
          _AccuracyBar(
            label: 'Cahaya',
            icon:  Icons.light_mode_outlined,
            color: const Color(0xFFBA7517),
            value: pref.luxAccuracy,
          ),
          const SizedBox(height: 10),
          _AccuracyBar(
            label: 'Kualitas Udara',
            icon:  Icons.air_outlined,
            color: const Color(0xFF1D9E75),
            value: pref.gasAccuracy,
          ),
          if (sessions < 5) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFBA7517), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Berikan feedback setelah setiap sesi agar AI semakin akurat.',
                    style: const TextStyle(fontSize: 11,
                        color: Color(0xFF854F0B), height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccuracyBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double value; // 0.0–1.0
  const _AccuracyBar({required this.label, required this.icon,
      required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      SizedBox(width: 90,
        child: Text(label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A2E))),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 36,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 900),
          builder: (_, v, __) => Text(
            '${(v * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ),
    ]);
  }
}

// ── Learned Prefs Card ────────────────────────────────────────────────────────
class _LearnedPrefsCard extends StatelessWidget {
  final LearnedPreference pref;
  final bool hasData;
  const _LearnedPrefsCard({required this.pref, required this.hasData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(children: [
        _PrefRow(
          icon:    Icons.thermostat_outlined,
          label:   'Suhu Ideal',
          value:   '${pref.minTemp.toStringAsFixed(1)} – ${pref.maxTemp.toStringAsFixed(1)}°C',
          color:   const Color(0xFFE8593C),
          hasData: hasData,
        ),
        const _Divider(),
        _PrefRow(
          icon:    Icons.water_drop_outlined,
          label:   'Kelembaban Ideal',
          value:   '${pref.minHumidity.toStringAsFixed(0)} – ${pref.maxHumidity.toStringAsFixed(0)}%',
          color:   const Color(0xFF378ADD),
          hasData: hasData,
        ),
        const _Divider(),
        _PrefRow(
          icon:    Icons.light_mode_outlined,
          label:   'Cahaya Ideal',
          value:   '${pref.minLux.toStringAsFixed(0)} – ${pref.maxLux.toStringAsFixed(0)} lux',
          color:   const Color(0xFFBA7517),
          hasData: hasData,
        ),
        const _Divider(),
        _PrefRow(
          icon:    Icons.air_outlined,
          label:   'Batas CO₂',
          value:   'Maks ${pref.maxGasLevel}%',
          color:   const Color(0xFF1D9E75),
          hasData: hasData,
        ),
      ]),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool hasData;
  const _PrefRow({required this.icon, required this.label,
      required this.value, required this.color, required this.hasData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)))),
        if (hasData)
          Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color))
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Belum cukup data',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.grey.shade100);
}

// ── Study Pattern Card ────────────────────────────────────────────────────────
class _StudyPatternCard extends StatelessWidget {
  final StudyPattern pattern;
  const _StudyPatternCard({required this.pattern});

  String _hourLabel(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(children: [
        // Jam favorit
        _PatternTile(
          icon:  Icons.schedule_outlined,
          label: 'Jam Paling Produktif',
          value: '${_hourLabel(pattern.bestHourStart)} – ${_hourLabel(pattern.bestHourEnd)}',
          sub:   'Comfort score tertinggi di rentang ini',
          color: const Color(0xFF378ADD),
        ),
        const _Divider(),

        // Durasi ideal
        _PatternTile(
          icon:  Icons.timer_outlined,
          label: 'Durasi Ideal per Sesi',
          value: '${pattern.idealDurationMin} menit',
          sub:   'Rata-rata sesi dengan comfort > 80',
          color: const Color(0xFF1D9E75),
        ),
        const _Divider(),

        // Hari terbaik
        _PatternTile(
          icon:  Icons.calendar_today_outlined,
          label: 'Hari Paling Produktif',
          value: pattern.bestDay,
          sub:   'Hari dengan rata-rata comfort tertinggi',
          color: const Color(0xFF534AB7),
        ),
        const _Divider(),

        // Total sesi
        _PatternTile(
          icon:  Icons.bookmark_outline,
          label: 'Total Sesi Tercatat',
          value: '${pattern.totalSessions} sesi',
          sub:   'Semua data dipakai melatih AI',
          color: const Color(0xFFBA7517),
        ),
      ]),
    );
  }
}

class _PatternTile extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;
  const _PatternTile({required this.icon, required this.label,
      required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 1),
            Text(sub, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ]),
        ),
        Text(value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

// ── Feedback History Card ─────────────────────────────────────────────────────
class _FeedbackHistoryCard extends StatelessWidget {
  final Map<int, int> stats;
  final int total;
  const _FeedbackHistoryCard({required this.stats, required this.total});

  static const _items = [
    (level: 4, emoji: '🤩', label: 'Sangat Nyaman',     color: Color(0xFF1D9E75)),
    (level: 3, emoji: '😊', label: 'Nyaman',             color: Color(0xFF378ADD)),
    (level: 2, emoji: '😐', label: 'Kurang Nyaman',      color: Color(0xFFBA7517)),
    (level: 1, emoji: '😫', label: 'Sangat Tidak Nyaman',color: Color(0xFFE8593C)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada feedback',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
              ),
            )
          else
            ..._items.map((item) {
              final count = stats[item.level] ?? 0;
              final ratio = total == 0 ? 0.0 : count / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  SizedBox(width: 110,
                    child: Text(item.label,
                      style: const TextStyle(fontSize: 11,
                          color: Color(0xFF1A1A2E)))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(item.color),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(width: 24,
                    child: Text('$count',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: item.color))),
                ]),
              );
            }),
        ],
      ),
    );
  }
}

// ── How AI Learns Card ────────────────────────────────────────────────────────
class _HowAiLearnsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEDFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC5C2F5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('✦ ', style: TextStyle(fontSize: 14, color: Color(0xFF534AB7))),
            Text('Bagaimana AI Belajar?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF534AB7))),
          ]),
          const SizedBox(height: 10),
          ...[
            '1. Sensor membaca kondisi ruangan setiap 30 detik selama sesi belajar.',
            '2. Setelah sesi, kamu memberikan feedback kenyamanan (emoji).',
            '3. AI mengambil data sensor saat feedback "Nyaman" atau "Sangat Nyaman".',
            '4. Dari data itu, AI menghitung rentang kondisi yang membuat kamu nyaman.',
            '5. Rentang ini dipakai untuk mengatur aktuator secara otomatis di sesi berikutnya.',
          ].map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(text,
              style: const TextStyle(fontSize: 11, color: Color(0xFF534AB7),
                  height: 1.5)),
          )),
        ],
      ),
    );
  }
}

// ── Reset Card ────────────────────────────────────────────────────────────────
class _ResetCard extends StatelessWidget {
  final VoidCallback onReset;
  const _ResetCard({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReset,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8593C).withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restart_alt, color: Color(0xFFE8593C), size: 18),
            SizedBox(width: 8),
            Text('Reset Profil AI',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Color(0xFFE8593C))),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E)),
    );
  }
}

BoxDecoration _cardDecor() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  boxShadow: [
    BoxShadow(color: Colors.black.withOpacity(0.04),
        blurRadius: 12, offset: const Offset(0, 3)),
  ],
);