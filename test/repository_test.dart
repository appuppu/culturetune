import 'dart:convert';
import 'dart:io';

import 'package:culture_tune/core/data/item_repository.dart';
import 'package:culture_tune/core/data/post_draft.dart';
import 'package:culture_tune/core/db/app_database.dart';
import 'package:culture_tune/core/models/beam_card.dart';
import 'package:culture_tune/core/models/culture_category.dart';
import 'package:culture_tune/core/models/culture_detail.dart';
import 'package:culture_tune/features/mix/mix_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ItemRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = Directory.systemTemp.createTempSync('ct_test');
    // サムネDLは常に404にしてネットワーク非依存にする
    repo = ItemRepository(
      db,
      tempDir,
      client: MockClient((_) async => http.Response('', 404)),
    );
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  group('ItemRepository', () {
    test('saveDraftで全フィールドが保存される', () async {
      final id = await repo.saveDraft(
        PostDraft(
          category: CultureCategory.book,
          title: 'テスト本',
          subtitle: '著者A',
          externalId: 'isbn:9784000000000',
          detail: const BookDetail(
            isbn: '9784000000000',
            author: '著者A',
            publisher: 'テスト社',
          ),
        ),
        oshiLevel: 5,
        moodTags: ['神', '沼'],
        moodColor: '#FF6B9D',
        memo: ' 最高だった ',
      );

      final item = await db.findItem(id);
      expect(item, isNotNull);
      expect(item!.category, CultureCategory.book);
      expect(item.title, 'テスト本');
      expect(item.oshiLevel, 5);
      expect(jsonDecode(item.moodTags), ['神', '沼']);
      expect(item.moodColor, '#FF6B9D');
      expect(item.memo, '最高だった'); // trimされる
      expect(item.source, CardSource.self);
      final detail = CultureDetail.fromJson(
        item.category,
        jsonDecode(item.detailJson) as Map<String, dynamic>,
      );
      expect((detail as BookDetail).publisher, 'テスト社');
    });

    test('ローカル画像がthumbsへコピーされる', () async {
      final src = File('${tempDir.path}/src.jpg')..writeAsBytesSync([1, 2, 3]);
      final id = await repo.saveDraft(
        PostDraft(
          category: CultureCategory.food,
          title: '推しパフェ',
          localImagePath: src.path,
        ),
        oshiLevel: 4,
        moodTags: [],
      );
      final item = await db.findItem(id);
      expect(item!.thumbPath, 'thumbs/$id.jpg');
      expect(File(repo.resolveThumb(item.thumbPath!)).existsSync(), isTrue);
    });

    test('saveBeamCardはsource=beamで保存し履歴も記録する', () async {
      const card = BeamCard(
        senderName: 'みお',
        senderColor: '#4EECD2',
        category: CultureCategory.music,
        title: 'もらった曲',
        externalId: 'abc12345678',
        oshiLevel: 5,
        moodTags: ['尊い'],
      );
      final id = await repo.saveBeamCard(card);

      final item = await db.findItem(id);
      expect(item!.source, CardSource.beam);
      expect(item.beamFrom, 'みお');

      final beams = await db.watchBeams().first;
      expect(beams, hasLength(1));
      expect(beams.single.direction, BeamDirection.received);
      expect(beams.single.peerName, 'みお');
      expect(beams.single.cardId, id);
    });

    test('deleteItemで行とサムネが消える', () async {
      final src = File('${tempDir.path}/src2.png')..writeAsBytesSync([9, 9]);
      final id = await repo.saveDraft(
        PostDraft(
          category: CultureCategory.food,
          title: '消すやつ',
          localImagePath: src.path,
        ),
        oshiLevel: 1,
        moodTags: [],
      );
      final item = (await db.findItem(id))!;
      final thumbFile = File(repo.resolveThumb(item.thumbPath!));
      expect(thumbFile.existsSync(), isTrue);

      await repo.deleteItem(item);
      expect(await db.findItem(id), isNull);
      expect(thumbFile.existsSync(), isFalse);
    });

    test('toggleFavoriteが反転する', () async {
      final id = await repo.saveDraft(
        PostDraft(category: CultureCategory.book, title: 'フェイバリット'),
        oshiLevel: 3,
        moodTags: [],
      );
      await repo.toggleFavorite((await db.findItem(id))!);
      expect((await db.findItem(id))!.isFavorite, isTrue);
      await repo.toggleFavorite((await db.findItem(id))!);
      expect((await db.findItem(id))!.isFavorite, isFalse);
    });
  });

  group('MixController', () {
    test('videoIdを持つMusic/Videoだけがキューに入る', () async {
      await repo.saveDraft(
        PostDraft(
          category: CultureCategory.music,
          title: '曲',
          externalId: 'abcdefghijk',
        ),
        oshiLevel: 5,
        moodTags: [],
      );
      await repo.saveDraft(
        PostDraft(
          category: CultureCategory.video,
          title: '動画',
          externalId: 'lmnopqrstuv',
        ),
        oshiLevel: 2,
        moodTags: [],
      );
      // videoIdなし(OGPのみ)の音楽と、11桁videoIdを持たない本は対象外
      await repo.saveDraft(
        PostDraft(category: CultureCategory.music, title: '外部サイト曲'),
        oshiLevel: 5,
        moodTags: [],
      );
      await repo.saveDraft(
        PostDraft(
          category: CultureCategory.book,
          title: '本',
          externalId: 'isbn:9784000000000',
        ),
        oshiLevel: 5,
        moodTags: [],
      );

      final items = await db.watchItems().first;
      final controller = MixController()..startTodayMix(items);
      expect(controller.state.queue, hasLength(2));
      expect(controller.state.queue.map((t) => t.videoId).toSet(), {
        'abcdefghijk',
        'lmnopqrstuv',
      });
    });

    test('next/prevはループする', () {
      final controller = MixController();
      controller.state = const MixState(
        queue: [
          MixTrack(videoId: 'a2345678901', title: 'A'),
          MixTrack(videoId: 'b2345678901', title: 'B'),
        ],
      );
      controller.next();
      expect(controller.state.index, 1);
      controller.next();
      expect(controller.state.index, 0); // ループ
      controller.prev();
      expect(controller.state.index, 1);
    });
  });
}
