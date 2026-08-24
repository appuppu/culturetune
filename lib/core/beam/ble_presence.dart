import 'dart:async';

import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'beam_transport.dart';

/// v1実装: BLEアドバタイズ+スキャンによる「近くにいる」検知のみ。
/// カード本体の受け渡しはQR(UI側)で行う。
class BlePresenceTransport implements BeamTransport {
  /// Culture Tune識別用のService UUID(16bitショートコード 0xC71E を128bit化)
  static final Guid _serviceGuid = Guid('0000c71e-0000-1000-8000-00805f9b34fb');

  final _peripheral = FlutterBlePeripheral();
  final _peersController = StreamController<List<BeamPeer>>.broadcast();
  final _statusController = StreamController<BeamPresenceStatus>.broadcast();

  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _sweepTimer;

  /// peerId -> (peer, 最終発見時刻)
  final _seen = <String, ({BeamPeer peer, DateTime at})>{};

  @override
  Stream<List<BeamPeer>> get peers => _peersController.stream;

  @override
  Stream<BeamPresenceStatus> get status => _statusController.stream;

  @override
  Future<void> start(BeamProfile me) async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        _statusController.add(BeamPresenceStatus.unsupported);
        return;
      }

      // 自分をアドバタイズ(名前は載る範囲でベストエフォート)
      try {
        await _peripheral.start(
          advertiseData: AdvertiseData(
            serviceUuid: _serviceGuid.str128,
            localName: me.advertiseName,
          ),
        );
      } catch (_) {
        // アドバタイズ不可端末でもスキャン(=相手を見つける側)は続行
      }

      // 周囲のしーるちょーユーザーをスキャン
      _scanSub = FlutterBluePlus.onScanResults.listen(_onResults);
      await FlutterBluePlus.startScan(
        withServices: [_serviceGuid],
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 8),
      );

      // 10秒見えない相手をリストから掃除
      _sweepTimer = Timer.periodic(const Duration(seconds: 3), (_) => _sweep());
      _statusController.add(BeamPresenceStatus.advertising);
    } catch (e) {
      final message = e.toString().toLowerCase();
      _statusController.add(
        message.contains('permission') || message.contains('denied')
            ? BeamPresenceStatus.permissionDenied
            : BeamPresenceStatus.error,
      );
    }
  }

  void _onResults(List<ScanResult> results) {
    final now = DateTime.now();
    for (final r in results) {
      final name = r.advertisementData.advName;
      _seen[r.device.remoteId.str] = (
        peer: BeamPeer(
          id: r.device.remoteId.str,
          displayName: name.isNotEmpty ? name : 'ともだち',
        ),
        at: now,
      );
    }
    _emit();
  }

  void _sweep() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 10));
    _seen.removeWhere((_, v) => v.at.isBefore(cutoff));
    _emit();
  }

  void _emit() {
    if (_peersController.isClosed) return;
    _peersController.add([for (final v in _seen.values) v.peer]);
  }

  @override
  Future<void> stop() async {
    _sweepTimer?.cancel();
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    try {
      await _peripheral.stop();
    } catch (_) {}
    _seen.clear();
    if (!_peersController.isClosed) _peersController.add(const []);
    if (!_statusController.isClosed) {
      _statusController.add(BeamPresenceStatus.idle);
    }
  }

  void dispose() {
    stop();
    _peersController.close();
    _statusController.close();
  }
}
