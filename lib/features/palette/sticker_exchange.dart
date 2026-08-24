import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/models/beam_card.dart';
import '../../core/models/culture_category.dart';
import '../../core/models/page_element_type.dart';
import '../../core/models/sticker_texture.dart';
import '../../core/stickers/page_renderer.dart';
import '../../core/stickers/sticker_share.dart';
import '../beam/beam_profile_provider.dart';
import '../book/page_models.dart';

/// 埋め込みデータの上限(これを超えるページは平坦画像のみで送る)
const _maxEmbedBytes = 12 * 1024 * 1024;

Map<String, dynamic> _linkOf(CultureItem item) => {
  'category': item.category.name,
  'title': item.title,
  if (item.subtitle != null) 'subtitle': item.subtitle,
  if (item.thumbUrl != null) 'thumbUrl': item.thumbUrl,
  if (item.externalId != null) 'externalId': item.externalId,
  if (item.url != null) 'url': item.url,
};

/// シールを「メタデータ入りPNG」としてLINE等の共有シートで送る。
/// 非消費型: 送っても手元のシールはなくならない(複製が届く)。
Future<void> shareStickerWithMeta(WidgetRef ref, Sticker sticker) async {
  final repo = ref.read(stickerRepositoryProvider);
  final db = ref.read(databaseProvider);
  final bytes = await File(repo.resolve(sticker.imagePath)).readAsBytes();

  Map<String, dynamic>? link;
  if (sticker.linkedItemId != null) {
    final item = await db.findItem(sticker.linkedItemId!);
    if (item != null) link = _linkOf(item);
  }

  String? audioB64;
  if (sticker.audioPath != null) {
    final audioFile = File(repo.resolve(sticker.audioPath!));
    if (audioFile.existsSync()) {
      audioB64 = base64Encode(await audioFile.readAsBytes());
    }
  }

  // 加工前素材も同梱: 受け取った側でもフチ色を変えられるようにする
  String? rawB64;
  if (sticker.rawPath != null) {
    final rawFile = File(repo.resolve(sticker.rawPath!));
    if (rawFile.existsSync()) {
      rawB64 = base64Encode(await rawFile.readAsBytes());
    }
  }

  final meta = {
    'v': 2,
    'kind': 'culturetune_sticker',
    'creatorName': sticker.creatorName,
    if (sticker.creatorColor != null) 'creatorColor': sticker.creatorColor,
    'texture': sticker.texture.name,
    'createdAt': sticker.createdAt.toIso8601String(),
    if (link != null) 'link': link,
    if (audioB64 != null) 'audio': audioB64,
    if (rawB64 != null) 'raw': rawB64,
    if (rawB64 != null) 'rawIsCutout': sticker.rawIsCutout,
    if (sticker.borderColor != null) 'borderColor': sticker.borderColor,
  };

  final embedded = StickerShare.embed(bytes, meta);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/culture_sticker_${sticker.id}.png');
  await file.writeAsBytes(embedded);
  await Share.shareXFiles([
    XFile(file.path),
  ], text: 'シールをあげる! しーるちょーの交換タブ「受け取る」で使えるよ');
}

/// シール帳ページを送る。
/// 見た目は1080x1920のPNGだが、中に要素データ(シール本体・カードのリンク・
/// テキスト)を埋め込むので、受信側では動画再生も追いデコもできる
/// 本物のページとして復元される。
Future<void> sharePageWithMeta(WidgetRef ref, StickerPage page) async {
  final db = ref.read(databaseProvider);
  final stickerRepo = ref.read(stickerRepositoryProvider);
  final profile = await ref.read(beamProfileProvider.future);

  // 表向きの画像(LINE上でそのまま見える)
  final flatPng = await renderPageToPng(
    db: db,
    stickerRepo: stickerRepo,
    itemRepo: ref.read(itemRepositoryProvider),
    page: page,
  );

  // 要素データを収集(サイズ超過時は埋め込みを諦めて平坦画像のみ)
  var embeddedBytes = 0;
  var overflow = false;
  final elements = <Map<String, dynamic>>[];
  for (final r in await loadResolvedElements(db, page.id)) {
    final el = r.element;
    final data = <String, dynamic>{
      'type': el.type.name,
      'x': el.x,
      'y': el.y,
      'scale': el.scale,
      'rotation': el.rotation,
      'z': el.z,
    };
    switch (el.type) {
      case PageElementType.profile:
        // 受け取った側でも同じ見た目になるよう、名前・色・写真を焼き込む
        final payload = ProfilePayload.fromJson(el.payload);
        String? avatarB64;
        final avatarPath = payload.isSnapshot
            ? payload.avatarPath
            : profile.imagePath;
        if (avatarPath != null && File(avatarPath).existsSync()) {
          final avatarBytes = await File(avatarPath).readAsBytes();
          embeddedBytes += avatarBytes.length;
          if (embeddedBytes <= _maxEmbedBytes) {
            avatarB64 = base64Encode(avatarBytes);
          }
        }
        data['profile'] = {
          'shape': payload.shape.name,
          'frameColor': payload.frameColorHex,
          'name': payload.isSnapshot ? payload.name : profile.name,
          'color': payload.isSnapshot ? payload.colorHex : profile.colorHex,
          if (avatarB64 != null) 'avatarPng': avatarB64,
        };
      case PageElementType.text:
        data['payload'] = el.payload;
      case PageElementType.card:
        data['link'] = _linkOf(r.item!);
      case PageElementType.sticker:
        final sticker = r.sticker!;
        final png = await File(
          stickerRepo.resolve(sticker.imagePath),
        ).readAsBytes();
        embeddedBytes += png.length;
        if (embeddedBytes > _maxEmbedBytes) {
          overflow = true;
          break;
        }
        Map<String, dynamic>? link;
        if (sticker.linkedItemId != null) {
          final item = await db.findItem(sticker.linkedItemId!);
          if (item != null) link = _linkOf(item);
        }
        String? audioB64;
        if (sticker.audioPath != null) {
          final audioFile = File(stickerRepo.resolve(sticker.audioPath!));
          if (audioFile.existsSync()) {
            final audioBytes = await audioFile.readAsBytes();
            embeddedBytes += audioBytes.length;
            if (embeddedBytes <= _maxEmbedBytes) {
              audioB64 = base64Encode(audioBytes);
            }
          }
        }
        // 加工前素材(容量が許す範囲で。受け取り側のフチ色変更用)
        String? rawB64;
        if (sticker.rawPath != null) {
          final rawFile = File(stickerRepo.resolve(sticker.rawPath!));
          if (rawFile.existsSync()) {
            final rawBytes = await rawFile.readAsBytes();
            embeddedBytes += rawBytes.length;
            if (embeddedBytes <= _maxEmbedBytes) {
              rawB64 = base64Encode(rawBytes);
            } else {
              embeddedBytes -= rawBytes.length;
            }
          }
        }
        data['sticker'] = {
          'texture': sticker.texture.name,
          'creatorName': sticker.creatorName,
          if (sticker.creatorColor != null)
            'creatorColor': sticker.creatorColor,
          if (link != null) 'link': link,
          'png': base64Encode(png),
          if (audioB64 != null) 'audio': audioB64,
          if (rawB64 != null) 'raw': rawB64,
          if (rawB64 != null) 'rawIsCutout': sticker.rawIsCutout,
          if (sticker.borderColor != null) 'borderColor': sticker.borderColor,
        };
    }
    if (overflow) break;
    elements.add(data);
  }

  // 背景画像(受け取ったページを再共有するケース)
  String? bgPng;
  if (!overflow && page.bgImagePath != null) {
    final file = File(page.bgImagePath!);
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      embeddedBytes += bytes.length;
      if (embeddedBytes <= _maxEmbedBytes) bgPng = base64Encode(bytes);
    }
  }

  final meta = {
    'v': 2,
    'kind': 'culturetune_page',
    'creatorName': profile.name,
    'creatorColor': profile.colorHex,
    'title': page.title,
    'createdAt': DateTime.now().toIso8601String(),
    if (page.bgColor != null) 'bgColor': page.bgColor,
    if (!overflow) 'elements': elements,
    if (bgPng != null) 'bgPng': bgPng,
  };

  final embedded = StickerShare.embed(flatPng, meta);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/culture_page_${page.id}.png');
  await file.writeAsBytes(embedded);
  await Share.shareXFiles([
    XFile(file.path),
  ], text: 'シール帳のページをあげる! しーるちょーの交換タブ「受け取る」で読めるよ。追いデコして返してくれてもいいよ');
}

/// ギャラリーの画像からシール/ページを取り込む(共有シートで受け取ったPNG)。
Future<void> importStickerFromGallery(
  BuildContext context,
  WidgetRef ref,
) async {
  final file = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (file == null || !context.mounted) return;

  final bytes = await file.readAsBytes();
  final meta = StickerShare.extract(bytes);
  if (!context.mounted) return;

  if (meta == null ||
      (meta['kind'] != 'culturetune_sticker' &&
          meta['kind'] != 'culturetune_page')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('しーるちょーのシールじゃないみたい(スクショではなく元のPNGを保存してね)')),
    );
    return;
  }

  final creatorName = meta['creatorName'] as String? ?? 'ともだち';
  final creatorColor = meta['creatorColor'] as String?;

  if (meta['kind'] == 'culturetune_page') {
    final restored = await _importPage(
      ref,
      meta,
      flatPng: bytes,
      creatorName: creatorName,
      creatorColor: creatorColor,
    );
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? '$creatorName のページをシール帳に追加したよ。追いデコして送り返すと交換日記になるよ'
              : '$creatorName のページを画像として追加したよ',
        ),
      ),
    );
    return;
  }

  // 単体シール
  final texture =
      StickerTexture.values.asNameMap()[meta['texture']] ??
      StickerTexture.normal;
  final linkedItemId = await _restoreLink(
    ref,
    meta['link'],
    creatorName: creatorName,
    creatorColor: creatorColor,
  );
  final audioB64 = meta['audio'] as String?;
  final rawB64 = meta['raw'] as String?;
  await ref
      .read(stickerRepositoryProvider)
      .importProcessed(
        pngBytes: bytes,
        texture: texture,
        creatorName: creatorName,
        creatorColor: creatorColor,
        linkedItemId: linkedItemId,
        source: CardSource.beam,
        audioBytes: audioB64 != null ? base64Decode(audioB64) : null,
        rawBytes: rawB64 != null ? base64Decode(rawB64) : null,
        rawIsCutout: meta['rawIsCutout'] as bool? ?? false,
        borderColorHex: meta['borderColor'] as String?,
      );

  if (!context.mounted) return;
  HapticFeedback.mediumImpact();
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$creatorName のシールをパレットに追加したよ')));
}

/// 埋め込みカルチャーをカードとして復元し、idを返す
Future<String?> _restoreLink(
  WidgetRef ref,
  Object? link, {
  required String creatorName,
  required String? creatorColor,
}) async {
  if (link is! Map<String, dynamic>) return null;
  try {
    return await ref
        .read(itemRepositoryProvider)
        .saveBeamCard(
          BeamCard(
            senderName: creatorName,
            senderColor: creatorColor ?? '#FF6B9D',
            category: CultureCategory.values.byName(link['category'] as String),
            title: link['title'] as String,
            subtitle: link['subtitle'] as String?,
            thumbUrl: link['thumbUrl'] as String?,
            externalId: link['externalId'] as String?,
            url: link['url'] as String?,
            oshiLevel: 3,
            moodTags: const [],
          ),
        );
  } catch (_) {
    return null;
  }
}

/// ページの復元。要素データがあれば「動くページ」として、
/// なければ平坦画像を背景にしたページとして取り込む。
/// 戻り値: 要素付きで復元できたか。
Future<bool> _importPage(
  WidgetRef ref,
  Map<String, dynamic> meta, {
  required Uint8List flatPng,
  required String creatorName,
  required String? creatorColor,
}) async {
  final db = ref.read(databaseProvider);
  final stickerRepo = ref.read(stickerRepositoryProvider);
  final docs = ref.read(documentsDirProvider);
  const uuid = Uuid();
  final pageId = uuid.v4();
  final now = DateTime.now();

  final rawTitle = (meta['title'] as String?)?.trim();
  final title = (rawTitle == null || rawTitle.isEmpty)
      ? '$creatorNameのページ'
      : '$rawTitle (from $creatorName)';

  final elementsMeta = meta['elements'];
  if (elementsMeta is! List) {
    // 旧形式/サイズ超過: 平坦画像を背景として復元
    final bgDir = Directory('${docs.path}/pages_bg');
    if (!bgDir.existsSync()) bgDir.createSync(recursive: true);
    final bgFile = File('${bgDir.path}/$pageId.png');
    await bgFile.writeAsBytes(flatPng);
    await db.upsertPage(
      StickerPagesCompanion.insert(
        id: pageId,
        title: drift.Value(title),
        bgImagePath: drift.Value(bgFile.path),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return false;
  }

  // 背景
  String? bgImagePath;
  final bgPng = meta['bgPng'] as String?;
  if (bgPng != null) {
    final bgDir = Directory('${docs.path}/pages_bg');
    if (!bgDir.existsSync()) bgDir.createSync(recursive: true);
    final bgFile = File('${bgDir.path}/$pageId.png');
    await bgFile.writeAsBytes(base64Decode(bgPng));
    bgImagePath = bgFile.path;
  }

  await db.upsertPage(
    StickerPagesCompanion.insert(
      id: pageId,
      title: drift.Value(title),
      bgColor: drift.Value(meta['bgColor'] as String?),
      bgImagePath: drift.Value(bgImagePath),
      createdAt: now,
      updatedAt: now,
    ),
  );

  // 同一シールの重複取り込みを防ぐ(このページ内で)
  final importedStickers = <String, String>{}; // base64 -> stickerId

  for (final raw in elementsMeta) {
    if (raw is! Map<String, dynamic>) continue;
    final type = PageElementType.values.asNameMap()[raw['type']];
    if (type == null) continue;

    String? refId;
    var payload = '{}';
    switch (type) {
      case PageElementType.profile:
        final profileMeta = raw['profile'];
        if (profileMeta is! Map<String, dynamic>) continue;
        String? avatarPath;
        final avatarPng = profileMeta['avatarPng'] as String?;
        if (avatarPng != null) {
          final avatarDir = Directory('${docs.path}/avatars_recv');
          if (!avatarDir.existsSync()) avatarDir.createSync(recursive: true);
          final avatarFile = File('${avatarDir.path}/${uuid.v4()}.png');
          await avatarFile.writeAsBytes(base64Decode(avatarPng));
          avatarPath = avatarFile.path;
        }
        payload = ProfilePayload(
          shape:
              ProfileShape.values.asNameMap()[profileMeta['shape']] ??
              ProfileShape.circle,
          frameColorHex: profileMeta['frameColor'] as String? ?? '#FFFFFF',
          name: profileMeta['name'] as String? ?? creatorName,
          colorHex: profileMeta['color'] as String? ?? creatorColor,
          avatarPath: avatarPath,
        ).toJson();
      case PageElementType.text:
        payload = raw['payload'] as String? ?? '{}';
      case PageElementType.card:
        refId = await _restoreLink(
          ref,
          raw['link'],
          creatorName: creatorName,
          creatorColor: creatorColor,
        );
        if (refId == null) continue;
      case PageElementType.sticker:
        final stickerMeta = raw['sticker'];
        if (stickerMeta is! Map<String, dynamic>) continue;
        final png = stickerMeta['png'] as String?;
        if (png == null) continue;
        refId = importedStickers[png];
        if (refId == null) {
          final linkedItemId = await _restoreLink(
            ref,
            stickerMeta['link'],
            creatorName: stickerMeta['creatorName'] as String? ?? creatorName,
            creatorColor:
                stickerMeta['creatorColor'] as String? ?? creatorColor,
          );
          final elementAudio = stickerMeta['audio'] as String?;
          final elementRaw = stickerMeta['raw'] as String?;
          refId = await stickerRepo.importProcessed(
            pngBytes: base64Decode(png),
            texture:
                StickerTexture.values.asNameMap()[stickerMeta['texture']] ??
                StickerTexture.normal,
            creatorName: stickerMeta['creatorName'] as String? ?? creatorName,
            creatorColor:
                stickerMeta['creatorColor'] as String? ?? creatorColor,
            linkedItemId: linkedItemId,
            source: CardSource.beam,
            audioBytes: elementAudio != null
                ? base64Decode(elementAudio)
                : null,
            rawBytes: elementRaw != null ? base64Decode(elementRaw) : null,
            rawIsCutout: stickerMeta['rawIsCutout'] as bool? ?? false,
            borderColorHex: stickerMeta['borderColor'] as String?,
          );
          importedStickers[png] = refId;
        }
    }

    await db.upsertPageElement(
      PageElementsCompanion.insert(
        id: uuid.v4(),
        pageId: pageId,
        type: drift.Value(type),
        refId: drift.Value(refId),
        payload: drift.Value(payload),
        x: (raw['x'] as num?)?.toDouble() ?? 0.5,
        y: (raw['y'] as num?)?.toDouble() ?? 0.5,
        scale: drift.Value((raw['scale'] as num?)?.toDouble() ?? 1),
        rotation: drift.Value((raw['rotation'] as num?)?.toDouble() ?? 0),
        z: drift.Value((raw['z'] as num?)?.toInt() ?? 0),
      ),
    );
  }
  return true;
}
