import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// フチの色を選ぶ共通シート。選ばれた色を返す(キャンセルはnull)
Future<Color?> showBorderColorSheet(BuildContext context) {
  return showModalBottomSheet<Color>(
    context: context,
    backgroundColor: CTColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'フチの色',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: CTColors.textSub,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in [Colors.white, ...CTColors.moodPalette])
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetContext, color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CTColors.textSub.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
