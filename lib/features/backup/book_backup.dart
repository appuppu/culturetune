import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/files/doc_paths.dart';
import '../../core/models/culture_category.dart';
import '../../core/models/page_element_type.dart';
import '../../core/models/sticker_texture.dart';
import '../beam/beam_profile_provider.dart';
import '../book/page_models.dart';

/// シール帳まるごとバックアップ。
/// 全データ(ページ・シール・カード・ボイス・背景・プロフィール)を
/// 1つのZIPに書き出し、iCloud Drive等にユーザー自身が保存する。
/// サーバーもアカウントも使わない機種変更・復元手段。
///
/// ZIP構成:
///   data.json            … 全テーブルの行
///   files/<相対パス>      … 画像・音声(Documents配下の相対パスを保存)
///   profile/avatar.jpg   … 交換プロフィールのアバター

String? _iso(DateTime? d) => d?.toIso8601String();

DateTime _dt(Object? v) =>
    DateTime.tryParse(v as String? ?? '') ?? DateTime.now();

/// 書き出し: ZIPを作って共有シートへ。戻り値はエラーメッセージ(成功ならnull)
Future<String?> exportBookBackup(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final docs = ref.read(documentsDirProvider);
  final profile = await ref.read(beamProfileProvider.future);

  final archive = Archive();

  Future<bool> addAbs(String zipPath, String absPath) async {
    final f = File(absPath);
    if (!await f.exists()) return false;
    archive.addFile(ArchiveFile.bytes(zipPath, await f.readAsBytes()));
    return true;
  }

  Future<bool> addRel(String rel) => addAbs('files/$rel', '${docs.path}/$rel');

  // カード
  final items = await db.select(db.cultureItems).get();
  final itemRows = <Map<String, dynamic>>[];
  for (final it in items) {
    if (it.thumbPath != null) await addRel(it.thumbPath!);
    itemRows.add({
      'id': it.id,
      'category': it.category.name,
      'title': it.title,
      'subtitle': it.subtitle,
      'thumbPath': it.thumbPath,
      'thumbUrl': it.thumbUrl,
      'externalId': it.externalId,
      'url': it.url,
      'memo': it.memo,
      'moodTags': it.moodTags,
      'moodColor': it.moodColor,
      'detailJson': it.detailJson,
      'lat': it.lat,
      'lng': it.lng,
      'placeName': it.placeName,
      'source': it.source.name,
      'beamFrom': it.beamFrom,
      'beamFromColor': it.beamFromColor,
      'isFavorite': it.isFavorite,
      'pinnedOrder': it.pinnedOrder,
      'archived': it.archived,
      'createdAt': _iso(it.createdAt),
      'consumedAt': _iso(it.consumedAt),
    });
  }

  // シール(画像・素材・ボイス)
  final stickers = await db.select(db.stickers).get();
  final stickerRows = <Map<String, dynamic>>[];
  for (final s in stickers) {
    await addRel(s.imagePath);
    if (s.audioPath != null) await addRel(s.audioPath!);
    if (s.rawPath != null) await addRel(s.rawPath!);
    stickerRows.add({
      'id': s.id,
      'imagePath': s.imagePath,
      'texture': s.texture.name,
      'creatorName': s.creatorName,
      'creatorColor': s.creatorColor,
      'source': s.source.name,
      'linkedItemId': s.linkedItemId,
      'audioPath': s.audioPath,
      'rawPath': s.rawPath,
      'rawIsCutout': s.rawIsCutout,
      'borderColor': s.borderColor,
      'archived': s.archived,
      'createdAt': _iso(s.createdAt),
    });
  }

  // ページ(背景画像は絶対パス保存なのでpageId名に付け替えて格納)
  final pages = await db.select(db.stickerPages).get();
  final pageRows = <Map<String, dynamic>>[];
  for (final p in pages) {
    String? bgZip;
    final bg = p.bgImagePath == null
        ? null
        : resolveDocFile(docs, p.bgImagePath!);
    if (bg != null) {
      final ext = bg.contains('.') ? bg.substring(bg.lastIndexOf('.')) : '.png';
      final rel = 'pages_bg/${p.id}$ext';
      if (await addAbs('files/$rel', bg)) bgZip = rel;
    }
    pageRows.add({
      'id': p.id,
      'title': p.title,
      'bgColor': p.bgColor,
      'borderColor': p.borderColor,
      'showTitle': p.showTitle,
      'bgZip': bgZip,
      'createdAt': _iso(p.createdAt),
      'updatedAt': _iso(p.updatedAt),
    });
  }

  // ページ要素(プロフィール要素のアバターも絶対パスなので付け替え)
  final elements = await db.select(db.pageElements).get();
  final elementRows = <Map<String, dynamic>>[];
  for (final e in elements) {
    String? avatarZip;
    if (e.type == PageElementType.profile) {
      final payload = ProfilePayload.fromJson(e.payload);
      final avatar = payload.avatarPath == null
          ? null
          : resolveDocFile(docs, payload.avatarPath!);
      if (avatar != null) {
        final rel = 'avatars_recv/${e.id}.png';
        if (await addAbs('files/$rel', avatar)) avatarZip = rel;
      }
    }
    elementRows.add({
      'id': e.id,
      'pageId': e.pageId,
      'type': e.type.name,
      'refId': e.refId,
      'payload': e.payload,
      'avatarZip': avatarZip,
      'x': e.x,
      'y': e.y,
      'scale': e.scale,
      'rotation': e.rotation,
      'z': e.z,
    });
  }

  // 交換履歴
  final beams = await db.select(db.beams).get();
  final beamRows = [
    for (final b in beams)
      {
        'id': b.id,
        'direction': b.direction.name,
        'peerName': b.peerName,
        'peerColor': b.peerColor,
        'cardId': b.cardId,
        'beamedAt': _iso(b.beamedAt),
      },
  ];

  // 交換プロフィール
  var hasAvatar = false;
  if (profile.imagePath != null) {
    hasAvatar = await addAbs('profile/avatar.jpg', profile.imagePath!);
  }

  final data = {
    'kind': 'shirucho_backup',
    'v': 1,
    'exportedAt': _iso(DateTime.now()),
    'profile': {
      'name': profile.name,
      'color': profile.colorHex,
      'hasAvatar': hasAvatar,
    },
    'items': itemRows,
    'stickers': stickerRows,
    'pages': pageRows,
    'elements': elementRows,
    'beams': beamRows,
  };
  archive.addFile(
    ArchiveFile.bytes('data.json', utf8.encode(jsonEncode(data))),
  );

  final zipBytes = ZipEncoder().encode(archive);
  final dir = await getTemporaryDirectory();
  final now = DateTime.now();
  final stamp =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final out = File('${dir.path}/しーるちょーバックアップ_$stamp.zip');
  await out.writeAsBytes(zipBytes);
  await Share.shareXFiles([
    XFile(out.path),
  ], text: 'しーるちょーのバックアップ($stamp)。設定→「バックアップを読み込む」で復元できるよ');
  return null;
}

/// 読み込み: ファイルを選んで復元。同じIDのデータは上書き(2回読んでも重複しない)。
/// 戻り値は結果メッセージ。
Future<String> importBookBackup(WidgetRef ref) async {
  const zipGroup = XTypeGroup(
    label: 'バックアップ',
    extensions: ['zip'],
    mimeTypes: ['application/zip'],
    uniformTypeIdentifiers: ['public.zip-archive'],
  );
  final picked = await openFile(acceptedTypeGroups: const [zipGroup]);
  if (picked == null) return '';
  final path = picked.path;

  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
  } catch (_) {
    return 'このファイルは読み込めなかったよ(しーるちょーのバックアップZIPを選んでね)';
  }

  final entries = <String, List<int>>{};
  for (final f in archive) {
    if (f.isFile) entries[f.name] = f.readBytes() ?? const [];
  }
  final dataBytes = entries['data.json'];
  if (dataBytes == null) return 'バックアップのデータが見つからなかったよ';
  final data = jsonDecode(utf8.decode(dataBytes));
  if (data is! Map<String, dynamic> || data['kind'] != 'shirucho_backup') {
    return 'しーるちょーのバックアップじゃないみたい';
  }

  final db = ref.read(databaseProvider);
  final docs = ref.read(documentsDirProvider);

  // files/配下を相対パスのままDocumentsへ展開
  for (final entry in entries.entries) {
    if (!entry.key.startsWith('files/')) continue;
    final rel = entry.key.substring('files/'.length);
    if (rel.isEmpty || rel.contains('..')) continue;
    final dest = File('${docs.path}/$rel');
    await dest.parent.create(recursive: true);
    await dest.writeAsBytes(entry.value);
  }

  // カード
  var itemCount = 0;
  for (final raw in (data['items'] as List? ?? const [])) {
    if (raw is! Map<String, dynamic>) continue;
    final category = CultureCategory.values.asNameMap()[raw['category']];
    if (category == null) continue;
    await db
        .into(db.cultureItems)
        .insertOnConflictUpdate(
          CultureItemsCompanion.insert(
            id: raw['id'] as String,
            category: category,
            title: raw['title'] as String? ?? '',
            subtitle: drift.Value(raw['subtitle'] as String?),
            thumbPath: drift.Value(raw['thumbPath'] as String?),
            thumbUrl: drift.Value(raw['thumbUrl'] as String?),
            externalId: drift.Value(raw['externalId'] as String?),
            url: drift.Value(raw['url'] as String?),
            memo: drift.Value(raw['memo'] as String?),
            moodTags: drift.Value(raw['moodTags'] as String? ?? '[]'),
            moodColor: drift.Value(raw['moodColor'] as String?),
            detailJson: drift.Value(raw['detailJson'] as String? ?? '{}'),
            lat: drift.Value((raw['lat'] as num?)?.toDouble()),
            lng: drift.Value((raw['lng'] as num?)?.toDouble()),
            placeName: drift.Value(raw['placeName'] as String?),
            source: drift.Value(
              CardSource.values.asNameMap()[raw['source']] ?? CardSource.self,
            ),
            beamFrom: drift.Value(raw['beamFrom'] as String?),
            beamFromColor: drift.Value(raw['beamFromColor'] as String?),
            isFavorite: drift.Value(raw['isFavorite'] as bool? ?? false),
            pinnedOrder: drift.Value((raw['pinnedOrder'] as num?)?.toInt()),
            archived: drift.Value(raw['archived'] as bool? ?? false),
            createdAt: _dt(raw['createdAt']),
            consumedAt: drift.Value(
              raw['consumedAt'] == null ? null : _dt(raw['consumedAt']),
            ),
          ),
        );
    itemCount++;
  }

  // シール
  var stickerCount = 0;
  for (final raw in (data['stickers'] as List? ?? const [])) {
    if (raw is! Map<String, dynamic>) continue;
    await db
        .into(db.stickers)
        .insertOnConflictUpdate(
          StickersCompanion.insert(
            id: raw['id'] as String,
            imagePath: raw['imagePath'] as String,
            texture: drift.Value(
              StickerTexture.values.asNameMap()[raw['texture']] ??
                  StickerTexture.normal,
            ),
            creatorName: raw['creatorName'] as String? ?? 'ゲスト',
            creatorColor: drift.Value(raw['creatorColor'] as String?),
            source: drift.Value(
              CardSource.values.asNameMap()[raw['source']] ?? CardSource.self,
            ),
            linkedItemId: drift.Value(raw['linkedItemId'] as String?),
            audioPath: drift.Value(raw['audioPath'] as String?),
            rawPath: drift.Value(raw['rawPath'] as String?),
            rawIsCutout: drift.Value(raw['rawIsCutout'] as bool? ?? false),
            borderColor: drift.Value(raw['borderColor'] as String?),
            archived: drift.Value(raw['archived'] as bool? ?? false),
            createdAt: _dt(raw['createdAt']),
          ),
        );
    stickerCount++;
  }

  // ページ(背景はこの端末の絶対パスに付け替え)
  var pageCount = 0;
  for (final raw in (data['pages'] as List? ?? const [])) {
    if (raw is! Map<String, dynamic>) continue;
    final bgZip = raw['bgZip'] as String?;
    await db
        .into(db.stickerPages)
        .insertOnConflictUpdate(
          StickerPagesCompanion.insert(
            id: raw['id'] as String,
            title: drift.Value(raw['title'] as String? ?? ''),
            bgColor: drift.Value(raw['bgColor'] as String?),
            borderColor: drift.Value(raw['borderColor'] as String?),
            showTitle: drift.Value(raw['showTitle'] as bool? ?? true),
            bgImagePath: drift.Value(bgZip),
            createdAt: _dt(raw['createdAt']),
            updatedAt: _dt(raw['updatedAt']),
          ),
        );
    pageCount++;
  }

  // ページ要素(プロフィールのアバターも付け替え)
  for (final raw in (data['elements'] as List? ?? const [])) {
    if (raw is! Map<String, dynamic>) continue;
    final type = PageElementType.values.asNameMap()[raw['type']];
    if (type == null) continue;
    var payload = raw['payload'] as String? ?? '{}';
    if (type == PageElementType.profile) {
      final avatarZip = raw['avatarZip'] as String?;
      final old = ProfilePayload.fromJson(payload);
      // アバターはこの端末に展開したパスへ付け替え(無ければ外す)
      payload = ProfilePayload(
        shape: old.shape,
        frameColorHex: old.frameColorHex,
        name: old.name,
        colorHex: old.colorHex,
        avatarPath: avatarZip,
      ).toJson();
    }
    await db
        .into(db.pageElements)
        .insertOnConflictUpdate(
          PageElementsCompanion.insert(
            id: raw['id'] as String,
            pageId: raw['pageId'] as String,
            type: drift.Value(type),
            refId: drift.Value(raw['refId'] as String?),
            payload: drift.Value(payload),
            x: (raw['x'] as num?)?.toDouble() ?? 0.5,
            y: (raw['y'] as num?)?.toDouble() ?? 0.5,
            scale: drift.Value((raw['scale'] as num?)?.toDouble() ?? 1),
            rotation: drift.Value((raw['rotation'] as num?)?.toDouble() ?? 0),
            z: drift.Value((raw['z'] as num?)?.toInt() ?? 0),
          ),
        );
  }

  // 交換履歴
  for (final raw in (data['beams'] as List? ?? const [])) {
    if (raw is! Map<String, dynamic>) continue;
    final direction = BeamDirection.values.asNameMap()[raw['direction']];
    if (direction == null) continue;
    await db
        .into(db.beams)
        .insertOnConflictUpdate(
          BeamsCompanion.insert(
            id: raw['id'] as String,
            direction: direction,
            peerName: raw['peerName'] as String? ?? '?',
            peerColor: drift.Value(raw['peerColor'] as String?),
            cardId: raw['cardId'] as String? ?? '',
            beamedAt: _dt(raw['beamedAt']),
          ),
        );
  }

  // 交換プロフィール
  final profileMeta = data['profile'];
  if (profileMeta is Map<String, dynamic>) {
    String? avatarTmp;
    final avatarBytes = entries['profile/avatar.jpg'];
    if (avatarBytes != null) {
      final dir = await getTemporaryDirectory();
      final tmp = File('${dir.path}/restore_avatar.jpg');
      await tmp.writeAsBytes(avatarBytes);
      avatarTmp = tmp.path;
    }
    await ref
        .read(beamProfileProvider.notifier)
        .save(
          name: profileMeta['name'] as String? ?? 'ゲスト',
          colorHex: profileMeta['color'] as String? ?? '#FF6B9D',
          newImagePath: avatarTmp,
        );
  }

  return 'シール帳$pageCount・シール$stickerCount・カード$itemCount枚を復元したよ';
}
