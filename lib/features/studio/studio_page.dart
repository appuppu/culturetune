import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../palette/create_sticker_page.dart';
import '../palette/palette_page.dart';
import '../palette/sticker_exchange.dart';
import '../post/post_flow.dart';
import '../settings/settings_page.dart';
import '../vault/vault_page.dart';

/// 選択中のセグメント(0=シール, 1=カード)。FABの動作切替にも使う
final studioSegmentProvider = StateProvider<int>((ref) => 0);

/// シールタブ: シール素材とカルチャーカードを1つのタブで管理する
class StudioPage extends ConsumerWidget {
  const StudioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(studioSegmentProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
            child: Row(
              children: [
                // セグメント: シール / カード
                for (final (i, label) in ['シール', 'カード'].indexed)
                  GestureDetector(
                    onTap: () =>
                        ref.read(studioSegmentProvider.notifier).state = i,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: segment == i
                            ? CTColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(CTRadius.pill),
                        border: Border.all(
                          color: segment == i
                              ? CTColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: segment == i
                              ? CTColors.primary
                              : CTColors.textSub,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    // 表示中のセグメント側の選択モードを切り替える
                    final provider = segment == 0
                        ? stickerSelectionProvider
                        : cardSelectionProvider;
                    final notifier = ref.read(provider.notifier);
                    notifier.state = notifier.state == null ? <String>{} : null;
                  },
                  icon: Icon(
                    Icons.checklist_rounded,
                    color:
                        ref.watch(
                              segment == 0
                                  ? stickerSelectionProvider
                                  : cardSelectionProvider,
                            ) !=
                            null
                        ? CTColors.primary
                        : CTColors.textSub,
                    size: 22,
                  ),
                  tooltip: 'えらんで削除',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showCreateSheet(context, ref),
                  icon: Icon(
                    Icons.add_circle_rounded,
                    color: CTColors.primary,
                    size: 24,
                  ),
                  tooltip: 'つくる',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                  icon: Icon(
                    Icons.settings_rounded,
                    color: CTColors.textSub,
                    size: 20,
                  ),
                  tooltip: '設定',
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: segment,
              children: const [PaletteBody(), VaultPage(embedded: true)],
            ),
          ),
        ],
      ),
    );
  }
}

/// 「＋」: シールもカードも作れる。もらった画像の取り込みもここから
void _showCreateSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.auto_fix_high_rounded),
            title: const Text('シールをつくる'),
            subtitle: const Text(
              '写真から自動切り抜きでシール化',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateStickerPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.style_rounded),
            title: const Text('カードをつくる'),
            subtitle: const Text(
              '本・音楽・動画・ご飯を登録',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              showPostCategorySheet(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: const Text('もらった画像を取り込む'),
            subtitle: const Text(
              'LINEなどで届いたシール/シール帳のPNGを復元',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              importStickerFromGallery(context, ref);
            },
          ),
        ],
      ),
    ),
  );
}
