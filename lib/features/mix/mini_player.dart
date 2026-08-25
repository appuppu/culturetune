import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    const ytGrey = Color(0xFFAAAAAA);
    return Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: BoxDecoration(
            color: ytDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 14,
                offset: Offset(0, 5),
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
                    // WKWebViewはFlutterのクリップを無視するため、
                    // 四隅にカード色の角マスクを上描きして角丸に見せる
                    return SizedBox(
                      width: w,
                      height: h,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          YoutubePlayer(
                            controller: _controller!,
                            aspectRatio: 16 / 9,
                          ),
                          const IgnorePointer(
                            child: CustomPaint(
                              painter: _CornerMaskPainter(
                                color: ytDark,
                                radius: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                child: Row(
                  children: [
                    _playing
                        ? const _EqualizerBars()
                        : Icon(
                            Icons.music_note_rounded,
                            size: 16,
                            color: CTColors.primary,
                          ),
                    const SizedBox(width: 8),
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
        )
        .animate()
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.25, duration: 420.ms, curve: Curves.easeOutBack);
  }
}

const ytDark = Color(0xFF0F0F0F);

/// プラットフォームビュー(WebView)の四隅を背景色で塗って角丸に見せる
class _CornerMaskPainter extends CustomPainter {
  const _CornerMaskPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_CornerMaskPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}

/// 再生中のイコライザー(3本のバーがぴょこぴょこ動く)
class _EqualizerBars extends StatelessWidget {
  const _EqualizerBars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, h) in const [10.0, 16.0, 7.0].indexed)
            Container(
                  width: 4,
                  height: h,
                  decoration: BoxDecoration(
                    color: CTColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleY(
                  begin: 1,
                  end: 0.35,
                  alignment: Alignment.bottomCenter,
                  duration: (280 + i * 110).ms,
                  curve: Curves.easeInOut,
                ),
        ],
      ),
    );
  }
}
