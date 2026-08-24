import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../backup/book_backup.dart';
import 'theme_provider.dart';

/// 設定: テーマ(カラー系統)の選択とバックアップ
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _busy = false;

  Future<void> _runBackup(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final message = await action();
      if (mounted && message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('失敗したよ: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'バックアップ',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: CTColors.surface,
              borderRadius: BorderRadius.circular(CTRadius.card),
              boxShadow: ctCardShadow,
            ),
            child: Column(
              children: [
                ListTile(
                  enabled: !_busy,
                  leading: const Icon(Icons.archive_rounded),
                  title: const Text(
                    'まるごと書き出す',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    '全シール帳・シール・カード・ボイスを1つのファイルに。iCloudやGoogleドライブに保存してね',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () => _runBackup(() => exportBookBackup(ref)),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  enabled: !_busy,
                  leading: const Icon(Icons.unarchive_rounded),
                  title: const Text(
                    'バックアップを読み込む',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    '機種変更のとき、保存したファイルから復元。同じデータは重複しないよ',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () => _runBackup(() => importBookBackup(ref)),
                ),
              ],
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
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
