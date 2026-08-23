import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/sticker_texture.dart';

/// シール画像の表示。ホロ質感は傾きセンサー連動でキラキラ反射する。
class StickerImage extends StatelessWidget {
  const StickerImage({
    super.key,
    required this.path,
    required this.texture,
    this.fit = BoxFit.contain,
  });

  final String path;
  final StickerTexture texture;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final image = Image.file(File(path), fit: fit);
    if (texture != StickerTexture.holo) return image;
    return _HoloShine(child: image);
  }
}

/// 端末の傾きに応じて光の帯がシール表面を走るエフェクト。
/// srcATopでシールの不透明部分だけに光を乗せる。
class _HoloShine extends StatefulWidget {
  const _HoloShine({required this.child});

  final Widget child;

  @override
  State<_HoloShine> createState() => _HoloShineState();
}

class _HoloShineState extends State<_HoloShine> {
  StreamSubscription<AccelerometerEvent>? _sub;
  double _tilt = 0; // -1..1

  @override
  void initState() {
    super.initState();
    _sub =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 80),
        ).listen((event) {
          // 左右の傾き(x軸)を光の位置に変換
          final tilt = (event.x / 6).clamp(-1.0, 1.0);
          if ((tilt - _tilt).abs() > 0.02 && mounted) {
            setState(() => _tilt = tilt);
          }
        }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shift = _tilt; // -1..1
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(-1 + shift, -1),
          end: Alignment(1 + shift, 1),
          colors: [
            Colors.white.withValues(alpha: 0),
            const Color(0xFFB0E8FF).withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.45),
            const Color(0xFFFFB0E8).withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0),
          ],
          stops: [
            0,
            (0.35 + shift * 0.1).clamp(0.05, 0.95),
            (0.5 + shift * 0.1).clamp(0.1, 0.97),
            (0.65 + shift * 0.1).clamp(0.15, 0.99),
            1,
          ],
          transform: GradientRotation(math.pi / 12 * shift),
        ).createShader(bounds);
      },
      child: widget.child,
    );
  }
}
