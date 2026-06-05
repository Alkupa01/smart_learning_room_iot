// lib/widgets/feedback_row.dart
// 4 tombol feedback kenyamanan — data dikirim ke provider (nanti ke Firebase)

import 'package:flutter/material.dart';

class FeedbackRow extends StatelessWidget {
  final int selectedLevel; // 0 = belum pilih, 1–4 = level
  final ValueChanged<int> onSelected;

  const FeedbackRow({
    super.key,
    required this.selectedLevel,
    required this.onSelected,
  });

  static const List<Map<String, Object>> _options = [
    {'emoji': '😫', 'label': 'Sangat\nTidak Nyaman', 'level': 1},
    {'emoji': '😐', 'label': 'Kurang\nNyaman',        'level': 2},
    {'emoji': '😊', 'label': 'Nyaman',                'level': 3},
    {'emoji': '🤩', 'label': 'Sangat\nNyaman',        'level': 4},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _options.map((opt) {
        final isSelected = selectedLevel == (opt['level'] as int);
        return GestureDetector(
          onTap: () => onSelected(opt['level'] as int),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1D9E75).withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1D9E75)
                    : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(opt['emoji'] as String,
                  style: TextStyle(
                    fontSize: isSelected ? 28 : 22,
                  ),
                ),
                const SizedBox(height: 5),
                Text(opt['label'] as String,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected
                        ? const Color(0xFF0F6E56)
                        : Colors.grey.shade500,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}