import 'culture_category.dart';

/// カテゴリ固有の詳細情報。DBでは culture_items.detail_json に格納する。
sealed class CultureDetail {
  const CultureDetail();

  Map<String, dynamic> toJson();

  static CultureDetail fromJson(
    CultureCategory category,
    Map<String, dynamic> json,
  ) {
    return switch (category) {
      CultureCategory.book => BookDetail.fromJson(json),
      CultureCategory.music ||
      CultureCategory.video => MediaDetail.fromJson(json),
      CultureCategory.food => FoodDetail.fromJson(json),
    };
  }
}

class BookDetail extends CultureDetail {
  const BookDetail({this.isbn, this.author, this.publisher});

  final String? isbn;
  final String? author;
  final String? publisher;

  factory BookDetail.fromJson(Map<String, dynamic> json) => BookDetail(
    isbn: json['isbn'] as String?,
    author: json['author'] as String?,
    publisher: json['publisher'] as String?,
  );

  @override
  Map<String, dynamic> toJson() => {
    if (isbn != null) 'isbn': isbn,
    if (author != null) 'author': author,
    if (publisher != null) 'publisher': publisher,
  };
}

/// Music / Video 共通(YouTube・その他URL)
class MediaDetail extends CultureDetail {
  const MediaDetail({
    this.videoId,
    this.channel,
    this.siteName,
    this.savedTimeOfDay,
  });

  final String? videoId; // YouTubeの場合のみ
  final String? channel;
  final String? siteName;
  final String? savedTimeOfDay; // morning | day | evening | night

  factory MediaDetail.fromJson(Map<String, dynamic> json) => MediaDetail(
    videoId: json['videoId'] as String?,
    channel: json['channel'] as String?,
    siteName: json['siteName'] as String?,
    savedTimeOfDay: json['savedTimeOfDay'] as String?,
  );

  @override
  Map<String, dynamic> toJson() => {
    if (videoId != null) 'videoId': videoId,
    if (channel != null) 'channel': channel,
    if (siteName != null) 'siteName': siteName,
    if (savedTimeOfDay != null) 'savedTimeOfDay': savedTimeOfDay,
  };
}

class FoodDetail extends CultureDetail {
  const FoodDetail({this.storeName, this.menuName, this.priceYen});

  final String? storeName;
  final String? menuName;
  final int? priceYen;

  factory FoodDetail.fromJson(Map<String, dynamic> json) => FoodDetail(
    storeName: json['storeName'] as String?,
    menuName: json['menuName'] as String?,
    priceYen: json['priceYen'] as int?,
  );

  @override
  Map<String, dynamic> toJson() => {
    if (storeName != null) 'storeName': storeName,
    if (menuName != null) 'menuName': menuName,
    if (priceYen != null) 'priceYen': priceYen,
  };
}
