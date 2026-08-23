import 'package:culture_tune/core/models/beam_card.dart';
import 'package:culture_tune/core/models/culture_category.dart';
import 'package:culture_tune/features/distribution/card_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const card = BeamCard(
    senderName: 'たくみ',
    senderColor: '#FF6B9D',
    category: CultureCategory.music,
    title: '配布テスト曲',
    thumbUrl: 'https://i.ytimg.com/vi/abc12345678/maxresdefault.jpg',
    externalId: 'abc12345678',
    url: 'https://youtu.be/abc12345678',
    oshiLevel: 3,
    moodTags: ['神'],
  );

  group('CardLink', () {
    test('リンク生成→パースがラウンドトリップする', () {
      final link = CardLink.build(card);
      expect(link, startsWith(CardLink.distributionPageUrl));

      final parsed = CardLink.parse(Uri.parse(link));
      expect(parsed, isNotNull);
      expect(parsed!.title, '配布テスト曲');
      expect(parsed.senderName, 'たくみ');
      expect(parsed.category, CultureCategory.music);
      expect(parsed.externalId, 'abc12345678');
    });

    test('カスタムスキームでもパースできる', () {
      final fragment = Uri.parse(CardLink.build(card)).fragment;
      final parsed = CardLink.parse(Uri.parse('culturetune://card#$fragment'));
      expect(parsed?.title, '配布テスト曲');
    });

    test('無関係なURLや壊れたデータはnull', () {
      expect(CardLink.parse(Uri.parse('https://example.com/#abc')), isNull);
      expect(
        CardLink.parse(Uri.parse('${CardLink.distributionPageUrl}#%%%')),
        isNull,
      );
      expect(CardLink.parse(Uri.parse(CardLink.distributionPageUrl)), isNull);
    });
  });
}
