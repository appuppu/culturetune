import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/models/culture_category.dart';

class MixTrack {
  const MixTrack({
    required this.videoId,
    required this.title,
    this.subtitle,
    this.thumbUrl,
  });

  final String videoId;
  final String title;
  final String? subtitle;
  final String? thumbUrl;
}

class MixState {
  const MixState({this.queue = const [], this.index = 0});

  final List<MixTrack> queue;
  final int index;

  bool get active => queue.isNotEmpty;
  MixTrack? get current => active ? queue[index] : null;

  MixState copyWith({List<MixTrack>? queue, int? index}) =>
      MixState(queue: queue ?? this.queue, index: index ?? this.index);
}

class MixController extends StateNotifier<MixState> {
  MixController() : super(const MixState());

  /// ランダムシャッフルで開始
  void startTodayMix(List<CultureItem> items) {
    final random = Random();
    final tracks =
        items
            .where(_isPlayable)
            .map(
              (i) => (
                score: random.nextDouble(),
                track: MixTrack(
                  videoId: i.externalId!,
                  title: i.title,
                  subtitle: i.subtitle,
                  thumbUrl: i.thumbUrl,
                ),
              ),
            )
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    state = MixState(queue: [for (final t in tracks) t.track]);
  }

  static bool _isPlayable(CultureItem i) =>
      (i.category == CultureCategory.music ||
          i.category == CultureCategory.video) &&
      i.externalId != null &&
      i.externalId!.length == 11;

  /// 1曲だけ即再生(カードタップ用)
  void playSingle(CultureItem item) {
    if (!_isPlayable(item)) return;
    state = MixState(
      queue: [
        MixTrack(
          videoId: item.externalId!,
          title: item.title,
          subtitle: item.subtitle,
          thumbUrl: item.thumbUrl,
        ),
      ],
    );
  }

  void next() {
    if (!state.active) return;
    // 最後まで行ったら先頭へループ
    state = state.copyWith(index: (state.index + 1) % state.queue.length);
  }

  void prev() {
    if (!state.active) return;
    state = state.copyWith(
      index: (state.index - 1 + state.queue.length) % state.queue.length,
    );
  }

  void stop() => state = const MixState();
}

final mixControllerProvider = StateNotifierProvider<MixController, MixState>(
  (ref) => MixController(),
);

/// MIX対象(YouTubeのvideoIdを持つMusic/Videoカード)があるか
final mixCandidatesProvider = StreamProvider.autoDispose((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchItems().map(
    (items) => items.where(MixController._isPlayable).toList(),
  );
});
