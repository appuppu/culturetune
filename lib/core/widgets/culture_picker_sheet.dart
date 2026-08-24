import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../theme/tokens.dart';
import 'thumb_image.dart';

/// カード(カルチャー)を1つ選ぶ共有シート。
/// シール作成時の埋め込みと、作成済みシールへの後付けの両方で使う。
Future<CultureItem?> showCulturePickerSheet(
  BuildContext context,
  AppDatabase db, {
  String title = 'どのカードにする?',
}) async {
  final items = await db.watchItems().first;
  if (!context.mounted) return null;
  if (items.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('シールタブの「カード」から先にカードをつくってね')));
    return null;
  }
  return showModalBottomSheet<CultureItem>(
    context: context,
    backgroundColor: CTColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ThumbImage(item: item),
                    ),
                  ),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(item.category.labelJa),
                  onTap: () => Navigator.pop(sheetContext, item),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
