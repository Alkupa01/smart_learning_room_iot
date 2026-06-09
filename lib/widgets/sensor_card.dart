// lib/widgets/sensor_card.dart
// Kartu sensor reusable — dipakai di Dashboard dan screen lainnya

import 'package:flutter/material.dart';

enum SensorTrend { up, stable, down }

class SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final String statusText;
  final SensorTrend trend;
  final VoidCallback? onTap;

  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    required this.statusText,
    this.trend = SensorTrend.stable,
    this.onTap,
  });

  Color get _statusColor {
    const ok = Color(0xFF1D9E75);
    const warn = Color(0xFFBA7517);
    const bad = Color(0xFFE8593C);
    if (statusText == 'Optimal' ||
        statusText == 'Baik' ||
        statusText == 'Segar')
      return ok;
    if (statusText == 'Hangat' ||
        statusText == 'Lembab' ||
        statusText == 'Cukup' ||
        statusText == 'Sedang' ||
        statusText == 'Redup') {
      return warn;
    }
    return bad;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              // FIX: Menggunakan .withOpacity langsung jauh lebih efisien & bebas eror .r .g .b
              color: accentColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    // FIX: Menggunakan .withOpacity
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: accentColor, size: 17),
                ),
                _TrendBadge(trend: trend),
              ],
            ),
            const Spacer(),

            // Value + Unit
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: unit.isNotEmpty ? ' $unit' : '',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),

            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),

            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                // FIX: Menggunakan .withOpacity standar
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 9,
                  color: _statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final SensorTrend trend;
  const _TrendBadge({required this.trend});

  @override
  Widget build(BuildContext context) {
    return switch (trend) {
      SensorTrend.up => const Icon(
        Icons.trending_up,
        size: 14,
        color: Color(0xFFE8593C),
      ),
      SensorTrend.down => const Icon(
        Icons.trending_down,
        size: 14,
        color: Color(0xFF1D9E75),
      ),
      SensorTrend.stable => Icon(
        Icons.remove,
        size: 14,
        color: Colors.grey.shade400,
      ),
    };
  }
}
