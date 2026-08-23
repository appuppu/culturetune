/// Beam(すれ違い)関連の抽象。
/// v1はBLEで「近くにいること」だけを検知し、カード本体はQRで受け渡す。
/// v2でBLE GATT直接転送やMultipeer(iOS同士)をこのインターフェースの
/// 実装として差し替えられるようにしている。
library;

class BeamProfile {
  const BeamProfile({
    required this.name,
    required this.colorHex,
    this.imagePath,
  });

  final String name;

  /// アバターカラー(例: '#FF6B9D')。絵文字は使わず色+頭文字で表現する
  final String colorHex;

  /// プロフィール写真(端末内の絶対パス)。交換相手には送られない
  final String? imagePath;

  /// BLEアドバタイズに載せる短い表示名(バイト数制限があるため詰める)
  String get advertiseName => name.length > 10 ? name.substring(0, 10) : name;
}

class BeamPeer {
  const BeamPeer({required this.id, required this.displayName});

  /// スキャンで得たデバイス識別子(OSにより匿名化される)
  final String id;
  final String displayName;

  @override
  bool operator ==(Object other) => other is BeamPeer && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum BeamPresenceStatus {
  idle,
  advertising,
  unsupported,
  permissionDenied,
  error,
}

/// 近接検知トランスポートの抽象
abstract interface class BeamTransport {
  /// 自分の存在をアドバタイズし、周囲のスキャンを開始する
  Future<void> start(BeamProfile me);

  /// 現在見えている相手の一覧(数秒見えなくなった相手は消える)
  Stream<List<BeamPeer>> get peers;

  /// 現在の状態(権限なし・非対応などのUI表示用)
  Stream<BeamPresenceStatus> get status;

  Future<void> stop();
}
