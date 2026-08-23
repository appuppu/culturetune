import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/data/item_repository.dart';
import '../../core/db/app_database.dart';

/// マップ用の「写真を丸く型どったピン」画像を生成する。
/// 気分カラーのリング付きで、写真が無いカードはカラー円+白アイコン。
Future<Uint8List> buildPhotoPinBytes(
  CultureItem item,
  Color ringColor,
  ItemRepository repo,
) async {
  const size = 132.0; // 円の直径(リング含む)
  const pointer = 20.0; // 下向きの三角
  const ring = 8.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(size / 2, size / 2);
  final radius = size / 2;

  // 下向きポインタ(しずく型の先端)
  final pointerPath = Path()
    ..moveTo(size / 2 - 16, size - 14)
    ..lineTo(size / 2, size + pointer)
    ..lineTo(size / 2 + 16, size - 14)
    ..close();
  canvas.drawPath(pointerPath, Paint()..color = ringColor);

  // リング
  canvas.drawCircle(center, radius, Paint()..color = ringColor);

  // 中身(写真 or カラー+アイコン)
  final innerRadius = radius - ring;
  final photo = await _loadPhoto(item, repo);
  if (photo != null) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
    );
    // cover相当で描画
    final src = _coverRect(photo.width.toDouble(), photo.height.toDouble());
    canvas.drawImageRect(
      photo,
      src,
      Rect.fromCircle(center: center, radius: innerRadius),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  } else {
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = ringColor.withValues(alpha: 0.85),
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(item.category.icon.codePoint),
        style: TextStyle(
          fontSize: 56,
          fontFamily: item.category.icon.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  final image = await recorder.endRecording().toImage(
    size.toInt(),
    (size + pointer).toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// 中央正方形をトリミングするソース矩形(cover相当)
Rect _coverRect(double w, double h) {
  final side = math.min(w, h);
  return Rect.fromLTWH((w - side) / 2, (h - side) / 2, side, side);
}

Future<ui.Image?> _loadPhoto(CultureItem item, ItemRepository repo) async {
  try {
    final path = item.thumbPath;
    if (path == null) return null;
    final file = File(repo.resolveThumb(path));
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 300);
    return (await codec.getNextFrame()).image;
  } catch (_) {
    return null;
  }
}
