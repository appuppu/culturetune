import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../core/beam/beam_transport.dart';
import '../../core/beam/ble_presence.dart';
import '../../core/beam/ble_transfer.dart';
import '../../core/models/culture_category.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/label_chip.dart';
import '../../core/widgets/use_case_card.dart';
import '../palette/sticker_exchange.dart';
import 'beam_profile_provider.dart';
import 'exchange_history.dart';
import 'send_pickers.dart';

final beamTransportProvider = Provider<BlePresenceTransport>((ref) {
  final transport = BlePresenceTransport();
  ref.onDispose(transport.dispose);
  return transport;
});

/// 交換履歴(新しい順)
final beamHistoryProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(databaseProvider).watchBeams(),
);

/// すれ違い交換タブ。
/// BLEレーダーで近くのユーザーを表示し、カード本体はQRで確実に受け渡す。
class BeamPage extends ConsumerStatefulWidget {
  const BeamPage({super.key});

  @override
  ConsumerState<BeamPage> createState() => _BeamPageState();
}

class _BeamPageState extends ConsumerState<BeamPage> {
  bool _radarOn = false;
  List<BeamPeer> _peers = [];
  BeamPresenceStatus _status = BeamPresenceStatus.idle;
  StreamSubscription<List<BeamPeer>>? _peersSub;
  StreamSubscription<BeamPresenceStatus>? _statusSub;

  @override
  void initState() {
    super.initState();
    final transport = ref.read(beamTransportProvider);
    _peersSub = transport.peers.listen((p) {
      if (mounted) setState(() => _peers = p);
    });
    transport.advertiseInfo.addListener(_onAdvInfo);
    transport.nearbyDeviceCount.addListener(_onAdvInfo);
    _requestSub = transport.incomingRequests.listen(_onIncomingRequest);
    _incomingSub = transport.incoming.listen(_onIncomingData);
    _statusSub = transport.status.listen((s) {
      if (mounted) setState(() => _status = s);
    });
  }

  @override
  void dispose() {
    ref.read(beamTransportProvider).advertiseInfo.removeListener(_onAdvInfo);
    ref
        .read(beamTransportProvider)
        .nearbyDeviceCount
        .removeListener(_onAdvInfo);
    _peersSub?.cancel();
    _statusSub?.cancel();
    _requestSub?.cancel();
    _incomingSub?.cancel();
    super.dispose();
  }

  void _onAdvInfo() {
    if (mounted) setState(() {});
  }

  StreamSubscription<({String name, int size, String code})>? _requestSub;
  StreamSubscription<({String name, Uint8List data})>? _incomingSub;

  /// 受信リクエスト: 相手が渡そうとしている。
  /// コードを入力して承認すると転送が始まる。
  Future<void> _onIncomingRequest(
    ({String name, int size, String code}) request,
  ) async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final transport = ref.read(beamTransportProvider);
    final controller = TextEditingController();
    String? errorText;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void submit() {
            if (controller.text == request.code) {
              Navigator.pop(dialogContext, true);
            } else {
              setDialogState(() => errorText = 'コードがちがうよ');
            }
          }

          return AlertDialog(
            title: Text('${request.name} からリクエスト!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'シールかシール帳が届きそうだよ'
                  '(${(request.size / 1024).round()}KB)。\n'
                  'あいての画面に出ている4けたのコードを入力してね',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '0000',
                    errorText: errorText,
                  ),
                  onSubmitted: (_) => submit(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('ことわる'),
              ),
              FilledButton(onPressed: submit, child: const Text('うけとる')),
            ],
          );
        },
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      await transport.approveIncoming();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('うけとり中…そのまま待っててね')));
    } else {
      await transport.rejectIncoming();
    }
  }

  /// 承認済みの転送が完了した(取り込んで通知)
  Future<void> _onIncomingData(({String name, Uint8List data}) event) async {
    if (!mounted) return;
    final message = await importSharedPngBytes(ref, event.data);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? '受け取ったデータを読めなかったよ')));
  }

  /// ふわふわ(相手)をタップ → わたす物を選んで直接Bluetooth送信
  Future<void> _onPeerTap(BeamPeer peer) async {
    HapticFeedback.selectionClick();
    final action = await showModalBottomSheet<String>(
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
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                '${peer.displayName} に何をわたす?',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high_rounded),
              title: const Text('シールをわたす(まとめてOK)'),
              onTap: () => Navigator.pop(sheetContext, 'sticker'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('シール帳をわたす'),
              onTap: () => Navigator.pop(sheetContext, 'page'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    Uint8List? bytes;
    String label;
    String? pageIdForLog;
    if (action == 'sticker') {
      final stickers = await pickStickersForSend(context, ref);
      if (stickers == null || stickers.isEmpty || !mounted) return;
      bytes = stickers.length == 1
          ? await buildStickerSharePng(ref, stickers.first, maxDim: 900)
          : await buildStickerBundle(ref, stickers);
      label = stickers.length == 1 ? 'シール' : 'シール×${stickers.length}';
    } else {
      final page = await pickPageForSend(context, ref);
      if (page == null || !mounted) return;
      bytes = await buildPageSharePng(
        ref,
        page,
        flatWidth: 540,
        stickerMaxDim: 900,
      );
      label = page.title.isEmpty ? 'シール帳' : 'シール帳「${page.title}」';
      pageIdForLog = page.id;
    }
    if (!mounted) return;

    final profile = await ref.read(beamProfileProvider.future);
    if (!mounted) return;
    // 安全のための確認コード(あいてが入力する)
    final code = (1000 + Random().nextInt(9000)).toString();
    final progress = ValueNotifier<(double?, String)>((null, 'つなげてるよ…'));
    final cancelled = ValueNotifier(false);
    var dialogOpen = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('${peer.displayName} へ'),
          content: ValueListenableBuilder(
            valueListenable: progress,
            builder: (_, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('あいてにこのコードを教えてね', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                    color: CTColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(value.$2, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: value.$1,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled.value = true;
                Navigator.pop(dialogContext);
              },
              child: const Text('やめる'),
            ),
          ],
        ),
      ).then((_) => dialogOpen = false),
    );
    final result = await BleTransfer.sendToPeer(
      remoteId: peer.id,
      senderName: profile.name,
      code: code,
      data: bytes,
      onProgress: (p, label) => progress.value = (p, label),
      cancelled: cancelled,
    );
    if (mounted && dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    if (result == SendResult.sent) {
      await recordExchange(
        ref,
        direction: BeamDirection.sent,
        peerName: peer.displayName,
        label: label,
        pageId: pageIdForLog,
      );
    }
    if (!mounted) return;
    final message = switch (result) {
      SendResult.sent => '${peer.displayName} にとどけたよ!',
      SendResult.rejected => '${peer.displayName} にことわられちゃった…',
      SendResult.timeout => '返事がなかったみたい。あいての画面を確認してもう一度試してね',
      SendResult.cancelled => 'やめたよ',
      SendResult.error => 'うまくとどかなかった…あいてがレーダーONか確認してもう一度試してね',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleRadar(bool on) async {
    final transport = ref.read(beamTransportProvider);
    setState(() => _radarOn = on);
    if (on) {
      final profile = await ref.read(beamProfileProvider.future);
      await transport.start(profile);
    } else {
      await transport.stop();
    }
  }

  void _editProfile() {
    final profile = ref.read(beamProfileProvider).valueOrNull;
    final nameController = TextEditingController(text: profile?.name ?? '');
    var colorHex = profile?.colorHex ?? '#FF6B9D';
    String? newImagePath;
    var removeImage = false;
    String? currentImage = profile?.imagePath;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('プロフィール'),
          // キーボード表示時や小さい画面でも収まるようスクロール可能にする
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // プロフィール写真(タップで変更)
                GestureDetector(
                  onTap: () async {
                    final file = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      imageQuality: 85,
                    );
                    if (file == null) return;
                    // 丸くくりぬき編集してからアバターにする
                    final cropped = await ImageCropper().cropImage(
                      sourcePath: file.path,
                      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                      compressQuality: 85,
                      uiSettings: [
                        AndroidUiSettings(
                          toolbarTitle: 'アイコンをくりぬく',
                          cropStyle: CropStyle.circle,
                          lockAspectRatio: true,
                          hideBottomControls: true,
                        ),
                        IOSUiSettings(
                          title: 'アイコンをくりぬく',
                          cropStyle: CropStyle.circle,
                          aspectRatioLockEnabled: true,
                          resetAspectRatioEnabled: false,
                        ),
                      ],
                    );
                    if (cropped != null) {
                      setDialogState(() {
                        newImagePath = cropped.path;
                        currentImage = cropped.path;
                        removeImage = false;
                      });
                    }
                  },
                  child: BeamAvatar(
                    name: nameController.text,
                    color: colorFromHex(colorHex),
                    imagePath: currentImage,
                    radius: 36,
                  ),
                ),
                TextButton(
                  onPressed: currentImage == null
                      ? null
                      : () => setDialogState(() {
                          removeImage = true;
                          newImagePath = null;
                          currentImage = null;
                        }),
                  child: const Text('写真を外す', style: TextStyle(fontSize: 12)),
                ),
                TextField(
                  controller: nameController,
                  maxLength: 8,
                  decoration: const InputDecoration(labelText: 'なまえ'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in beamColorChoices)
                      GestureDetector(
                        onTap: () =>
                            setDialogState(() => colorHex = hexFromColor(c)),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorHex == hexFromColor(c)
                                  ? CTColors.textMain
                                  : Colors.transparent,
                              width: 3,
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(beamProfileProvider.notifier)
                    .save(
                      name: nameController.text,
                      colorHex: colorHex,
                      newImagePath: newImagePath,
                      removeImage: removeImage,
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistory() => showExchangeHistorySheet(context);

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(beamProfileProvider).valueOrNull;

    return Container(
      color: CTColors.bgBase,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
              child: Row(
                children: [
                  Text(
                    '交換',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: CTColors.primary,
                    ),
                  ),
                  const Spacer(),
                  LabelChip(
                    icon: Icons.history_rounded,
                    label: '履歴',
                    onTap: _showHistory,
                  ),
                  // プロフィール(タップで編集できることが分かるチップ)
                  GestureDetector(
                    onTap: _editProfile,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
                      decoration: BoxDecoration(
                        color: CTColors.surface,
                        borderRadius: BorderRadius.circular(CTRadius.pill),
                        boxShadow: ctCardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BeamAvatar(
                            name: profile?.name ?? '?',
                            color: colorFromHex(profile?.colorHex),
                            imagePath: profile?.imagePath,
                            radius: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile?.name ?? '?',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(
                            Icons.edit_rounded,
                            size: 11,
                            color: CTColors.textSub,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: const Text(
                '近くのともだちレーダー',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _statusLabel(),
                style: const TextStyle(fontSize: 12),
              ),
              value: _radarOn,
              onChanged: _toggleRadar,
              activeTrackColor: CTColors.primary,
            ),
            Expanded(
              child: _PeerField(
                peers: _peers,
                radarOn: _radarOn,
                onPeerTap: _onPeerTap,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(
                'みつけたともだちをタップすると、シールやシール帳を渡せるよ。\n'
                '遠くのともだちには、シールやシール帳の共有ボタンからLINEで送れるよ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.6,
                  color: CTColors.textSub,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel() {
    if (!_radarOn) return 'オンにすると近くのしーるちょーユーザーが見えるよ';
    final transport = ref.read(beamTransportProvider);
    final adv = transport.advertiseInfo.value;
    final advLabel = switch (adv) {
      'ok' => '発信OK',
      '' => '発信準備中',
      _ => '発信NG($adv)',
    };
    final nearby = transport.nearbyDeviceCount.value;
    return switch (_status) {
      BeamPresenceStatus.advertising =>
        '$advLabel / 周囲$nearby台 / '
            '${_peers.isEmpty ? 'さがし中…' : '${_peers.length}人 みつけた!'}',
      BeamPresenceStatus.unsupported => 'この端末はBluetoothに対応してないみたい',
      BeamPresenceStatus.permissionDenied => 'Bluetoothの許可が必要だよ(設定から変更してね)',
      BeamPresenceStatus.error => 'うまく動いてない…もう一度オンにしてみてね',
      BeamPresenceStatus.idle => '準備中…',
    };
  }
}

/// 見つかった相手がぷかぷか浮かぶフィールド。
/// タップで交換開始、ドラッグで移動できる(重なり回避)。
class _PeerField extends StatefulWidget {
  const _PeerField({
    required this.peers,
    required this.radarOn,
    required this.onPeerTap,
  });

  final List<BeamPeer> peers;
  final bool radarOn;
  final void Function(BeamPeer peer) onPeerTap;

  @override
  State<_PeerField> createState() => _PeerFieldState();
}

class _PeerFieldState extends State<_PeerField> {
  /// ドラッグで動かした相手の位置(peer id → 位置)
  final _dragOffsets = <String, Offset>{};

  List<BeamPeer> get peers => widget.peers;
  bool get radarOn => widget.radarOn;

  @override
  Widget build(BuildContext context) {
    if (!radarOn) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.radar_rounded,
                size: 48,
                color: CTColors.textSub.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                '近くのともだちと その場で交換',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CTColors.textMain,
                ),
              ),
              const SizedBox(height: 16),
              const UseCaseCard(
                icon: Icons.wifi_tethering_rounded,
                colorIndex: 0,
                title: 'ふたりともレーダーをオン',
                body: '上のスイッチをオンにすると、近くでアプリを開いているともだちがふわふわ浮かんでくるよ',
              ),
              const UseCaseCard(
                icon: Icons.touch_app_rounded,
                colorIndex: 1,
                title: 'ともだちをタップしてえらぶ',
                body: '浮かんできたともだちをタップして、わたすシール(まとめてOK)やシール帳をえらぶよ',
              ),
              const UseCaseCard(
                icon: Icons.pin_rounded,
                colorIndex: 3,
                title: '4けたのコードで交換完了',
                body: '画面に出るコードを口で伝えて、あいてが入力したら転送スタート。音楽や地図もそのまま届くよ',
              ),
            ],
          ),
        ),
      );
    }
    if (peers.isEmpty) {
      return Center(
        child: Icon(Icons.radar_rounded, size: 56, color: CTColors.primary)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
              duration: 900.ms,
            )
            .fade(begin: 0.5, end: 1),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        Offset positionOf(BeamPeer peer, int i) {
          final dragged = _dragOffsets[peer.id];
          if (dragged != null) return dragged;
          return Offset(
            _fraction(peer.id, i, 13) * (constraints.maxWidth - 90),
            _fraction(peer.id, i, 7) * (constraints.maxHeight - 110),
          );
        }

        return Stack(
          children: [
            for (final (i, peer) in peers.indexed)
              Positioned(
                left: positionOf(peer, i).dx,
                top: positionOf(peer, i).dy,
                child: GestureDetector(
                  onTap: () => widget.onPeerTap(peer),
                  onPanUpdate: (details) {
                    final current = positionOf(peer, i) + details.delta;
                    setState(() {
                      _dragOffsets[peer.id] = Offset(
                        current.dx.clamp(0, constraints.maxWidth - 90),
                        current.dy.clamp(0, constraints.maxHeight - 110),
                      );
                    });
                  },
                  child: _FloatingPeer(peer: peer, index: i),
                ),
              ),
          ],
        );
      },
    );
  }

  /// peer idから0..1の擬似ランダム座標を作る(毎フレーム安定)
  static double _fraction(String id, int index, int salt) {
    final h = (id.hashCode ^ (index * 2654435761) ^ salt) & 0x7fffffff;
    return (h % 1000) / 1000;
  }
}

class _FloatingPeer extends StatelessWidget {
  const _FloatingPeer({required this.peer, required this.index});

  final BeamPeer peer;
  final int index;

  /// 相手のIDから安定したアバターカラーを割り当てる
  Color get _peerColor =>
      CTColors.moodPalette[peer.id.hashCode.abs() %
          CTColors.moodPalette.length];

  @override
  Widget build(BuildContext context) {
    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: ctCardShadow,
              ),
              child: BeamAvatar(
                name: peer.displayName,
                color: _peerColor,
                radius: 26,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(CTRadius.pill),
              ),
              child: Text(
                peer.displayName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -6, end: 6, duration: (1200 + index * 240).ms)
        .animate()
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}
