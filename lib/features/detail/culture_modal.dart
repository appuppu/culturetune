import 'dart:convert';

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/models/culture_category.dart';
import '../../core/models/culture_detail.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/thumb_image.dart';
import '../../core/api/music_preview.dart';
import '../../core/stickers/voice_player.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/beam_card.dart';
import '../beam/beam_profile_provider.dart';
import '../distribution/card_link.dart';
import '../map/photo_pin.dart';
import '../mix/mix_controller.dart';
import 'story_card.dart';

/// カードをタップしたときの入口。画面遷移せず、その場で完結させる:
/// - 音楽(YouTube): ミニプレイヤーで即再生(モーダルすら出さない)
/// - 動画: モーダル内でインライン再生
/// - ご飯: モーダル内マップ(iOS) / 店舗情報+外部マップ(Android)
/// - 本・その他: モーダルで情報表示
Future<void> openCultureItem(
  BuildContext context,
  WidgetRef ref,
  CultureItem item,
) async {
  final videoId = _videoIdOf(item);

  // 音楽・動画はタップ=再生。下からYouTube Music風プレイヤーが出る
  if ((item.category == CultureCategory.music ||
          item.category == CultureCategory.video) &&
      videoId != null) {
    HapticFeedback.lightImpact();
    ref.read(mixControllerProvider.notifier).playSingle(item);
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CTColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    // 下スワイプで閉じられ、中身が多いときはシート内でスクロール
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: _CultureSheet(item: item),
      ),
    ),
  );
}

String? _videoIdOf(CultureItem item) {
  final detail = CultureDetail.fromJson(
    item.category,
    jsonDecode(item.detailJson) as Map<String, dynamic>,
  );
  return detail is MediaDetail ? detail.videoId : null;
}

class _CultureSheet extends ConsumerStatefulWidget {
  const _CultureSheet({required this.item});

  final CultureItem item;

  @override
  ConsumerState<_CultureSheet> createState() => _CultureSheetState();
}

class _CultureSheetState extends ConsumerState<_CultureSheet> {
  YoutubePlayerController? _yt;
  bool _ytFailed = false;
  late bool _pinned = widget.item.pinnedOrder != null;

  CultureItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    final videoId = _videoIdOf(item);
    if (videoId != null &&
        (item.category == CultureCategory.video ||
            item.category == CultureCategory.music)) {
      _yt = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
      _yt!.stream.listen((value) {
        if (value.hasError && mounted) setState(() => _ytFailed = true);
      });
    }
  }

  @override
  void dispose() {
    _yt?.close();
    super.dispose();
  }

  Color get _moodColor {
    final hex = item.moodColor;
    if (hex == null || !hex.startsWith('#')) return item.category.color;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? item.category.color : Color(0xFF000000 | value);
  }

  /// 配布: リンクコピー / リンク共有 / ストーリー画像
  Future<void> _showDistributeSheet() async {
    final profile = await ref.read(beamProfileProvider.future);
    final link = CardLink.build(
      BeamCard.fromItem(
        item,
        senderName: profile.name,
        senderColor: profile.colorHex,
      ),
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: CTColors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CTRadius.sheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'このカードを配布する',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'インスタのストーリーに貼るなら: ストーリー画像を書き出して投稿し、'
                'リンクスタンプにコピーしたURLを設定してね',
                style: TextStyle(fontSize: 11, color: CTColors.textSub),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: const Text('配布リンクをコピー'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('リンクをコピーしたよ')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_rounded),
              title: const Text('リンクを共有'),
              onTap: () {
                Navigator.pop(sheetContext);
                Share.share('「${item.title}」のカードをあげる!\n$link');
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: const Text('ストーリー画像を書き出す(1080x1920)'),
              onTap: () {
                Navigator.pop(sheetContext);
                showStoryShareSheet(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('このカードを削除する?'),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('やめとく'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(itemRepositoryProvider).deleteItem(item);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tags = (jsonDecode(item.moodTags) as List).cast<String>();
    final color = _moodColor;

    // モーダルが伸びる問題の調査ログ(デバッグビルドのみ)
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final size = context.size;
        debugPrint(
          '[culture_modal] category=${item.category.name} '
          'sheetSize=$size yt=${_yt != null} url=${item.url}',
        );
      });
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: CTColors.textSub.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(CTRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ヘッダー: タイトル + アクション
            Row(
              children: [
                Icon(item.category.icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await ref.read(itemRepositoryProvider).togglePinned(item);
                    if (mounted) setState(() => _pinned = !_pinned);
                  },
                  icon: Icon(
                    _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 20,
                    color: _pinned ? CTColors.primary : CTColors.textSub,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _showDistributeSheet,
                  icon: Icon(
                    Icons.ios_share_rounded,
                    size: 20,
                    color: CTColors.textSub,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _delete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: CTColors.textSub,
                  ),
                ),
              ],
            ),
            if (item.subtitle != null)
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  item.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: CTColors.textSub, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            // 本体(カテゴリ別)
            _body(color),
            if (tags.isNotEmpty || item.memo != null) ...[
              const SizedBox(height: 12),
              if (tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(CTRadius.pill),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              if (item.memo != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.memo!,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(Color color) {
    // 動画/音楽: インライン再生
    if (_yt != null) {
      if (_ytFailed) {
        return _openExternallyTile(
          'この動画はアプリ内で再生できないみたい',
          'YouTubeで開く',
          item.url ?? 'https://www.youtube.com/watch?v=${_videoIdOf(item)}',
        );
      }
      // AspectRatioで高さを固定しないと、シートが画面全体まで伸びてしまう
      return ClipRRect(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        borderRadius: BorderRadius.circular(CTRadius.card),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(controller: _yt!, aspectRatio: 16 / 9),
        ),
      );
    }

    // ご飯: マップ(iOS) / 店舗情報(Android)
    if (item.category == CultureCategory.food) {
      return _foodBody(color);
    }

    // Spotify: 公式埋め込みプレイヤーで30秒プレビュー
    final spotifyEmbed = item.url != null
        ? MusicPreview.spotifyEmbedUrl(item.url!)
        : null;
    if (spotifyEmbed != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SpotifyEmbed(embedUrl: spotifyEmbed),
          const SizedBox(height: 8),
          _openButton(),
        ],
      );
    }

    // Apple Music: iTunes Lookupで30秒プレビューを取得して再生
    final isAppleMusic =
        item.url != null && MusicPreview.appleMusicId(item.url!) != null;
    if (isAppleMusic) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(CTRadius.card),
            child: SizedBox(height: 200, child: ThumbImage(item: item)),
          ),
          const SizedBox(height: 10),
          _ApplePreviewButton(url: item.url!),
          const SizedBox(height: 6),
          _openButton(),
        ],
      );
    }

    // 本・その他: サムネ + 外部リンク
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(CTRadius.card),
          child: SizedBox(height: 200, child: ThumbImage(item: item)),
        ),
        if (item.url != null) ...[const SizedBox(height: 10), _openButton()],
      ],
    );
  }

  Widget _openButton() {
    return OutlinedButton.icon(
      onPressed: () =>
          launchUrl(Uri.parse(item.url!), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.open_in_new_rounded, size: 16),
      label: const Text('アプリで開く'),
    );
  }

  Widget _foodBody(Color color) {
    final hasLocation = item.lat != null && item.lng != null;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    if (hasLocation && isIOS) {
      return ClipRRect(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        borderRadius: BorderRadius.circular(CTRadius.card),
        child: SizedBox(
          height: 240,
          child: FutureBuilder(
            future: buildPhotoPinBytes(
              item,
              color,
              ref.read(itemRepositoryProvider),
            ),
            builder: (context, snapshot) => AppleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(item.lat!, item.lng!),
                zoom: 15,
              ),
              annotations: {
                Annotation(
                  annotationId: AnnotationId(item.id),
                  position: LatLng(item.lat!, item.lng!),
                  anchor: const Offset(0.5, 1),
                  icon: snapshot.hasData
                      ? BitmapDescriptor.fromBytes(snapshot.data!)
                      : BitmapDescriptor.defaultAnnotation,
                ),
              },
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(CTRadius.card),
          child: SizedBox(height: 180, child: ThumbImage(item: item)),
        ),
        if (item.placeName != null || hasLocation) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              final uri = hasLocation
                  ? Uri.parse(
                      'geo:${item.lat},${item.lng}?q=${item.lat},${item.lng}'
                      '(${Uri.encodeComponent(item.placeName ?? item.title)})',
                    )
                  : Uri.parse(
                      'geo:0,0?q=${Uri.encodeComponent(item.placeName!)}',
                    );
              launchUrl(uri);
            },
            icon: const Icon(Icons.map_rounded, size: 16),
            label: Text(item.placeName ?? 'マップで開く'),
          ),
        ],
      ],
    );
  }

  Widget _openExternallyTile(String message, String label, String url) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CTColors.surface,
        borderRadius: BorderRadius.circular(CTRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: CTColors.textSub),
            ),
          ),
          FilledButton(
            onPressed: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

/// Spotify公式の埋め込みプレイヤー(30秒プレビュー・キー不要)
class _SpotifyEmbed extends StatefulWidget {
  const _SpotifyEmbed({required this.embedUrl});

  final String embedUrl;

  @override
  State<_SpotifyEmbed> createState() => _SpotifyEmbedState();
}

class _SpotifyEmbedState extends State<_SpotifyEmbed> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.transparent)
    ..loadRequest(Uri.parse(widget.embedUrl));

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      borderRadius: BorderRadius.circular(CTRadius.card),
      child: SizedBox(
        height: 152,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}

/// Apple Musicの30秒プレビュー再生ボタン
class _ApplePreviewButton extends ConsumerStatefulWidget {
  const _ApplePreviewButton({required this.url});

  final String url;

  @override
  ConsumerState<_ApplePreviewButton> createState() =>
      _ApplePreviewButtonState();
}

class _ApplePreviewButtonState extends ConsumerState<_ApplePreviewButton> {
  String? _previewUrl;
  bool _loading = true;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    MusicPreview.appleMusicPreviewUrl(widget.url).then((url) {
      if (mounted) {
        setState(() {
          _previewUrl = url;
          _loading = false;
        });
      }
    });
    ref.read(voicePlayerProvider).onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_previewUrl == null) return const SizedBox.shrink();
    return FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: CTColors.primary),
      onPressed: () async {
        if (_playing) {
          await stopVoice(ref);
          if (mounted) setState(() => _playing = false);
        } else {
          await playPreviewUrl(ref, _previewUrl!);
          if (mounted) setState(() => _playing = true);
        }
      },
      icon: Icon(
        _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
        size: 20,
      ),
      label: Text(_playing ? '停止' : '30秒プレビューを聞く'),
    );
  }
}
