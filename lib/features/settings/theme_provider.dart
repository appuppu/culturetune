import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/tokens.dart';

const _themeKey = 'theme_id';

/// アプリ起動前に呼び、保存済みテーマをCTColorsへ反映する
Future<CTPalette> loadSavedPalette() async {
  final prefs = await SharedPreferences.getInstance();
  final palette = CTThemes.byId(prefs.getString(_themeKey));
  CTColors.current = palette;
  return palette;
}

class ThemeNotifier extends Notifier<CTPalette> {
  @override
  CTPalette build() => CTColors.current;

  Future<void> select(CTPalette palette) async {
    CTColors.current = palette;
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, palette.id);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, CTPalette>(
  ThemeNotifier.new,
);
