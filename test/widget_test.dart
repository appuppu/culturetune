import 'package:culture_tune/core/api/book_repository.dart';
import 'package:culture_tune/core/api/link_preview_service.dart';
import 'package:culture_tune/core/models/beam_card.dart';
import 'package:culture_tune/core/models/culture_category.dart';
import 'package:culture_tune/core/models/culture_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BeamCard', () {
    test('JSON往復でデータが保たれる', () {
      const card = BeamCard(
        senderName: 'たくみ',
        senderColor: '#FF6B9D',
        category: CultureCategory.music,
        title: 'テスト曲',
        subtitle: 'テストチャンネル',
        thumbUrl: 'https://i.ytimg.com/vi/abc12345678/maxresdefault.jpg',
        externalId: 'abc12345678',
        url: 'https://youtu.be/abc12345678',
        oshiLevel: 5,
        moodTags: ['神', 'リピ確'],
        moodColor: '#FF6B9D',
      );

      final decoded = BeamCard.tryParse(card.encode());
      expect(decoded, isNotNull);
      expect(decoded!.title, 'テスト曲');
      expect(decoded.category, CultureCategory.music);
      expect(decoded.senderName, 'たくみ');
      expect(decoded.oshiLevel, 5);
      expect(decoded.moodTags, ['神', 'リピ確']);
      expect(decoded.moodColor, '#FF6B9D');
    });

    test('不正なJSONはnull', () {
      expect(BeamCard.tryParse('not json'), isNull);
      expect(BeamCard.tryParse('{"kind":"other"}'), isNull);
    });
  });

  group('CultureDetail', () {
    test('カテゴリ別にJSON往復できる', () {
      final book =
          CultureDetail.fromJson(
                CultureCategory.book,
                const BookDetail(
                  isbn: '9784000000000',
                  author: '著者A',
                  publisher: 'テスト社',
                ).toJson(),
              )
              as BookDetail;
      expect(book.author, '著者A');
      expect(book.publisher, 'テスト社');

      final food =
          CultureDetail.fromJson(
                CultureCategory.food,
                const FoodDetail(
                  storeName: 'テスト店',
                  menuName: '推しパフェ',
                  priceYen: 480,
                ).toJson(),
              )
              as FoodDetail;
      expect(food.menuName, '推しパフェ');
    });
  });

  group('ISBN正規化', () {
    test('ハイフン付きISBN-13を受け付ける', () {
      expect(
        BookRepository.normalizeIsbn('978-4-06-519981-0'),
        '9784065199810',
      );
    });
    test('桁数不正はnull', () {
      expect(BookRepository.normalizeIsbn('12345'), isNull);
    });
  });

  group('YouTube videoId抽出', () {
    const id = 'dQw4w9WgXcQ';
    test('各URL形式に対応', () {
      final urls = [
        'https://www.youtube.com/watch?v=$id',
        'https://youtu.be/$id?si=xyz',
        'https://www.youtube.com/shorts/$id',
        'https://music.youtube.com/watch?v=$id',
        'https://www.youtube.com/live/$id',
        'https://www.youtube.com/embed/$id',
      ];
      for (final url in urls) {
        expect(LinkPreviewService.extractYouTubeVideoId(url), id, reason: url);
      }
    });
    test('YouTube以外はnull', () {
      expect(
        LinkPreviewService.extractYouTubeVideoId('https://example.com/watch'),
        isNull,
      );
    });
  });
}
