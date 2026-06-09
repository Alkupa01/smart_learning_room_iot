// lib/widgets/session_chart.dart
// Bar chart mingguan + comfort indicator menggunakan fl_chart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyBarChart extends StatefulWidget {
  // Data: list of (day label, minutes, avg comfort score)
  final List<({String day, int minutes, double comfort})> data;

  const WeeklyBarChart({super.key, required this.data});

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  int _touched = -1;

  Color _barColor(double comfort) {
    if (comfort >= 80) return const Color(0xFF1D9E75);
    if (comfort >= 60) return const Color(0xFFBA7517);
    if (comfort > 0) return const Color(0xFFE8593C);
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final maxMin = widget.data
        .map((d) => d.minutes)
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();
    final maxY = maxMin == 0 ? 60.0 : (maxMin * 1.3).ceilToDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // FIX: Struktur penulisan properti warna tooltip fl_chart teranyar
            getTooltipColor: (group) => const Color(0xFF1A1A2E),
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = widget.data[group.x];
              return BarTooltipItem(
                '${d.day}\n${d.minutes}m',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          touchCallback: (event, response) {
            setState(() {
              _touched = response?.spot?.touchedBarGroupIndex ?? -1;
            });
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY / 3,
              getTitlesWidget: (val, _) => Text(
                val == 0 ? '' : '${val.toInt()}m',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= widget.data.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    widget.data[i].day,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: _touched == i
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: _touched == i
                          ? const Color(0xFF1D9E75)
                          : Colors.grey.shade500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(widget.data.length, (i) {
          final d = widget.data[i];
          final isToday = i == widget.data.length - 1;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: d.minutes.toDouble(),
                color: _touched == i || isToday
                    ? _barColor(d.comfort)
                    : _barColor(d.comfort).withOpacity(0.5),
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: Colors.grey.shade50,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Comfort Line Chart (untuk chart comfort score harian) ─────────────────────
class ComfortLineChart extends StatelessWidget {
  final List<({String time, double score})> data;

  const ComfortLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Belum ada data sesi hari ini',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1A2E),
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    'Score: ${s.y.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 25,
              getTitlesWidget: (val, _) => Text(
                val.toInt().toString(),
                style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (data.length / 4).ceilToDouble(),
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Text(
                  data[i].time,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i].score),
            ),
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF1D9E75),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3.5,
                color: const Color(0xFF1D9E75),
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1D9E75).withOpacity(0.15),
                  const Color(0xFF1D9E75).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Zona nyaman (60–80) reference line
          LineChartBarData(
            spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), 80)),
            isCurved: false,
            color: const Color(0xFF1D9E75).withOpacity(0.2),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: [4, 4],
          ),
        ],
      ),
    );
  }
}
