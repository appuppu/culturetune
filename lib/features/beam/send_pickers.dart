import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/theme/tokens.dart';
import '../book/pages_page.dart';
import '../palette/sticker_exchange.dart';

/// シールを選んで共有シートで送る(交換タブ)
Future<void> pickAndSendSticker(BuildContext context, WidgetRef ref) async {
  final selected = await pickStickerForSend(context, ref);
  if (selected == null || !context.mounted) return;
  await shareStickerWithMeta(ref, selected);
}

/// シール帳を選んで共有シートで送る(交換タブ)
Future<void> pickAndSendPage(BuildContext context, WidgetRef ref) async {
  final selected = await pickPageForSend(context, ref);
  if (selected == null || !context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('シール帳を画像にしてるよ…')));
  await sharePageWithMeta(ref, selected);
}

/// シールを1つ選ぶ(選ぶだけ。送り方は呼び出し側が決める)
Future<Sticker?> pickStickerForSend(BuildContext context, WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final stickers = await db.watchStickers().first;
  if (!context.mounted) return null;
  if (stickers.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('まずシールタブでシールをつくってね')));
    return null;
  }
  final repo = ref.read(stickerRepositoryProvider);
  return showModalBottomSheet<Sticker>(
    context: context,
    backgroundColor: CTColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: 320,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: stickers.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => Navigator.pop(sheetContext, stickers[i]),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CTColors.surface,
                borderRadius: BorderRadius.circular(CTRadius.card),
              ),
              child: Image.file(
                File(repo.resolve(stickers[i].imagePath)),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// シール帳を1冊選ぶ(選ぶだけ)
Future<StickerPage?> pickPageForSend(
  BuildContext context,
  WidgetRef ref,
) async {
  final db = ref.read(databaseProvider);
  final pages = await db.watchPages().first;
  if (!context.mounted) return null;
  if (pages.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('まずシール帳をつくってね')));
    return null;
  }
  return showModalBottomSheet<StickerPage>(
    context: context,
    backgroundColor: CTColors.bgBase,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.72,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'どのシール帳を送る?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 9 / 16,
                ),
                itemCount: pages.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => Navigator.pop(sheetContext, pages[i]),
                  child: PageCanvas(page: pages[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
