import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/culture_category.dart';
import '../models/page_element_type.dart';
import '../models/sticker_texture.dart';

part 'app_database.g.dart';

/// 保存カード本体。カテゴリ固有の情報は detailJson に持つ。
class CultureItems extends Table {
  TextColumn get id => text()(); // UUID v4
  TextColumn get category => textEnum<CultureCategory>()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()(); // 著者/チャンネル/店名など
  TextColumn get thumbPath => text().nullable()(); // ローカル画像の相対パス
  TextColumn get thumbUrl => text().nullable()(); // 元画像URL(交換時の再取得用)
  TextColumn get externalId =>
      text().nullable()(); // itunes:id / ISBN / videoId
  TextColumn get url => text().nullable()();
  TextColumn get memo => text().nullable()(); // 一言メモ 140字
  IntColumn get oshiLevel => integer().withDefault(const Constant(3))(); // 1..5
  TextColumn get moodTags =>
      text().withDefault(const Constant('[]'))(); // JSON配列
  TextColumn get moodColor => text().nullable()(); // カード縁色 hex
  TextColumn get detailJson => text().withDefault(const Constant('{}'))();
  RealColumn get lat => real().nullable()(); // food/iOSのみ
  RealColumn get lng => real().nullable()();
  TextColumn get placeName => text().nullable()();
  TextColumn get source =>
      textEnum<CardSource>().withDefault(Constant(CardSource.self.name))();
  TextColumn get beamFrom => text().nullable()(); // 交換相手の表示名
  TextColumn get beamFromColor => text().nullable()(); // 相手のアバターカラー(hex)
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get pinnedOrder => integer().nullable()(); // ピン留め順(nullなら未ピン)
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get consumedAt => dateTime().nullable()(); // 観た/読んだ/食べた日

  @override
  Set<Column> get primaryKey => {id};
}

/// シール(切り抜き+加工済みの透過PNG素材)
class Stickers extends Table {
  TextColumn get id => text()(); // UUID v4
  TextColumn get imagePath => text()(); // stickers/xxx.png (相対パス)
  TextColumn get texture => textEnum<StickerTexture>().withDefault(
    Constant(StickerTexture.normal.name),
  )();
  TextColumn get creatorName => text()(); // 作成者クレジット
  TextColumn get creatorColor => text().nullable()(); // 作成者のアバターカラー
  TextColumn get source =>
      textEnum<CardSource>().withDefault(Constant(CardSource.self.name))();
  TextColumn get linkedItemId => text().nullable()(); // 紐付けたカルチャーカードのid
  TextColumn get audioPath => text().nullable()(); // ボイス(相対パス)
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// シール帳のページ(デコキャンバス)
class StickerPages extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get bgColor => text().nullable()(); // hex(#FFF7F9)
  TextColumn get bgImagePath => text().nullable()(); // 背景写真(相対パス)
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ページ上に貼られた要素(シール / カード / テキスト)
class PageElements extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text()();
  TextColumn get type => textEnum<PageElementType>().withDefault(
    Constant(PageElementType.sticker.name),
  )();
  TextColumn get refId => text().nullable()(); // stickerId or cultureItemId
  TextColumn get payload =>
      text().withDefault(const Constant('{}'))(); // text要素の内容など
  RealColumn get x => real()(); // キャンバス幅に対する相対位置 0..1(中心)
  RealColumn get y => real()();
  RealColumn get scale => real().withDefault(const Constant(1))();
  RealColumn get rotation => real().withDefault(const Constant(0))(); // radian
  IntColumn get z => integer().withDefault(const Constant(0))(); // 重なり順

  @override
  Set<Column> get primaryKey => {id};
}

/// Beam交換の履歴
class Beams extends Table {
  TextColumn get id => text()();
  TextColumn get direction => textEnum<BeamDirection>()();
  TextColumn get peerName => text()();
  TextColumn get peerColor => text().nullable()(); // 相手のアバターカラー(hex)
  TextColumn get cardId => text()();
  DateTimeColumn get beamedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [CultureItems, Beams, Stickers, StickerPages, PageElements],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(cultureItems, cultureItems.beamFromColor);
        await m.addColumn(cultureItems, cultureItems.pinnedOrder);
      }
      if (from < 3) {
        await m.createTable(stickers);
        await m.createTable(stickerPages);
      }
      if (from < 5 && from >= 3) {
        await m.addColumn(stickers, stickers.audioPath);
      }
      if (from < 4) {
        await m.createTable(pageElements);
        if (from >= 3) {
          // 旧page_stickersからシール要素として移行
          await customStatement('''
            INSERT INTO page_elements
              (id, page_id, type, ref_id, payload, x, y, scale, rotation, z)
            SELECT id, page_id, 'sticker', sticker_id, '{}', x, y, scale,
              rotation, z
            FROM page_stickers
          ''');
          await customStatement('DROP TABLE page_stickers');
        }
      }
    },
  );

  static QueryExecutor _open() => driftDatabase(name: 'culture_tune');

  /// 棚の一覧(ピン留め順→新着順)。categoryを渡すと絞り込み。
  Stream<List<CultureItem>> watchItems({CultureCategory? category}) {
    final query = select(cultureItems)
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.pinnedOrder.isNotNull(),
          mode: OrderingMode.desc,
        ),
        (t) => OrderingTerm.asc(t.pinnedOrder),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    if (category != null) {
      query.where((t) => t.category.equalsValue(category));
    }
    return query.watch();
  }

  /// ピン留めの最大順序(新規ピンは末尾に付ける)
  Future<int> maxPinnedOrder() async {
    final max = cultureItems.pinnedOrder.max();
    final row = await (selectOnly(cultureItems)..addColumns([max])).getSingle();
    return row.read(max) ?? 0;
  }

  Future<void> setPinnedOrder(String id, int? order) {
    return (update(cultureItems)..where((t) => t.id.equals(id))).write(
      CultureItemsCompanion(pinnedOrder: Value(order)),
    );
  }

  Future<CultureItem?> findItem(String id) =>
      (select(cultureItems)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertItem(CultureItemsCompanion entry) =>
      into(cultureItems).insertOnConflictUpdate(entry);

  Future<void> deleteItem(String id) =>
      (delete(cultureItems)..where((t) => t.id.equals(id))).go();

  Future<void> insertBeam(BeamsCompanion entry) => into(beams).insert(entry);

  Stream<List<Beam>> watchBeams() =>
      (select(beams)..orderBy([(t) => OrderingTerm.desc(t.beamedAt)])).watch();

  // ---- シール ----

  Stream<List<Sticker>> watchStickers() => (select(
    stickers,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<Sticker?> findSticker(String id) =>
      (select(stickers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertSticker(StickersCompanion entry) =>
      into(stickers).insert(entry);

  Future<void> deleteSticker(String id) async {
    await (delete(pageElements)..where((t) => t.refId.equals(id))).go();
    await (delete(stickers)..where((t) => t.id.equals(id))).go();
  }

  // ---- ページ ----

  Stream<List<StickerPage>> watchPages() => (select(
    stickerPages,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<void> upsertPage(StickerPagesCompanion entry) =>
      into(stickerPages).insertOnConflictUpdate(entry);

  Future<void> deletePage(String id) async {
    await (delete(pageElements)..where((t) => t.pageId.equals(id))).go();
    await (delete(stickerPages)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<PageElement>> watchPageElements(String pageId) =>
      (select(pageElements)
            ..where((t) => t.pageId.equals(pageId))
            ..orderBy([(t) => OrderingTerm.asc(t.z)]))
          .watch();

  Future<List<PageElement>> getPageElements(String pageId) =>
      (select(pageElements)
            ..where((t) => t.pageId.equals(pageId))
            ..orderBy([(t) => OrderingTerm.asc(t.z)]))
          .get();

  Future<void> upsertPageElement(PageElementsCompanion entry) =>
      into(pageElements).insertOnConflictUpdate(entry);

  Future<void> deletePageElement(String id) =>
      (delete(pageElements)..where((t) => t.id.equals(id))).go();

  Future<void> touchPage(String pageId) =>
      (update(stickerPages)..where((t) => t.id.equals(pageId))).write(
        StickerPagesCompanion(updatedAt: Value(DateTime.now())),
      );
}
