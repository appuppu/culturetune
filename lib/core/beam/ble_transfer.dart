import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  static Future<bool> sendToPeer({
    required String remoteId,
    required String senderName,
    required Uint8List data,
    required void Function(double progress, String label) onProgress,
  }) async {
    final device = BluetoothDevice.fromId(remoteId);
    try {
      onProgress(0, 'つなげてるよ…');
      await device.connect(timeout: const Duration(seconds: 15));
      final services = await device.discoverServices();
      final service = services.firstWhere((s) => s.uuid == presenceGuid);
      final meta = service.characteristics.firstWhere(
        (c) => c.uuid == inboxMetaGuid,
      );
      final dataChar = service.characteristics.firstWhere(
        (c) => c.uuid == inboxDataGuid,
      );

      await meta.write(
        utf8.encode(jsonEncode({'size': data.length, 'name': senderName})),
      );

      final chunkSize = (device.mtuNow - 3).clamp(20, 512);
      var sent = 0;
      var chunkIndex = 0;
      while (sent < data.length) {
        final end = (sent + chunkSize).clamp(0, data.length);
        // 流量制御: 8チャンクごとに応答ありで書いて詰まりを防ぐ
        final flush = chunkIndex % 8 == 7 || end == data.length;
        await dataChar.write(data.sublist(sent, end), withoutResponse: !flush);
        sent = end;
        chunkIndex++;
        if (chunkIndex % 8 == 0 || sent == data.length) {
          onProgress(sent / data.length, 'わたし中… ${(sent / 1024).round()}KB');
        }
      }
      onProgress(1, 'とどけたよ!');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ble_transfer] sendToPeer failed: $e');
      return false;
    } finally {
      try {
        await device.disconnect();
      } catch (_) {}
    }
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
