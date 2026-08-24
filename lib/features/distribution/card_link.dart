import 'dart:convert';

import '../../core/models/beam_card.dart';

/// カードのリンク配布。
/// カードのデータはURLのフラグメント(#以降)にbase64urlで埋め込む。
/// フラグメントはサーバーに送信されないため、静的ページ側には何も残らない。
abstract final class CardLink {
  /// GitHub Pages等に配置する受け取りページのURL。
  /// web_distribution/README.md の手順で公開したURLに書き換える。
  static const distributionPageUrl = 'https://appuppu.github.io/card/';

  /// アプリ直接起動用のカスタムスキーム(インストール済み端末用)
  static const scheme = 'culturetune';

  /// カード → 配布リンク
  static String build(BeamCard card) {
    final payload = base64UrlEncode(utf8.encode(card.encode()));
    return '$distributionPageUrl#$payload';
  }

  /// 受信したURL(https配布リンク or culturetune://card#...)→ カード。
  /// 対象外・壊れたリンクはnull
  static BeamCard? parse(Uri uri) {
    final isCustomScheme = uri.scheme == scheme;
    final isDistributionPage = uri.toString().startsWith(
      distributionPageUrl.split('#').first,
    );
    if (!isCustomScheme && !isDistributionPage) return null;

    final fragment = uri.fragment;
    if (fragment.isEmpty) return null;
    try {
      final json = utf8.decode(base64Url.decode(base64.normalize(fragment)));
      return BeamCard.tryParse(json);
    } catch (_) {
      return null;
    }
  }
}
