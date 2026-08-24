import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../core/beam/beam_transport.dart';
import '../../core/beam/ble_presence.dart';
import '../../core/db/app_database.dart';
import '../../core/models/culture_category.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/label_chip.dart';
import 'beam_profile_provider.dart';
import '../palette/sticker_exchange.dart';

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
    _statusSub = transport.status.listen((s) {
      if (mounted) setState(() => _status = s);
    });
  }

  @override
  void dispose() {
    _peersSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
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

  /// パレットからシールを選んで共有シートで送る
  Future<void> _pickStickerToSend() async {
    final db = ref.read(databaseProvider);
    final stickers = await db.watchStickers().first;
    if (!mounted) return;
    if (stickers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('まずシールタブでシールをつくってね')));
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
    await shareStickerWithMeta(ref, selected);
  }

  /// シール帳のページを選んで共有シートで送る
  Future<void> _pickPageToSend() async {
    final db = ref.read(databaseProvider);
    final pages = await db.watchPages().first;
    if (!mounted) return;
    if (pages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('まずシール帳をつくってね')));
      return;
    }
    final selected = await showModalBottomSheet<StickerPage>(
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
          child: ListView.builder(
            itemCount: pages.length,
            itemBuilder: (_, i) {
              final page = pages[i];
              return ListTile(
                leading: const Icon(Icons.menu_book_rounded),
                title: Text(
                  page.title.isEmpty
                      ? '${page.updatedAt.month}/${page.updatedAt.day}のシール帳'
                      : page.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(sheetContext, page),
              );
            },
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('シール帳を画像にしてるよ…')));
    await sharePageWithMeta(ref, selected);
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

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CTColors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CTRadius.sheet),
        ),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final list = ref.watch(beamHistoryProvider).valueOrNull ?? [];
          return SafeArea(
            child: list.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'まだ交換履歴がないよ',
                      style: TextStyle(color: CTColors.textSub),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final b = list[i];
                      final isSent = b.direction == BeamDirection.sent;
                      return ListTile(
                        leading: BeamAvatar(
                          name: b.peerName,
                          color: colorFromHex(b.peerColor),
                          radius: 16,
                        ),
                        title: Text(
                          b.peerName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${b.beamedAt.year}/${b.beamedAt.month}/${b.beamedAt.day}',
                        ),
                        trailing: Icon(
                          isSent
                              ? Icons.call_made_rounded
                              : Icons.call_received_rounded,
                          size: 18,
                          color: isSent ? CTColors.primary : CTColors.mint,
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(beamProfileProvider).valueOrNull;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0F6), Color(0xFFEDF9FF)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
              child: Row(
                children: [
                  Text(
                    'カード交換',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: CTColors.primary,
                    ),
                  ),
                  const Spacer(),
                  LabelChip(
                    icon: Icons.download_rounded,
                    label: '受け取る',
                    onTap: () => importStickerFromGallery(context, ref),
                  ),
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
              child: _PeerField(peers: _peers, radarOn: _radarOn),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: CTColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _pickStickerToSend();
                      },
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: const Text('シールを送る'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: CTColors.mint,
                        foregroundColor: CTColors.textMain,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _pickPageToSend();
                      },
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: const Text('シール帳を送る'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel() {
    if (!_radarOn) return 'オンにすると近くのしーるちょーユーザーが見えるよ';
    return switch (_status) {
      BeamPresenceStatus.advertising =>
        _peers.isEmpty ? 'さがし中…' : '${_peers.length}人 みつけた!',
      BeamPresenceStatus.unsupported => 'この端末はBluetoothに対応してないみたい',
      BeamPresenceStatus.permissionDenied => 'Bluetoothの許可が必要だよ(設定から変更してね)',
      BeamPresenceStatus.error => 'うまく動いてない…もう一度オンにしてみてね',
      BeamPresenceStatus.idle => '準備中…',
    };
  }
}

/// 見つかった相手がぷかぷか浮かぶフィールド
class _PeerField extends StatelessWidget {
  const _PeerField({required this.peers, required this.radarOn});

  final List<BeamPeer> peers;
  final bool radarOn;

  @override
  Widget build(BuildContext context) {
    if (!radarOn) {
      return Center(
        child: Icon(
          Icons.radar_rounded,
          size: 56,
          color: CTColors.textSub.withValues(alpha: 0.4),
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
        return Stack(
          children: [
            for (final (i, peer) in peers.indexed)
              Positioned(
                left: _fraction(peer.id, i, 13) * (constraints.maxWidth - 90),
                top: _fraction(peer.id, i, 7) * (constraints.maxHeight - 110),
                child: _FloatingPeer(peer: peer, index: i),
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
