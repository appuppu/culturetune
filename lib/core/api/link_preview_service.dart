import 'dart:convert';

import 'package:http/http.dart' as http;

class LinkPreview {
  const LinkPreview({
    required this.url,
    required this.title,
    this.thumbnailUrl,
    this.channel,
    this.siteName,
    this.youtubeVideoId,
  });

  final String url;
  final String title;
  final String? thumbnailUrl;
  final String? channel; // 投稿者・チャンネル名
  final String? siteName;
  final String? youtubeVideoId;

  bool get isYouTube => youtubeVideoId != null;
}

/// URL → リンクプレビュー。
/// YouTubeは公式oEmbed(キー不要)、それ以外はOGPメタタグをパースする。
class LinkPreviewService {
  LinkPreviewService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<LinkPreview?> fetch(String rawUrl) async {
    final url = rawUrl.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return null;

    final videoId = extractYouTubeVideoId(url);
    if (videoId != null) {
      final fromOembed = await _fetchYouTubeOembed(url, videoId);
      if (fromOembed != null) return fromOembed;
    }
    // Spotifyは公式oEmbed(キー不要)が確実。他サブスク(Apple Music等)はOGPで取れる
    if (uri.host.endsWith('open.spotify.com')) {
      final fromSpotify = await _fetchSpotifyOembed(url);
      if (fromSpotify != null) return fromSpotify;
    }
    return _fetchOgp(url, videoId: videoId);
  }

  /// Spotify oEmbed (キー不要)
  Future<LinkPreview?> _fetchSpotifyOembed(String url) async {
    try {
      final uri = Uri.https('open.spotify.com', '/oembed', {'url': url});
      final res = await _client.get(uri);
      if (res.statusCode != 200) return null;
      final json =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final title = json['title'] as String?;
      if (title == null) return null;
      return LinkPreview(
        url: url,
        title: title,
        thumbnailUrl: json['thumbnail_url'] as String?,
        siteName: 'Spotify',
      );
    } catch (_) {
      return null;
    }
  }

  /// YouTube oEmbed (キー不要)
  Future<LinkPreview?> _fetchYouTubeOembed(String url, String videoId) async {
    final uri = Uri.https('www.youtube.com', '/oembed', {
      'url': url,
      'format': 'json',
    });
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;

    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final title = json['title'] as String?;
    if (title == null) return null;

    return LinkPreview(
      url: url,
      title: title,
      // oEmbedのhqdefaultより高画質を優先し、詳細画面で映えるようにする
      thumbnailUrl: 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg',
      channel: json['author_name'] as String?,
      siteName: 'YouTube',
      youtubeVideoId: videoId,
    );
  }

  /// OGPメタタグの軽量パース(HTML全体のDOM構築はしない)
  Future<LinkPreview?> _fetchOgp(String url, {String? videoId}) async {
    final http.Response res;
    try {
      res = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': 'CultureTune/1.0 (+ogp-preview)'},
      );
    } catch (_) {
      return null;
    }
    if (res.statusCode != 200) return null;

    final html = utf8.decode(res.bodyBytes, allowMalformed: true);
    final title = _metaContent(html, 'og:title') ?? _htmlTitle(html);
    if (title == null) return null;

    return LinkPreview(
      url: url,
      title: title,
      thumbnailUrl: _metaContent(html, 'og:image'),
      siteName: _metaContent(html, 'og:site_name'),
      youtubeVideoId: videoId,
    );
  }

  static String? _metaContent(String html, String property) {
    // property/content の順不同どちらにも対応
    final patterns = [
      RegExp(
        '<meta[^>]+(?:property|name)=["\']$property["\'][^>]+content=["\']([^"\']*)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]+content=["\']([^"\']*)["\'][^>]+(?:property|name)=["\']$property["\']',
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(html);
      final content = m?.group(1);
      if (content != null && content.isNotEmpty) return _unescape(content);
    }
    return null;
  }

  static String? _htmlTitle(String html) {
    final m = RegExp(
      '<title[^>]*>([^<]*)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    final t = m?.group(1)?.trim();
    return (t == null || t.isEmpty) ? null : _unescape(t);
  }

  static String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'");

  /// watch / youtu.be / shorts / live / embed / music の各URL形式からvideoIdを抽出
  static String? extractYouTubeVideoId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;

    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    const ytHosts = {'youtube.com', 'm.youtube.com', 'music.youtube.com'};

    String? id;
    if (host == 'youtu.be') {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (ytHosts.contains(host)) {
      final segs = uri.pathSegments;
      if (uri.path == '/watch') {
        id = uri.queryParameters['v'];
      } else if (segs.length >= 2 &&
          const {'shorts', 'live', 'embed'}.contains(segs.first)) {
        id = segs[1];
      }
    }
    if (id == null) return null;
    return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ? id : null;
  }
}
