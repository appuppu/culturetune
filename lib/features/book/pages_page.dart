import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/theme/tokens.dart';
import 'element_view.dart';
import 'page_editor_page.dart';
import 'page_models.dart';

/// シール帳タブ: 最新ページを全面に出し、縦スワイプでページをめくる。
/// ページ上のカード/シールはその場でタップ再生できる。
class PagesPage extends ConsumerWidget {
  const PagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(stickerPagesProvider);

    return SafeArea(
      // ヘッダー行を持たず、ページを全面に。操作ボタンは上に浮かせる
      child: Stack(
        children: [
          Positioned.fill(
            child: pages.when(
              data: (list) => list.isEmpty
                  ? _EmptyBook(onCreate: () => createNewPage(context, ref))
                  : _PagePager(pages: list),
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
                  icon: Icons.grid_view_rounded,
                  tooltip: 'ページ一覧',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PagesGridPage()),
                  ),
                ),
                const SizedBox(width: 8),
                _FloatingAction(
                  icon: Icons.add_rounded,
                  color: CTColors.primary,
                  tooltip: '新しいページ',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 56, color: CTColors.primary),
          const SizedBox(height: 12),
          Text(
            'タップすると音楽や動画が鳴る\n自分だけのシール帳をつくろう',
            textAlign: TextAlign.center,
            style: TextStyle(color: CTColors.textSub, height: 1.6),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('最初のページをつくる'),
          ),
        ],
      ),
    );
  }
}

/// 縦スワイプのページめくり(次のページがチラ見えする)
class _PagePager extends ConsumerStatefulWidget {
  const _PagePager({required this.pages});

  final List<StickerPage> pages;

  @override
  ConsumerState<_PagePager> createState() => _PagePagerState();
}

class _PagePagerState extends ConsumerState<_PagePager> {
  final _controller = PageController(viewportFraction: 0.965);
  int _current = 0;

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
        title: const Text('このページを削除する?'),
        content: Text(
          page.title.isEmpty
              ? '${page.updatedAt.month}/${page.updatedAt.day}のページ'
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(CTRadius.card),
        boxShadow: ctCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (page.bgImagePath != null)
            Image.file(File(page.bgImagePath!), fit: BoxFit.cover),
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
          if (page.title.isNotEmpty)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(CTRadius.pill),
                ),
                child: Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ページ一覧(グリッド)。長押しで削除
class PagesGridPage extends ConsumerWidget {
  const PagesGridPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(stickerPagesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('ページ一覧')),
      body: pages.isEmpty
          ? Center(
              child: Text(
                'まだページがないよ',
                style: TextStyle(color: CTColors.textSub),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 9 / 16,
              ),
              itemCount: pages.length,
              itemBuilder: (_, i) {
                final page = pages[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PageEditorPage(page: page),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: PageCanvas(page: page)),
                      // 削除は長押しではなく明示的なメニューから
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              color: Colors.white,
                            ),
                            onSelected: (value) async {
                              if (value != 'delete') return;
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('このページを削除する?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('やめとく'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text(
                                        '削除',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await ref
                                    .read(databaseProvider)
                                    .deletePage(page.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'delete', child: Text('削除')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
