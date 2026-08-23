import 'dart:io';

import 'dart:typed_data' show Uint8List;

import 'package:drift/drift.dart' hide Uint8List;
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
  }) async {
    final cutoutPath = await CutoutService.cutoutSubject(photoPath);
    final bytes = await StickerFactory.makeSticker(
      sourcePath: cutoutPath ?? photoPath,
      texture: texture,
      isCutout: cutoutPath != null,
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
    );
  }

  /// 加工済みシール画像(交換で受け取ったもの等)をそのまま登録する
  Future<String> importProcessed({
    required Uint8List pngBytes,
    required StickerTexture texture,
    required String creatorName,
    String? creatorColor,
    String? linkedItemId,
    CardSource source = CardSource.beam,
    Uint8List? audioBytes,
  }) {
    return _save(
      bytes: pngBytes,
      texture: texture,
      creatorName: creatorName,
      creatorColor: creatorColor,
      linkedItemId: linkedItemId,
      source: source,
      audioBytes: audioBytes,
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
  }) async {
    final id = _uuid.v4();
    final dir = await _stickersDir();
    await File('${dir.path}/$id.png').writeAsBytes(bytes);
    String? audioPath;
    if (audioBytes != null && audioBytes.isNotEmpty) {
      await File('${dir.path}/$id.m4a').writeAsBytes(audioBytes);
      audioPath = 'stickers/$id.m4a';
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
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }

  Future<void> deleteSticker(Sticker sticker) async {
    await _db.deleteSticker(sticker.id);
    final file = File(resolve(sticker.imagePath));
    if (await file.exists()) await file.delete();
    if (sticker.audioPath != null) {
      final audio = File(resolve(sticker.audioPath!));
      if (await audio.exists()) await audio.delete();
    }
  }
}
