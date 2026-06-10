// lib/screens/analytics_screen.dart
// Screen Analitik — summary, chart mingguan, comfort harian, best session

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../models/study_session.dart';
import '../widgets/session_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period       = ref.watch(analyticsPeriodProvider);
    final sessions     = ref.watch(filteredSessionsProvider);
    final totalSeconds = ref.watch(totalSecondsProvider);
    final avgComfort   = ref.watch(avgComfortProvider);
    final bestSession  = ref.watch(bestSessionProvider);
    final weeklyData   = ref.watch(weeklyChartDataProvider);

    final chartTitle = switch (period) {
      AnalyticsPeriod.today => 'Durasi Belajar per Jam',
      AnalyticsPeriod.week => 'Durasi Belajar per Hari',
      AnalyticsPeriod.month => 'Durasi Belajar per Minggu',
    };

    final chartSubtitle = switch (period) {
      AnalyticsPeriod.today => 'Hari ini (2 jam per bar)',
      AnalyticsPeriod.week => 'Minggu ini (per hari)',
      AnalyticsPeriod.month => 'Bulan ini (per minggu)',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              backgroundColor: const Color(0xFFF4F6FA),
              scrolledUnderElevation: 0,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analitik Belajar',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E)),
                  ),
                  Text('Lacak progress sesi belajarmu',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                // Export hint
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(Icons.ios_share_outlined,
                      color: Colors.grey.shade400, size: 20),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── 1. Filter periode ────────────────────────────────
                  _PeriodFilter(
                    selected: period,
                    onChanged: (p) =>
                        ref.read(analyticsPeriodProvider.notifier).state = p,
                  ),
                  const SizedBox(height: 16),

                  // ── 2. Summary cards ─────────────────────────────────
                  _SummaryCards(
                    totalSeconds: totalSeconds,
                    avgComfort:   avgComfort,
                    totalSessions: sessions.length,
                  ),
                  const SizedBox(height: 16),

                  // ── 3. Bar chart mingguan ─────────────────────────────
                  _ChartCard(
                    title:    chartTitle,
                    subtitle: chartSubtitle,
                    height:   180,
                    child:    WeeklyBarChart(data: weeklyData),
                  ),
                  const SizedBox(height: 12),

                  // ── 4. Comfort line chart ─────────────────────────────
                  _ChartCard(
                    title:    'Comfort Score Hari Ini',
                    subtitle: 'Per sesi belajar',
                    height:   160,
                    child: ComfortLineChart(
                      data: sessions
                          .where((s) => DateTime.now()
                              .difference(s.startTime)
                              .inDays == 0)
                          .map((s) => (
                                time:  s.timeLabel,
                                score: s.avgComfortScore,
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 5. Best session card ──────────────────────────────
                  if (bestSession != null)
                    _BestSessionCard(session: bestSession),
                  const SizedBox(height: 16),

                  // ── 6. Daftar sesi terbaru ────────────────────────────
                  _SectionLabel(label: 'Sesi Terbaru'),
                  const SizedBox(height: 8),
                  if (sessions.isEmpty)
                    _EmptyState()
                  else
                    ...sessions.take(5).map(
                        (s) => _SessionTile(session: s)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period Filter ─────────────────────────────────────────────────────────────
class _PeriodFilter extends StatelessWidget {
  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;
  const _PeriodFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PChip(label: 'Hari Ini', period: AnalyticsPeriod.today,
            selected: selected, onTap: onChanged),
        const SizedBox(width: 8),
        _PChip(label: 'Minggu Ini', period: AnalyticsPeriod.week,
            selected: selected, onTap: onChanged),
        const SizedBox(width: 8),
        _PChip(label: 'Bulan Ini', period: AnalyticsPeriod.month,
            selected: selected, onTap: onChanged),
      ],
    );
  }
}

class _PChip extends StatelessWidget {
  final String label;
  final AnalyticsPeriod period;
  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onTap;
  const _PChip({required this.label, required this.period,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOn = selected == period;
    return GestureDetector(
      onTap: () => onTap(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isOn ? const Color(0xFF1D9E75) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isOn ? [BoxShadow(color: const Color(0xFF1D9E75).withOpacity(0.3),
              blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: isOn ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

// ── Summary Cards ─────────────────────────────────────────────────────────────
class _SummaryCards extends StatelessWidget {
  final int totalSeconds;
  final double avgComfort;
  final int totalSessions;
  const _SummaryCards({
    required this.totalSeconds,
    required this.avgComfort,
    required this.totalSessions,
  });

  String get _durationLabel {
    final s = totalSeconds % 60;
    final m = totalSeconds ~/ 60;
    final h = m ~/ 60;
    final mm = m % 60;

    if (h > 0) {
      return s == 0
          ? '${h}j ${mm}m'
          : '${h}j ${mm}m ${s}s';
    }
    if (m > 0) {
      return s == 0 ? '${m}m' : '${m}m ${s}s';
    }
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon:  Icons.timer_outlined,
          label: 'Total Belajar',
          value: _durationLabel,
          color: const Color(0xFF378ADD),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon:  Icons.sentiment_satisfied_alt_outlined,
          label: 'Avg Comfort',
          value: avgComfort == 0 ? '-' : avgComfort.toStringAsFixed(0),
          color: const Color(0xFF1D9E75),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon:  Icons.bookmark_outline,
          label: 'Sesi',
          value: totalSessions.toString(),
          color: const Color(0xFF534AB7),
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: color, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Chart Card wrapper ────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double height;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle,
      required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E)),
              ),
              Text(subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

// ── Best Session Card ─────────────────────────────────────────────────────────
class _BestSessionCard extends StatelessWidget {
  final StudySession session;
  const _BestSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D9E75), Color(0xFF0A7A5A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1D9E75).withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Text('Sesi Terbaik Periode Ini',
                style: TextStyle(fontSize: 12, color: Colors.white70,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Text('✦ AI', style: TextStyle(fontSize: 9,
                      color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _BestStat(label: 'Comfort', value: session.avgComfortScore.toStringAsFixed(0)),
              const SizedBox(width: 20),
              _BestStat(label: 'Durasi',  value: session.durationLabel),
              const SizedBox(width: 20),
              _BestStat(label: 'Hari',    value: '${session.dayLabel} ${session.timeLabel}'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ConditionChip(icon: Icons.thermostat,   value: '${session.avgTemperature.toStringAsFixed(1)}°C'),
                _ConditionChip(icon: Icons.water_drop,   value: '${session.avgHumidity.toStringAsFixed(0)}%'),
                _ConditionChip(icon: Icons.light_mode,   value: '${session.avgLux.toStringAsFixed(0)} lx'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Kondisi lingkungan saat sesi ini dipelajari AI sebagai referensi optimal.',
            style: TextStyle(fontSize: 10, color: Colors.white60, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BestStat extends StatelessWidget {
  final String label, value;
  const _BestStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 18,
            fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
      ],
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final IconData icon;
  final String value;
  const _ConditionChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: Colors.white70, size: 13),
      const SizedBox(width: 4),
      Text(value, style: const TextStyle(fontSize: 11,
          color: Colors.white, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── Session Tile ──────────────────────────────────────────────────────────────
class _SessionTile extends StatelessWidget {
  final StudySession session;
  const _SessionTile({required this.session});

  Color get _scoreColor {
    if (session.avgComfortScore >= 80) return const Color(0xFF1D9E75);
    if (session.avgComfortScore >= 60) return const Color(0xFFBA7517);
    return const Color(0xFFE8593C);
  }

  String get _feedbackEmoji => ['', '😫', '😐', '😊', '🤩'][session.feedbackLevel];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _scoreColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(session.avgComfortScore.toStringAsFixed(0),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                    color: _scoreColor),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${session.dayLabel}  ·  ${session.timeLabel}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 3),
                Text('${session.durationLabel}  ·  ${session.avgTemperature.toStringAsFixed(1)}°C  ·  ${session.avgHumidity.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Feedback emoji
          Text(_feedbackEmoji, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_outlined, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text('Belum ada sesi di periode ini',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          const SizedBox(height: 4),
          Text('Mulai sesi belajar dari halaman Dashboard',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}