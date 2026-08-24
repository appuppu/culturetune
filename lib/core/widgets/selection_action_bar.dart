import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 一括選択モードの下部アクションバー(シール/カードの一括削除で共用)
class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({
    super.key,
    required this.count,
    required this.onDelete,
    required this.onClose,
  });

  final int count;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: CTColors.surface,
        borderRadius: BorderRadius.circular(CTRadius.pill),
        boxShadow: ctCardShadow,
        border: Border.all(color: CTColors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count == 0 ? 'タップして選ぶ' : '$count個選択中',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: count == 0 ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('削除'),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: '選択をやめる',
          ),
        ],
      ),
    );
  }
}
