// lib/widgets/comfort_gauge.dart
// Arc gauge semi-lingkaran dengan animasi smooth saat nilai berubah

import 'dart:math';
import 'package:flutter/material.dart';

class ComfortGauge extends StatefulWidget {
  final int score;
  const ComfortGauge({super.key, required this.score});

  @override
  State<ComfortGauge> createState() => _ComfortGaugeState();
}

class _ComfortGaugeState extends State<ComfortGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _anim = Tween<double>(begin: 0, end: widget.score.toDouble())
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(ComfortGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _anim = Tween<double>(
        begin: _anim.value,
        end:   widget.score.toDouble(),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _colorForScore(double s) {
    if (s >= 80) return const Color(0xFF1D9E75);
    if (s >= 60) return const Color(0xFFBA7517);
    return const Color(0xFFE8593C);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final color = _colorForScore(_anim.value);
        return CustomPaint(
          size: const Size(200, 120),
          painter: _GaugePainter(score: _anim.value, color: color),
          child: SizedBox(
            width: 200,
            height: 120,
            child: Align(
              alignment: const Alignment(0, 0.55),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -1,
                    ),
                    child: Text(_anim.value.round().toString()),
                  ),
                  Text(
                    'dari 100',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  static const _startAngle = pi;
  static const _sweepTotal = pi;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final r  = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // ── 1. Zone background (merah/kuning/hijau) ───────────────────────────
    final zones = [
      (0.0,  0.35, const Color(0xFFE8593C)),
      (0.35, 0.3,  const Color(0xFFBA7517)),
      (0.65, 0.35, const Color(0xFF1D9E75)),
    ];
    for (final (start, sweep, c) in zones) {
      canvas.drawArc(
        rect, _startAngle + start * _sweepTotal, sweep * _sweepTotal, false,
        Paint()
          // FIX: Menggunakan .red, .green, .blue standar Flutter
          ..color = Color.fromRGBO(c.red, c.green, c.blue, 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.butt,
      );
    }

    // ── 2. Track utama ────────────────────────────────────────────────────
    canvas.drawArc(
      rect, _startAngle, _sweepTotal, false,
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );

    // ── 3. Arc aktif (warna berdasarkan skor) ─────────────────────────────
    final activeSweep = (score / 100) * _sweepTotal;
    if (activeSweep > 0.01) {
      // Shadow arc
      canvas.drawArc(
        rect.inflate(1), _startAngle, activeSweep, false,
        Paint()
          // FIX: Menggunakan .red, .green, .blue standar Flutter
          ..color = Color.fromRGBO(color.red, color.green, color.blue, 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Main arc
      canvas.drawArc(
        rect, _startAngle, activeSweep, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round,
      );

      // Dot di ujung arc
      final tipAngle = _startAngle + activeSweep;
      final tipX = cx + r * cos(tipAngle);
      final tipY = cy + r * sin(tipAngle);
      canvas.drawCircle(Offset(tipX, tipY), 8, Paint()..color = color);
      canvas.drawCircle(Offset(tipX, tipY), 4, Paint()..color = Colors.white);
    }

    // ── 4. Tick marks ─────────────────────────────────────────────────────
    for (int i = 0; i <= 10; i++) {
      final a   = _startAngle + (i / 10) * _sweepTotal;
      final rIn  = r - 12;
      final rOut = r + 4;
      final x1 = cx + rIn  * cos(a);
      final y1 = cy + rIn  * sin(a);
      final x2 = cx + rOut * cos(a);
      final y2 = cy + rOut * sin(a);
      canvas.drawLine(
        Offset(x1, y1), Offset(x2, y2),
        Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = i % 5 == 0 ? 2 : 1,
      );
    }

    // ── 5. Label 0, 50, 100 ───────────────────────────────────────────────
    _drawLabel(canvas, '0',   cx, cy, r + 22, _startAngle);
    _drawLabel(canvas, '50',  cx, cy, r + 22, _startAngle + _sweepTotal / 2);
    _drawLabel(canvas, '100', cx, cy, r + 22, _startAngle + _sweepTotal);
  }

  void _drawLabel(Canvas canvas, String text, double cx, double cy, double r, double angle) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(
      cx + r * cos(angle) - tp.width / 2,
      cy + r * sin(angle) - tp.height / 2,
    ));
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.score != score || old.color != color;
}
