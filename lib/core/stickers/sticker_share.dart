import 'dart:convert';
import 'dart:typed_data';

/// シールPNGへのメタデータ埋め込み/抽出。
/// PNGのtEXtチャンク(keyword: culturetune)にJSONを保存する。
/// LINE等の共有シートで画像として送っても、PNGのまま保存されれば
/// 受信側で作者クレジットや埋め込みカルチャーを復元できる。
abstract final class StickerShare {
  static const _keyword = 'culturetune';
  static final _pngSignature = Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ]);

  /// PNGバイト列にメタデータJSONを埋め込む(IENDの直前にtEXt挿入)
  static Uint8List embed(Uint8List png, Map<String, dynamic> meta) {
    _assertPng(png);
    // 既存のculturetuneチャンクは除去してから入れ直す
    final stripped = _removeChunk(png);

    final payload = utf8.encode(jsonEncode(meta));
    final data = BytesBuilder()
      ..add(ascii.encode(_keyword))
      ..addByte(0)
      ..add(payload);
    final chunk = _buildChunk('tEXt', data.toBytes());

    // IENDチャンク(最後の12バイト+α)の直前に挿入
    final iendOffset = _findChunkOffset(stripped, 'IEND');
    final out = BytesBuilder()
      ..add(stripped.sublist(0, iendOffset))
      ..add(chunk)
      ..add(stripped.sublist(iendOffset));
    return out.toBytes();
  }

  /// PNGからメタデータJSONを取り出す。無ければnull
  static Map<String, dynamic>? extract(Uint8List png) {
    if (png.length < 8) return null;
    for (var i = 0; i < 8; i++) {
      if (png[i] != _pngSignature[i]) return null;
    }
    var offset = 8;
    while (offset + 8 <= png.length) {
      final length = _readUint32(png, offset);
      final type = ascii.decode(png.sublist(offset + 4, offset + 8));
      if (type == 'tEXt') {
        final data = png.sublist(offset + 8, offset + 8 + length);
        final sep = data.indexOf(0);
        if (sep > 0 && ascii.decode(data.sublist(0, sep)) == _keyword) {
          try {
            return jsonDecode(utf8.decode(data.sublist(sep + 1)))
                as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        }
      }
      if (type == 'IEND') break;
      offset += 12 + length; // length(4)+type(4)+data+crc(4)
    }
    return null;
  }

  static void _assertPng(Uint8List png) {
    for (var i = 0; i < 8; i++) {
      if (png.length <= i || png[i] != _pngSignature[i]) {
        throw const FormatException('PNGではありません');
      }
    }
  }

  static Uint8List _removeChunk(Uint8List png) {
    final out = BytesBuilder()..add(png.sublist(0, 8));
    var offset = 8;
    while (offset + 8 <= png.length) {
      final length = _readUint32(png, offset);
      final end = offset + 12 + length;
      final type = ascii.decode(png.sublist(offset + 4, offset + 8));
      var skip = false;
      if (type == 'tEXt') {
        final data = png.sublist(offset + 8, offset + 8 + length);
        final sep = data.indexOf(0);
        if (sep > 0 && ascii.decode(data.sublist(0, sep)) == _keyword) {
          skip = true;
        }
      }
      if (!skip) out.add(png.sublist(offset, end));
      if (type == 'IEND') break;
      offset = end;
    }
    return out.toBytes();
  }

  static int _findChunkOffset(Uint8List png, String chunkType) {
    var offset = 8;
    while (offset + 8 <= png.length) {
      final length = _readUint32(png, offset);
      final type = ascii.decode(png.sublist(offset + 4, offset + 8));
      if (type == chunkType) return offset;
      offset += 12 + length;
    }
    return png.length;
  }

  static Uint8List _buildChunk(String type, Uint8List data) {
    final out = BytesBuilder()
      ..add(_writeUint32(data.length))
      ..add(ascii.encode(type))
      ..add(data);
    final crcInput = BytesBuilder()
      ..add(ascii.encode(type))
      ..add(data);
    out.add(_writeUint32(_crc32(crcInput.toBytes())));
    return out.toBytes();
  }

  static int _readUint32(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  static Uint8List _writeUint32(int value) => Uint8List.fromList([
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ]);

  // ---- CRC32 (PNG仕様) ----
  static final List<int> _crcTable = _makeCrcTable();

  static List<int> _makeCrcTable() {
    final table = List<int>.filled(256, 0);
    for (var n = 0; n < 256; n++) {
      var c = n;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
      }
      table[n] = c;
    }
    return table;
  }

  static int _crc32(Uint8List bytes) {
    var crc = 0xFFFFFFFF;
    for (final b in bytes) {
      crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >> 8);
    }
    return crc ^ 0xFFFFFFFF;
  }
}
