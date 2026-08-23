import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/culture_category.dart';
import '../../core/theme/tokens.dart';
import 'food_post_page.dart';
import 'isbn_scan_page.dart';
import 'url_post_page.dart';

/// ＋ボタン → キャンディ型カテゴリ選択ボトムシート
Future<void> showPostCategorySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: CTColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: CTColors.textSub.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(CTRadius.pill),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'なにを推す?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            // 4カテゴリを2x2で表示
            for (
              var row = 0;
              row < CultureCategory.values.length;
              row += 2
            ) ...[
              if (row > 0) const SizedBox(height: 12),
              Row(
                children: [
                  for (
                    var i = row;
                    i < row + 2 && i < CultureCategory.values.length;
                    i++
                  ) ...[
                    if (i > row) const SizedBox(width: 12),
                    Expanded(
                      child: _CategoryCandy(
                        category: CultureCategory.values[i],
                        onTap: () {
                          final c = CultureCategory.values[i];
                          HapticFeedback.lightImpact();
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => _entryPage(c)),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _entryPage(CultureCategory category) {
  return switch (category) {
    CultureCategory.book => const IsbnScanPage(),
    CultureCategory.music => const UrlPostPage(category: CultureCategory.music),
    CultureCategory.video => const UrlPostPage(category: CultureCategory.video),
    CultureCategory.food => const FoodPostPage(),
  };
}

class _CategoryCandy extends StatelessWidget {
  const _CategoryCandy({required this.category, required this.onTap});

  final CultureCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: CTColors.surface,
          borderRadius: BorderRadius.circular(CTRadius.card),
          border: Border.all(
            color: category.color.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: ctCardShadow,
        ),
        child: Column(
          children: [
            Icon(category.icon, size: 32, color: category.color),
            const SizedBox(height: 6),
            Text(
              category.labelJa,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
