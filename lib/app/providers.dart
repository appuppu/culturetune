import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/book_repository.dart';
import '../core/api/link_preview_service.dart';
import '../core/data/item_repository.dart';
import '../core/db/app_database.dart';
import '../core/models/culture_category.dart';
import '../core/stickers/sticker_repository.dart';

/// main()でgetApplicationDocumentsDirectory()の値にoverrideされる
final documentsDirProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('main()でoverrideすること'),
);

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(
    ref.watch(databaseProvider),
    ref.watch(documentsDirProvider),
  );
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final bookRepositoryProvider = Provider((ref) => BookRepository());
final linkPreviewServiceProvider = Provider((ref) => LinkPreviewService());

/// Vaultで選択中のカテゴリ(null = All)
final vaultCategoryProvider = StateProvider<CultureCategory?>((ref) => null);

final vaultItemsProvider = StreamProvider.autoDispose((ref) {
  final db = ref.watch(databaseProvider);
  final category = ref.watch(vaultCategoryProvider);
  return db.watchItems(category: category);
});

/// フィルタ無しの全カード(Wrap集計などに使う)
final allItemsProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(databaseProvider).watchItems();
});

final stickerRepositoryProvider = Provider<StickerRepository>((ref) {
  return StickerRepository(
    ref.watch(databaseProvider),
    ref.watch(documentsDirProvider),
  );
});

/// マイシールパレット(新着順)
final stickersProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(databaseProvider).watchStickers();
});

/// シール帳のページ一覧(更新順)
final stickerPagesProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(databaseProvider).watchPages();
});
