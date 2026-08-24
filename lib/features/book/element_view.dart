import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/files/doc_paths.dart';
import '../../core/models/page_element_type.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sticker_image.dart';
import '../../core/db/app_database.dart';
import '../../core/stickers/voice_player.dart';
import '../../core/widgets/thumb_image.dart';
import '../beam/beam_profile_provider.dart';
import '../detail/culture_modal.dart';
import 'page_models.dart';

/// 要素タップ時の共通アクション:
/// カード/カルチャー埋め込みシール → その場で再生・マップ・情報表示。
Future<void> openElementAction(
  BuildContext context,
  WidgetRef ref,
  ResolvedElement resolved,
) async {
  // ボイス付きシールはタップで声が鳴る(最優先)
  final audioPath = resolved.sticker?.audioPath;
  if (audioPath != null) {
    await playVoice(
      ref,
      ref.read(stickerRepositoryProvider).resolve(audioPath),
    );
    return;
  }

  CultureItem? item = resolved.item;
  final linkedId = resolved.sticker?.linkedItemId;
  if (item == null && linkedId != null) {
    item = await ref.read(databaseProvider).findItem(linkedId);
  }
  if (item != null && context.mounted) {
    await openCultureItem(context, ref, item);
  }
}

/// ページ要素1つの見た目(エディタ・サムネイル共通)。
/// 位置(Positioned)や回転は呼び出し側が担当し、ここはサイズと中身だけ描く。
class ElementView extends ConsumerWidget {
  const ElementView({
    super.key,
    required this.resolved,
    required this.canvasWidth,
  });

  final ResolvedElement resolved;
  final double canvasWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final el = resolved.element;
    switch (el.type) {
      case PageElementType.sticker:
        final sticker = resolved.sticker!;
        final size = canvasWidth * 0.42 * el.scale;
        return SizedBox(
          width: size,
          height: size,
          child: StickerImage(
            path: ref
                .read(stickerRepositoryProvider)
                .resolve(sticker.imagePath),
            texture: sticker.texture,
          ),
        );
      case PageElementType.card:
        final item = resolved.item!;
        final w = canvasWidth * 0.4 * el.scale;
        // ネスト角丸: inner = outer - gap
        final outer = w * 0.09;
        return Container(
          width: w,
          decoration: BoxDecoration(
            color: CTColors.surface,
            borderRadius: BorderRadius.circular(outer),
            border: Border.all(color: item.category.color, width: w * 0.016),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: w * 0.05,
                offset: Offset(0, w * 0.02),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(CTRadius.inner(outer, w * 0.016)),
                ),
                child: SizedBox(
                  width: w,
                  height: w / item.category.thumbAspect,
                  child: ThumbImage(item: item),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(w * 0.055),
                child: Row(
                  children: [
                    Icon(
                      item.category.icon,
                      size: w * 0.09,
                      color: item.category.color,
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: w * 0.075,
                          fontWeight: FontWeight.w800,
                          color: CTColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case PageElementType.text:
        final payload = TextPayload.fromJson(el.payload);
        return Text(
          payload.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: canvasWidth * 0.06 * payload.sizeFactor * el.scale,
            fontWeight: FontWeight.w800,
            color: payload.color,
            height: 1.25,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        );
      case PageElementType.profile:
        final payload = ProfilePayload.fromJson(el.payload);
        final size = canvasWidth * 0.18 * el.scale;
        return ProfileShapeAvatar(payload: payload, size: size);
    }
  }
}

/// 形と枠色を選べるプロフィールアバター。
/// スナップショット(受け取ったページ)ならその情報を、
/// 自分のページなら現在のプロフィールを表示する。
class ProfileShapeAvatar extends ConsumerWidget {
  const ProfileShapeAvatar({
    super.key,
    required this.payload,
    required this.size,
  });

  final ProfilePayload payload;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String name;
    final Color color;
    final String? imagePath;
    if (payload.isSnapshot) {
      name = payload.name!;
      color = colorFromHex(payload.colorHex);
      final rawPath = payload.avatarPath;
      imagePath = rawPath == null
          ? null
          : resolveDocFile(ref.watch(documentsDirProvider), rawPath);
    } else {
      final profile = ref.watch(beamProfileProvider).valueOrNull;
      name = profile?.name ?? '?';
      color = colorFromHex(profile?.colorHex);
      imagePath = profile?.imagePath;
    }

    final frame = payload.frameColor;
    final radius = switch (payload.shape) {
      ProfileShape.circle => size / 2,
      ProfileShape.rounded => size * 0.28,
      ProfileShape.square => size * 0.1,
      ProfileShape.diamond => size * 0.16,
    };
    final rotate = payload.shape == ProfileShape.diamond;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: frame,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: size * 0.08,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.07),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          CTRadius.inner(radius, size * 0.07),
        ),
        child: _face(name, color, imagePath, rotate),
      ),
    );

    if (rotate) {
      avatar = Transform.rotate(angle: 0.785398, child: avatar); // 45°
    }
    return SizedBox(
      width: size * (rotate ? 1.42 : 1),
      height: size * (rotate ? 1.42 : 1),
      child: Center(child: avatar),
    );
  }

  Widget _face(String name, Color color, String? imagePath, bool rotate) {
    Widget face;
    if (imagePath != null && File(imagePath).existsSync()) {
      face = Image.file(File(imagePath), fit: BoxFit.cover);
    } else {
      face = ColoredBox(
        color: color,
        child: Center(
          child: Text(
            name.isEmpty ? '?' : name.characters.first,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.4,
            ),
          ),
        ),
      );
    }
    // ダイヤ形は中身を逆回転して顔をまっすぐに保つ
    return rotate ? Transform.rotate(angle: -0.785398, child: face) : face;
  }
}
