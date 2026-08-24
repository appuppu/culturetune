import 'package:flutter/material.dart';

import '../db/app_database.dart';
import 'culture_category.dart';

/// カードの枠色。登録時に保存した気分カラー(hex固定)を最優先し、
/// 無い場合のみカテゴリ色へフォールバックする。
/// カテゴリ色はテーマ連動なので、hexを優先することで
/// テーマを変えてもシール帳上のカードの枠色が変わらない。
Color moodColorOf(CultureItem item) {
  final hex = item.moodColor;
  if (hex != null && hex.startsWith('#')) {
    final value = int.tryParse(hex.substring(1), radix: 16);
    if (value != null) return Color(0xFF000000 | value);
  }
  return item.category.color;
}
