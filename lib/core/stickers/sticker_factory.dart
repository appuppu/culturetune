import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/sticker_texture.dart';

/// 切り抜き画像(または通常写真)を「本物のシール」風に加工する。
/// - ぷっくりした白フチ(シルエットの膨張)
/// - ドロップシャドウ
/// - 質感ごとの光沢/ハイライト
class StickerFactory {
  /// [sourcePath]の画像をシール化した透過PNGバイト列を返す。
  /// [isCutout]がfalseのとき(被写体切り抜き不可時)は角丸マスクでシール化する。
  static Future<Uint8List> makeSticker({
    required String sourcePath,
    required StickerTexture texture,
    required bool isCutout,
    Color borderColor = Colors.white,
  }) async {
    final base = await _loadBase(sourcePath, isCutout: isCutout);
    final w = base.width.toDouble();
    final h = base.height.toDouble();

    // 白フチ幅と余白
    final border = (math.max(w, h) * 0.035).clamp(8.0, 18.0);
    final pad = border + 24;
    final outW = (w + pad * 2).toInt();
    final outH = (h + pad * 2).toInt();
    final center = Offset(pad, pad);

    // 1) シルエット(白フチ形状)を作る: 白塗り画像を円周上にスタンプ
    final silhouette = await _renderSilhouette(
      base,
      border: border,
      pad: pad,
      outW: outW,
      outH: outH,
    );

    // 2) 合成
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final fullRect = Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble());

    // ドロップシャドウ(シルエットを黒くぼかして下にずらす)
    canvas.drawImage(
      silhouette,
      const Offset(0, 7),
      Paint()
        ..colorFilter = const ColorFilter.mode(Colors.black38, BlendMode.srcIn)
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
    );

    // フチ(色は選択可。クリアは半透明に)
    final borderAlpha = texture == StickerTexture.clear ? 0.72 : 1.0;
    canvas.drawImage(
      silhouette,
      Offset.zero,
      Paint()
        ..colorFilter = ColorFilter.mode(
          borderColor.withValues(alpha: borderAlpha),
          BlendMode.srcIn,
        ),
    );

    // 本体(クリアは少し透かす)
    final bodyAlpha = texture == StickerTexture.clear ? 0.82 : 1.0;
    canvas.drawImage(
      base,
      center,
      Paint()..color = Colors.white.withValues(alpha: bodyAlpha),
    );

    // 3) 質感オーバーレイ(シルエット形状でマスク)
    canvas.saveLayer(fullRect, Paint());
    _paintTexture(canvas, fullRect, texture);
    canvas.drawImage(
      silhouette,
      Offset.zero,
      Paint()..blendMode = BlendMode.dstIn,
    );
    canvas.restore();

    final image = await recorder.endRecording().toImage(outW, outH);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  /// 画像を読み込み。切り抜きなしの場合は角丸マスクを適用してシール形状にする
  static Future<ui.Image> _loadBase(
    String path, {
    required bool isCutout,
  }) async {
    final bytes = await ui.ImmutableBuffer.fromFilePath(path);
    final descriptor = await ui.ImageDescriptor.encoded(bytes);
    final scale = 900 / math.max(descriptor.width, descriptor.height);
    final codec = await descriptor.instantiateCodec(
      targetWidth: scale < 1 ? (descriptor.width * scale).round() : null,
      targetHeight: scale < 1 ? (descriptor.height * scale).round() : null,
    );
    final image = (await codec.getNextFrame()).image;
    if (isCutout) return image;

    // 角丸マスク
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(math.min(w, h) * 0.14),
      ),
    );
    canvas.drawImage(image, Offset.zero, Paint());
    return recorder.endRecording().toImage(image.width, image.height);
  }

  /// 白フチ形状: 元画像のアルファを円周方向にborder分スタンプして膨張させる
  static Future<ui.Image> _renderSilhouette(
    ui.Image base, {
    required double border,
    required double pad,
    required int outW,
    required int outH,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn);
    const steps = 24;
    for (var i = 0; i < steps; i++) {
      final angle = 2 * math.pi * i / steps;
      // 縁を滑らかにするため2重の半径でスタンプ
      for (final r in [border, border * 0.6]) {
        canvas.drawImage(
          base,
          Offset(pad + math.cos(angle) * r, pad + math.sin(angle) * r),
          paint,
        );
      }
    }
    canvas.drawImage(base, Offset(pad, pad), paint);
    return recorder.endRecording().toImage(outW, outH);
  }

  /// 質感ごとのオーバーレイ描画(この後シルエットでマスクされる)
  static void _paintTexture(Canvas canvas, Rect rect, StickerTexture texture) {
    // 共通: 斜めの光沢バンド
    void gloss(double alpha) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: alpha),
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: alpha * 0.5),
            ],
            stops: const [0, 0.35, 0.75, 1],
          ).createShader(rect),
      );
    }

    switch (texture) {
      case StickerTexture.normal:
        gloss(0.16);
      case StickerTexture.puffy:
        // ぷっくりジェル: 上部ハイライト + 下部の内側シェード
        canvas.drawRect(
          rect,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.4, -0.5),
              radius: 1.1,
              colors: [
                Colors.white.withValues(alpha: 0.38),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(rect),
        );
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0),
                Colors.black.withValues(alpha: 0.10),
              ],
              stops: const [0.6, 1],
            ).createShader(rect),
        );
      case StickerTexture.clear:
        gloss(0.30);
      case StickerTexture.holo:
        // ベースの虹色(表示時にさらに傾きセンサー連動の光が乗る)
        canvas.drawRect(
          rect,
          Paint()
            ..blendMode = BlendMode.screen
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF8FD0).withValues(alpha: 0.30),
                const Color(0xFF8FD0FF).withValues(alpha: 0.30),
                const Color(0xFFB0FFC8).withValues(alpha: 0.30),
                const Color(0xFFFFF38F).withValues(alpha: 0.30),
              ],
            ).createShader(rect),
        );
        gloss(0.18);
    }
  }
}
