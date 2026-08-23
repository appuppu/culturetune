import 'dart:convert';

import 'package:http/http.dart' as http;

class BookInfo {
  const BookInfo({
    required this.isbn,
    required this.title,
    this.author,
    this.publisher,
    this.coverUrl,
  });

  final String isbn;
  final String title;
  final String? author;
  final String? publisher;
  final String? coverUrl;
}

/// openBD API (キー不要・登録不要) https://openbd.jp/
class OpenBdClient {
  OpenBdClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<BookInfo?> fetchByIsbn(String isbn) async {
    final uri = Uri.https('api.openbd.jp', '/v1/get', {'isbn': isbn});
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;

    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    if (list.isEmpty || list.first == null) return null;

    final summary =
        (list.first as Map<String, dynamic>)['summary']
            as Map<String, dynamic>?;
    if (summary == null) return null;

    final title = summary['title'] as String?;
    if (title == null || title.isEmpty) return null;

    final cover = summary['cover'] as String?;
    return BookInfo(
      isbn: summary['isbn'] as String? ?? isbn,
      title: title,
      author: _emptyToNull(summary['author'] as String?),
      publisher: _emptyToNull(summary['publisher'] as String?),
      coverUrl: (cover != null && cover.isNotEmpty) ? cover : null,
    );
  }

  static String? _emptyToNull(String? s) => (s == null || s.isEmpty) ? null : s;
}
