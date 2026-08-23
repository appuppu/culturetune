import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../core/beam/beam_transport.dart';
import '../../core/theme/tokens.dart';

/// アバターカラーの選択肢(気分カラーパレットと共通)
List<Color> get beamColorChoices => CTColors.moodPalette;

/// hex文字列('#FF6B9D')→ Color。不正値はプライマリにフォールバック
Color colorFromHex(String? hex) {
  if (hex == null || !hex.startsWith('#')) return CTColors.primary;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? CTColors.primary : Color(0xFF000000 | value);
}

String hexFromColor(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// カード交換で名乗るプロフィール(端末ローカル保存)
class BeamProfileNotifier extends AsyncNotifier<BeamProfile> {
  static const _nameKey = 'beam_name';
  static const _colorKey = 'beam_color';
  static const _avatarFileName = 'beam_avatar.jpg';

  String get _avatarPath =>
      '${ref.read(documentsDirProvider).path}/$_avatarFileName';

  @override
  Future<BeamProfile> build() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAvatar = File(_avatarPath).existsSync();
    return BeamProfile(
      name: prefs.getString(_nameKey) ?? 'ゲスト',
      colorHex: prefs.getString(_colorKey) ?? '#FF6B9D',
      imagePath: hasAvatar ? _avatarPath : null,
    );
  }

  Future<void> save({
    required String name,
    required String colorHex,
    String? newImagePath,
    bool removeImage = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = name.trim().isEmpty ? 'ゲスト' : name.trim();
    await prefs.setString(_nameKey, trimmed);
    await prefs.setString(_colorKey, colorHex);

    final avatarFile = File(_avatarPath);
    if (removeImage) {
      if (avatarFile.existsSync()) avatarFile.deleteSync();
    } else if (newImagePath != null) {
      await File(newImagePath).copy(_avatarPath);
      // 同名ファイル差し替えのため画像キャッシュを破棄
      imageCache.clear();
      imageCache.clearLiveImages();
    }

    state = AsyncData(
      BeamProfile(
        name: trimmed,
        colorHex: colorHex,
        imagePath: avatarFile.existsSync() ? _avatarPath : null,
      ),
    );
  }
}

final beamProfileProvider =
    AsyncNotifierProvider<BeamProfileNotifier, BeamProfile>(
      BeamProfileNotifier.new,
    );

/// アバター表示: 写真があれば写真、なければ名前の頭文字+カラー
class BeamAvatar extends StatelessWidget {
  const BeamAvatar({
    super.key,
    required this.name,
    required this.color,
    this.imagePath,
    this.radius = 20,
  });

  final String name;
  final Color color;
  final String? imagePath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && File(path).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(path)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        name.isEmpty ? '?' : name.characters.first,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
