import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// シールのボイス再生用プレイヤー(アプリ全体で1つ)
final voicePlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// ボイスを再生する(再生中のものは止めて差し替え)
Future<void> playVoice(WidgetRef ref, String absolutePath) async {
  HapticFeedback.lightImpact();
  final player = ref.read(voicePlayerProvider);
  await player.stop();
  await player.play(DeviceFileSource(absolutePath));
}

/// ネット上の音声(30秒プレビュー等)を再生する
Future<void> playPreviewUrl(WidgetRef ref, String url) async {
  HapticFeedback.lightImpact();
  final player = ref.read(voicePlayerProvider);
  await player.stop();
  await player.play(UrlSource(url));
}

Future<void> stopVoice(WidgetRef ref) async {
  await ref.read(voicePlayerProvider).stop();
}
