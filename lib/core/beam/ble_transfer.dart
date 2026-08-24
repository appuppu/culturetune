import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 相手指定送信の結果
enum SendResult { sent, rejected, timeout, cancelled, error }

/// シール/シール帳のPNGバイト列をBluetoothでその場転送する。
/// 送信側(iOSのみ): ネイティブのGATTサーバでアドバタイズ+チャンク通知。
/// 受信側(iOS/Android): スキャン→接続→METAでサイズ取得→通知でチャンク受信。
abstract final class BleTransfer {
  static final serviceGuid = Guid('0000c71f-0000-1000-8000-00805f9b34fb');
  static final metaGuid = Guid('0000c720-0000-1000-8000-00805f9b34fb');
  static final dataGuid = Guid('0000c721-0000-1000-8000-00805f9b34fb');
  static final ctrlGuid = Guid('0000c722-0000-1000-8000-00805f9b34fb');

  static const channel = MethodChannel('culturetune/ble_transfer');

  /// レーダーの発信サービス(受信ポスト同居)
  static final presenceGuid = Guid('0000c71e-0000-1000-8000-00805f9b34fb');
  static final inboxMetaGuid = Guid('0000c723-0000-1000-8000-00805f9b34fb');
  static final inboxDataGuid = Guid('0000c724-0000-1000-8000-00805f9b34fb');
  static final inboxRespGuid = Guid('0000c725-0000-1000-8000-00805f9b34fb');

  static bool get canSend => Platform.isIOS;

  /// 送信待機を開始。イベント(状態・進捗)はonEventに流れる。
  static Future<void> serve({
    required String name,
    required Uint8List data,
    required void Function(String event, Object? args) onEvent,
  }) async {
    channel.setMethodCallHandler((call) async {
      onEvent(call.method, call.arguments);
    });
    await channel.invokeMethod('serve', {'name': name, 'data': data});
  }

  static Future<void> stopServe() async {
    channel.setMethodCallHandler(null);
    try {
      await channel.invokeMethod('stop');
    } catch (_) {}
  }

  /// レーダーで見つけた相手(remoteId)へ直接送りつける。
  /// 相手はレーダーON(=受信ポスト公開中)である必要がある。
  /// 流れ: 接続 → リクエスト送信 → 相手がコード入力で承認 → データ転送。
  static Future<SendResult> sendToPeer({
    required String remoteId,
    required String senderName,
    required String code,
    required Uint8List data,
    required void Function(double progress, String label) onProgress,
    required ValueListenable<bool> cancelled,
  }) async {
    final device = BluetoothDevice.fromId(remoteId);
    try {
      onProgress(0, 'つなげてるよ…');
      await device.connect(timeout: const Duration(seconds: 15));
      final services = await device.discoverServices();
      final service = services.firstWhere((s) => s.uuid == presenceGuid);
      BluetoothCharacteristic charOf(Guid guid) =>
          service.characteristics.firstWhere((c) => c.uuid == guid);

      // 承認通知を購読してからリクエストを送る
      final resp = charOf(inboxRespGuid);
      final approval = Completer<String>();
      final respSub = resp.onValueReceived.listen((value) {
        if (!approval.isCompleted) approval.complete(utf8.decode(value));
      });
      device.cancelWhenDisconnected(respSub);
      await resp.setNotifyValue(true);

      await charOf(inboxMetaGuid).write(
        utf8.encode(
          jsonEncode({'size': data.length, 'name': senderName, 'code': code}),
        ),
      );

      onProgress(0, 'あいての承認を待ってるよ…\nコードを教えてあげてね');
      String answer;
      try {
        answer = await Future.any([
          approval.future,
          Future<String>.delayed(const Duration(minutes: 2), () => 'timeout'),
          _waitCancel(cancelled),
        ]);
      } on Object {
        answer = 'error';
      }
      if (answer == 'cancelled') return SendResult.cancelled;
      if (answer == 'no') return SendResult.rejected;
      if (answer != 'ok') return SendResult.timeout;

      // MTUを待ってから最大チャンクで送る(初期値のままだと極端に遅い)
      final mtu = await device.mtu.first;
      final chunkSize = (mtu - 3).clamp(20, 512);
      final dataChar = charOf(inboxDataGuid);
      var sent = 0;
      // 8チャンクを応答なしでまとめて発射し、最後の1本だけ応答ありで
      // フラッシュする(1本ずつawaitするとチャネル往復で遅くなる)
      const burst = 8;
      while (sent < data.length) {
        if (cancelled.value) return SendResult.cancelled;
        final writes = <Future<void>>[];
        for (var i = 0; i < burst && sent < data.length; i++) {
          final end = (sent + chunkSize).clamp(0, data.length);
          final last = end == data.length || i == burst - 1;
          writes.add(
            dataChar.write(data.sublist(sent, end), withoutResponse: !last),
          );
          sent = end;
        }
        await Future.wait(writes);
        onProgress(
          sent / data.length,
          'わたし中… ${(sent / 1024).round()}KB / ${(data.length / 1024).round()}KB',
        );
      }
      onProgress(1, 'とどけたよ!');
      return SendResult.sent;
    } catch (e) {
      if (kDebugMode) debugPrint('[ble_transfer] sendToPeer failed: $e');
      return SendResult.error;
    } finally {
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  static Future<String> _waitCancel(ValueListenable<bool> cancelled) async {
    while (!cancelled.value) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return 'cancelled';
  }

  /// 近くの送信待機中の相手を探して受信する。
  /// 見つからない/失敗はnull。進捗は0.0-1.0で通知。
  static Future<Uint8List?> receive({
    required void Function(double progress, String label) onProgress,
  }) async {
    onProgress(0, 'Bluetoothを準備中…');
    final state = await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            return BluetoothAdapterState.off;
          },
        );
    if (state != BluetoothAdapterState.on) return null;

    onProgress(0, 'あいてを探してるよ…');
    // OSのサービスフィルタは取りこぼすことがあるため、
    // 全スキャンしてアプリ側でUUID選別する(レーダーと同じ方式)
    BluetoothDevice? found;
    final scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final hit = r.advertisementData.serviceUuids.any(
          (g) => g.str128.toLowerCase().contains('c71f'),
        );
        if (hit) {
          found ??= r.device;
          break;
        }
      }
    });
    await FlutterBluePlus.startScan(
      continuousUpdates: true,
      timeout: const Duration(seconds: 25),
    );
    final deadline = DateTime.now().add(const Duration(seconds: 25));
    while (found == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await scanSub.cancel();
    final device = found;
    if (device == null) return null;

    onProgress(0, 'つながった!受信中…');
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      final services = await device.discoverServices();
      final service = services.firstWhere((s) => s.uuid == serviceGuid);
      BluetoothCharacteristic charOf(Guid guid) =>
          service.characteristics.firstWhere((c) => c.uuid == guid);

      final metaRaw = await charOf(metaGuid).read();
      final meta = jsonDecode(utf8.decode(metaRaw)) as Map<String, dynamic>;
      final size = (meta['size'] as num).toInt();
      final senderName = meta['name'] as String? ?? 'ともだち';
      if (size <= 0) return null;

      final buffer = BytesBuilder(copy: false);
      final done = Completer<void>();
      final dataChar = charOf(dataGuid);
      final valueSub = dataChar.onValueReceived.listen((chunk) {
        buffer.add(chunk);
        onProgress(
          (buffer.length / size).clamp(0.0, 1.0),
          '$senderName から受信中… ${(buffer.length / 1024).round()}KB',
        );
        if (buffer.length >= size && !done.isCompleted) done.complete();
      });
      device.cancelWhenDisconnected(valueSub);
      await dataChar.setNotifyValue(true);
      await charOf(ctrlGuid).write(utf8.encode('go'));

      await done.future.timeout(const Duration(minutes: 3));
      onProgress(1, 'できあがり!');
      return buffer.toBytes();
    } catch (e) {
      if (kDebugMode) debugPrint('[ble_transfer] receive failed: $e');
      return null;
    } finally {
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }
}
