import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/tokens.dart';

/// メッセージ(寄せ書き・交換日記の書き込み)をメモ紙風のPNGにする。
/// 改行つき・5行程度のメッセージカードを想定。
/// 生成した画像はそのままシール加工パイプラインに流せる。
Future<String> renderMessageNote({
  required String text,
  required Color bg,
}) async {
  const width = 760.0;
  const pad = 60.0;
  final dark = bg.computeLuminance() > 0.55;
  final textColor = dark ? const Color(0xFF33272A) : Colors.white;

  // 文字量に合わせてフォントを縮めていく(最大52・最小24)
  TextPainter painter;
  var fontSize = 52.0;
  while (true) {
    painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - pad * 2);
    if (painter.height <= 900 || fontSize <= 24) break;
    fontSize -= 4;
  }

  final height = (painter.height + pad * 2 + 30).clamp(300.0, 1060.0);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, width, height);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(44)),
    Paint()..color = bg,
  );
  // メモ紙らしさ: 上端にうっすら濃い帯(テープ風)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(width / 2 - 90, 26, 180, 26),
      const Radius.circular(13),
    ),
    Paint()..color = textColor.withValues(alpha: 0.14),
  );
  painter.paint(
    canvas,
    Offset((width - painter.width) / 2, (height - painter.height) / 2 + 10),
  );

  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/note_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  return file.path;
}

/// メッセージカードの入力ダイアログ(本文+メモ紙の色)。
/// シール作成画面とシール帳エディタの両方から使う。
Future<(String, Color)?> showMessageNoteDialog(BuildContext context) {
  return showDialog<(String, Color)>(
    context: context,
    builder: (dialogContext) => const MessageNoteDialog(),
  );
}

class MessageNoteDialog extends StatefulWidget {
  const MessageNoteDialog({super.key});

  @override
  State<MessageNoteDialog> createState() => _MessageNoteDialogState();
}

class _MessageNoteDialogState extends State<MessageNoteDialog> {
  final _controller = TextEditingController();
  Color _bg = Colors.white;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CTColors.bgBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CTRadius.sheet),
      ),
      title: const Text('メッセージカード', style: TextStyle(fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 150,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'メッセージをかいてね\n(改行もつかえるよ)',
                filled: true,
                fillColor: CTColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CTRadius.card),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final color in [Colors.white, ...CTColors.moodPalette])
                  GestureDetector(
                    onTap: () => setState(() => _bg = color),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _bg == color
                              ? CTColors.textMain
                              : CTColors.textSub.withValues(alpha: 0.25),
                          width: _bg == color ? 2.5 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('やめる'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, (_controller.text.trim(), _bg)),
          child: const Text('カードにする'),
        ),
      ],
    );
  }
}
