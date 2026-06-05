// lib/widgets/pomodoro_timer.dart
// Arc timer melingkar dengan CustomPainter + animasi

import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/pomodoro_provider.dart';

class PomodoroTimerWidget extends StatefulWidget {
  final PomodoroData data;
  const PomodoroTimerWidget({super.key, required this.data});

  @override
  State<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends State<PomodoroTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.data.isBreak) return const Color(0xFF378ADD);
    return switch (widget.data.state) {
      PomodoroState.running    => const Color(0xFF1D9E75),
      PomodoroState.paused     => const Color(0xFFBA7517),
      PomodoroState.finished   => const Color(0xFF534AB7),
      _                        => Colors.grey.shade400,
    };
  }

  String get _label {
    if (widget.data.state == PomodoroState.idle)     return 'Siap';
    if (widget.data.state == PomodoroState.finished) return 'Selesai!';
    if (widget.data.isBreak)                         return 'Istirahat';
    return switch (widget.data.state) {
      PomodoroState.running => 'Fokus',
      PomodoroState.paused  => 'Dijeda',
      _                     => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final pulseOpacity = widget.data.state == PomodoroState.running
            ? 0.06 + _pulse.value * 0.06
            : 0.0;

        return CustomPaint(
          size: const Size(240, 240),
          painter: _TimerPainter(
            progress:     widget.data.progress,
            color:        _color,
            pulseOpacity: pulseOpacity,
            isIdle:       widget.data.state == PomodoroState.idle,
          ),
          child: SizedBox(
            width: 240, height: 240,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(_label,
                      key: ValueKey(_label),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _color.withOpacity(0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Timer
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: widget.data.state == PomodoroState.finished ? 32 : 48,
                      fontWeight: FontWeight.w800,
                      color: _color,
                      letterSpacing: -2,
                    ),
                    child: Text(
                      widget.data.state == PomodoroState.finished
                          ? '🎉'
                          : widget.data.timeLabel,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Sesi indicator dots
                  _SessionDots(
                    current: widget.data.currentSession,
                    total:   widget.data.totalSessions,
                    color:   _color,
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

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double pulseOpacity;
  final bool isIdle;

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.pulseOpacity,
    required this.isIdle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width / 2;
    final cy   = size.height / 2;
    final r    = size.width / 2 - 16;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Pulse glow saat running
    if (pulseOpacity > 0) {
      canvas.drawCircle(
        Offset(cx, cy), r + 10,
        Paint()
          ..color = color.withOpacity(pulseOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Track
    canvas.drawArc(rect, -pi / 2, 2 * pi, false,
      Paint()
        ..color = Colors.grey.shade100
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (!isIdle && progress > 0) {
      // Shadow
      canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false,
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // Main arc
      canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }

    // Tick marks (12 buah seperti jam)
    for (int i = 0; i < 60; i++) {
      final a    = -pi / 2 + (i / 60) * 2 * pi;
      final isMajor = i % 5 == 0;
      final rIn  = r - (isMajor ? 10 : 6);
      final rOut = r + 5;
      canvas.drawLine(
        Offset(cx + rIn * cos(a),  cy + rIn * sin(a)),
        Offset(cx + rOut * cos(a), cy + rOut * sin(a)),
        Paint()
          ..color = Colors.grey.shade200
          ..strokeWidth = isMajor ? 2 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.pulseOpacity != pulseOpacity;
}

class _SessionDots extends StatelessWidget {
  final int current, total;
  final Color color;
  const _SessionDots({required this.current, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final done = i < current - 1;
        final active = i == current - 1;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width:  active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: done || active ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}