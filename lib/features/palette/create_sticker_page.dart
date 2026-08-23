import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/models/culture_category.dart';
import '../../core/models/sticker_texture.dart';
import '../../core/stickers/cutout_service.dart';
import '../../core/stickers/sticker_factory.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/candy_button.dart';
import '../../core/widgets/sticker_image.dart';
import '../../core/widgets/thumb_image.dart';
import '../beam/beam_profile_provider.dart';

/// シール作成: 写真選択 → 自動切り抜き → 質感選択 → カルチャー紐付け → 保存
class CreateStickerPage extends ConsumerStatefulWidget {
  const CreateStickerPage({super.key});

  @override
  ConsumerState<CreateStickerPage> createState() => _CreateStickerPageState();
}

class _CreateStickerPageState extends ConsumerState<CreateStickerPage> {
  String? _photoPath; // 元写真
  String? _cutoutPath; // 切り抜き済み透過PNG(null=切り抜き不可)
  bool _cutoutTried = false;
  StickerTexture _texture = StickerTexture.normal;
  Color _borderColor = Colors.white;

  /// (質感+枠色)ごとのプレビューキャッシュ(一時ファイルパス)
  final Map<String, String> _previewCache = {};

  String get _cacheKey =>
      '${_texture.name}_${_borderColor.toARGB32().toRadixString(16)}';
  bool _processing = false;
  bool _saving = false;
  CultureItem? _linkedItem;

  // ボイス録音
  final _recorder = AudioRecorder();
  final _previewPlayer = AudioPlayer();
  String? _audioPath;
  bool _recording = false;
  Timer? _recordLimit;

  @override
  void dispose() {
    _recordLimit?.cancel();
    _recorder.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      _recordLimit?.cancel();
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _audioPath = path;
      });
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('マイクの許可が必要だよ')));
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000),
      path: '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _recording = true);
    // 最大15秒で自動停止
    _recordLimit = Timer(const Duration(seconds: 15), () {
      if (_recording) _toggleRecord();
    });
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 92,
    );
    if (file == null || !mounted) return;
    setState(() {
      _photoPath = file.path;
      _cutoutPath = null;
      _cutoutTried = false;
      _previewCache.clear();
      _processing = true;
    });
    // 被写体切り抜き(不可ならnullのまま=角丸フォールバック)
    final cutout = await CutoutService.cutoutSubject(file.path);
    if (!mounted) return;
    setState(() {
      _cutoutPath = cutout;
      _cutoutTried = true;
    });
    await _process();
  }

  Future<void> _process() async {
    final photo = _photoPath;
    if (photo == null) return;
    if (_previewCache.containsKey(_cacheKey)) {
      setState(() => _processing = false);
      return;
    }
    setState(() => _processing = true);
    try {
      final bytes = await StickerFactory.makeSticker(
        sourcePath: _cutoutPath ?? photo,
        texture: _texture,
        isCutout: _cutoutPath != null,
        borderColor: _borderColor,
      );
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/sticker_preview_${_cacheKey}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      setState(() => _previewCache[_cacheKey] = file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加工に失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _pickLinkedItem() async {
    final items = await ref.read(databaseProvider).watchItems().first;
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('カードタブから先にカルチャーを登録してね')));
      return;
    }
    final selected = await showModalBottomSheet<CultureItem>(
      context: context,
      backgroundColor: CTColors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CTRadius.sheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'どのカルチャーを埋め込む?',
                style: TextStyle(fontWeight: FontWeight.w800),
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
    if (selected != null && mounted) {
      setState(() => _linkedItem = selected);
    }
  }

  Future<void> _save() async {
    final preview = _previewCache[_cacheKey];
    if (preview == null || _saving) return;
    setState(() => _saving = true);
    try {
      final profile = await ref.read(beamProfileProvider.future);
      final bytes = await File(preview).readAsBytes();
      await ref
          .read(stickerRepositoryProvider)
          .importProcessed(
            pngBytes: Uint8List.fromList(bytes),
            texture: _texture,
            creatorName: profile.name,
            creatorColor: profile.colorHex,
            linkedItemId: _linkedItem?.id,
            source: CardSource.self,
            audioBytes: _audioPath != null
                ? await File(_audioPath!).readAsBytes()
                : null,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('シールをパレットに追加したよ')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewCache[_cacheKey];

    return Scaffold(
      appBar: AppBar(title: const Text('シールをつくる')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // プレビューエリア
            GestureDetector(
              onTap: _photoPath == null ? () => _showPickSheet() : null,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: CTColors.surface,
                  borderRadius: BorderRadius.circular(CTRadius.card),
                  boxShadow: ctCardShadow,
                ),
                child: preview != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: StickerImage(path: preview, texture: _texture),
                      )
                    : Center(
                        child: _processing
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_fix_high_rounded,
                                    size: 44,
                                    color: CTColors.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '写真を選ぶと自動でシールになるよ',
                                    style: TextStyle(color: CTColors.textSub),
                                  ),
                                ],
                              ),
                      ),
              ),
            ),
            if (_photoPath != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_cutoutTried && _cutoutPath == null)
                    Text(
                      '被写体を切り抜けなかったので角丸シールにしたよ',
                      style: TextStyle(fontSize: 11, color: CTColors.textSub),
                    ),
                  TextButton.icon(
                    onPressed: () => _showPickSheet(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('写真を選び直す'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // 質感選択
            Text(
              '質感',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: CTColors.textSub,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final t in StickerTexture.values)
                  Expanded(
                    child: GestureDetector(
                      onTap: _photoPath == null
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() => _texture = t);
                              _process();
                            },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _texture == t
                              ? CTColors.primary.withValues(alpha: 0.15)
                              : CTColors.surface,
                          borderRadius: BorderRadius.circular(CTRadius.card),
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
                              size: 20,
                              color: _texture == t
                                  ? CTColors.primary
                                  : CTColors.textSub,
                            ),
                            const SizedBox(height: 4),
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
            const SizedBox(height: 16),
            // 枠色(カードの気分カラーと同じパレット)
            Text(
              'フチの色',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: CTColors.textSub,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final color in [Colors.white, ...CTColors.moodPalette])
                  GestureDetector(
                    onTap: _photoPath == null
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _borderColor = color);
                            _process();
                          },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 30,
                      height: 30,
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
            const SizedBox(height: 16),
            // ボイス(タップで鳴るシールになる)
            Text(
              'ボイス(任意・タップすると鳴るシールになる)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: CTColors.textSub,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _recording
                        ? Colors.redAccent
                        : CTColors.primary,
                  ),
                  onPressed: _photoPath == null ? null : _toggleRecord,
                  icon: Icon(
                    _recording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 18,
                  ),
                  label: Text(_recording ? '停止(最大15秒)' : '録音する'),
                ),
                const SizedBox(width: 8),
                if (_audioPath != null && !_recording) ...[
                  IconButton(
                    onPressed: () async {
                      await _previewPlayer.stop();
                      await _previewPlayer.play(DeviceFileSource(_audioPath!));
                    },
                    icon: Icon(
                      Icons.play_circle_fill_rounded,
                      color: CTColors.primary,
                      size: 28,
                    ),
                    tooltip: '試聴',
                  ),
                  IconButton(
                    onPressed: () => setState(() => _audioPath = null),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: CTColors.textSub,
                      size: 22,
                    ),
                    tooltip: 'ボイスを消す',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // カルチャー紐付け
            Text(
              'カルチャーを埋め込む(任意)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: CTColors.textSub,
              ),
            ),
            const SizedBox(height: 8),
            if (_linkedItem != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _linkedItem!.category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(CTRadius.card),
                ),
                child: Row(
                  children: [
                    Icon(
                      _linkedItem!.category.icon,
                      size: 18,
                      color: _linkedItem!.category.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _linkedItem!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _linkedItem = null),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickLinkedItem,
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('カードから選ぶ(タップで再生/マップが開くようになる)'),
              ),
            const SizedBox(height: 20),
            CandyButton(
              label: _saving ? '保存中…' : 'パレットに追加',
              onPressed: preview == null || _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  void _showPickSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CTRadius.sheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('カメラで撮る'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('ライブラリから選ぶ(自撮り・推し・イラスト何でも)'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
