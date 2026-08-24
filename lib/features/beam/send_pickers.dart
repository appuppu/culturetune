import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/theme/tokens.dart';
import '../book/pages_page.dart';

/// シールを複数選ぶ(最大[max]枚)。空/キャンセルはnull
Future<List<Sticker>?> pickStickersForSend(
  BuildContext context,
  WidgetRef ref, {
  int max = 10,
}) async {
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
  final selected = <String>{};
  return showModalBottomSheet<List<Sticker>>(
    context: context,
    backgroundColor: CTColors.bgBase,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  selected.isEmpty
                      ? 'わたすシールを選んでね(最大$max枚)'
                      : '${selected.length}枚えらんだよ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: stickers.length,
                  itemBuilder: (_, i) {
                    final sticker = stickers[i];
                    final isOn = selected.contains(sticker.id);
                    return GestureDetector(
                      onTap: () => setSheetState(() {
                        if (isOn) {
                          selected.remove(sticker.id);
                        } else if (selected.length < max) {
                          selected.add(sticker.id);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: CTColors.surface,
                          borderRadius: BorderRadius.circular(CTRadius.card),
                          border: Border.all(
                            color: isOn ? CTColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Image.file(
                                File(repo.resolve(sticker.imagePath)),
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (isOn)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: CTColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(sheetContext, [
                            for (final s in stickers)
                              if (selected.contains(s.id)) s,
                          ]),
                    child: Text(
                      selected.isEmpty ? 'えらんでね' : '${selected.length}枚をわたす',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
