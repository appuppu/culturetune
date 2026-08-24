import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// メッセージ(寄せ書き・交換日記の書き込み)をメモ紙風のPNGにする。
/// 生成した画像はそのままシール加工パイプラインに流せる。
Future<String> renderMessageNote({
  required String text,
  required Color bg,
}) async {
  const width = 760.0;
  const pad = 76.0;
  final dark = bg.computeLuminance() > 0.55;
  final textColor = dark ? const Color(0xFF33272A) : Colors.white;

  // 文字量に合わせてフォントを縮めていく(最大84・最小34)
  TextPainter painter;
  var fontSize = 84.0;
  while (true) {
    painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.35,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - pad * 2);
    if (painter.height <= 620 || fontSize <= 34) break;
    fontSize -= 6;
  }

  final height = (painter.height + pad * 2).clamp(360.0, 820.0);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, width, height);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(44)),
    Paint()..color = bg,
  );
  // メモ紙らしさ: 上端にうっすら濃い帯(テープ風)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(width / 2 - 90, 26, 180, 26),
      const Radius.circular(13),
    ),
    Paint()..color = textColor.withValues(alpha: 0.14),
  );
  painter.paint(
    canvas,
    Offset((width - painter.width) / 2, (height - painter.height) / 2 + 10),
  );

  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/note_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  return file.path;
}
