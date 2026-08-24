// ignore_for_file: avoid_print
import 'package:culture_tune/core/models/beam_card.dart';
import 'package:culture_tune/core/models/culture_category.dart';
import 'package:culture_tune/features/distribution/card_link.dart';

void main() {
  const card = BeamCard(
    senderName: 'たくみ',
    senderColor: '#FF6B9D',
    category: CultureCategory.music,
    title: 'テスト配布カード',
    thumbUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    externalId: 'dQw4w9WgXcQ',
    url: 'https://youtu.be/dQw4w9WgXcQ',
    oshiLevel: 3,
    moodTags: ['神'],
  );
  print(CardLink.build(card));
}
