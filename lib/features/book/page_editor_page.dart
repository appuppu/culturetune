import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/files/doc_paths.dart';
import '../../core/models/page_element_type.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/border_color_sheet.dart';
import '../../core/widgets/thumb_image.dart';
import '../palette/create_sticker_page.dart';
import '../post/post_flow.dart';
import 'element_view.dart';
import 'page_models.dart';

/// デコキャンバス(9:16 ストーリーサイズ)。
/// シール・カード・テキストをドラッグ/ピンチ/回転で自由配置する。
class PageEditorPage extends ConsumerStatefulWidget {
  const PageEditorPage({
    super.key,
    required this.page,
    this.startEditing = false,
  });

  final StickerPage page;

  /// 新規作成時はtrue(いきなり編集)。一覧から開いたときは閲覧モード
  final bool startEditing;

  @override
  ConsumerState<PageEditorPage> createState() => _PageEditorPageState();
}

class _PageEditorPageState extends ConsumerState<PageEditorPage> {
  final _canvasKey = GlobalKey();
  final _uuid = const Uuid();

  List<ResolvedElement> _elements = [];
  String? _selectedId;
  late bool _editing = widget.startEditing;
  bool _loaded = false;
  bool _exporting = false;
  late String _title = widget.page.title;
  late String? _bgColorHex = widget.page.bgColor;
  late String? _bgImagePath = widget.page.bgImagePath;
  late String? _pageBorderHex = widget.page.borderColor;
  late bool _showTitle = widget.page.showTitle;

  double _startScale = 1;
  double _startRotation = 0;

  // ドラッグ中のゴミ箱(要素をここへ運んで離すとはがれる)
  bool _dragging = false;
  bool _overTrash = false;

  // キャンバス全体ピンチ(選択要素の拡大縮小の救済用)
  bool _canvasPinch = false;

  /// ゴミ箱の相対位置(キャンバス下中央)と判定
  static const _trashX = 0.5;
  static const _trashY = 0.9;

  bool _isOverTrash(double x, double y, double w, double h) {
    final dx = (x - _trashX) * w;
    final dy = (y - _trashY) * h;
    return dx * dx + dy * dy < 48 * 48;
  }

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final elements = await loadResolvedElements(_db, widget.page.id);

    if (!mounted) return;
    setState(() {
      _elements = elements..sort((a, b) => a.element.z.compareTo(b.element.z));
      _loaded = true;
    });
  }

  Future<void> _persistElement(ResolvedElement r) async {
    final el = r.element;
    await _db.upsertPageElement(
      PageElementsCompanion.insert(
        id: el.id,
        pageId: widget.page.id,
        type: Value(el.type),
        refId: Value(el.refId),
        payload: Value(el.payload),
        x: el.x,
        y: el.y,
        scale: Value(el.scale),
        rotation: Value(el.rotation),
        z: Value(el.z),
      ),
    );
    await _db.touchPage(widget.page.id);
  }

  Future<void> _persistPage() async {
    await _db.upsertPage(
      StickerPagesCompanion.insert(
        id: widget.page.id,
        title: Value(_title),
        bgColor: Value(_bgColorHex),
        bgImagePath: Value(_bgImagePath),
        borderColor: Value(_pageBorderHex),
        showTitle: Value(_showTitle),
        createdAt: widget.page.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Color get _bgColor {
    final hex = _bgColorHex;
    if (hex == null || !hex.startsWith('#')) return CTColors.surface;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? CTColors.surface : Color(0xFF000000 | value);
  }

  Color? get _pageBorderColor {
    final hex = _pageBorderHex;
    if (hex == null || !hex.startsWith('#')) return null;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  ResolvedElement? get _selected {
    for (final r in _elements) {
      if (r.element.id == _selectedId) return r;
    }
    return null;
  }

  int get _maxZ => _elements.isEmpty
      ? 0
      : _elements.map((e) => e.element.z).reduce((a, b) => a > b ? a : b);

  Future<void> _addElement(ResolvedElement resolved) async {
    HapticFeedback.mediumImpact(); // ペタッ
    setState(() {
      _elements.add(resolved);
      _selectedId = resolved.element.id;
    });
    await _persistElement(resolved);
  }

  PageElement _newElement({
    required PageElementType type,
    String? refId,
    String payload = '{}',
  }) {
    return PageElement(
      id: _uuid.v4(),
      pageId: widget.page.id,
      type: type,
      refId: refId,
      payload: payload,
      x: 0.5,
      y: 0.45,
      scale: 1,
      rotation: 0,
      z: _maxZ + 1,
    );
  }

  /// プロフィールアイコンを貼る(任意・1ページ1つまで)
  Future<void> _addProfile() async {
    final existing = _elements
        .where((e) => e.type == PageElementType.profile)
        .toList();
    if (existing.isNotEmpty) {
      setState(() => _selectedId = existing.first.element.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールはもう貼ってあるよ(ダブルタップで形や色を変えられる)')),
      );
      return;
    }
    await _addElement(
      ResolvedElement(
        element: PageElement(
          id: _uuid.v4(),
          pageId: widget.page.id,
          type: PageElementType.profile,
          refId: null,
          payload: const ProfilePayload().toJson(),
          x: 0.84,
          y: 0.93,
          scale: 1,
          rotation: 0,
          z: _maxZ + 1,
        ),
      ),
    );
  }

  /// 選択中シールのフチ色を変える(素材があるシールのみ)
  Future<void> _recolorSelected() async {
    final r = _selected;
    final sticker = r?.sticker;
    if (sticker == null) return;
    if (sticker.rawPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('このシールは素材が無いのでフチ色を変えられないよ(もらったシール・古いシール)'),
        ),
      );
      return;
    }
    final color = await showBorderColorSheet(context);
    if (color == null || !mounted) return;
    final ok = await ref
        .read(stickerRepositoryProvider)
        .recolorBorder(sticker, color);
    if (ok && mounted) setState(() {});
  }

  /// シールを選んで貼る。1枚も無ければその場で作成→自動で貼る
  Future<void> _addSticker() async {
    var stickers = await _db.watchStickers().first;
    if (!mounted) return;
    if (stickers.isEmpty) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CreateStickerPage()));
      stickers = await _db.watchStickers().first;
      if (stickers.isEmpty || !mounted) return;
      // 作りたてのシールをそのままページにペタッ
      await _addElement(
        ResolvedElement(
          element: _newElement(
            type: PageElementType.sticker,
            refId: stickers.first.id,
          ),
          sticker: stickers.first,
        ),
      );
      return;
    }
    final repo = ref.read(stickerRepositoryProvider);
    final selected = await showModalBottomSheet<Sticker>(
      context: context,
      backgroundColor: CTColors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CTRadius.sheet),
        ),
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
    if (selected == null || !mounted) return;
    await _addElement(
      ResolvedElement(
        element: _newElement(type: PageElementType.sticker, refId: selected.id),
        sticker: selected,
      ),
    );
  }

  /// カルチャーカードを選んで貼る
  Future<void> _addCard() async {
    final items = await _db.watchItems().first;
    if (!mounted) return;
    if (items.isEmpty) {
      // その場で登録フローを開く(完了するとこの画面に戻ってくる)
      await showPostCategorySheet(context);
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
        child: SizedBox(
          height: 360,
          child: ListView.builder(
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
      ),
    );
    if (selected == null || !mounted) return;
    await _addElement(
      ResolvedElement(
        element: _newElement(type: PageElementType.card, refId: selected.id),
        item: selected,
      ),
    );
  }

  Future<void> _editTitle() async {
    final controller = TextEditingController(text: _title);
    var show = _showTitle;
    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('シール帳のタイトル'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 20,
                decoration: const InputDecoration(hintText: '例: 8月の推し記録'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('シール帳の上に表示', style: TextStyle(fontSize: 14)),
                value: show,
                onChanged: (v) => setDialogState(() => show = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, (controller.text, show)),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _title = result.$1.trim();
      _showTitle = result.$2;
    });
    await _persistPage();
  }

  Future<void> _removeSelected() async {
    final r = _selected;
    if (r == null) return;
    await _removeElement(r);
  }

  Future<void> _removeElement(ResolvedElement r) async {
    HapticFeedback.heavyImpact(); // ペリッ
    setState(() {
      _elements.removeWhere((e) => e.element.id == r.element.id);
      _selectedId = null;
    });
    await _db.deletePageElement(r.element.id);
    await _db.touchPage(widget.page.id);
    // パレットから削除済み(アーカイブ)のシールが不要になったら掃除
    await ref.read(stickerRepositoryProvider).cleanupArchived();
  }

  Future<void> _bringToFront() async {
    final r = _selected;
    if (r == null) return;
    setState(() {
      r.element = r.element.copyWith(z: _maxZ + 1);
      _elements.sort((a, b) => a.element.z.compareTo(b.element.z));
    });
    await _persistElement(r);
  }

  Future<void> _sendToBack() async {
    final r = _selected;
    if (r == null) return;
    final minZ = _elements
        .map((e) => e.element.z)
        .reduce((a, b) => a < b ? a : b);
    setState(() {
      r.element = r.element.copyWith(z: minZ - 1);
      _elements.sort((a, b) => a.element.z.compareTo(b.element.z));
    });
    await _persistElement(r);
  }

  Future<void> _pickBackground() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CTColors.bgBase,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CTRadius.sheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '背景色',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: CTColors.textSub,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final color in [
                      Colors.white,
                      const Color(0xFF1B1D22),
                      ...CTColors.moodPalette,
                    ])
                      GestureDetector(
                        onTap: () => Navigator.pop(
                          sheetContext,
                          'color:${_hexOf(color)}',
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CTColors.textSub.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'シール帳のフチ',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: CTColors.textSub,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // なし
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetContext, 'pborder:none'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CTColors.textSub.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.block_rounded,
                          size: 20,
                          color: CTColors.textSub,
                        ),
                      ),
                    ),
                    for (final color in [
                      Colors.white,
                      const Color(0xFF1B1D22),
                      ...CTColors.moodPalette,
                    ])
                      GestureDetector(
                        onTap: () => Navigator.pop(
                          sheetContext,
                          'pborder:${_hexOf(color)}',
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 7),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('写真から選ぶ(シール帳サイズに切り取り)'),
                  onTap: () => Navigator.pop(sheetContext, 'photo'),
                ),
                if (_bgImagePath != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.hide_image_rounded),
                    title: const Text('背景写真を外す'),
                    onTap: () => Navigator.pop(sheetContext, 'remove'),
                  ),
                const Divider(),
                const SizedBox(height: 6),
                Text(
                  'きせかえ',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: CTColors.textSub,
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder(
                  future: _presetBackgrounds(),
                  builder: (context, snapshot) {
                    final presets = snapshot.data ?? const <String>[];
                    if (presets.isEmpty) return const SizedBox.shrink();
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 9 / 16,
                          ),
                      itemCount: presets.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () =>
                            Navigator.pop(sheetContext, 'asset:${presets[i]}'),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(presets[i], fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action.startsWith('color:')) {
      setState(() => _bgColorHex = action.substring(6));
      await _persistPage();
      return;
    }
    if (action == 'remove') {
      final oldPath = _bgImagePath;
      setState(() => _bgImagePath = null);
      await _persistPage();
      if (oldPath != null) {
        final file = File(
          resolveDocFile(ref.read(documentsDirProvider), oldPath),
        );
        if (await file.exists()) await file.delete();
      }
      return;
    }
    if (action.startsWith('pborder:')) {
      final value = action.substring(8);
      setState(() => _pageBorderHex = value == 'none' ? null : value);
      await _persistPage();
      return;
    }
    if (action.startsWith('asset:')) {
      await _applyPresetBackground(action.substring(6));
      return;
    }
    // 写真から選ぶ → 9:16にクロップして背景に
    await _pickBackgroundPhoto();
  }

  /// assets/backgrounds/ 内の画像を列挙(足せば自動で選択肢に増える)
  Future<List<String>> _presetBackgrounds() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where((a) => a.startsWith('assets/backgrounds/'))
        .toList()
      ..sort();
  }

  /// プリセット背景を選択: ページ専用にコピーして通常の背景写真として扱う
  /// (交換・書き出し・バックアップが既存の仕組みのまま動く)
  Future<void> _applyPresetBackground(String assetKey) async {
    final bytes = await rootBundle.load(assetKey);
    if (!mounted) return;
    final docs = ref.read(documentsDirProvider);
    final bgDir = Directory('${docs.path}/pages_bg');
    if (!bgDir.existsSync()) bgDir.createSync(recursive: true);
    final dest = File(
      '${bgDir.path}/${widget.page.id}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await dest.writeAsBytes(bytes.buffer.asUint8List());
    final rel = toRelativeDocPath(docs, dest.path);
    final oldPath = _bgImagePath;
    setState(() => _bgImagePath = rel);
    await _persistPage();
    if (oldPath != null && oldPath != rel) {
      final old = File(resolveDocFile(docs, oldPath));
      if (await old.exists()) await old.delete();
    }
  }

  Future<void> _pickBackgroundPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2160,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      // シール帳と同じ9:16に固定
      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'シール帳サイズに切り取る',
          toolbarColor: CTColors.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'シール帳サイズに切り取る',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    final docs = ref.read(documentsDirProvider);
    final bgDir = Directory('${docs.path}/pages_bg');
    if (!bgDir.existsSync()) bgDir.createSync(recursive: true);
    final dest = File(
      '${bgDir.path}/${widget.page.id}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await File(cropped.path).copy(dest.path);

    final rel = toRelativeDocPath(docs, dest.path);
    final oldPath = _bgImagePath;
    setState(() => _bgImagePath = rel);
    await _persistPage();
    if (oldPath != null && oldPath != rel) {
      final old = File(resolveDocFile(docs, oldPath));
      if (await old.exists()) await old.delete();
    }
  }

  /// 1080x1920 PNGで書き出して共有シートへ
  Future<void> _export() async {
    if (_exporting) return;
    setState(() {
      _exporting = true;
      _selectedId = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      final boundary =
          _canvasKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final ratio = 1080 / boundary.size.width;
      final image = await boundary.toImage(pixelRatio: ratio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/deco_page_${widget.page.id}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: '#しーるちょー');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('書き出しに失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Scaffold(
      appBar: AppBar(
        title: _editing
            ? GestureDetector(
                onTap: _editTitle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_title.isEmpty ? 'タイトルをつける' : _title),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_rounded, size: 16, color: CTColors.textSub),
                  ],
                ),
              )
            : Text(_title.isEmpty ? 'シール帳' : _title),
        actions: [
          if (_editing)
            IconButton(
              onPressed: () => setState(() {
                _editing = false;
                _selectedId = null;
              }),
              icon: const Icon(Icons.check_rounded),
              tooltip: '完了',
            )
          else ...[
            IconButton(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'デコる',
            ),
            IconButton(
              onPressed: _exporting ? null : _export,
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'ストーリーサイズで書き出し',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // 9:16 ストーリーサイズのキャンバス
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedId = null),
                          // 小さくしすぎた要素の救済: 選択中なら
                          // キャンバスのどこでも2本指ピンチで拡大・回転できる
                          onScaleStart: (_) => _canvasPinch = false,
                          onScaleUpdate: (details) {
                            final r = _selected;
                            if (r == null ||
                                !_editing ||
                                details.pointerCount < 2) {
                              return;
                            }
                            if (!_canvasPinch) {
                              _canvasPinch = true;
                              _startScale = r.element.scale / details.scale;
                              _startRotation =
                                  r.element.rotation - details.rotation;
                            }
                            setState(() {
                              r.element = r.element.copyWith(
                                scale: (_startScale * details.scale).clamp(
                                  0.25,
                                  4.0,
                                ),
                                rotation: _startRotation + details.rotation,
                              );
                            });
                          },
                          onScaleEnd: (_) {
                            if (!_canvasPinch) return;
                            _canvasPinch = false;
                            final r = _selected;
                            if (r != null) _persistElement(r);
                          },
                          child: Container(
                            foregroundDecoration: _pageBorderColor == null
                                ? null
                                : BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      CTRadius.card,
                                    ),
                                    border: Border.all(
                                      color: _pageBorderColor!,
                                      width: 4,
                                    ),
                                  ),
                            decoration: BoxDecoration(
                              color: _bgColor,
                              borderRadius: BorderRadius.circular(
                                CTRadius.card,
                              ),
                              image: _bgImagePath != null
                                  ? DecorationImage(
                                      image: FileImage(
                                        File(
                                          resolveDocFile(
                                            ref.read(documentsDirProvider),
                                            _bgImagePath!,
                                          ),
                                        ),
                                      ),
                                      fit: BoxFit.cover,
                                      onError: (_, _) {},
                                    )
                                  : null,
                              boxShadow: ctCardShadow,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                if (!_loaded)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                for (final r in _elements)
                                  _buildElement(r, w, h),
                                // ドラッグ中だけ出るゴミ箱(ここで離すとはがれる)
                                if (_editing && _dragging)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: h * _trashY - 28,
                                    child: Center(
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 120,
                                        ),
                                        width: _overTrash ? 64 : 52,
                                        height: _overTrash ? 64 : 52,
                                        decoration: BoxDecoration(
                                          color: _overTrash
                                              ? Colors.redAccent
                                              : Colors.black.withValues(
                                                  alpha: 0.45,
                                                ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete_rounded,
                                          color: Colors.white,
                                          size: _overTrash ? 30 : 24,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ツールバー(編集モードのみ)
          if (!_editing)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'カードやシールをタップで再生・表示 / 右上の鉛筆でデコる',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: CTColors.textSub),
                ),
              ),
            )
          else
            SafeArea(
              child: SizedBox(
                height: 68,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _ToolButton(
                      icon: Icons.add_reaction_rounded,
                      label: 'シール',
                      onTap: _addSticker,
                    ),
                    _ToolButton(
                      icon: Icons.style_rounded,
                      label: 'カード',
                      onTap: _addCard,
                    ),
                    _ToolButton(
                      icon: Icons.palette_rounded,
                      label: '背景',
                      onTap: _pickBackground,
                    ),
                    _ToolButton(
                      icon: Icons.account_circle_rounded,
                      label: 'プロフ',
                      onTap: _addProfile,
                    ),
                    _ToolButton(
                      icon: Icons.format_color_fill_rounded,
                      label: 'フチ色',
                      onTap: selected?.sticker == null
                          ? null
                          : _recolorSelected,
                    ),
                    _ToolButton(
                      icon: Icons.flip_to_front_rounded,
                      label: '前面へ',
                      onTap: selected == null ? null : _bringToFront,
                    ),
                    _ToolButton(
                      icon: Icons.flip_to_back_rounded,
                      label: '背面へ',
                      onTap: selected == null ? null : _sendToBack,
                    ),
                    _ToolButton(
                      icon: Icons.cut_rounded,
                      label: '剥がす',
                      onTap: selected == null ? null : _removeSelected,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildElement(ResolvedElement r, double w, double h) {
    final el = r.element;
    final isSelected = el.id == _selectedId;

    return Positioned(
      left: el.x * w,
      top: el.y * h,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: !_editing
            ? GestureDetector(
                // 閲覧モード: タップで再生・マップ・情報をその場に出す
                onTap: () => _onDoubleTap(r),
                child: Transform.rotate(
                  angle: el.rotation,
                  child: ElementView(resolved: r, canvasWidth: w),
                ),
              )
            : GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedId = el.id);
                },
                // ダブルタップ: カード/リンク付きシールは詳細へ
                onDoubleTap: () => _onDoubleTap(r),
                onScaleStart: (details) {
                  setState(() {
                    _selectedId = el.id;
                    _dragging = true;
                    _overTrash = false;
                  });
                  _startScale = el.scale;
                  _startRotation = el.rotation;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    r.element = r.element.copyWith(
                      x: (r.element.x + details.focalPointDelta.dx / w).clamp(
                        0.0,
                        1.0,
                      ),
                      y: (r.element.y + details.focalPointDelta.dy / h).clamp(
                        0.0,
                        1.0,
                      ),
                      scale: (_startScale * details.scale).clamp(0.25, 4.0),
                      rotation: _startRotation + details.rotation,
                    );
                    final over = _isOverTrash(r.element.x, r.element.y, w, h);
                    if (over != _overTrash) {
                      _overTrash = over;
                      if (over) HapticFeedback.selectionClick();
                    }
                  });
                },
                onScaleEnd: (_) async {
                  final trash = _overTrash;
                  setState(() {
                    _dragging = false;
                    _overTrash = false;
                  });
                  if (trash) {
                    await _removeElement(r);
                  } else {
                    await _persistElement(r);
                  }
                },
                child: Transform.rotate(
                  angle: el.rotation,
                  child: Container(
                    decoration: isSelected
                        ? BoxDecoration(
                            border: Border.all(
                              color: CTColors.primary.withValues(alpha: 0.7),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          )
                        : null,
                    child: ElementView(resolved: r, canvasWidth: w),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _onDoubleTap(ResolvedElement r) async {
    if (r.type == PageElementType.text) return; // テキスト作成機能は廃止
    if (r.type == PageElementType.profile) {
      if (_editing) await _editProfileStyle(r);
      return;
    }
    await openElementAction(context, ref, r);
  }

  /// プロフィールアイコンの形と枠色を変える
  Future<void> _editProfileStyle(ResolvedElement r) async {
    var payload = ProfilePayload.fromJson(r.element.payload);
    final result = await showModalBottomSheet<ProfilePayload>(
      context: context,
      backgroundColor: CTColors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CTRadius.sheet),
        ),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: ProfileShapeAvatar(payload: payload, size: 84)),
                const SizedBox(height: 16),
                Text(
                  'かたち',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: CTColors.textSub,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final entry in const [
                      (ProfileShape.circle, 'まる'),
                      (ProfileShape.rounded, 'かどまる'),
                      (ProfileShape.square, 'しかく'),
                      (ProfileShape.diamond, 'ダイヤ'),
                    ])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(
                            () => payload = payload.copyWith(shape: entry.$1),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: payload.shape == entry.$1
                                  ? CTColors.primary.withValues(alpha: 0.15)
                                  : CTColors.surface,
                              borderRadius: BorderRadius.circular(
                                CTRadius.card,
                              ),
                              border: Border.all(
                                color: payload.shape == entry.$1
                                    ? CTColors.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              entry.$2,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'ふちの色',
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
                        onTap: () => setSheetState(
                          () => payload = payload.copyWith(
                            frameColorHex: _hexOf(color),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: payload.frameColor == color
                                  ? CTColors.textMain
                                  : CTColors.textSub.withValues(alpha: 0.25),
                              width: payload.frameColor == color ? 2.5 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, payload),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      r.element = r.element.copyWith(payload: result.toJson());
    });
    await _persistElement(r);
  }

  static String _hexOf(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: enabled
                    ? CTColors.primary.withValues(alpha: 0.12)
                    : CTColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: enabled ? CTColors.primary : CTColors.textSub,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: enabled ? CTColors.textMain : CTColors.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
