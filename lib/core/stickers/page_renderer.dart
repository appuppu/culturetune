import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../features/book/page_models.dart';
import '../data/item_repository.dart';
import '../files/doc_paths.dart';
import '../db/app_database.dart';
import '../models/page_element_type.dart';
import 'sticker_repository.dart';

/// シール帳ページを1080x1920のPNGへ描画する(交換の送信用)。
/// エディタ画面を開かずにページを画像化できる。
Future<Uint8List> renderPageToPng({
  required Directory docs,
  required AppDatabase db,
  required StickerRepository stickerRepo,
  required ItemRepository itemRepo,
  required StickerPage page,
  int width = 1080,
}) async {
  final w = width.toDouble();
  final h = w * 16 / 9;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // 背景
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = _bgColor(page));
  if (page.bgImagePath != null) {
    final bg = await _loadImage(resolveDocFile(docs, page.bgImagePath!));
    if (bg != null) _drawCover(canvas, bg, Rect.fromLTWH(0, 0, w, h));
  }

  final elements = await loadResolvedElements(db, page.id);
  elements.sort((a, b) => a.element.z.compareTo(b.element.z));

  for (final r in elements) {
    final el = r.element;
    canvas.save();
    canvas.translate(el.x * w, el.y * h);
    canvas.rotate(el.rotation);

    switch (el.type) {
      case PageElementType.sticker:
        final image = await _loadImage(
          stickerRepo.resolve(r.sticker!.imagePath),
        );
        if (image != null) {
          final size = w * 0.42 * el.scale;
          _drawContain(canvas, image, size);
        }
      case PageElementType.card:
        await _drawCard(canvas, r, itemRepo, w * 0.4 * el.scale);
      case PageElementType.profile:
        await _drawProfile(
          canvas,
          ProfilePayload.fromJson(el.payload),
          w * 0.18 * el.scale,
          docs,
        );
      case PageElementType.text:
        final payload = TextPayload.fromJson(el.payload);
        final painter = TextPainter(
          text: TextSpan(
            text: payload.text,
            style: TextStyle(
              fontSize: w * 0.06 * payload.sizeFactor * el.scale,
              fontWeight: FontWeight.w800,
              color: payload.color,
              height: 1.25,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: w * 0.9);
        painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    }
    canvas.restore();
  }

  // シール帳のフチ(内側に沿わせて描く)
  final borderColor = _pageBorderColor(page);
  if (borderColor != null) {
    final stroke = w * 0.012;
    canvas.drawRect(
      Rect.fromLTWH(stroke / 2, stroke / 2, w - stroke, h - stroke),
      Paint()
        ..color = borderColor
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  final image = await recorder.endRecording().toImage(width, h.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

Color? _pageBorderColor(StickerPage page) {
  final hex = page.borderColor;
  if (hex == null || !hex.startsWith('#')) return null;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

Color _bgColor(StickerPage page) {
  final hex = page.bgColor;
  if (hex == null || !hex.startsWith('#')) return Colors.white;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? Colors.white : Color(0xFF000000 | value);
}

Future<ui.Image?> _loadImage(String path) async {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    return (await codec.getNextFrame()).image;
  } catch (_) {
    return null;
  }
}

/// 中心原点に、size×sizeへcontainで描画
void _drawContain(Canvas canvas, ui.Image image, double size) {
  final scale = size / math.max(image.width, image.height);
  final dw = image.width * scale;
  final dh = image.height * scale;
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromCenter(center: Offset.zero, width: dw, height: dh),
    Paint()..filterQuality = FilterQuality.medium,
  );
}

/// rectへcoverで描画
void _drawCover(Canvas canvas, ui.Image image, Rect rect) {
  final scale = math.max(rect.width / image.width, rect.height / image.height);
  final sw = rect.width / scale;
  final sh = rect.height / scale;
  canvas.drawImageRect(
    image,
    Rect.fromLTWH((image.width - sw) / 2, (image.height - sh) / 2, sw, sh),
    rect,
    Paint()..filterQuality = FilterQuality.medium,
  );
}

/// カード要素(白い角丸カード+サムネ+タイトル)を中心原点に描画
Future<void> _drawCard(
  Canvas canvas,
  ResolvedElement r,
  ItemRepository itemRepo,
  double cardW,
) async {
  final item = r.item!;
  final thumbH = cardW / item.category.thumbAspect;
  final footerH = cardW * 0.19;
  final cardH = thumbH + footerH;
  final rect = Rect.fromCenter(
    center: Offset.zero,
    width: cardW,
    height: cardH,
  );
  final outer = cardW * 0.09;
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(outer));

  // 影 + 本体
  canvas.drawRRect(
    rrect.shift(Offset(0, cardW * 0.02)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cardW * 0.03),
  );
  canvas.drawRRect(rrect, Paint()..color = Colors.white);

  // サムネ(ローカル画像があれば)
  canvas.save();
  canvas.clipRRect(rrect);
  final thumbRect = Rect.fromLTWH(rect.left, rect.top, cardW, thumbH);
  ui.Image? thumb;
  if (item.thumbPath != null) {
    thumb = await _loadImage(itemRepo.resolveThumb(item.thumbPath!));
  }
  if (thumb != null) {
    _drawCover(canvas, thumb, thumbRect);
  } else {
    canvas.drawRect(
      thumbRect,
      Paint()..color = item.category.color.withValues(alpha: 0.2),
    );
  }
  canvas.restore();

  // タイトル
  final painter = TextPainter(
    text: TextSpan(
      text: item.title,
      style: TextStyle(
        fontSize: cardW * 0.075,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF33272A),
      ),
    ),
    maxLines: 1,
    ellipsis: '…',
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: cardW * 0.85);
  painter.paint(
    canvas,
    Offset(rect.left + cardW * 0.075, rect.top + thumbH + footerH * 0.22),
  );

  // 枠線
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cardW * 0.016
      ..color = item.category.color,
  );
}

/// プロフィールアイコン(形+枠色+アバター)を中心原点に描画。
/// スナップショットが無い(自分のページの)場合は名前イニシャルのみ描く。
Future<void> _drawProfile(
  Canvas canvas,
  ProfilePayload payload,
  double size,
  Directory docs,
) async {
  final radius = switch (payload.shape) {
    ProfileShape.circle => size / 2,
    ProfileShape.rounded => size * 0.28,
    ProfileShape.square => size * 0.1,
    ProfileShape.diamond => size * 0.16,
  };
  if (payload.shape == ProfileShape.diamond) {
    canvas.save();
    canvas.rotate(math.pi / 4);
  }

  final rect = Rect.fromCenter(center: Offset.zero, width: size, height: size);
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

  canvas.drawRRect(
    rrect.shift(Offset(0, size * 0.04)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.05),
  );
  canvas.drawRRect(rrect, Paint()..color = payload.frameColor);

  final pad = size * 0.07;
  final inner = RRect.fromRectAndRadius(
    rect.deflate(pad),
    Radius.circular((radius - pad).clamp(0, radius)),
  );
  canvas.save();
  canvas.clipRRect(inner);
  if (payload.shape == ProfileShape.diamond) canvas.rotate(-math.pi / 4);

  ui.Image? avatar;
  if (payload.avatarPath != null) {
    avatar = await _loadImage(resolveDocFile(docs, payload.avatarPath!));
  }
  if (avatar != null) {
    _drawCover(canvas, avatar, rect.deflate(pad).inflate(size * 0.21));
  } else {
    final bg = payload.colorHex != null
        ? (int.tryParse(payload.colorHex!.substring(1), radix: 16) ?? 0xFF6B9D)
        : 0xFF6B9D;
    canvas.drawRect(
      rect.inflate(size * 0.5),
      Paint()..color = Color(0xFF000000 | bg),
    );
    final initial = (payload.name?.isNotEmpty ?? false)
        ? payload.name!.characters.first
        : '?';
    final painter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  }
  canvas.restore();
  if (payload.shape == ProfileShape.diamond) canvas.restore();
}
