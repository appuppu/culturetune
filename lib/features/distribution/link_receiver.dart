import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/beam_card.dart';
import '../../core/theme/tokens.dart';
import 'card_link.dart';

/// 配布リンク(https / culturetune://)でアプリが開かれたときの受信処理。
/// HomeShellから初期化し、受け取り確認シートを出して保存する。
class LinkReceiver {
  LinkReceiver(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> start(WidgetRef ref) async {
    // アプリがリンクから起動された場合
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(ref, initial);
    // 起動中にリンクを踏んだ場合
    _sub = _appLinks.uriLinkStream.listen((uri) => _handle(ref, uri));
  }

  void dispose() => _sub?.cancel();

  Future<void> _handle(WidgetRef ref, Uri uri) async {
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await receiveCardFromUri(context, ref, uri);
  }
}

/// カードURI(配布リンク/QRの中身)を受け取り確認つきで保存する。
/// リンク受信とQR読み取りの両方から使う。戻り値: 保存したか。
Future<bool> receiveCardFromUri(
  BuildContext context,
  WidgetRef ref,
  Uri uri,
) async {
  final card = CardLink.parse(uri);
  if (card == null || !context.mounted) return false;

  final accepted = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: CTColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (sheetContext) => _AcceptSheet(card: card),
  );
  if (accepted != true) return false;
  await ref.read(itemRepositoryProvider).saveBeamCard(card);
  if (context.mounted) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${card.senderName} の「${card.title}」を受け取ったよ')),
    );
  }
  return true;
}

class _AcceptSheet extends StatelessWidget {
  const _AcceptSheet({required this.card});

  final BeamCard card;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${card.senderName} からのカード',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (card.thumbUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(CTRadius.card),
                child: CachedNetworkImage(
                  imageUrl: card.thumbUrl!,
                  height: 160,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Icon(
                    card.category.icon,
                    size: 48,
                    color: card.category.color,
                  ),
                ),
              )
            else
              Icon(card.category.icon, size: 48, color: card.category.color),
            const SizedBox(height: 12),
            Text(
              card.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('やめとく'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('うけとる'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
