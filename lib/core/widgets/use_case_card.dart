import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 空状態に出す「使いかた」説明カード(シール帳/シール/カード/交換で共用)
class UseCaseCard extends StatelessWidget {
  const UseCaseCard({
    super.key,
    required this.icon,
    required this.colorIndex,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final int colorIndex;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final color =
        CTColors.moodPalette[colorIndex % CTColors.moodPalette.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CTColors.surface,
        borderRadius: BorderRadius.circular(CTRadius.card),
        boxShadow: ctCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: CTColors.textSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
