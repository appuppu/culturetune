import 'package:flutter/material.dart';

/// アプリ全体のカラーパレット。テーマ切替に対応するため、
/// 全色をCTPaletteのインスタンスとして持つ。
class CTPalette {
  const CTPalette({
    required this.id,
    required this.nameJa,
    required this.description,
    required this.brightness,
    required this.bgBase,
    required this.surface,
    required this.primary,
    required this.primaryGradient,
    required this.textMain,
    required this.textSub,
    required this.shadow,
    required this.mint,
    required this.lemon,
    required this.lavender,
    required this.peach,
    required this.soda,
    required this.book,
    required this.music,
    required this.video,
    required this.food,
    required this.mood,
  });

  final String id;
  final String nameJa;
  final String description;
  final Brightness brightness;

  final Color bgBase;
  final Color surface;
  final Color primary;
  final LinearGradient primaryGradient;
  final Color textMain;
  final Color textSub;
  final Color shadow;

  // 汎用アクセント
  final Color mint;
  final Color lemon;
  final Color lavender;
  final Color peach;
  final Color soda;

  // カテゴリカラー
  final Color book;
  final Color music;
  final Color video;
  final Color food;

  /// 気分カラーパレット(投稿時に選ぶカード縁色)
  final List<Color> mood;
}

/// 選択できるテーマ一覧
abstract final class CTThemes {
  /// ポップ&キュート(デフォルト)
  static const candyPop = CTPalette(
    id: 'candy_pop',
    nameJa: 'キャンディポップ',
    description: 'ポップでキュートなピンク系',
    brightness: Brightness.light,
    bgBase: Color(0xFFFFF7F9),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFF6B9D),
    primaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF8FB8), Color(0xFFFF5C93)],
    ),
    textMain: Color(0xFF33272A),
    textSub: Color(0xFF9A8F94),
    shadow: Color(0x24FF6B9D),
    mint: Color(0xFF4EECD2),
    lemon: Color(0xFFFFD84D),
    lavender: Color(0xFFC5B3FF),
    peach: Color(0xFFFFB48F),
    soda: Color(0xFF7ED6FF),
    book: Color(0xFF34D8BC),
    music: Color(0xFFFF6B9D),
    video: Color(0xFF56BFF5),
    food: Color(0xFFFF9E6B),
    mood: [
      Color(0xFFFF6B9D),
      Color(0xFF34D8BC),
      Color(0xFFFFD84D),
      Color(0xFFC5B3FF),
      Color(0xFFFF9E6B),
      Color(0xFF56BFF5),
      Color(0xFFFF9ECF),
      Color(0xFFA3E063),
    ],
  );

  /// 男性向けモダン・ミニマル
  static const monoModern = CTPalette(
    id: 'mono_modern',
    nameJa: 'モノモダン',
    description: 'シンプルで落ち着いたモノトーン系',
    brightness: Brightness.light,
    bgBase: Color(0xFFF6F6F7),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF1F2430),
    primaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2E3442), Color(0xFF191D26)],
    ),
    textMain: Color(0xFF1B1D22),
    textSub: Color(0xFF8A8D94),
    shadow: Color(0x14000000),
    mint: Color(0xFF5AA88F),
    lemon: Color(0xFFC9A24B),
    lavender: Color(0xFF8B87B8),
    peach: Color(0xFFBE8A6A),
    soda: Color(0xFF6B93B8),
    book: Color(0xFF5AA88F),
    music: Color(0xFF56607A),
    video: Color(0xFF6B93B8),
    food: Color(0xFFBE8A6A),
    mood: [
      Color(0xFF1F2430),
      Color(0xFF5AA88F),
      Color(0xFFC9A24B),
      Color(0xFF8B87B8),
      Color(0xFFBE8A6A),
      Color(0xFF6B93B8),
      Color(0xFF9A5B66),
      Color(0xFF7C8A5A),
    ],
  );

  /// ダーク+ネオン
  static const neonNight = CTPalette(
    id: 'neon_night',
    nameJa: 'ネオンナイト',
    description: '夜っぽいダーク×ネオン系',
    brightness: Brightness.dark,
    bgBase: Color(0xFF17151C),
    surface: Color(0xFF232030),
    primary: Color(0xFFFF6B9D),
    primaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF7FAC), Color(0xFFE84C82)],
    ),
    textMain: Color(0xFFF4F0F2),
    textSub: Color(0xFF9A93A5),
    shadow: Color(0x66000000),
    mint: Color(0xFF3EE6C4),
    lemon: Color(0xFFFFE066),
    lavender: Color(0xFFB39DFF),
    peach: Color(0xFFFFA26B),
    soda: Color(0xFF63D2FF),
    book: Color(0xFF3EE6C4),
    music: Color(0xFFFF6B9D),
    video: Color(0xFF63D2FF),
    food: Color(0xFFFFA26B),
    mood: [
      Color(0xFFFF6B9D),
      Color(0xFF3EE6C4),
      Color(0xFFFFE066),
      Color(0xFFB39DFF),
      Color(0xFFFFA26B),
      Color(0xFF63D2FF),
      Color(0xFFFF8FD0),
      Color(0xFFA6E86B),
    ],
  );

  /// さわやかミント×ソーダ
  static const mintSoda = CTPalette(
    id: 'mint_soda',
    nameJa: 'ミントソーダ',
    description: 'さわやかなミント×ブルー系',
    brightness: Brightness.light,
    bgBase: Color(0xFFF3FAF9),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF18B9A2),
    primaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2FD0B8), Color(0xFF10A18D)],
    ),
    textMain: Color(0xFF1E2B29),
    textSub: Color(0xFF7D928E),
    shadow: Color(0x1F18B9A2),
    mint: Color(0xFF18B9A2),
    lemon: Color(0xFFFFD84D),
    lavender: Color(0xFF9DA9F0),
    peach: Color(0xFFFF9E6B),
    soda: Color(0xFF4FB6F0),
    book: Color(0xFF18B9A2),
    music: Color(0xFF9DA9F0),
    video: Color(0xFF4FB6F0),
    food: Color(0xFFFF9E6B),
    mood: [
      Color(0xFF18B9A2),
      Color(0xFF4FB6F0),
      Color(0xFFFFD84D),
      Color(0xFF9DA9F0),
      Color(0xFFFF9E6B),
      Color(0xFF63D97C),
      Color(0xFFFF8FA8),
      Color(0xFF7E8CE0),
    ],
  );

  static const all = [candyPop, monoModern, neonNight, mintSoda];

  static CTPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => candyPop);
}

/// 現在のテーマの色に静的アクセスするためのファサード。
/// テーマ切替時は CTColors.current を差し替えてアプリを再ビルドする。
abstract final class CTColors {
  static CTPalette current = CTThemes.candyPop;

  static Color get bgBase => current.bgBase;
  static Color get surface => current.surface;
  static Color get primary => current.primary;
  static LinearGradient get primaryGradient => current.primaryGradient;
  static Color get textMain => current.textMain;
  static Color get textSub => current.textSub;
  static Color get shadow => current.shadow;
  static Color get mint => current.mint;
  static Color get lemon => current.lemon;
  static Color get lavender => current.lavender;
  static Color get peach => current.peach;
  static Color get soda => current.soda;
  static List<Color> get moodPalette => current.mood;

  /// アクセント色の上に載せる文字色。
  /// 明るい色には濃色、暗い色には白(ダークテーマでの視認性対策)
  static Color onAccent(Color bg) =>
      bg.computeLuminance() > 0.5 ? const Color(0xFF1B1D22) : Colors.white;
}

abstract final class CTRadius {
  /// カードらしい控えめな角丸
  static const card = 14.0;
  static const button = 16.0;
  static const sheet = 24.0;
  static const pill = 999.0;

  /// ネストした角丸の内側半径。デザインの定石
  /// 「innerRadius = outerRadius - gap(枠線幅やpadding)」に従う。
  static double inner(double outer, double gap) =>
      (outer - gap).clamp(0, outer).toDouble();
}

/// カードのふんわり浮き出るシャドウ
List<BoxShadow> get ctCardShadow => [
  BoxShadow(color: CTColors.shadow, blurRadius: 16, offset: const Offset(0, 5)),
];
