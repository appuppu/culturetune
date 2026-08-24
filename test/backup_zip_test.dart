import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('バックアップZIPの書き込みと読み出しが往復できる', () {
    final archive = Archive();
    final data = {'kind': 'shirucho_backup', 'v': 1};
    archive.addFile(
      ArchiveFile.bytes('data.json', utf8.encode(jsonEncode(data))),
    );
    archive.addFile(
      ArchiveFile.bytes('files/stickers/a.png', List.filled(64, 7)),
    );

    final zipBytes = ZipEncoder().encode(archive);

    final decoded = ZipDecoder().decodeBytes(zipBytes);
    final entries = <String, List<int>>{};
    for (final f in decoded) {
      if (f.isFile) entries[f.name] = f.readBytes() ?? const [];
    }

    final parsed = jsonDecode(utf8.decode(entries['data.json']!));
    expect(parsed['kind'], 'shirucho_backup');
    expect(entries['files/stickers/a.png'], List.filled(64, 7));
  });
}
