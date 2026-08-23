import 'package:flutter/material.dart';

/// シールの質感エフェクト
enum StickerTexture {
  normal(labelJa: 'ノーマル', icon: Icons.circle_outlined),
  puffy(labelJa: 'ぷくぷく', icon: Icons.bubble_chart_rounded),
  clear(labelJa: 'クリア', icon: Icons.blur_on_rounded),
  holo(labelJa: 'ホロ', icon: Icons.auto_awesome_rounded);

  const StickerTexture({required this.labelJa, required this.icon});

  final String labelJa;
  final IconData icon;
}
