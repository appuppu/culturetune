import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/sticker_texture.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/candy_button.dart';
import '../beam/beam_profile_provider.dart';

/// 複数の写真をまとめてシールにする(旅行のご飯写真などを一気に)。
/// 質感とフチ色は全枚数に共通で適用する。
class BatchCreatePage extends ConsumerStatefulWidget {
  const BatchCreatePage({super.key, required this.photoPaths});

  final List<String> photoPaths;

  @override
  ConsumerState<BatchCreatePage> createState() => _BatchCreatePageState();
}

class _BatchCreatePageState extends ConsumerState<BatchCreatePage> {
  StickerTexture _texture = StickerTexture.normal;
  Color _borderColor = Colors.white;
  bool _running = false;
  int _done = 0;

  Future<void> _run() async {
    if (_running) return;
    setState(() => _running = true);
    final repo = ref.read(stickerRepositoryProvider);
    final profile = await ref.read(beamProfileProvider.future);
    for (final path in widget.photoPaths) {
      await repo.createFromPhoto(
        photoPath: path,
        texture: _texture,
        creatorName: profile.name,
        creatorColor: profile.colorHex,
        borderColor: _borderColor,
      );
      if (!mounted) return;
      setState(() => _done++);
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.photoPaths.length}枚のシールをパレットに追加したよ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photoPaths.length;

    return Scaffold(
      appBar: AppBar(title: Text('まとめてシールにする($total枚)')),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: total,
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(CTRadius.card),
                child: Image.file(
                  File(widget.photoPaths[i]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (final t in StickerTexture.values)
                        Expanded(
                          child: GestureDetector(
                            onTap: _running
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _texture = t);
                                  },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _texture == t
                                    ? CTColors.primary.withValues(alpha: 0.15)
                                    : CTColors.surface,
                                borderRadius: BorderRadius.circular(
                                  CTRadius.card,
                                ),
                                border: Border.all(
                                  color: _texture == t
                                      ? CTColors.primary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    t.icon,
                                    size: 18,
                                    color: _texture == t
                                        ? CTColors.primary
                                        : CTColors.textSub,
                                  ),
                                  Text(
                                    t.labelJa,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final color in [
                        Colors.white,
                        ...CTColors.moodPalette,
                      ])
                        GestureDetector(
                          onTap: _running
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _borderColor = color);
                                },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _borderColor == color
                                    ? CTColors.textMain
                                    : CTColors.textSub.withValues(alpha: 0.25),
                                width: _borderColor == color ? 2.5 : 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1枚ずつ自動で切り抜くよ。カードの埋め込みはあとからシール詳細で追加できるよ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: CTColors.textSub),
                  ),
                  const SizedBox(height: 10),
                  if (_running) ...[
                    LinearProgressIndicator(
                      value: total == 0 ? null : _done / total,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'シール化中… $_done / $total',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: CTColors.textSub),
                    ),
                    const SizedBox(height: 10),
                  ],
                  CandyButton(
                    label: _running ? '作成中…' : '$total枚まとめてシールにする',
                    onPressed: _running ? null : _run,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
