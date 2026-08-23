// 外部APIの疎通確認用スクリプト: dart run tool/api_smoke_test.dart
// ignore_for_file: avoid_print
import 'package:culture_tune/core/api/book_repository.dart';
import 'package:culture_tune/core/api/link_preview_service.dart';

Future<void> main() async {
  final books = BookRepository();
  // 「君たちはどう生きるか」(マガジンハウス) のISBN
  final book = await books.fetchByIsbn('978-4-8387-2946-3');
  print(
    'openBD/GoogleBooks: title=${book?.title} author=${book?.author} '
    'publisher=${book?.publisher} cover=${book?.coverUrl}',
  );

  final preview = LinkPreviewService();
  final yt = await preview.fetch('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
  print(
    'YouTube oEmbed: title=${yt?.title} channel=${yt?.channel} '
    'videoId=${yt?.youtubeVideoId} thumb=${yt?.thumbnailUrl}',
  );

  final ogp = await preview.fetch('https://ja.wikipedia.org/wiki/映画');
  print(
    'OGP: title=${ogp?.title} site=${ogp?.siteName} image=${ogp?.thumbnailUrl}',
  );
}
