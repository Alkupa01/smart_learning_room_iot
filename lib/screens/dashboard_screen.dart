// lib/screens/dashboard_screen.dart
// Halaman utama Smart Learning Room System
// Menampilkan: Status banner, Comfort Index gauge, sensor grid, presence, session button

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_data.dart';
import '../providers/sensor_provider.dart';
import '../widgets/comfort_gauge.dart';
import '../widgets/sensor_card.dart';
import '../widgets/status_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionTimerProvider);

    final sensorAsync    = ref.watch(sensorProvider);
    final sessionActive  = ref.watch(sessionActiveProvider);
    final sessionSeconds = ref.watch(sessionSecondsProvider);

    ref.listen(sensorProvider, (_, next) {
      next.whenData((s) => ref.read(actuatorProvider.notifier).applyAiRules(s));
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: sensorAsync.when(
        loading: () => const _LoadingView(),
        error:   (e, _) => _ErrorView(error: e.toString()),
        data:    (sensor) => _Body(
          sensor:         sensor,
          sessionActive:  sessionActive,
          sessionSeconds: sessionSeconds,
          ref:            ref,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final SensorData sensor;
  final bool sessionActive;
  final int sessionSeconds;
  final WidgetRef ref;

  const _Body({
    required this.sensor,
    required this.sessionActive,
    required this.sessionSeconds,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: const Color(0xFFF4F6FA),
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Smart Learning Room',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  ),
                  Text('Real-time Monitoring',
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _PresenceChip(presence: sensor.presence),
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              StatusBanner(
                sensor:         sensor,
                sessionActive:  sessionActive,
                sessionSeconds: sessionSeconds,
              ),
              const SizedBox(height: 16),

              _ComfortCard(sensor: sensor),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kondisi Lingkungan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  ),
                  Text(
                    'Baru saja', // Dimodifikasi statis simpel untuk performa web stream
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _SensorGrid(sensor: sensor),
              const SizedBox(height: 16),

              _AiSuggestionCard(sensor: sensor),
              const SizedBox(height: 16),

              _SessionButton(
                active: sessionActive,
                onTap:  () => ref.read(sessionActiveProvider.notifier).state = !sessionActive,
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ComfortCard extends StatelessWidget {
  final SensorData sensor;
  const _ComfortCard({required this.sensor});

  Color get _color {
    if (sensor.comfortScore >= 80) return const Color(0xFF1D9E75);
    if (sensor.comfortScore >= 60) return const Color(0xFFBA7517);
    return const Color(0xFFE8593C);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            // FIX: Menggunakan .withOpacity agar tidak crash r, g, b di web
            color: _color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Comfort Index',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('✦ AI Engine',
                  style: TextStyle(fontSize: 9, color: Color(0xFF534AB7), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ComfortGauge(score: sensor.comfortScore),
          const SizedBox(height: 14),

          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sensor.comfortStatus,
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(label: 'Suhu',   value: '${sensor.temperature.toStringAsFixed(1)}°C'),
              _divider(),
              _MiniStat(label: 'RH',    value: '${sensor.humidity.toStringAsFixed(0)}%'),
              _divider(),
              _MiniStat(label: 'Suara', value: '${sensor.soundLevel}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 28, color: Colors.grey.shade200);
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 1),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _SensorGrid extends StatelessWidget {
  final SensorData sensor;
  const _SensorGrid({required this.sensor});

  SensorTrend _tempTrend(double t)   => t > 27 ? SensorTrend.up   : t < 22 ? SensorTrend.down   : SensorTrend.stable;
  SensorTrend _rhTrend(double rh)    => rh > 65 ? SensorTrend.up  : rh < 40 ? SensorTrend.down  : SensorTrend.stable;
  SensorTrend _soundTrend(int s)     => s > 50  ? SensorTrend.up  : SensorTrend.down;

  String _tempStatus(double t)  => t >= 22 && t <= 26 ? 'Optimal' : t > 28 ? 'Terlalu Panas' : t > 26 ? 'Hangat' : 'Dingin';
  String _rhStatus(double rh)   => rh >= 40 && rh <= 60 ? 'Optimal' : rh > 65 ? 'Lembab'  : 'Kering';
  String _luxStatus(double l)   => l >= 300 && l <= 500 ? 'Optimal' : l > 500  ? 'Terlalu Terang' : 'Redup';

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        SensorCard(
          icon:         Icons.thermostat_outlined,
          label:       'Suhu',
          value:       sensor.temperature.toStringAsFixed(1),
          unit:        '°C',
          accentColor: const Color(0xFFE8593C),
          statusText:  _tempStatus(sensor.temperature),
          trend:       _tempTrend(sensor.temperature),
        ),
        SensorCard(
          icon:         Icons.water_drop_outlined,
          label:       'Kelembaban',
          value:       sensor.humidity.toStringAsFixed(0),
          unit:        '%',
          accentColor: const Color(0xFF378ADD),
          statusText:  _rhStatus(sensor.humidity),
          trend:       _rhTrend(sensor.humidity),
        ),
        SensorCard(
          icon:         Icons.light_mode_outlined,
          label:       'Intensitas Cahaya',
          value:       sensor.lux.toStringAsFixed(0),
          unit:        'lux',
          accentColor: const Color(0xFFBA7517),
          statusText:  _luxStatus(sensor.lux),
          trend:       SensorTrend.stable,
        ),
        // FIX: Diubah penuh menampilkan data kebisingan KY-037
        SensorCard(
          icon:         Icons.volume_up_rounded,
          label:       'Kebisingan Ruang',
          value:       '${sensor.soundLevel}',
          unit:        '%',
          accentColor: const Color(0xFF1D9E75),
          statusText:  sensor.soundStatus,
          trend:       _soundTrend(sensor.soundLevel),
        ),
      ],
    );
  }
}

class _AiSuggestionCard extends StatelessWidget {
  final SensorData sensor;
  const _AiSuggestionCard({required this.sensor});

  String? get _suggestion {
    if (sensor.temperature > 27) return 'Suhu ruangan tinggi — fan otomatis dinyalakan untuk sirkulasi udara.';
    if (sensor.humidity > 65)    return 'Kelembaban melebihi batas nyaman — disarankan buka ventilasi.';
    if (sensor.lux < 250)        return 'Cahaya redup terdeteksi — lampu otomatis dinyalakan.';
    if (sensor.soundLevel > 60)  return 'Ruangan terdeteksi bising — gunakan penutup telinga atau kondisikan ruangan.';
    if (sensor.comfortScore > 80) return 'Semua kondisi optimal — waktu terbaik untuk sesi belajar intensif!';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = _suggestion;
    if (s == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEDFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC5C2F5), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✦ ', style: TextStyle(color: Color(0xFF534AB7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saran AI',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF534AB7)),
                ),
                const SizedBox(height: 3),
                Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF534AB7), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresenceChip extends StatelessWidget {
  final bool presence;
  const _PresenceChip({required this.presence});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: presence ? const Color(0xFFE1F5EE) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline,
            size: 12,
            color: presence ? const Color(0xFF0F6E56) : Colors.grey,
          ),
          const SizedBox(width: 5),
          Text(
            presence ? 'Terdeteksi' : 'Kosong',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: presence ? const Color(0xFF0F6E56) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _SessionButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [const Color(0xFFE8593C), const Color(0xFFC0392B)]
                : [const Color(0xFF1D9E75), const Color(0xFF0F6E56)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: active ? const Color(0x59E8593C) : const Color(0x591D9E75),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? Icons.stop_circle_outlined : Icons.play_circle_outline,
              color: Colors.white, size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              active ? 'Akhiri Sesi Belajar' : 'Mulai Sesi Belajar',
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF1D9E75), strokeWidth: 3),
          SizedBox(height: 16),
          Text('Menghubungkan ke sensor ESP32-S3...',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            const Text('Gagal terhubung ke sensor',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(error,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}