import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/models/culture_category.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/label_chip.dart';
import '../../core/widgets/thumb_image.dart';
import '../detail/culture_modal.dart';
import '../map/food_map_page.dart';
import '../mix/mix_controller.dart';
import '../post/post_flow.dart';
import '../settings/settings_page.dart';
import '../wrap/wrap_page.dart';

class VaultPage extends ConsumerWidget {
  const VaultPage({super.key, this.embedded = false});

  /// シールタブ内に埋め込まれるときはロゴ・設定ボタンを持たない
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(vaultItemsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カードを主役にするため、ヘッダーは1行コンパクトに
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
            child: Row(
              children: [
                if (!embedded)
                  Text(
                    'Culture Tune',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: CTColors.primary,
                    ),
                  ),
                const Spacer(),
                const _FoodMapButton(),
                LabelChip(
                  icon: Icons.auto_awesome_rounded,
                  label: '今月のレポ',
                  color: CTColors.lemon,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const WrapPage())),
                ),
                const _MixButton(),
                if (!embedded)
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
          const _CategoryPills(),
          Expanded(
            child: items.when(
              data: (list) =>
                  list.isEmpty ? const _EmptyVault() : _VaultBody(items: list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('エラー: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

/// ピン留めストリップ + 3列グリッド
class _VaultBody extends ConsumerWidget {
  const _VaultBody({required this.items});

  final List<CultureItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = items.where((i) => i.pinnedOrder != null).toList();
    final rest = items.where((i) => i.pinnedOrder == null).toList();

    return CustomScrollView(
      slivers: [
        if (pinned.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.push_pin_rounded,
                    size: 13,
                    color: CTColors.textSub,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ピン留め(長押しで並べ替え)',
                    style: TextStyle(fontSize: 11, color: CTColors.textSub),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 152,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                itemCount: pinned.length,
                proxyDecorator: (child, _, _) =>
                    Transform.scale(scale: 1.06, child: child),
                onReorderItem: (oldIndex, newIndex) {
                  final reordered = [...pinned];
                  final moved = reordered.removeAt(oldIndex);
                  reordered.insert(newIndex, moved);
                  ref.read(itemRepositoryProvider).reorderPinned(reordered);
                  HapticFeedback.lightImpact();
                },
                itemBuilder: (_, i) => Container(
                  key: ValueKey(pinned[i].id),
                  width: 84,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.topCenter,
                  child: CultureCard(item: pinned[i]),
                ),
              ),
            ),
          ),
        ],
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
          // コンテンツの形(本=縦長/動画=横長/音楽・ご飯=正方形)に合わせて
          // 高さが変わるためメーソンリー配置にする
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childCount: rest.length,
            itemBuilder: (_, i) => CultureCard(item: rest[i]),
          ),
        ),
      ],
    );
  }
}

/// ご飯フィルタ中に出るマップボタン
class _FoodMapButton extends ConsumerWidget {
  const _FoodMapButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(vaultCategoryProvider) != CultureCategory.food) {
      return const SizedBox.shrink();
    }
    return LabelChip(
      icon: Icons.map_rounded,
      label: 'ご飯マップ',
      color: CTColors.peach,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FoodMapPage())),
    );
  }
}

/// 「今日の推しMIX」開始ボタン(再生できるカードがあるときだけ表示)
class _MixButton extends ConsumerWidget {
  const _MixButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidates = ref.watch(mixCandidatesProvider).valueOrNull ?? [];
    if (candidates.isEmpty) return const SizedBox.shrink();

    return LabelChip(
      icon: Icons.play_circle_fill_rounded,
      label: '連続再生',
      color: CTColors.primary,
      onTap: () =>
          ref.read(mixControllerProvider.notifier).startTodayMix(candidates),
    );
  }
}

/// カテゴリピル: 1画面の横幅に全部収まる等幅コンパクト表示
class _CategoryPills extends ConsumerWidget {
  const _CategoryPills();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(vaultCategoryProvider);

    Widget pill({
      CultureCategory? category,
      required String label,
      required Color color,
    }) {
      final isSelected = selected == category;
      return Expanded(
        child: GestureDetector(
          onTap: () =>
              ref.read(vaultCategoryProvider.notifier).state = category,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.3)
                  : CTColors.surface,
              borderRadius: BorderRadius.circular(CTRadius.pill),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CTColors.textMain,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Row(
        children: [
          pill(category: null, label: 'All', color: CTColors.primary),
          for (final c in CultureCategory.values)
            pill(category: c, label: c.labelJa, color: c.color),
        ],
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_rounded, size: 56, color: CTColors.primary),
          const SizedBox(height: 12),
          Text(
            '本・音楽・動画・ご飯を登録すると\nタップで再生できるカードになるよ',
            textAlign: TextAlign.center,
            style: TextStyle(color: CTColors.textSub, height: 1.6),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => showPostCategorySheet(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('カードをつくる'),
          ),
        ],
      ),
    );
  }
}

/// トレカ風カード: 上=写真、下=白背景にタイトル・タグ・アバター。
/// 長押しでピン留め。
class CultureCard extends ConsumerWidget {
  const CultureCard({super.key, required this.item});

  final CultureItem item;

  Color get _moodColor {
    final hex = item.moodColor;
    if (hex == null || !hex.startsWith('#')) return item.category.color;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? item.category.color : Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _moodColor;
    final tags = (jsonDecode(item.moodTags) as List).cast<String>();

    return GestureDetector(
      onTap: () => openCultureItem(context, ref, item),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        ref.read(itemRepositoryProvider).togglePinned(item);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(item.pinnedOrder != null ? 'ピン留めを外したよ' : 'ピン留めしたよ'),
            ),
          );
      },
      child: Container(
        decoration: BoxDecoration(
          color: CTColors.surface,
          borderRadius: BorderRadius.circular(CTRadius.card),
          border: Border.all(color: color, width: 2),
          boxShadow: ctCardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 上: 写真。カテゴリごとの形(本=縦長/動画=横長/他=正方形)
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(CTRadius.inner(CTRadius.card, 2)),
                  ),
                  child: AspectRatio(
                    aspectRatio: item.category.thumbAspect,
                    child: SizedBox(
                      width: double.infinity,
                      child: ThumbImage(item: item),
                    ),
                  ),
                ),
                // 下: 白背景に文字とアバター
                Padding(
                  padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          tags.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.5,
                            color: CTColors.textSub,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (item.pinnedOrder != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.push_pin_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
