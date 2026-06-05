// lib/screens/pomodoro_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/sensor_provider.dart';
import '../models/sensor_data.dart';
import '../widgets/pomodoro_timer.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoro   = ref.watch(pomodoroProvider);
    final sensorAsync = ref.watch(sensorProvider);

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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sesi Belajar',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E)),
                  ),
                  Text(
                    'Sesi ${pomodoro.currentSession} dari ${pomodoro.totalSessions}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                // Setting total sesi
                if (pomodoro.state == PomodoroState.idle)
                  IconButton(
                    icon: const Icon(Icons.tune_outlined, color: Colors.grey),
                    onPressed: () => _showSettings(context, ref, pomodoro),
                  ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── 1. Break Warning ──────────────────────────────────
                  sensorAsync.maybeWhen(
                    data: (s) => _BreakWarning(sensor: s, pomodoro: pomodoro),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // ── 2. Timer ──────────────────────────────────────────
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: PomodoroTimerWidget(data: pomodoro),
                    ),
                  ),

                  // ── 3. Control Buttons ────────────────────────────────
                  _Controls(pomodoro: pomodoro, ref: ref, context: context),
                  const SizedBox(height: 20),

                  // ── 4. Env Mini Monitor ───────────────────────────────
                  sensorAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error:   (_, __) => const SizedBox.shrink(),
                    data:    (s) => _EnvMonitor(sensor: s),
                  ),
                  const SizedBox(height: 16),

                  // ── 5. Comfort progress bar ───────────────────────────
                  sensorAsync.maybeWhen(
                    data: (s) => _ComfortBar(score: s.comfortScore),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // ── 6. Sesi history dots ──────────────────────────────
                  if (pomodoro.sessionScores.isNotEmpty)
                    _SessionHistory(scores: pomodoro.sessionScores),

                  // ── 7. Finished state ─────────────────────────────────
                  if (pomodoro.state == PomodoroState.finished)
                    _FinishedCard(
                      scores: pomodoro.sessionScores,
                      onReset: () => ref.read(pomodoroProvider.notifier).stop(),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref, PomodoroData data) {
    int sessions = data.totalSessions;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Pengaturan Sesi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumlah sesi (Pomodoro)',
                      style: TextStyle(fontSize: 13)),
                  Row(children: [
                    IconButton(
                      onPressed: () => setState(() { if (sessions > 1) sessions--; }),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: const Color(0xFF1D9E75),
                    ),
                    Text('$sessions',
                      style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w700)),
                    IconButton(
                      onPressed: () => setState(() { if (sessions < 8) sessions++; }),
                      icon: const Icon(Icons.add_circle_outline),
                      color: const Color(0xFF1D9E75),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              Text('${sessions * 25} menit fokus  +  ${sessions * 5} menit istirahat',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    // TODO: update total sessions di notifier jika perlu
                    Navigator.pop(ctx);
                  },
                  child: const Text('Simpan',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Break Warning ─────────────────────────────────────────────────────────────
class _BreakWarning extends StatelessWidget {
  final SensorData sensor;
  final PomodoroData pomodoro;
  const _BreakWarning({required this.sensor, required this.pomodoro});

  bool get _shouldWarn =>
      pomodoro.state == PomodoroState.running &&
      !pomodoro.isBreak &&
      sensor.gasLevel > 55;

  @override
  Widget build(BuildContext context) {
    if (!_shouldWarn) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBA7517).withOpacity(0.3)),
      ),
      child: Row(children: [
        const Text('⏰ ', style: TextStyle(fontSize: 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Istirahat Disarankan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFF854F0B)),
              ),
              Text('CO₂ meningkat (${sensor.gasLevel}%) — '
                  'buka jendela saat istirahat untuk segar kembali',
                style: const TextStyle(fontSize: 10, color: Color(0xFF854F0B),
                    height: 1.4),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Control Buttons ───────────────────────────────────────────────────────────
class _Controls extends StatelessWidget {
  final PomodoroData pomodoro;
  final WidgetRef ref;
  final BuildContext context;
  const _Controls({required this.pomodoro, required this.ref, required this.context});

  PomodoroNotifier get _notifier => ref.read(pomodoroProvider.notifier);

  @override
  Widget build(BuildContext context) {
    return switch (pomodoro.state) {
      PomodoroState.idle     => _IdleControls(onStart: _notifier.start),
      PomodoroState.running  => _RunningControls(
          onPause: _notifier.pause,
          onBreak: _notifier.startBreak,
          onStop:  () => _confirmStop(context),
          isBreak: pomodoro.isBreak,
        ),
      PomodoroState.paused   => _PausedControls(
          onResume: _notifier.resume,
          onStop:   () => _confirmStop(context),
        ),
      PomodoroState.shortBreak => _BreakControls(
          onSkip:  _notifier.skipBreak,
          onStop:  () => _confirmStop(context),
        ),
      PomodoroState.finished => const SizedBox.shrink(),
    };
  }

  void _confirmStop(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hentikan Sesi?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Progress sesi yang sedang berjalan akan hilang.',
            style: TextStyle(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Lanjutkan')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8593C)),
            onPressed: () { Navigator.pop(ctx); _notifier.stop(); },
            child: const Text('Stop', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _IdleControls extends StatelessWidget {
  final VoidCallback onStart;
  const _IdleControls({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return _BigButton(
      label: '▶  Mulai Sesi Fokus',
      color: const Color(0xFF1D9E75),
      onTap: onStart,
    );
  }
}

class _RunningControls extends StatelessWidget {
  final VoidCallback onPause, onBreak, onStop;
  final bool isBreak;
  const _RunningControls({required this.onPause, required this.onBreak,
      required this.onStop, required this.isBreak});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (!isBreak)
        _BigButton(
          label: '⏸  Jeda',
          color: const Color(0xFFBA7517),
          onTap: onPause,
        ),
      if (!isBreak) const SizedBox(height: 10),
      Row(children: [
        if (!isBreak) ...[
          Expanded(child: _SmallButton(
            label: '☕ Istirahat',
            color: const Color(0xFF378ADD),
            onTap: onBreak,
          )),
          const SizedBox(width: 10),
        ],
        Expanded(child: _SmallButton(
          label: '⏹ Stop',
          color: const Color(0xFFE8593C),
          onTap: onStop,
          outlined: true,
        )),
      ]),
    ]);
  }
}

class _PausedControls extends StatelessWidget {
  final VoidCallback onResume, onStop;
  const _PausedControls({required this.onResume, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _BigButton(label: '▶  Lanjutkan', color: const Color(0xFF1D9E75), onTap: onResume),
      const SizedBox(height: 10),
      _SmallButton(label: '⏹ Stop', color: const Color(0xFFE8593C), onTap: onStop, outlined: true),
    ]);
  }
}

class _BreakControls extends StatelessWidget {
  final VoidCallback onSkip, onStop;
  const _BreakControls({required this.onSkip, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _BigButton(label: '⏭  Skip Istirahat', color: const Color(0xFF378ADD), onTap: onSkip),
      const SizedBox(height: 10),
      _SmallButton(label: '⏹ Stop', color: const Color(0xFFE8593C), onTap: onStop, outlined: true),
    ]);
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.black, 0.15)!],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withOpacity(0.35),
              blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;
  const _SmallButton({required this.label, required this.color,
      required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: outlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(14),
          border: outlined ? Border.all(color: color.withOpacity(0.5)) : null,
          boxShadow: outlined ? [] : [BoxShadow(color: color.withOpacity(0.2),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: outlined ? color : Colors.white,
              fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

// ── Env Monitor ───────────────────────────────────────────────────────────────
class _EnvMonitor extends StatelessWidget {
  final SensorData sensor;
  const _EnvMonitor({required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kondisi Lingkungan',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _EnvItem(
              icon: Icons.thermostat_outlined,
              label: 'Suhu',
              value: '${sensor.temperature.toStringAsFixed(1)}°C',
              color: const Color(0xFFE8593C),
              ok: sensor.temperature >= 22 && sensor.temperature <= 27,
            )),
            Expanded(child: _EnvItem(
              icon: Icons.water_drop_outlined,
              label: 'Kelembaban',
              value: '${sensor.humidity.toStringAsFixed(0)}%',
              color: const Color(0xFF378ADD),
              ok: sensor.humidity >= 40 && sensor.humidity <= 65,
            )),
            Expanded(child: _EnvItem(
              icon: Icons.air_outlined,
              label: 'Udara',
              value: sensor.gasLevel < 40 ? 'Segar'
                   : sensor.gasLevel < 65 ? 'Sedang' : 'Pengap',
              color: const Color(0xFF1D9E75),
              ok: sensor.gasLevel < 60,
            )),
          ]),
        ],
      ),
    );
  }
}

class _EnvItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool ok;
  const _EnvItem({required this.icon, required this.label,
      required this.value, required this.color, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      const SizedBox(height: 4),
      Icon(ok ? Icons.check_circle : Icons.warning_amber_rounded,
        size: 12,
        color: ok ? const Color(0xFF1D9E75) : const Color(0xFFBA7517),
      ),
    ]);
  }
}

// ── Comfort Bar ───────────────────────────────────────────────────────────────
class _ComfortBar extends StatelessWidget {
  final int score;
  const _ComfortBar({required this.score});

  Color get _color {
    if (score >= 80) return const Color(0xFF1D9E75);
    if (score >= 60) return const Color(0xFFBA7517);
    return const Color(0xFFE8593C);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Comfort sesi ini',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
          Text('$score / 100',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _color)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Tidak Nyaman', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
          Text('Optimal',      style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
        ]),
      ]),
    );
  }
}

// ── Session History ───────────────────────────────────────────────────────────
class _SessionHistory extends StatelessWidget {
  final List<double> scores;
  const _SessionHistory({required this.scores});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sesi Sebelumnya',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
          const SizedBox(height: 10),
          Row(children: scores.asMap().entries.map((e) {
            final color = e.value >= 80 ? const Color(0xFF1D9E75)
                : e.value >= 60 ? const Color(0xFFBA7517)
                : const Color(0xFFE8593C);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(children: [
                  Text(e.value.toStringAsFixed(0),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
                  Text('Sesi ${e.key + 1}',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                ]),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }
}

// ── Finished Card ─────────────────────────────────────────────────────────────
class _FinishedCard extends StatelessWidget {
  final List<double> scores;
  final VoidCallback onReset;
  const _FinishedCard({required this.scores, required this.onReset});

  double get _avgScore => scores.isEmpty ? 0
      : scores.reduce((a, b) => a + b) / scores.length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF534AB7), Color(0xFF3730A3)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: const Color(0xFF534AB7).withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        const Text('🎉', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        const Text('Semua Sesi Selesai!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Rata-rata Comfort: ${_avgScore.toStringAsFixed(0)} / 100',
          style: const TextStyle(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 16),
        const Text('Data sesi ini dicatat AI untuk mempelajari kondisi optimal belajarmu.',
          style: TextStyle(fontSize: 11, color: Colors.white60, height: 1.5),
          textAlign: TextAlign.center),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onReset,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('Mulai Sesi Baru',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: Color(0xFF534AB7))),
          ),
        ),
      ]),
    );
  }
}