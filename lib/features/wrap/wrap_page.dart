import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/models/culture_category.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/thumb_image.dart';

/// 今月のまとめレポ。ストーリー画像として共有できる。
class WrapPage extends ConsumerStatefulWidget {
  const WrapPage({super.key});

  @override
  ConsumerState<WrapPage> createState() => _WrapPageState();
}

class _WrapPageState extends ConsumerState<WrapPage> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final ratio = 1080 / boundary.size.width;
      final image = await boundary.toImage(pixelRatio: ratio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final file = File(
        '${dir.path}/culture_wrap_${now.year}_${now.month}.png',
      );
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await Share.shareXFiles([
        XFile(file.path),
      ], text: '${now.month}月のしーるちょうレポ #しーるちょう');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('書き出しに失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(allItemsProvider).valueOrNull ?? [];
    final now = DateTime.now();
    final monthItems = items
        .where(
          (i) => i.createdAt.year == now.year && i.createdAt.month == now.month,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${now.month}月のレポ'),
        actions: [
          IconButton(
            onPressed: monthItems.isEmpty || _sharing ? null : _share,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'ストーリー画像で共有',
          ),
        ],
      ),
      body: monthItems.isEmpty
          ? Center(
              child: Text(
                '今月はまだカードがないよ',
                style: TextStyle(color: CTColors.textSub),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: _WrapCard(items: monthItems, month: now.month),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _WrapCard extends StatelessWidget {
  const _WrapCard({required this.items, required this.month});

  final List<CultureItem> items;
  final int month;

  @override
  Widget build(BuildContext context) {
    final byCategory = <CultureCategory, int>{};
    final tagCount = <String, int>{};
    for (final item in items) {
      byCategory.update(item.category, (v) => v + 1, ifAbsent: () => 1);
      for (final t in (jsonDecode(item.moodTags) as List).cast<String>()) {
        tagCount.update(t, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final topCategory =
        (byCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first;
    final topTag = tagCount.isEmpty
        ? null
        : (tagCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
    // ベストカード: ピン留め優先、次に新着
    final best =
        (items.toList()..sort((a, b) {
              final aPin = a.pinnedOrder != null ? 0 : 1;
              final bPin = b.pinnedOrder != null ? 0 : 1;
              final byPin = aPin.compareTo(bPin);
              return byPin != 0 ? byPin : b.createdAt.compareTo(a.createdAt);
            }))
            .first;
    final maxCount = byCategory.values.reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3EE), Color(0xFFFFF7F9), Color(0xFFDFF9F3)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$month月のしーるちょうレポ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: CTColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${items.length}枚のカードを集めたよ!',
            style: TextStyle(fontSize: 13, color: CTColors.textSub),
          ),
          const SizedBox(height: 16),
          // カテゴリバー
          for (final c in CultureCategory.values)
            if (byCategory.containsKey(c))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Icon(c.icon, size: 18, color: c.color),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(CTRadius.pill),
                        child: LinearProgressIndicator(
                          value: byCategory[c]! / maxCount,
                          minHeight: 12,
                          color: c.color,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        ' ${byCategory[c]}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatBubble(label: '推しジャンル', value: topCategory.key.labelJa),
              const SizedBox(width: 10),
              if (topTag != null) _StatBubble(label: '今月の気分', value: topTag),
            ],
          ),
          const Spacer(),
          const Text(
            '今月のベストカード',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: CTColors.surface,
              borderRadius: BorderRadius.circular(CTRadius.card),
              border: Border.all(color: CTColors.lemon, width: 3),
              boxShadow: ctCardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(CTRadius.inner(CTRadius.card, 3)),
                  ),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: ThumbImage(item: best),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        best.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'しーるちょう',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: CTColors.primary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(CTRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: CTColors.textSub)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
