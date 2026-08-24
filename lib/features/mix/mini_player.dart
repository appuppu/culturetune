import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme/tokens.dart';
import '../settings/theme_provider.dart';
import 'mix_controller.dart';

/// 画面下部に常駐するキャンディ型ミニプレイヤー。
/// 曲が終わると自動で次のカードへ(推しMIX連続再生)。
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _sub;
  String? _loadedVideoId;
  int _consecutiveErrors = 0;
  bool _playing = true;

  @override
  void dispose() {
    _sub?.cancel();
    _controller?.close();
    super.dispose();
  }

  void _sync(MixState mix) {
    final track = mix.current;
    if (track == null) {
      _sub?.cancel();
      _sub = null;
      _controller?.close();
      _controller = null;
      _loadedVideoId = null;
      return;
    }
    if (_controller == null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: track.videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: false,
          strictRelatedVideos: true,
        ),
      );
      _loadedVideoId = track.videoId;
      _sub = _controller!.stream.listen((value) {
        if (value.playerState == PlayerState.playing) _consecutiveErrors = 0;
        final playing = value.playerState == PlayerState.playing;
        if (playing != _playing && mounted) {
          setState(() => _playing = playing);
        }
        if (value.playerState == PlayerState.ended) {
          ref.read(mixControllerProvider.notifier).next();
        } else if (value.hasError) {
          // 再生できない動画は自動スキップ。全滅したらループせず停止する
          _consecutiveErrors++;
          final notifier = ref.read(mixControllerProvider.notifier);
          if (_consecutiveErrors >=
              ref.read(mixControllerProvider).queue.length) {
            notifier.stop();
          } else {
            notifier.next();
          }
        }
      });
    } else if (_loadedVideoId != track.videoId) {
      _loadedVideoId = track.videoId;
      _controller!.loadVideoById(videoId: track.videoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // テーマ変更に追従させる(constの親からは再ビルドされないため)
    ref.watch(themeProvider);
    final mix = ref.watch(mixControllerProvider);
    _sync(mix);

    final track = mix.current;
    if (track == null || _controller == null) {
      return const SizedBox.shrink();
    }

    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[mini_player] size=${context.size}');
      });
    }

    // YouTubeのデベロッパーポリシー準拠:
    // 埋め込みプレイヤーは200x200px以上で、動画を隠さず表示する。
    // 見た目はYouTube Music風(ダーク基調・白アイコン)。
    const ytDark = Color(0xFF0F0F0F);
    const ytGrey = Color(0xFFAAAAAA);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: ytDark,
        borderRadius: BorderRadius.circular(CTRadius.card),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WebView(プラットフォームビュー)はFlutterの角丸クリップが
          // 効かないため、カードの内側に余白を取って収める
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = math.max(200.0, w * 9 / 16);
                return SizedBox(
                  width: w,
                  height: h,
                  child: YoutubePlayer(
                    controller: _controller!,
                    aspectRatio: 16 / 9,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        [
                          if (track.subtitle != null &&
                              track.subtitle!.isNotEmpty)
                            track.subtitle!,
                          '${mix.index + 1}/${mix.queue.length}',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: ytGrey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 34,
                  icon: Icon(
                    _playing
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                  ),
                  color: Colors.white,
                  onPressed: () => _playing
                      ? _controller?.pauseVideo()
                      : _controller?.playVideo(),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 28,
                  icon: const Icon(Icons.skip_next_rounded),
                  color: Colors.white,
                  onPressed: () =>
                      ref.read(mixControllerProvider.notifier).next(),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded),
                  color: ytGrey,
                  onPressed: () =>
                      ref.read(mixControllerProvider.notifier).stop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
