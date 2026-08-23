import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/db/app_database.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/thumb_image.dart';

/// ストーリー(9:16)用のシェア画像プレビューを開き、PNG書き出し→共有する
Future<void> showStoryShareSheet(BuildContext context, CultureItem item) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: CTColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (_) => _StorySharePreview(item: item),
  );
}

class _StorySharePreview extends StatefulWidget {
  const _StorySharePreview({required this.item});

  final CultureItem item;

  @override
  State<_StorySharePreview> createState() => _StorySharePreviewState();
}

class _StorySharePreviewState extends State<_StorySharePreview> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      // プレビュー幅×pixelRatioで約1080pxに揃える
      final ratio = 1080 / boundary.size.width;
      final image = await boundary.toImage(pixelRatio: ratio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/culture_card_${widget.item.id}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await Share.shareXFiles([
        XFile(file.path),
      ], text: '${widget.item.title} #CultureTune');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('画像の書き出しに失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ストーリー画像で共有',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: StoryCard(item: widget.item),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sharing ? null : _share,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(_sharing ? '書き出し中…' : 'シェアする'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1080x1920で書き出されるカードデザイン本体
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.item});

  final CultureItem item;

  Color get _moodColor {
    final hex = item.moodColor;
    if (hex == null || !hex.startsWith('#')) return item.category.color;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? item.category.color : Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final tags = (jsonDecode(item.moodTags) as List).cast<String>();
    final color = _moodColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.55),
            CTColors.bgBase,
            color.withValues(alpha: 0.35),
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // カード本体
          Container(
            decoration: BoxDecoration(
              color: CTColors.surface,
              borderRadius: BorderRadius.circular(CTRadius.card),
              border: Border.all(color: color, width: 3),
              boxShadow: ctCardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(CTRadius.inner(CTRadius.card, 3)),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ThumbImage(item: item),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CTColors.textSub,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final t in tags)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    CTRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (item.memo != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.memo!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Culture Tune',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: CTColors.primary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
