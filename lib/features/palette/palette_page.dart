import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/models/culture_category.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sticker_image.dart';
import '../beam/beam_profile_provider.dart';
import '../detail/culture_modal.dart';
import 'create_sticker_page.dart';
import '../../core/stickers/voice_player.dart';
import '../../core/widgets/border_color_sheet.dart';
import '../../core/widgets/culture_picker_sheet.dart';
import '../../core/widgets/selection_action_bar.dart';
import 'sticker_exchange.dart';

/// シールの選択モード。null=通常、Set=選択中のシールid
final stickerSelectionProvider = StateProvider<Set<String>?>((ref) => null);

/// シール素材のグリッド(シールタブに埋め込まれる)
class PaletteBody extends ConsumerWidget {
  const PaletteBody({super.key});

  Future<void> _deleteSelected(
    BuildContext context,
    WidgetRef ref,
    List<Sticker> all,
  ) async {
    final selected = ref.read(stickerSelectionProvider) ?? const <String>{};
    final targets = all.where((s) => selected.contains(s.id)).toList();
    if (targets.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${targets.length}個のシールを削除する?'),
        content: const Text('シール帳に貼ってある分もはがれるよ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final repo = ref.read(stickerRepositoryProvider);
    for (final s in targets) {
      await repo.deleteSticker(s);
    }
    ref.read(stickerSelectionProvider.notifier).state = null;
    if (context.mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${targets.length}個のシールを削除したよ')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickers = ref.watch(stickersProvider);
    final selection = ref.watch(stickerSelectionProvider);

    return stickers.when(
      data: (list) => list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_fix_high_rounded,
                    size: 56,
                    color: CTColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '写真を選ぶだけで\n切り抜きシールがつくれるよ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: CTColors.textSub, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateStickerPage(),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('写真からシールをつくる'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    4,
                    12,
                    selection != null ? 76 : 12,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _StickerTile(sticker: list[i]),
                ),
                if (selection != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: SelectionActionBar(
                      count: selection.length,
                      onDelete: () => _deleteSelected(context, ref, list),
                      onClose: () =>
                          ref.read(stickerSelectionProvider.notifier).state =
                              null,
                    ),
                  ),
              ],
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
    );
  }
}

class _StickerTile extends ConsumerWidget {
  const _StickerTile({required this.sticker});

  final Sticker sticker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(stickerRepositoryProvider);
    final selection = ref.watch(stickerSelectionProvider);
    final selecting = selection != null;
    final selected = selection?.contains(sticker.id) ?? false;

    return GestureDetector(
      onTap: () {
        if (selecting) {
          HapticFeedback.selectionClick();
          final next = {...selection};
          selected ? next.remove(sticker.id) : next.add(sticker.id);
          ref.read(stickerSelectionProvider.notifier).state = next;
          return;
        }
        showStickerSheet(context, ref, sticker);
      },
      onLongPress: selecting
          ? null
          : () {
              HapticFeedback.mediumImpact();
              ref.read(stickerSelectionProvider.notifier).state = {sticker.id};
            },
      child: Container(
        decoration: BoxDecoration(
          color: CTColors.surface,
          borderRadius: BorderRadius.circular(CTRadius.card),
          boxShadow: ctCardShadow,
        ),
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: StickerImage(
                path: repo.resolve(sticker.imagePath),
                texture: sticker.texture,
              ),
            ),
            if (sticker.audioPath != null)
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: CTColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            if (sticker.linkedItemId != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: CTColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            if (sticker.source == CardSource.beam)
              Positioned(
                top: 0,
                left: 0,
                child: BeamAvatar(
                  name: sticker.creatorName,
                  color: colorFromHex(sticker.creatorColor),
                  radius: 8,
                ),
              ),
            if (selecting)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected
                      ? CTColors.primary
                      : CTColors.textSub.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// シール詳細シート: 大きなプレビュー+クレジット+紐付けカルチャー+操作
Future<void> showStickerSheet(
  BuildContext context,
  WidgetRef ref,
  Sticker sticker,
) {
  final repo = ref.read(stickerRepositoryProvider);
  return showModalBottomSheet(
    context: context,
    backgroundColor: CTColors.bgBase,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 240,
              child: StickerImage(
                path: repo.resolve(sticker.imagePath),
                texture: sticker.texture,
              ),
            ),
            const SizedBox(height: 12),
            // シール裏面のクレジット
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BeamAvatar(
                  name: sticker.creatorName,
                  color: colorFromHex(sticker.creatorColor),
                  radius: 10,
                ),
                const SizedBox(width: 6),
                Text(
                  'Created by ${sticker.creatorName} · '
                  '${sticker.createdAt.year}/${sticker.createdAt.month}/${sticker.createdAt.day}',
                  style: TextStyle(fontSize: 12, color: CTColors.textSub),
                ),
              ],
            ),
            if (sticker.audioPath != null) ...[
              const SizedBox(height: 10),
              Consumer(
                builder: (context, sheetRef, _) => FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: CTColors.mint,
                    foregroundColor: CTColors.textMain,
                  ),
                  onPressed: () =>
                      playVoice(sheetRef, repo.resolve(sticker.audioPath!)),
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  label: const Text('ボイスを聞く'),
                ),
              ),
            ],
            if (sticker.rawPath != null) ...[
              const SizedBox(height: 10),
              Consumer(
                builder: (context, sheetRef, _) => OutlinedButton.icon(
                  onPressed: () async {
                    final color = await showBorderColorSheet(context);
                    if (color == null) return;
                    final ok = await sheetRef
                        .read(stickerRepositoryProvider)
                        .recolorBorder(sticker, color);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('フチの色を変えたよ')),
                      );
                    }
                  },
                  icon: const Icon(Icons.palette_rounded, size: 18),
                  label: const Text('フチの色を変える'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            // カードの後付け(店の場所・曲などをタップで開けるようにする)
            Consumer(
              builder: (context, sheetRef, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final item = await showCulturePickerSheet(
                        context,
                        sheetRef.read(databaseProvider),
                      );
                      if (item == null) return;
                      await sheetRef
                          .read(databaseProvider)
                          .updateStickerLink(sticker.id, item.id);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('「${item.title}」を埋め込んだよ(タップで開けるよ)'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: Text(
                      sticker.linkedItemId == null ? 'カードを埋め込む' : '埋め込みカードを変える',
                    ),
                  ),
                  if (sticker.linkedItemId != null)
                    IconButton(
                      tooltip: '埋め込みを外す',
                      onPressed: () async {
                        await sheetRef
                            .read(databaseProvider)
                            .updateStickerLink(sticker.id, null);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      icon: Icon(
                        Icons.link_off_rounded,
                        size: 20,
                        color: CTColors.textSub,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _LinkedCultureButton(sticker: sticker, sheetContext: sheetContext),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await shareStickerWithMeta(ref, sticker);
                    },
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('送る'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      await ref
                          .read(stickerRepositoryProvider)
                          .deleteSticker(sticker);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('削除'),
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

/// 紐付けカルチャーを開くボタン(未設定なら非表示)
class _LinkedCultureButton extends ConsumerWidget {
  const _LinkedCultureButton({
    required this.sticker,
    required this.sheetContext,
  });

  final Sticker sticker;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedId = sticker.linkedItemId;
    if (linkedId == null) return const SizedBox.shrink();

    return FutureBuilder<CultureItem?>(
      future: ref.read(databaseProvider).findItem(linkedId),
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: item.category.color,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(sheetContext);
              openCultureItem(context, ref, item);
            },
            icon: Icon(
              item.category == CultureCategory.food
                  ? Icons.place_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
