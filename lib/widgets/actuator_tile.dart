// lib/widgets/actuator_tile.dart
// Tile untuk kontrol relay/servo dengan label alasan AI

import 'package:flutter/material.dart';

class ActuatorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String aiReason;
  final bool isOn;
  final bool enabled; // false = mode Auto (dikontrol AI)
  final ValueChanged<bool> onToggle;

  const ActuatorTile({
    super.key,
    required this.icon,
    required this.label,
    required this.aiReason,
    required this.isOn,
    required this.onToggle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOn ? const Color(0xFF1D9E75) : Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isOn
                ? const Color(0xFF1D9E75).withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isOn
              ? const Color(0xFF1D9E75).withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          // Label + AI reason
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text('✦ ',
                      style: TextStyle(fontSize: 9, color: Color(0xFF534AB7)),
                    ),
                    Expanded(
                      child: Text(aiReason,
                        style: const TextStyle(
                          fontSize: 10, color: Color(0xFF534AB7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Toggle
          GestureDetector(
            onTap: enabled ? () => onToggle(!isOn) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48, height: 26,
              decoration: BoxDecoration(
                color: isOn ? const Color(0xFF1D9E75) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20, height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}