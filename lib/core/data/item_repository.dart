import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/beam_card.dart';
import '../models/culture_category.dart';
import 'post_draft.dart';

/// カードの保存・削除。サムネはアプリのDocuments/thumbs/に取り込み、
/// DBには相対パスだけを持たせる(iOSはコンテナパスが変わるため)。
class ItemRepository {
  ItemRepository(this._db, this._documentsDir, {http.Client? client})
    : _client = client ?? http.Client();

  final AppDatabase _db;
  final Directory _documentsDir;
  final http.Client _client;
  final _uuid = const Uuid();

  Future<Directory> _thumbsDir() async {
    final dir = Directory('${_documentsDir.path}/thumbs');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 下書き + 仕上げ入力を確定保存し、カードidを返す
  Future<String> saveDraft(
    PostDraft draft, {
    required int oshiLevel,
    required List<String> moodTags,
    String? moodColor,
    String? memo,
  }) async {
    final id = _uuid.v4();
    final thumbPath = await _importThumb(
      id: id,
      localImagePath: draft.localImagePath,
      thumbUrl: draft.thumbUrl,
    );

    await _db.upsertItem(
      CultureItemsCompanion.insert(
        id: id,
        category: draft.category,
        title: draft.title,
        subtitle: Value(draft.subtitle),
        thumbPath: Value(thumbPath),
        thumbUrl: Value(draft.thumbUrl),
        externalId: Value(draft.externalId),
        url: Value(draft.url),
        memo: Value(memo?.trim().isEmpty ?? true ? null : memo!.trim()),
        oshiLevel: Value(oshiLevel),
        moodTags: Value(jsonEncode(moodTags)),
        moodColor: Value(moodColor),
        detailJson: Value(jsonEncode(draft.detail?.toJson() ?? {})),
        lat: Value(draft.lat),
        lng: Value(draft.lng),
        placeName: Value(draft.placeName),
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }

  /// Beamで受け取ったカードを保存(source=beam)+交換履歴を記録
  Future<String> saveBeamCard(BeamCard card) async {
    final id = _uuid.v4();
    final thumbPath = await _importThumb(
      id: id,
      thumbUrl: card.thumbUrl,
      localImagePath: null,
    );

    await _db.upsertItem(
      CultureItemsCompanion.insert(
        id: id,
        category: card.category,
        title: card.title,
        subtitle: Value(card.subtitle),
        thumbPath: Value(thumbPath),
        thumbUrl: Value(card.thumbUrl),
        externalId: Value(card.externalId),
        url: Value(card.url),
        oshiLevel: Value(card.oshiLevel),
        moodTags: Value(jsonEncode(card.moodTags)),
        moodColor: Value(card.moodColor),
        source: const Value(CardSource.beam),
        beamFrom: Value(card.senderName),
        beamFromColor: Value(card.senderColor),
        createdAt: DateTime.now(),
      ),
    );
    await _db.insertBeam(
      BeamsCompanion.insert(
        id: _uuid.v4(),
        direction: BeamDirection.received,
        peerName: card.senderName,
        peerColor: Value(card.senderColor),
        cardId: id,
        beamedAt: DateTime.now(),
      ),
    );
    return id;
  }

  Future<void> recordSentBeam({
    required String peerName,
    String? peerColor,
    required String cardId,
  }) {
    return _db.insertBeam(
      BeamsCompanion.insert(
        id: _uuid.v4(),
        direction: BeamDirection.sent,
        peerName: peerName,
        peerColor: Value(peerColor),
        cardId: cardId,
        beamedAt: DateTime.now(),
      ),
    );
  }

  /// ピン留めのON/OFF。ONのときは末尾の順序で追加する
  Future<void> togglePinned(CultureItem item) async {
    if (item.pinnedOrder != null) {
      await _db.setPinnedOrder(item.id, null);
    } else {
      final max = await _db.maxPinnedOrder();
      await _db.setPinnedOrder(item.id, max + 1);
    }
  }

  /// ピン留めカードの並べ替え結果を保存する
  Future<void> reorderPinned(List<CultureItem> orderedPinned) async {
    for (final (i, item) in orderedPinned.indexed) {
      await _db.setPinnedOrder(item.id, i + 1);
    }
  }

  Future<void> toggleFavorite(CultureItem item) {
    return _db.upsertItem(
      item.toCompanion(false).copyWith(isFavorite: Value(!item.isFavorite)),
    );
  }

  Future<void> deleteItem(CultureItem item) async {
    await _db.deleteItem(item.id);
    final path = item.thumbPath;
    if (path != null) {
      final file = File('${_documentsDir.path}/$path');
      if (await file.exists()) await file.delete();
    }
  }

  /// サムネの取り込み。ローカル画像はコピー、URLはダウンロード。
  /// 失敗しても保存自体は続行する(表示はthumbUrl/プレースホルダで賄う)。
  Future<String?> _importThumb({
    required String id,
    required String? localImagePath,
    required String? thumbUrl,
  }) async {
    try {
      final dir = await _thumbsDir();
      if (localImagePath != null) {
        final ext = localImagePath.split('.').last.toLowerCase();
        final safeExt =
            const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(ext)
            ? ext
            : 'jpg';
        final dest = '${dir.path}/$id.$safeExt';
        await File(localImagePath).copy(dest);
        return 'thumbs/$id.$safeExt';
      }
      if (thumbUrl != null) {
        final res = await _client.get(Uri.parse(thumbUrl));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          final dest = '${dir.path}/$id.img';
          await File(dest).writeAsBytes(res.bodyBytes);
          return 'thumbs/$id.img';
        }
      }
    } catch (_) {
      // ネットワーク断などは無視してURL表示にフォールバック
    }
    return null;
  }

  /// 相対thumbPath → 絶対パス
  String resolveThumb(String relativePath) =>
      '${_documentsDir.path}/$relativePath';
}
