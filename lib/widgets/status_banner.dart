// lib/widgets/status_banner.dart
// Banner status di atas dashboard — warna berubah otomatis berdasarkan Comfort Score

import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class StatusBanner extends StatelessWidget {
  final SensorData sensor;
  final bool sessionActive;
  final int sessionSeconds;

  const StatusBanner({
    super.key,
    required this.sensor,
    required this.sessionActive,
    required this.sessionSeconds,
  });

  ({Color bg, Color fg, IconData icon, String text}) get _config {
    if (sensor.comfortScore >= 80) {
      return (
        bg:   const Color(0xFFE1F5EE),
        fg:   const Color(0xFF0F6E56),
        icon: Icons.check_circle_outline,
        text: 'Kondisi Optimal — Siap Belajar!',
      );
    }
    if (sensor.comfortScore >= 60) {
      return (
        bg:   const Color(0xFFFFF8E1),
        fg:   const Color(0xFF854F0B),
        icon: Icons.warning_amber_outlined,
        text: 'Kondisi Cukup — Perlu Penyesuaian',
      );
    }
    return (
      bg:   const Color(0xFFFFEBEE),
      fg:   const Color(0xFFA32D2D),
      icon: Icons.error_outline,
      text: 'Kondisi Kurang Nyaman',
    );
  }

  String _fmtDuration(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final c = _config;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(c.icon, color: c.fg, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              c.text,
              style: TextStyle(
                color: c.fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (sessionActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Color.fromRGBO((c.fg.r * 255.0).round(), (c.fg.g * 255.0).round(), (c.fg.b * 255.0).round(), 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 11, color: c.fg),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDuration(sessionSeconds),
                    style: TextStyle(
                      color: c.fg,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Color.fromRGBO((c.fg.r * 255.0).round(), (c.fg.g * 255.0).round(), (c.fg.b * 255.0).round(), 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                sensor.comfortScore.toString(),
                style: TextStyle(color: c.fg, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
