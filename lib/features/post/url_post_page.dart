import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/link_preview_service.dart';
import '../../core/data/post_draft.dart';
import '../../core/models/culture_category.dart';
import '../../core/models/culture_detail.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/candy_button.dart';
import 'finish_page.dart';

/// Music / Video: URL貼り付け → リンクプレビュー確認 → 仕上げへ
class UrlPostPage extends ConsumerStatefulWidget {
  const UrlPostPage({super.key, required this.category});

  final CultureCategory category;

  @override
  ConsumerState<UrlPostPage> createState() => _UrlPostPageState();
}

class _UrlPostPageState extends ConsumerState<UrlPostPage> {
  final _controller = TextEditingController();
  LinkPreview? _preview;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _controller.text = text;
      await _fetch();
    }
  }

  Future<void> _fetch() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _preview = null;
    });
    final preview = await ref.read(linkPreviewServiceProvider).fetch(url);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (preview == null) {
        _error = 'プレビューを取得できなかった…URLを確認してね';
      } else {
        _preview = preview;
        HapticFeedback.lightImpact();
      }
    });
  }

  static String _timeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 10) return 'morning';
    if (hour >= 10 && hour < 17) return 'day';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  void _next() {
    final p = _preview!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinishPage(
          draft: PostDraft(
            category: widget.category,
            title: p.title,
            subtitle: p.channel ?? p.siteName,
            thumbUrl: p.thumbnailUrl,
            externalId: p.youtubeVideoId,
            url: p.url,
            detail: MediaDetail(
              videoId: p.youtubeVideoId,
              channel: p.channel,
              siteName: p.siteName,
              savedTimeOfDay: _timeOfDay(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category;

    return Scaffold(
      appBar: AppBar(title: Text('${c.labelJa}のURLを貼る')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _fetch(),
              decoration: InputDecoration(
                hintText: c == CultureCategory.music
                    ? 'YouTube / Spotify / Apple MusicのURL'
                    : 'YouTubeなど動画のURL',
                filled: true,
                fillColor: CTColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CTRadius.card),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_rounded),
                  onPressed: _paste,
                  tooltip: 'ペースト',
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _fetch,
              icon: const Icon(Icons.travel_explore_rounded),
              label: const Text('プレビューを見る'),
            ),
            const SizedBox(height: 20),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text(_error!, style: TextStyle(color: CTColors.textSub)),
            if (_preview != null) ...[
              _PreviewTile(preview: _preview!, color: c.color),
              const SizedBox(height: 20),
              CandyButton(label: 'つぎへ', onPressed: _next),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.preview, required this.color});

  final LinkPreview preview;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CTColors.surface,
        borderRadius: BorderRadius.circular(CTRadius.card),
        border: Border.all(color: color, width: 2.5),
        boxShadow: ctCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preview.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(CTRadius.inner(CTRadius.card, 2.5)),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: preview.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) =>
                      ColoredBox(color: color.withValues(alpha: 0.2)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (preview.channel != null || preview.siteName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    preview.channel ?? preview.siteName!,
                    style: TextStyle(color: CTColors.textSub, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
