import 'dart:convert';

import 'package:http/http.dart' as http;

/// 音楽サブスクの30秒プレビュー対応。
/// - Spotify: 公式埋め込みプレイヤー(キー不要)のURLを導出
/// - Apple Music: URLから曲IDを抽出し、iTunes Lookup API(キー不要)で
///   previewUrl(30秒m4a)を取得
abstract final class MusicPreview {
  /// open.spotify.com のURL → 埋め込みプレイヤーURL。対象外はnull
  static String? spotifyEmbedUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host != 'open.spotify.com') return null;

    // /intl-ja/track/xxx のような地域プレフィックスを除去
    final segs = uri.pathSegments.where((s) => !s.startsWith('intl-')).toList();
    if (segs.length < 2) return null;
    const types = {'track', 'album', 'playlist', 'episode', 'show', 'artist'};
    if (!types.contains(segs[0])) return null;
    final id = segs[1].split('?').first;
    if (id.isEmpty) return null;
    return 'https://open.spotify.com/embed/${segs[0]}/$id';
  }

  /// music.apple.com のURLから曲/アルバムIDを抽出。
  /// 曲: ...album/xxx/123?i=456 → 456 / ...song/xxx/789 → 789
  static String? appleMusicId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (!uri.host.toLowerCase().endsWith('music.apple.com')) return null;

    final trackId = uri.queryParameters['i'];
    if (trackId != null && int.tryParse(trackId) != null) return trackId;

    // パス末尾の数値ID(song/album)
    for (final seg in uri.pathSegments.reversed) {
      if (int.tryParse(seg) != null) return seg;
    }
    return null;
  }

  /// Apple MusicのURL → 30秒プレビューの音声URL(m4a)。取れなければnull
  static Future<String?> appleMusicPreviewUrl(
    String url, {
    http.Client? client,
  }) async {
    final id = appleMusicId(url);
    if (id == null) return null;
    final c = client ?? http.Client();
    try {
      final res = await c.get(
        Uri.https('itunes.apple.com', '/lookup', {'id': id, 'country': 'jp'}),
      );
      if (res.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      final results = (json as Map<String, dynamic>)['results'] as List?;
      if (results == null || results.isEmpty) return null;
      // アルバムIDだった場合は先頭トラックのプレビューにフォールバック
      for (final r in results) {
        final preview = (r as Map<String, dynamic>)['previewUrl'] as String?;
        if (preview != null) return preview;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
