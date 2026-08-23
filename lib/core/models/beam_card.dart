import 'dart:convert';

import '../db/app_database.dart';
import 'culture_category.dart';

/// Beam(すれ違い交換)で受け渡すカードパケット。
/// プライバシーのため個人メモ・位置情報は含めない。
class BeamCard {
  const BeamCard({
    this.version = 1,
    required this.senderName,
    required this.senderColor,
    required this.category,
    required this.title,
    this.subtitle,
    this.thumbUrl,
    this.externalId,
    this.url,
    required this.oshiLevel,
    required this.moodTags,
    this.moodColor,
  });

  final int version;
  final String senderName;

  /// 送り主のアバターカラー(hex)
  final String senderColor;
  final CultureCategory category;
  final String title;
  final String? subtitle;
  final String? thumbUrl;
  final String? externalId;
  final String? url;
  final int oshiLevel;
  final List<String> moodTags;
  final String? moodColor; // hex文字列 (#FF6B9D)

  /// 手持ちのカードから交換用パケットを作る(メモ・位置情報は除外)
  factory BeamCard.fromItem(
    CultureItem item, {
    required String senderName,
    required String senderColor,
  }) {
    return BeamCard(
      senderName: senderName,
      senderColor: senderColor,
      category: item.category,
      title: item.title,
      subtitle: item.subtitle,
      thumbUrl: item.thumbUrl,
      externalId: item.externalId,
      url: item.url,
      oshiLevel: item.oshiLevel,
      moodTags: (jsonDecode(item.moodTags) as List).cast<String>(),
      moodColor: item.moodColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'v': version,
    'kind': 'culture_card',
    'sender': {'name': senderName, 'color': senderColor},
    'card': {
      'category': category.name,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (thumbUrl != null) 'thumbUrl': thumbUrl,
      if (externalId != null) 'externalId': externalId,
      if (url != null) 'url': url,
      'oshiLevel': oshiLevel,
      'moodTags': moodTags,
      if (moodColor != null) 'moodColor': moodColor,
    },
  };

  static BeamCard? tryParse(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['kind'] != 'culture_card') return null;
      final card = json['card'] as Map<String, dynamic>;
      final sender = json['sender'] as Map<String, dynamic>? ?? const {};
      return BeamCard(
        version: json['v'] as int? ?? 1,
        senderName: sender['name'] as String? ?? '???',
        senderColor: sender['color'] as String? ?? '#FF6B9D',
        category: CultureCategory.values.byName(card['category'] as String),
        title: card['title'] as String,
        subtitle: card['subtitle'] as String?,
        thumbUrl: card['thumbUrl'] as String?,
        externalId: card['externalId'] as String?,
        url: card['url'] as String?,
        oshiLevel: card['oshiLevel'] as int? ?? 3,
        moodTags: (card['moodTags'] as List? ?? const []).cast<String>(),
        moodColor: card['moodColor'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());
}
