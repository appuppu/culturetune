import '../models/culture_category.dart';
import '../models/culture_detail.dart';

/// 登録フロー中に持ち回る下書き。各動線で作られ、共通仕上げ画面で確定する。
class PostDraft {
  PostDraft({
    required this.category,
    required this.title,
    this.subtitle,
    this.thumbUrl,
    this.localImagePath,
    this.externalId,
    this.url,
    this.detail,
    this.lat,
    this.lng,
    this.placeName,
  });

  final CultureCategory category;
  final String title;
  final String? subtitle;
  final String? thumbUrl;

  /// Food写真などデバイス内の画像(保存時にアプリ領域へコピーされる)
  final String? localImagePath;
  final String? externalId;
  final String? url;
  final CultureDetail? detail;
  final double? lat;
  final double? lng;
  final String? placeName;
}
