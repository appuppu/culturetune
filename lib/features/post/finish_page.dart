import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/post_draft.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/candy_button.dart';

/// 全カテゴリ共通の仕上げ画面。気分カラー・メモを入力して保存。
class FinishPage extends ConsumerStatefulWidget {
  const FinishPage({super.key, required this.draft});

  final PostDraft draft;

  @override
  ConsumerState<FinishPage> createState() => _FinishPageState();
}

class _FinishPageState extends ConsumerState<FinishPage> {
  late Color _moodColor = widget.draft.category.color;
  final _memoController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  String get _moodColorHex =>
      '#${(_moodColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(itemRepositoryProvider)
          .saveDraft(
            widget.draft,
            oshiLevel: 3,
            moodTags: const [],
            moodColor: _moodColorHex,
            memo: _memoController.text,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      // 登録動線(入力ページ+仕上げ)の2枚だけ閉じて、開始した画面に戻る
      var popped = 0;
      Navigator.of(context).popUntil((_) => popped++ >= 2);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('カードを追加したよ')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      appBar: AppBar(title: const Text('仕上げ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreviewCard(draft: draft, borderColor: _moodColor),
            const SizedBox(height: 24),
            const _SectionLabel('気分カラー'),
            Row(
              children: [
                for (final color in CTColors.moodPalette)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _moodColor = color);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _moodColor == color
                              ? CTColors.textMain
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionLabel('一言メモ'),
            TextField(
              controller: _memoController,
              maxLength: 140,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '推しポイントをひとこと…',
                filled: true,
                fillColor: CTColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CTRadius.card),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CandyButton(
              label: _saving ? '保存中…' : 'コレクションに追加',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        color: CTColors.textSub,
        fontSize: 13,
      ),
    ),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.draft, required this.borderColor});

  final PostDraft draft;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CTColors.surface,
        borderRadius: BorderRadius.circular(CTRadius.card),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: ctCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(CTRadius.inner(CTRadius.card, 2.5)),
            ),
            child: SizedBox(width: 88, height: 88, child: _thumb()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    draft.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (draft.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      draft.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: CTColors.textSub, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _thumb() {
    if (draft.localImagePath != null) {
      return Image.file(File(draft.localImagePath!), fit: BoxFit.cover);
    }
    if (draft.thumbUrl != null) {
      return CachedNetworkImage(imageUrl: draft.thumbUrl!, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: draft.category.color.withValues(alpha: 0.25),
      child: Center(
        child: Icon(draft.category.icon, size: 32, color: draft.category.color),
      ),
    );
  }
}
