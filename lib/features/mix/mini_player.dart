import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme/tokens.dart';
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
    // 全幅16:9で出し、高さは最低200pxを保証する(足りない端末は上下黒帯)。
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: CTColors.surface,
        borderRadius: BorderRadius.circular(CTRadius.card),
        border: Border.all(color: CTColors.primary, width: 2),
        boxShadow: ctCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = math.max(200.0, w * 9 / 16);
              // WebViewはClipRRectが効かない環境があるため
              // saveLayerで確実にクロップする
              return ClipRRect(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(CTRadius.inner(CTRadius.card, 2)),
                ),
                child: SizedBox(
                  width: w,
                  height: h,
                  child: ColoredBox(
                    color: Colors.black,
                    child: YoutubePlayer(
                      controller: _controller!,
                      aspectRatio: 16 / 9,
                    ),
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.music_note_rounded, size: 14, color: CTColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${track.title}  ${track.subtitle ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${mix.index + 1}/${mix.queue.length}',
                style: TextStyle(fontSize: 10, color: CTColors.textSub),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.skip_next_rounded),
                color: CTColors.primary,
                onPressed: () =>
                    ref.read(mixControllerProvider.notifier).next(),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded),
                color: CTColors.textSub,
                onPressed: () =>
                    ref.read(mixControllerProvider.notifier).stop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
