// lib/screens/control_screen.dart
// Screen Kontrol — Mode Auto AI / Manual, actuator control, feedback

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sensor_provider.dart';
import '../models/sensor_data.dart';
import '../widgets/actuator_tile.dart';
import '../widgets/feedback_row.dart';

class ControlScreen extends ConsumerWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorAsync = ref.watch(sensorProvider);
    final actuator    = ref.watch(actuatorProvider);
    final feedback    = ref.watch(feedbackProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              floating: true,
              backgroundColor: const Color(0xFFF4F6FA),
              scrolledUnderElevation: 0,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kontrol Ruangan',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E)),
                  ),
                  Text('Atur kondisi ruang belajarmu',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── 1. Mode Toggle ─────────────────────────────────────
                  _SectionLabel(label: 'Mode Operasi'),
                  const SizedBox(height: 8),
                  _ModeToggle(
                    mode:     actuator.mode,
                    onChanged: (m) =>
                        ref.read(actuatorProvider.notifier).setMode(m),
                  ),
                  const SizedBox(height: 6),
                  // Info mode
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: actuator.mode == 'auto'
                        ? const _InfoChip(
                            key: ValueKey('auto'),
                            text: '✦ AI mengontrol aktuator secara otomatis berdasarkan sensor',
                            color: Color(0xFF534AB7),
                            bg:    Color(0xFFEEEDFE),
                          )
                        : const _InfoChip(
                            key: ValueKey('manual'),
                            text: 'Mode manual — kamu yang tentukan nyala/matinya perangkat',
                            color: Color(0xFF854F0B),
                            bg:    Color(0xFFFFF8E1),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // ── 2. Aktuator Tiles ──────────────────────────────────
                  _SectionLabel(label: 'Perangkat'),
                  const SizedBox(height: 8),
                  sensorAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error:   (_, __) => const SizedBox.shrink(),
                    data:    (sensor) => Column(
                      children: [
                        ActuatorTile(
                          icon:     Icons.air,
                          label:    'Ventilasi (Fan)',
                          aiReason: _fanReason(sensor, actuator.mode),
                          isOn:     actuator.fan,
                          enabled:  actuator.mode == 'manual',
                          onToggle: (_) =>
                              ref.read(actuatorProvider.notifier).toggleFan(),
                        ),
                        const SizedBox(height: 10),
                        ActuatorTile(
                          icon:     Icons.lightbulb_outline,
                          label:    'Pencahayaan (Lampu)',
                          aiReason: _lightReason(sensor, actuator.mode),
                          isOn:     actuator.light,
                          enabled:  actuator.mode == 'manual',
                          onToggle: (_) =>
                              ref.read(actuatorProvider.notifier).toggleLight(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 3. Servo Slider ────────────────────────────────────
                  _SectionLabel(label: 'Jendela / Ventilasi (Servo)'),
                  const SizedBox(height: 8),
                  _ServoSlider(
                    angle:    actuator.servoAngle,
                    enabled:  actuator.mode == 'manual',
                    onChanged: (v) =>
                        ref.read(actuatorProvider.notifier).setServo(v),
                  ),
                  const SizedBox(height: 20),

                  // ── 4. Status Sensor Ringkas ───────────────────────────
                  sensorAsync.maybeWhen(
                    data: (s) => _SensorSummaryRow(sensor: s),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),

                  // ── 5. Feedback ────────────────────────────────────────
                  _SectionLabel(label: 'Seberapa Nyaman Kondisi Sekarang?'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04),
                            blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        FeedbackRow(
                          selectedLevel: feedback,
                          onSelected: (level) {
                            ref.read(feedbackProvider.notifier).state = level;
                            ref.read(firebaseServiceProvider).sendUserFeedback(level);
                            _showFeedbackSnackbar(context, level);
                          },
                        ),
                        if (feedback > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F5EE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Color(0xFF0F6E56), size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Feedback tersimpan — AI sedang belajar dari preferensimu',
                                  style: TextStyle(
                                    fontSize: 10, color: Color(0xFF0F6E56),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 6. Reset AI button ─────────────────────────────────
                  _ResetButton(
                    onTap: () => _showResetDialog(context, ref),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fanReason(SensorData s, String mode) {
    if (mode == 'auto') {
      if (s.temperature > 27) return 'Aktif — suhu ${s.temperature.toStringAsFixed(1)}°C melewati batas';
      if (s.soundLevel > 50)  return 'Aktif — ruangan terdeteksi bising (${s.soundLevel}%)';
      return 'Standby — kondisi optimal';
    }
    return 'Mode manual — kontrol manual';
  }

  String _lightReason(SensorData s, String mode) {
    if (mode == 'auto') {
      if (s.lux < 250) return 'Aktif — cahaya ${s.lux.toStringAsFixed(0)} lux di bawah optimal';
      return 'Standby — cahaya cukup (${s.lux.toStringAsFixed(0)} lux)';
    }
    return 'Mode manual — kontrol manual';
  }

  void _showFeedbackSnackbar(BuildContext context, int level) {
    final labels = ['', 'Sangat Tidak Nyaman 😫', 'Kurang Nyaman 😐', 'Nyaman 😊', 'Sangat Nyaman 🤩'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Feedback: ${labels[level]} — dicatat AI'),
        backgroundColor: const Color(0xFF1D9E75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Profil AI?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Semua data preferensi yang sudah dipelajari AI akan dihapus. '
          'Sistem akan mulai belajar dari awal.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8593C)),
            onPressed: () {
              ref.read(feedbackProvider.notifier).state = 0;
              Navigator.pop(ctx);
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
      style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const _InfoChip({super.key, required this.text, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ModeOption(
            label:     '✦  Auto AI',
            selected: mode == 'auto',
            onTap:     () => onChanged('auto'),
            selectedColor: const Color(0xFF534AB7),
          ),
          _ModeOption(
            label:     '⚙  Manual',
            selected: mode == 'manual',
            onTap:     () => onChanged('manual'),
            selectedColor: const Color(0xFFBA7517),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  const _ModeOption({required this.label, required this.selected,
      required this.onTap, required this.selectedColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]
                : [],
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? selectedColor : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ServoSlider extends StatelessWidget {
  final double angle;
  final bool enabled;
  final ValueChanged<double> onChanged;
  const _ServoSlider({required this.angle, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sudut Bukaan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: enabled ? const Color(0xFF1A1A2E) : Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${angle.round()}°',
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF1D9E75),
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: const Color(0xFF1D9E75),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF1D9E75),
              overlayColor: const Color(0xFF1D9E75).withOpacity(0.12),
            ),
            child: Slider(
              value:    angle,
              min:      0,
              max:      90,
              divisions: 9,
              onChanged: enabled ? onChanged : null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tutup', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              Text('Buka Penuh', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
          if (!enabled) ...[
            const SizedBox(height: 8),
            Text('Dikendalikan AI di mode Auto',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _SensorSummaryRow extends StatelessWidget {
  final SensorData sensor;
  const _SensorSummaryRow({required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Status Sensor', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Comfort ${sensor.comfortScore}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF0F6E56),
                      fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniVal(icon: Icons.thermostat_outlined, value: '${sensor.temperature.toStringAsFixed(1)}°C', color: const Color(0xFFE8593C)),
              _MiniVal(icon: Icons.water_drop_outlined, value: '${sensor.humidity.toStringAsFixed(0)}%',    color: const Color(0xFF378ADD)),
              _MiniVal(icon: Icons.light_mode_outlined, value: '${sensor.lux.toStringAsFixed(0)}lx',       color: const Color(0xFFBA7517)),
              // RECONFIQ: Membaca parameter suara KY-037
              _MiniVal(icon: Icons.volume_up_outlined,  value: 'Suara ${sensor.soundLevel}%',               color: const Color(0xFF1D9E75)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniVal extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniVal({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
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
              style: TextStyle(fontSize: 13, color: Color(0xFFE8593C),
                  fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}