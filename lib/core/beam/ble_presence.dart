import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'beam_transport.dart';

/// v1実装: BLEアドバタイズ+スキャンによる「近くにいる」検知のみ。
/// カード本体の受け渡しはQR(UI側)で行う。
class BlePresenceTransport implements BeamTransport {
  /// Culture Tune識別用のService UUID(16bitショートコード 0xC71E を128bit化)
  static final Guid _serviceGuid = Guid('0000c71e-0000-1000-8000-00805f9b34fb');

  static const _iosAdvertiseChannel = MethodChannel(
    'culturetune/ble_advertise',
  );

  final _peripheral = FlutterBlePeripheral();

  /// 発信状態の見える化(ok / error: ... / state=n)。UIの診断表示用
  final ValueNotifier<String> advertiseInfo = ValueNotifier('');
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

      // iOSは起動直後や権限ダイアログ中はアダプタ状態が不明で、
      // その間にstartScanすると失敗する。ONになるまで待つ。
      final state = await FlutterBluePlus.adapterState
          .where(
            (s) =>
                s == BluetoothAdapterState.on ||
                s == BluetoothAdapterState.unauthorized ||
                s == BluetoothAdapterState.off,
          )
          .first
          .timeout(const Duration(seconds: 15));
      if (kDebugMode) debugPrint('[ble] adapterState=$state');
      if (state == BluetoothAdapterState.unauthorized) {
        _statusController.add(BeamPresenceStatus.permissionDenied);
        return;
      }
      if (state != BluetoothAdapterState.on) {
        _statusController.add(BeamPresenceStatus.error);
        return;
      }

      // 自分をアドバタイズ(名前は載る範囲でベストエフォート)。
      // iOSはプラグインがpoweredOn前に発信して失敗するため自前実装を使う
      try {
        if (Platform.isIOS) {
          _iosAdvertiseChannel.setMethodCallHandler((call) async {
            if (call.method == 'advState') {
              advertiseInfo.value = call.arguments as String? ?? '';
              if (kDebugMode) {
                debugPrint('[ble] advState=${advertiseInfo.value}');
              }
            }
          });
          await _iosAdvertiseChannel.invokeMethod('start', {
            'name': me.advertiseName,
            'uuid': _serviceGuid.str128,
          });
          if (kDebugMode) {
            debugPrint('[ble] ios advertise start name=${me.advertiseName}');
          }
        } else {
          await _peripheral.start(
            advertiseData: AdvertiseData(
              serviceUuid: _serviceGuid.str128,
              localName: me.advertiseName,
            ),
          );
          if (kDebugMode) {
            debugPrint(
              '[ble] advertising=${await _peripheral.isAdvertising} '
              'name=${me.advertiseName}',
            );
          }
        }
      } catch (e) {
        // アドバタイズ不可端末でもスキャン(=相手を見つける側)は続行
        if (kDebugMode) debugPrint('[ble] advertise failed: $e');
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
    if (kDebugMode && results.isNotEmpty) {
      debugPrint(
        '[ble] scan results=${results.length} '
        'names=${[for (final r in results) r.advertisementData.advName]}',
      );
    }
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
      if (Platform.isIOS) {
        await _iosAdvertiseChannel.invokeMethod('stop');
      } else {
        await _peripheral.stop();
      }
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
