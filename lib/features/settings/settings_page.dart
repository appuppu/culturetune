import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import 'theme_provider.dart';

/// 設定: テーマ(カラー系統)の選択
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'カラーテーマ',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          for (final palette in CTThemes.all)
            _ThemeTile(
              palette: palette,
              selected: palette.id == selected.id,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(themeProvider.notifier).select(palette);
              },
            ),
          const SizedBox(height: 12),
          Text(
            'アプリアイコンの色はストア公開時のテーマに合わせています',
            style: TextStyle(fontSize: 11, color: CTColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final CTPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(CTRadius.card),
          border: Border.all(
            color: selected ? palette.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: ctCardShadow,
        ),
        child: Row(
          children: [
            // プレビュー: 背景+カード+アクセントの組み合わせ
            Container(
              width: 64,
              height: 44,
              decoration: BoxDecoration(
                color: palette.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: palette.textSub.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    children: [
                      for (final c in [
                        palette.book,
                        palette.video,
                        palette.food,
                      ])
                        Expanded(
                          child: Container(
                            width: 14,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    palette.nameJa,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textMain,
                    ),
                  ),
                  Text(
                    palette.description,
                    style: TextStyle(fontSize: 11, color: palette.textSub),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: palette.primary),
          ],
        ),
      ),
    );
  }
}
