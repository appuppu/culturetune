import 'dart:io';

/// Documents配下のファイル参照はDBに「相対パス」で保存する。
///
/// iOSは再インストール(開発中の再ビルド含む)のたびにアプリコンテナの
/// UUIDが変わるため、絶対パスを保存すると次回起動で全部リンク切れになる
/// (背景が赤いバツになる原因)。旧データの絶対パスは、既知のマーカー以降を
/// 取り出して現在のDocumentsに付け替えて救済する。
const _markers = ['/Documents/', '/app_flutter/'];

/// 相対 or 旧絶対パス → 現在の端末で有効な絶対パス
String resolveDocFile(Directory docs, String path) {
  if (!path.startsWith('/')) return '${docs.path}/$path';
  if (File(path).existsSync()) return path;
  for (final marker in _markers) {
    final i = path.indexOf(marker);
    if (i != -1) return '${docs.path}/${path.substring(i + marker.length)}';
  }
  return path;
}

/// 絶対パス → DB保存用の相対パス(Documents外のパスはそのまま返す)
String toRelativeDocPath(Directory docs, String path) {
  if (!path.startsWith('/')) return path;
  if (path.startsWith('${docs.path}/')) {
    return path.substring(docs.path.length + 1);
  }
  for (final marker in _markers) {
    final i = path.indexOf(marker);
    if (i != -1) return path.substring(i + marker.length);
  }
  return path;
}
