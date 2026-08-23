import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../db/app_database.dart';

/// カードのサムネ表示。ローカル取り込み済み画像を最優先し、
/// 無ければthumbUrl、それも無ければカテゴリ絵文字プレースホルダ。
class ThumbImage extends ConsumerWidget {
  const ThumbImage({super.key, required this.item, this.fit = BoxFit.cover});

  final CultureItem item;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(itemRepositoryProvider);

    final localPath = item.thumbPath;
    if (localPath != null) {
      final file = File(repo.resolveThumb(localPath));
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          errorBuilder: (_, _, _) => _fallback(),
        );
      }
    }
    if (item.thumbUrl != null) {
      return CachedNetworkImage(
        imageUrl: item.thumbUrl!,
        fit: fit,
        errorWidget: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _fallback() => item.thumbUrl != null
      ? CachedNetworkImage(imageUrl: item.thumbUrl!, fit: fit)
      : _placeholder();

  Widget _placeholder() => ColoredBox(
    color: item.category.color.withValues(alpha: 0.25),
    child: Center(
      child: Icon(item.category.icon, size: 40, color: item.category.color),
    ),
  );
}
