import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../core/files/doc_paths.dart';
import '../../core/widgets/use_case_card.dart';
import '../../core/db/app_database.dart';
import '../../core/theme/tokens.dart';
import '../../core/stickers/page_renderer.dart';
import '../beam/exchange_history.dart';
import 'element_view.dart';
import 'page_editor_page.dart';
import 'page_models.dart';

/// シール帳タブ: 最新ページを全面に出し、縦スワイプでページをめくる。
/// 一覧ボタンで画面遷移せず、その場で2列グリッドにアニメーション切替する。
class PagesPage extends ConsumerStatefulWidget {
  const PagesPage({super.key});

  @override
  ConsumerState<PagesPage> createState() => _PagesPageState();
}

class _PagesPageState extends ConsumerState<PagesPage> {
  bool _grid = false;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(stickerPagesProvider);

    return SafeArea(
      // ヘッダー行を持たず、ページを全面に。操作ボタンは上に浮かせる
      child: Stack(
        children: [
          Positioned.fill(
            child: pages.when(
              data: (list) => list.isEmpty
                  ? _EmptyBook(onCreate: () => createNewPage(context, ref))
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(
                            begin: 0.94,
                            end: 1.0,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _grid
                          ? _PageGrid(
                              key: const ValueKey('grid'),
                              pages: list,
                              onOpen: (i) => setState(() {
                                _currentIndex = i;
                                _grid = false;
                              }),
                            )
                          : _PagePager(
                              key: ValueKey('pager_$_currentIndex'),
                              pages: list,
                              initialPage: _currentIndex,
                              onPageChanged: (i) => _currentIndex = i,
                            ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('エラー: $e')),
            ),
          ),
          Positioned(
            top: 6,
            right: 10,
            child: Row(
              children: [
                _FloatingAction(
                  icon: _grid
                      ? Icons.fullscreen_rounded
                      : Icons.grid_view_rounded,
                  tooltip: _grid ? '1冊ずつ見る' : 'シール帳一覧',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _grid = !_grid);
                  },
                ),
                const SizedBox(width: 8),
                _FloatingAction(
                  icon: Icons.add_rounded,
                  color: CTColors.primary,
                  tooltip: '新しいシール帳',
                  onTap: () => createNewPage(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2列のシール帳一覧(その場でページャーと切り替わる)。
/// タップで1冊表示に戻り、長押しで削除。
class _PageGrid extends ConsumerWidget {
  const _PageGrid({super.key, required this.pages, required this.onOpen});

  final List<StickerPage> pages;
  final void Function(int index) onOpen;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    StickerPage page,
  ) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('このシール帳を削除する?'),
        content: Text(
          page.title.isEmpty
              ? '${page.updatedAt.month}/${page.updatedAt.day}のシール帳'
              : page.title,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('やめとく'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(databaseProvider).deletePage(page.id);
      await ref.read(stickerRepositoryProvider).cleanupArchived();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 44, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 9 / 16,
      ),
      itemCount: pages.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onOpen(i);
        },
        onLongPress: () => _confirmDelete(context, ref, pages[i]),
        child: PageCanvas(page: pages[i]),
      ),
    );
  }
}

/// ページの上に浮かぶ丸ボタン
class _FloatingAction extends StatelessWidget {
  const _FloatingAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CTColors.surface.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: ctCardShadow,
          ),
          child: Icon(icon, size: 20, color: color ?? CTColors.textSub),
        ),
      ),
    );
  }
}

class _EmptyBook extends StatelessWidget {
  const _EmptyBook({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.menu_book_rounded, size: 48, color: CTColors.primary),
            const SizedBox(height: 10),
            Text(
              'タップすると音が鳴る\nじぶんだけのシール帳',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.5,
                color: CTColors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '写真がシールになって、曲や地図を貼れる。\nたとえばこんな使いかた:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: CTColors.textSub,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            const UseCaseCard(
              icon: Icons.favorite_rounded,
              colorIndex: 0,
              title: '推し活ログ',
              body: '新曲やMV、出演作をカードにして集めよう。シール帳に貼ればタップでその場で再生できるよ',
            ),
            const UseCaseCard(
              icon: Icons.flight_takeoff_rounded,
              colorIndex: 5,
              title: '旅行のきろく',
              body: '旅の写真をまとめてシール化。ごはんの店カードはタップで地図がひらくよ',
            ),
            const UseCaseCard(
              icon: Icons.swap_horiz_rounded,
              colorIndex: 1,
              title: '交換日記・寄せ書き',
              body: 'ともだちに渡して追いデコしてもらおう。メッセージシールやボイスで声も残せる',
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('最初のシール帳をつくる'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 縦スワイプのページめくり(次のページがチラ見えする)
class _PagePager extends ConsumerStatefulWidget {
  const _PagePager({
    super.key,
    required this.pages,
    this.initialPage = 0,
    this.onPageChanged,
  });

  final List<StickerPage> pages;
  final int initialPage;
  final void Function(int index)? onPageChanged;

  @override
  ConsumerState<_PagePager> createState() => _PagePagerState();
}

class _PagePagerState extends ConsumerState<_PagePager> {
  late final _controller = PageController(
    viewportFraction: 0.965,
    initialPage: widget.initialPage,
  );
  late int _current = widget.initialPage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(StickerPage page) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('このシール帳を削除する?'),
        content: Text(
          page.title.isEmpty
              ? '${page.updatedAt.month}/${page.updatedAt.day}のシール帳'
              : page.title,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('やめとく'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(databaseProvider).deletePage(page.id);
      await ref.read(stickerRepositoryProvider).cleanupArchived();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: widget.pages.length,
          onPageChanged: (i) {
            HapticFeedback.selectionClick();
            setState(() => _current = i);
            widget.onPageChanged?.call(i);
          },
          itemBuilder: (_, i) {
            final page = widget.pages[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Stack(
                    children: [
                      // 長押しでページ削除
                      GestureDetector(
                        onLongPress: () => _confirmDelete(page),
                        child: PageCanvas(page: page, interactive: true),
                      ),
                      // このシール帳の交換のきろく
                      Positioned(
                        right: 8,
                        bottom: 104,
                        child: _RoundIconButton(
                          icon: Icons.history_rounded,
                          onTap: () => showExchangeHistorySheet(
                            context,
                            pageId: page.id,
                          ),
                        ),
                      ),
                      // カメラロールに保存
                      Positioned(
                        right: 8,
                        bottom: 56,
                        child: Consumer(
                          builder: (context, ref, _) => _RoundIconButton(
                            icon: Icons.save_alt_rounded,
                            onTap: () =>
                                savePageToCameraRoll(context, ref, page),
                          ),
                        ),
                      ),
                      // ページ操作(デコる)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: _RoundIconButton(
                          icon: Icons.edit_rounded,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PageEditorPage(
                                page: page,
                                startEditing: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // ページ位置インジケータ
        Positioned(
          right: 6,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: CTColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(CTRadius.pill),
              ),
              child: Text(
                '${_current + 1}\n─\n${widget.pages.length}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: CTColors.textSub,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: CTColors.surface.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: ctCardShadow,
        ),
        child: Icon(icon, size: 18, color: CTColors.primary),
      ),
    );
  }
}

/// 新しいページを作ってエディタ(編集モード)を開く。
/// 何も編集せずに閉じた場合は、空の白ページを残さず自動で破棄する。
Future<void> createNewPage(BuildContext context, WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final id = const Uuid().v4();
  final now = DateTime.now();
  await db.upsertPage(
    StickerPagesCompanion.insert(id: id, createdAt: now, updatedAt: now),
  );
  if (!context.mounted) return;
  final pages = await db.watchPages().first;
  final page = pages.firstWhere((p) => p.id == id);
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PageEditorPage(page: page, startEditing: true),
    ),
  );

  // 未編集(要素なし・タイトルなし・背景も初期値)なら破棄
  final elements = await db.getPageElements(id);
  final saved = (await db.watchPages().first)
      .where((p) => p.id == id)
      .firstOrNull;
  if (saved != null &&
      elements.isEmpty &&
      saved.title.isEmpty &&
      saved.bgColor == null &&
      saved.bgImagePath == null) {
    await db.deletePage(id);
  }
}

/// ページの描画(ページャー・一覧グリッド共通)。
/// interactive=trueなら要素タップでその場再生。
/// シール帳を画像にしてカメラロールへ保存する
Future<void> savePageToCameraRoll(
  BuildContext context,
  WidgetRef ref,
  StickerPage page,
) async {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('シール帳を画像にしてるよ…')));
  final png = await renderPageToPng(
    docs: ref.read(documentsDirProvider),
    db: ref.read(databaseProvider),
    stickerRepo: ref.read(stickerRepositoryProvider),
    itemRepo: ref.read(itemRepositoryProvider),
    page: page,
  );
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/book_${page.id}.png');
  await file.writeAsBytes(png);
  if (!context.mounted) return;
  try {
    await Gal.putImage(file.path);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('カメラロールに保存したよ')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存できなかった…写真へのアクセスを許可してね($e)')));
    }
  }
}

/// ページタイトル: レトロポップな二層文字(白文字+アクセント色の落ち影)
class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.fontSize});

  final String title;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 1.25,
      letterSpacing: 1.2,
    );
    final offset = fontSize * 0.07;
    return Stack(
      children: [
        // 後ろ: アクセント色のずらし影(読みやすさ用のぼかし影も持たせる)
        Transform.translate(
          offset: Offset(offset, offset),
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: base.copyWith(
              color: CTColors.primary,
              shadows: const [Shadow(color: Colors.black38, blurRadius: 10)],
            ),
          ),
        ),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

class PageCanvas extends ConsumerWidget {
  const PageCanvas({super.key, required this.page, this.interactive = false});

  final StickerPage page;
  final bool interactive;

  Color get _bg {
    final hex = page.bgColor;
    if (hex == null || !hex.startsWith('#')) return CTColors.surface;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? CTColors.surface : Color(0xFF000000 | value);
  }

  Color? get _border {
    final hex = page.borderColor;
    if (hex == null || !hex.startsWith('#')) return null;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(CTRadius.card),
        boxShadow: ctCardShadow,
      ),
      // フチは要素の上に重ねて描く(額縁のイメージ)
      foregroundDecoration: _border == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(CTRadius.card),
              border: Border.all(color: _border!, width: 4),
            ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (page.bgImagePath != null)
            Image.file(
              File(
                resolveDocFile(
                  ref.watch(documentsDirProvider),
                  page.bgImagePath!,
                ),
              ),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          FutureBuilder(
            future: loadResolvedElements(db, page.id),
            builder: (context, snapshot) {
              final elements = snapshot.data ?? const <ResolvedElement>[];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    children: [
                      for (final r in elements)
                        Positioned(
                          left: r.element.x * w,
                          top: r.element.y * h,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, -0.5),
                            child: Transform.rotate(
                              angle: r.element.rotation,
                              child: interactive
                                  ? GestureDetector(
                                      onTap: () =>
                                          openElementAction(context, ref, r),
                                      child: ElementView(
                                        resolved: r,
                                        canvasWidth: w,
                                      ),
                                    )
                                  : ElementView(resolved: r, canvasWidth: w),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          // タイトル: 左上に大きめ表示(背景に埋もれないよう影付き)
          if (page.title.isNotEmpty && page.showTitle)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth * 0.05,
                      constraints.maxWidth * 0.045,
                      constraints.maxWidth * 0.05,
                      0,
                    ),
                    child: _PageTitle(
                      title: page.title,
                      fontSize: constraints.maxWidth * 0.064,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
