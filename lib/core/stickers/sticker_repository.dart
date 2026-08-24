import 'dart:io';

import 'dart:typed_data' show Uint8List;

import 'package:drift/drift.dart' hide Uint8List;
import 'package:flutter/painting.dart' show Color, FileImage;
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/culture_category.dart';
import '../models/sticker_texture.dart';
import 'cutout_service.dart';
import 'sticker_factory.dart';

/// シールの作成・保存・削除。画像はDocuments/stickers/に保存する。
class StickerRepository {
  StickerRepository(this._db, this._documentsDir);

  final AppDatabase _db;
  final Directory _documentsDir;
  final _uuid = const Uuid();

  Future<Directory> _stickersDir() async {
    final dir = Directory('${_documentsDir.path}/stickers');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String resolve(String relativePath) => '${_documentsDir.path}/$relativePath';

  /// 写真からシールを作成して保存する。
  /// 被写体切り抜きを試み、できなければ角丸マスクでシール化する。
  Future<String> createFromPhoto({
    required String photoPath,
    required StickerTexture texture,
    required String creatorName,
    String? creatorColor,
    String? linkedItemId,
    String? audioSourcePath,
    Color borderColor = const Color(0xFFFFFFFF),
  }) async {
    final cutoutPath = await CutoutService.cutoutSubject(photoPath);
    final bytes = await StickerFactory.makeSticker(
      sourcePath: cutoutPath ?? photoPath,
      texture: texture,
      isCutout: cutoutPath != null,
      borderColor: borderColor,
    );
    return _save(
      bytes: bytes,
      texture: texture,
      creatorName: creatorName,
      creatorColor: creatorColor,
      linkedItemId: linkedItemId,
      source: CardSource.self,
      audioBytes: audioSourcePath != null
          ? await File(audioSourcePath).readAsBytes()
          : null,
      rawSourcePath: cutoutPath ?? photoPath,
      rawIsCutout: cutoutPath != null,
      borderColorHex: hexOfColor(borderColor),
    );
  }

  static String hexOfColor(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// 加工済みシール画像(交換で受け取ったもの等)をそのまま登録する
  Future<String> importProcessed({
    required Uint8List pngBytes,
    required StickerTexture texture,
    required String creatorName,
    String? creatorColor,
    String? linkedItemId,
    CardSource source = CardSource.beam,
    Uint8List? audioBytes,
    String? rawSourcePath,
    bool rawIsCutout = false,
    String? borderColorHex,
  }) {
    return _save(
      bytes: pngBytes,
      texture: texture,
      creatorName: creatorName,
      creatorColor: creatorColor,
      linkedItemId: linkedItemId,
      source: source,
      audioBytes: audioBytes,
      rawSourcePath: rawSourcePath,
      rawIsCutout: rawIsCutout,
      borderColorHex: borderColorHex,
    );
  }

  Future<String> _save({
    required Uint8List bytes,
    required StickerTexture texture,
    required String creatorName,
    required String? creatorColor,
    required String? linkedItemId,
    required CardSource source,
    Uint8List? audioBytes,
    String? rawSourcePath,
    bool rawIsCutout = false,
    String? borderColorHex,
  }) async {
    final id = _uuid.v4();
    final dir = await _stickersDir();
    await File('${dir.path}/$id.png').writeAsBytes(bytes);
    String? audioPath;
    if (audioBytes != null && audioBytes.isNotEmpty) {
      await File('${dir.path}/$id.m4a').writeAsBytes(audioBytes);
      audioPath = 'stickers/$id.m4a';
    }
    // フチ色を後から変えられるよう、加工前の素材を保存しておく
    String? rawPath;
    if (rawSourcePath != null && File(rawSourcePath).existsSync()) {
      await File(rawSourcePath).copy('${dir.path}/${id}_raw.png');
      rawPath = 'stickers/${id}_raw.png';
    }
    await _db.insertSticker(
      StickersCompanion.insert(
        id: id,
        imagePath: 'stickers/$id.png',
        texture: Value(texture),
        creatorName: creatorName,
        creatorColor: Value(creatorColor),
        source: Value(source),
        linkedItemId: Value(linkedItemId),
        audioPath: Value(audioPath),
        rawPath: Value(rawPath),
        rawIsCutout: Value(rawIsCutout),
        borderColor: Value(borderColorHex),
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }

  /// フチの色を変えてシール画像を作り直す。
  /// 素材(rawPath)が無いシール(旧作成分・交換で受領分)はfalse。
  Future<bool> recolorBorder(Sticker sticker, Color color) async {
    final raw = sticker.rawPath;
    if (raw == null) return false;
    final bytes = await StickerFactory.makeSticker(
      sourcePath: resolve(raw),
      texture: sticker.texture,
      isCutout: sticker.rawIsCutout,
      borderColor: color,
    );
    final file = File(resolve(sticker.imagePath));
    await file.writeAsBytes(bytes);
    await FileImage(file).evict();
    await _db.updateStickerBorder(sticker.id, hexOfColor(color));
    return true;
  }

  Future<void> deleteSticker(Sticker sticker) async {
    await _db.deleteSticker(sticker.id);
    for (final rel in [sticker.imagePath, sticker.audioPath, sticker.rawPath]) {
      if (rel == null) continue;
      final file = File(resolve(rel));
      if (await file.exists()) await file.delete();
    }
  }
}
