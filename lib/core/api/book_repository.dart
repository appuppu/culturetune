import 'package:http/http.dart' as http;

import 'google_books_client.dart';
import 'openbd_client.dart';

/// ISBN → 書誌情報。openBD優先、無ければGoogle Booksへフォールバック。
/// 書影はさらに国立国会図書館(NDL)サムネイルAPIでも補完する。
class BookRepository {
  BookRepository({
    OpenBdClient? openBd,
    GoogleBooksClient? googleBooks,
    http.Client? client,
  }) : _openBd = openBd ?? OpenBdClient(),
       _googleBooks = googleBooks ?? GoogleBooksClient(),
       _client = client ?? http.Client();

  final OpenBdClient _openBd;
  final GoogleBooksClient _googleBooks;
  final http.Client _client;

  Future<BookInfo?> fetchByIsbn(String rawIsbn) async {
    final isbn = normalizeIsbn(rawIsbn);
    if (isbn == null) return null;

    final fromOpenBd = await _openBd.fetchByIsbn(isbn);
    // openBDは書影が無いことがあるので、Google/NDLで順に補完する
    var result = fromOpenBd;
    if (result == null || result.coverUrl == null) {
      final fromGoogle = await _googleBooks.fetchByIsbn(isbn);
      if (result == null) {
        result = fromGoogle;
      } else if (fromGoogle != null) {
        result = BookInfo(
          isbn: result.isbn,
          title: result.title,
          author: result.author ?? fromGoogle.author,
          publisher: result.publisher ?? fromGoogle.publisher,
          coverUrl: result.coverUrl ?? fromGoogle.coverUrl,
        );
      }
    }
    if (result != null && result.coverUrl == null) {
      final directCover = await _fetchGoogleCover(isbn);
      if (directCover != null) {
        result = BookInfo(
          isbn: result.isbn,
          title: result.title,
          author: result.author,
          publisher: result.publisher,
          coverUrl: directCover,
        );
      }
    }
    return result;
  }

  /// Google Booksの表紙直リンク(キー不要)。
  /// 存在しない場合も200で小さなプレースホルダ画像が返るため、
  /// サイズで実在チェックしてから採用する。
  Future<String?> _fetchGoogleCover(String isbn13) async {
    final url =
        'https://books.google.com/books/content'
        '?vid=ISBN:$isbn13&printsec=frontcover&img=1&zoom=1';
    try {
      final res = await _client.get(Uri.parse(url));
      final type = res.headers['content-type'] ?? '';
      if (res.statusCode == 200 &&
          type.startsWith('image/') &&
          res.bodyBytes.length > 3000) {
        return url;
      }
    } catch (_) {}
    return null;
  }

  /// ハイフン等を除去し、ISBN-10/13の形式チェック
  static String? normalizeIsbn(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (digits.length == 13 || digits.length == 10) return digits;
    return null;
  }
}
