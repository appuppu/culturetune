import 'dart:convert';

import 'package:http/http.dart' as http;

import 'openbd_client.dart';

/// Google Books API (キー不要)。openBDに無い書籍のフォールバック。
class GoogleBooksClient {
  GoogleBooksClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<BookInfo?> fetchByIsbn(String isbn) async {
    final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
      'q': 'isbn:$isbn',
      'country': 'JP',
    });
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;

    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final items = json['items'] as List?;
    if (items == null || items.isEmpty) return null;

    final info =
        (items.first as Map<String, dynamic>)['volumeInfo']
            as Map<String, dynamic>?;
    final title = info?['title'] as String?;
    if (info == null || title == null) return null;

    final authors = (info['authors'] as List?)?.cast<String>();
    final links = info['imageLinks'] as Map<String, dynamic>?;
    // http:// で返ることがあるので https に寄せる
    final thumb = (links?['thumbnail'] as String?)?.replaceFirst(
      'http://',
      'https://',
    );

    return BookInfo(
      isbn: isbn,
      title: title,
      author: authors?.join('、'),
      publisher: info['publisher'] as String?,
      coverUrl: thumb,
    );
  }
}
