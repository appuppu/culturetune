import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/models/beam_card.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/culture_picker_sheet.dart';
import '../distribution/card_link.dart';
import '../distribution/link_receiver.dart';
import 'beam_profile_provider.dart';

/// QRでその場交換。
/// みせる: カードを選んでQR表示 / よみとる: 相手のQRをカメラで読む。
/// QRの中身は配布リンクと同じURLなので、標準カメラで読んでも
/// 配布ページ経由で受け取れる。
class QrExchangePage extends ConsumerStatefulWidget {
  const QrExchangePage({super.key});

  @override
  ConsumerState<QrExchangePage> createState() => _QrExchangePageState();
}

class _QrExchangePageState extends ConsumerState<QrExchangePage> {
  int _segment = 0; // 0=みせる 1=よみとる
  CultureItem? _item;
  bool _handling = false;

  Future<void> _pickCard() async {
    final item = await showCulturePickerSheet(
      context,
      ref.read(databaseProvider),
      title: 'どのカードを渡す?',
    );
    if (item != null && mounted) setState(() => _item = item);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final uri = Uri.tryParse(raw);
    if (uri == null || CardLink.parse(uri) == null) return;
    _handling = true;
    HapticFeedback.mediumImpact();
    final saved = await receiveCardFromUri(context, ref, uri);
    // 同じQRを連続で読まないよう、少し置いてから再開
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted && saved) {
      setState(() => _segment = 0);
    }
    _handling = false;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(beamProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('QRでその場交換')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                for (final (i, label) in ['みせる', 'よみとる'].indexed)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _segment = i);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _segment == i
                              ? CTColors.primary.withValues(alpha: 0.15)
                              : CTColors.surface,
                          borderRadius: BorderRadius.circular(CTRadius.pill),
                          border: Border.all(
                            color: _segment == i
                                ? CTColors.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _segment == i
                                ? CTColors.primary
                                : CTColors.textSub,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _segment == 0
                ? _ShowQrBody(
                    item: _item,
                    senderName: profile?.name ?? 'ゲスト',
                    senderColor: profile?.colorHex ?? '#FF6B9D',
                    onPick: _pickCard,
                  )
                : MobileScanner(onDetect: _onDetect),
          ),
          if (_segment == 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'あいての「みせる」QRを画面内におさめてね',
                style: TextStyle(fontSize: 12, color: CTColors.textSub),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShowQrBody extends StatelessWidget {
  const _ShowQrBody({
    required this.item,
    required this.senderName,
    required this.senderColor,
    required this.onPick,
  });

  final CultureItem? item;
  final String senderName;
  final String senderColor;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final selected = item;
    if (selected == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2_rounded, size: 64, color: CTColors.primary),
            const SizedBox(height: 12),
            Text(
              '渡したいカードを選ぶと\nQRコードが出るよ',
              textAlign: TextAlign.center,
              style: TextStyle(color: CTColors.textSub, height: 1.6),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.style_rounded, size: 18),
              label: const Text('カードを選ぶ'),
            ),
          ],
        ),
      );
    }

    final link = CardLink.build(
      BeamCard.fromItem(
        selected,
        senderName: senderName,
        senderColor: senderColor,
      ),
    );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CTRadius.card),
              boxShadow: ctCardShadow,
            ),
            child: QrImageView(
              data: link,
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            selected.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'あいてのしーるちょーの「よみとる」か、ふつうのカメラでも読めるよ',
            style: TextStyle(fontSize: 11, color: CTColors.textSub),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('カードを変える'),
          ),
        ],
      ),
    );
  }
}
