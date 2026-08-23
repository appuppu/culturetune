import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/db/app_database.dart';
import '../../core/models/page_element_type.dart';

/// ページ要素 + 参照先(シール/カード)を解決したもの
class ResolvedElement {
  ResolvedElement({required this.element, this.sticker, this.item});

  PageElement element;
  final Sticker? sticker;
  final CultureItem? item;

  PageElementType get type => element.type;
}

Future<List<ResolvedElement>> loadResolvedElements(
  AppDatabase db,
  String pageId,
) async {
  final rows = await db.getPageElements(pageId);
  final resolved = <ResolvedElement>[];
  for (final row in rows) {
    switch (row.type) {
      case PageElementType.sticker:
        final sticker = await db.findSticker(row.refId ?? '');
        if (sticker != null) {
          resolved.add(ResolvedElement(element: row, sticker: sticker));
        }
      case PageElementType.card:
        final item = await db.findItem(row.refId ?? '');
        if (item != null) {
          resolved.add(ResolvedElement(element: row, item: item));
        }
      case PageElementType.text:
      case PageElementType.profile:
        resolved.add(ResolvedElement(element: row));
    }
  }
  return resolved;
}

/// テキスト要素のpayload
class TextPayload {
  const TextPayload({
    required this.text,
    required this.colorHex,
    this.sizeFactor = 1.0,
  });

  final String text;
  final String colorHex;

  /// 1.0=M。キャンバス幅×0.06×factorがフォントサイズになる
  final double sizeFactor;

  factory TextPayload.fromJson(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return TextPayload(
        text: map['text'] as String? ?? '',
        colorHex: map['color'] as String? ?? '#FFFFFF',
        sizeFactor: (map['size'] as num?)?.toDouble() ?? 1.0,
      );
    } catch (_) {
      return const TextPayload(text: '', colorHex: '#FFFFFF');
    }
  }

  String toJson() =>
      jsonEncode({'text': text, 'color': colorHex, 'size': sizeFactor});

  Color get color {
    if (!colorHex.startsWith('#')) return Colors.white;
    final value = int.tryParse(colorHex.substring(1), radix: 16);
    return value == null ? Colors.white : Color(0xFF000000 | value);
  }
}

/// プロフィールアイコンの形
enum ProfileShape { circle, rounded, square, diamond }

/// プロフィール要素のpayload。
/// 自分のページでは形/枠色のみ持ち、名前や写真はライブのプロフィールを参照。
/// 交換で受け取ったページではname/color/avatarPathのスナップショットが入る。
class ProfilePayload {
  const ProfilePayload({
    this.shape = ProfileShape.circle,
    this.frameColorHex = '#FFFFFF',
    this.name,
    this.colorHex,
    this.avatarPath,
  });

  final ProfileShape shape;
  final String frameColorHex;
  final String? name;
  final String? colorHex;
  final String? avatarPath;

  bool get isSnapshot => name != null;

  factory ProfilePayload.fromJson(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return ProfilePayload(
        shape:
            ProfileShape.values.asNameMap()[map['shape']] ??
            ProfileShape.circle,
        frameColorHex: map['frameColor'] as String? ?? '#FFFFFF',
        name: map['name'] as String?,
        colorHex: map['color'] as String?,
        avatarPath: map['avatarPath'] as String?,
      );
    } catch (_) {
      return const ProfilePayload();
    }
  }

  String toJson() => jsonEncode({
    'shape': shape.name,
    'frameColor': frameColorHex,
    if (name != null) 'name': name,
    if (colorHex != null) 'color': colorHex,
    if (avatarPath != null) 'avatarPath': avatarPath,
  });

  ProfilePayload copyWith({ProfileShape? shape, String? frameColorHex}) =>
      ProfilePayload(
        shape: shape ?? this.shape,
        frameColorHex: frameColorHex ?? this.frameColorHex,
        name: name,
        colorHex: colorHex,
        avatarPath: avatarPath,
      );

  Color get frameColor {
    if (!frameColorHex.startsWith('#')) return Colors.white;
    final value = int.tryParse(frameColorHex.substring(1), radix: 16);
    return value == null ? Colors.white : Color(0xFF000000 | value);
  }
}
