import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/providers.dart';
import '../../core/beam/ble_transfer.dart';
import '../../core/models/beam_card.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/culture_picker_sheet.dart';
import '../distribution/card_link.dart';
import '../distribution/link_receiver.dart';
import '../palette/sticker_exchange.dart';
import 'beam_profile_provider.dart';
import 'send_pickers.dart';

/// その場交換。
/// わたす: シール/シール帳はBluetooth転送、カードはQR表示。
/// うけとる: Bluetooth受信 or QRカメラ読み取り。
class SpotExchangePage extends ConsumerStatefulWidget {
  const SpotExchangePage({super.key});

  @override
  ConsumerState<SpotExchangePage> createState() => _SpotExchangePageState();
}

enum _Mode { menu, qrShow, qrScan, bleSending, bleReceiving }

class _SpotExchangePageState extends ConsumerState<SpotExchangePage> {
  _Mode _mode = _Mode.menu;
  String _status = '';
  double? _progress;
  String? _qrLink;
  String _qrTitle = '';
  bool _scanHandling = false;

  @override
  void dispose() {
    BleTransfer.stopServe();
    super.dispose();
  }

  void _reset() {
    BleTransfer.stopServe();
    setState(() {
      _mode = _Mode.menu;
      _status = '';
      _progress = null;
      _qrLink = null;
    });
  }

  Future<void> _sendViaBle(Future<Uint8List?> Function() buildBytes) async {
    if (!BleTransfer.canSend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth送信は今はiPhoneからだけできるよ(受け取りは両方OK)'),
        ),
      );
      return;
    }
    setState(() {
      _mode = _Mode.bleSending;
      _status = 'じゅんび中…';
      _progress = null;
    });
    final bytes = await buildBytes();
    if (bytes == null || !mounted) {
      if (mounted) _reset();
      return;
    }
    final profile = await ref.read(beamProfileProvider.future);
    if (!mounted) return;
    setState(() => _status = 'あいてが「うけとる」を押すのを待ってるよ…');
    await BleTransfer.serve(
      name: profile.name,
      data: bytes,
      onEvent: (event, args) {
        if (!mounted) return;
        switch (event) {
          case 'serveAdvertising':
            setState(() => _status = 'あいてが「うけとる」を押すのを待ってるよ…');
          case 'peerSubscribed':
            setState(() => _status = 'あいてが見つかった!');
          case 'sendProgress':
            final map = (args as Map).cast<String, Object?>();
            final sent = (map['sent'] as num).toDouble();
            final total = (map['total'] as num).toDouble();
            setState(() {
              _progress = total == 0 ? null : sent / total;
              _status = '送信中… ${(sent / 1024).round()}KB';
            });
          case 'sendDone':
            HapticFeedback.mediumImpact();
            BleTransfer.stopServe();
            setState(() {
              _status = 'とどけたよ!';
              _progress = 1;
            });
          case 'serveError':
            setState(() => _status = 'Bluetoothがうまく動かないみたい($args)');
        }
      },
    );
  }

  Future<void> _receiveViaBle() async {
    setState(() {
      _mode = _Mode.bleReceiving;
      _status = 'Bluetoothを準備中…';
      _progress = null;
    });
    final bytes = await BleTransfer.receive(
      onProgress: (progress, label) {
        if (!mounted) return;
        setState(() {
          _progress = progress == 0 ? null : progress;
          _status = label;
        });
      },
    );
    if (!mounted) return;
    if (bytes == null) {
      setState(() => _status = 'あいてが見つからなかったよ。あいてが「わたす」で待っているあいだにもう一度試してね');
      return;
    }
    final message = await importSharedPngBytes(ref, bytes);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? '受け取ったデータを読めなかったよ')));
    _reset();
  }

  Future<void> _showCardQr() async {
    final item = await showCulturePickerSheet(
      context,
      ref.read(databaseProvider),
      title: 'どのカードを渡す?',
    );
    if (item == null || !mounted) return;
    final profile = await ref.read(beamProfileProvider.future);
    if (!mounted) return;
    setState(() {
      _qrLink = CardLink.build(
        BeamCard.fromItem(
          item,
          senderName: profile.name,
          senderColor: profile.colorHex,
        ),
      );
      _qrTitle = item.title;
      _mode = _Mode.qrShow;
    });
  }

  Future<void> _onQrDetect(BarcodeCapture capture) async {
    if (_scanHandling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final uri = Uri.tryParse(raw);
    if (uri == null || CardLink.parse(uri) == null) return;
    _scanHandling = true;
    HapticFeedback.mediumImpact();
    final saved = await receiveCardFromUri(context, ref, uri);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted && saved) _reset();
    _scanHandling = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('その場で交換'),
        leading: _mode == _Mode.menu
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _reset,
              ),
      ),
      body: switch (_mode) {
        _Mode.menu => _menu(),
        _Mode.qrShow => _qrShowBody(),
        _Mode.qrScan => Column(
          children: [
            Expanded(child: MobileScanner(onDetect: _onQrDetect)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'あいての「カードをQRでみせる」画面を読み取ってね',
                style: TextStyle(fontSize: 12, color: CTColors.textSub),
              ),
            ),
          ],
        ),
        _Mode.bleSending || _Mode.bleReceiving => _bleBody(),
      },
    );
  }

  Widget _menu() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'わたす',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: CTColors.textSub,
          ),
        ),
        const SizedBox(height: 6),
        _MenuTile(
          icon: Icons.auto_fix_high_rounded,
          title: 'シールをわたす',
          subtitle: 'Bluetoothで直接とどける(あいてはこの画面で「うけとる」)',
          onTap: () async {
            final sticker = await pickStickerForSend(context, ref);
            if (sticker == null || !mounted) return;
            await _sendViaBle(() => buildStickerSharePng(ref, sticker));
          },
        ),
        _MenuTile(
          icon: Icons.menu_book_rounded,
          title: 'シール帳をわたす',
          subtitle: '音楽や地図も動くデータごとBluetoothでとどける',
          onTap: () async {
            final page = await pickPageForSend(context, ref);
            if (page == null || !mounted) return;
            await _sendViaBle(() => buildPageSharePng(ref, page));
          },
        ),
        _MenuTile(
          icon: Icons.qr_code_2_rounded,
          title: 'カードをQRでみせる',
          subtitle: '画面のQRをあいてに読んでもらう(ふつうのカメラでもOK)',
          onTap: _showCardQr,
        ),
        const SizedBox(height: 18),
        Text(
          'うけとる',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: CTColors.textSub,
          ),
        ),
        const SizedBox(height: 6),
        _MenuTile(
          icon: Icons.bluetooth_searching_rounded,
          title: 'Bluetoothでうけとる',
          subtitle: 'あいてが「わたす」で待っているときに押してね',
          onTap: _receiveViaBle,
        ),
        _MenuTile(
          icon: Icons.qr_code_scanner_rounded,
          title: 'QRをよみとる',
          subtitle: 'あいてのカードQRをカメラで読む',
          onTap: () => setState(() => _mode = _Mode.qrScan),
        ),
      ],
    );
  }

  Widget _bleBody() {
    final sending = _mode == _Mode.bleSending;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sending
                  ? Icons.bluetooth_audio_rounded
                  : Icons.bluetooth_searching_rounded,
              size: 64,
              color: CTColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.5),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: _reset, child: const Text('やめる')),
          ],
        ),
      ),
    );
  }

  Widget _qrShowBody() {
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
              data: _qrLink!,
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _qrTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'あいての「QRをよみとる」か、ふつうのカメラでも読めるよ',
            style: TextStyle(fontSize: 11, color: CTColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CTColors.surface,
        borderRadius: BorderRadius.circular(CTRadius.card),
        boxShadow: ctCardShadow,
      ),
      child: ListTile(
        leading: Icon(icon, color: CTColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        onTap: onTap,
      ),
    );
  }
}
