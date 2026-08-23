import 'dart:convert';
import 'dart:typed_data';

import 'package:culture_tune/core/stickers/sticker_share.dart';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// 1x1透明PNG
final _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StickerShare', () {
    test('メタデータの埋め込み→抽出がラウンドトリップする', () {
      final meta = {
        'v': 1,
        'kind': 'culturetune_sticker',
        'creatorName': 'たくみ',
        'creatorColor': '#FF6B9D',
        'texture': 'holo',
        'link': {'category': 'music', 'title': '神曲'},
      };
      final embedded = StickerShare.embed(Uint8List.fromList(_tinyPng), meta);
      final extracted = StickerShare.extract(embedded);
      expect(extracted, isNotNull);
      expect(extracted!['creatorName'], 'たくみ');
      expect(extracted['texture'], 'holo');
      expect((extracted['link'] as Map)['title'], '神曲');
    });

    test('埋め込み後もPNGとしてデコードできる(CRC/チャンク構造が正しい)', () async {
      final embedded = StickerShare.embed(Uint8List.fromList(_tinyPng), {
        'v': 1,
        'kind': 'culturetune_sticker',
        'creatorName': 'test',
      });
      final codec = await ui.instantiateImageCodec(embedded);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1);
      expect(frame.image.height, 1);
    });

    test('2回埋め込んでもチャンクは1つに保たれる', () {
      var png = Uint8List.fromList(_tinyPng);
      png = StickerShare.embed(png, {'creatorName': 'A'});
      png = StickerShare.embed(png, {'creatorName': 'B'});
      expect(StickerShare.extract(png)!['creatorName'], 'B');
      // 旧チャンクが残っていないことをサイズで確認
      final single = StickerShare.embed(Uint8List.fromList(_tinyPng), {
        'creatorName': 'B',
      });
      expect(png.length, single.length);
    });

    test('PNG以外や無関係のPNGはnull', () {
      expect(StickerShare.extract(Uint8List.fromList([1, 2, 3])), isNull);
      expect(StickerShare.extract(Uint8List.fromList(_tinyPng)), isNull);
    });
  });
}
