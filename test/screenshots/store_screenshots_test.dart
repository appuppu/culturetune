import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:culture_tune/app/providers.dart';
import 'package:culture_tune/core/db/app_database.dart';
import 'package:culture_tune/core/theme/tokens.dart';
import 'package:culture_tune/features/beam/beam_page.dart';
import 'package:culture_tune/features/book/pages_page.dart';
import 'package:culture_tune/features/studio/studio_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ストア用スクリーンショットの生成ツール。
/// 通常のテスト実行ではスキップされる。生成するときは:
///   flutter test --dart-define=SCREENSHOTS=1 test/screenshots/
/// 出力: release_assets/screenshots/{ios,android}/
void main() {
  const enabled = bool.fromEnvironment('SCREENSHOTS');

  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loadFonts() async {
    Future<void> loadFamily(String family, List<String> paths) async {
      final loader = FontLoader(family);
      for (final path in paths) {
        final file = File(path);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          loader.addFont(Future.value(ByteData.view(bytes.buffer)));
        }
      }
      await loader.load();
    }

    // アプリのフォント名に欧文+ヒラギノを割り当てて実機同等の見た目にする
    const textFonts = [
      '/System/Library/Fonts/Supplemental/Arial.ttf',
      '/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc',
      '/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc',
    ];
    await loadFamily('MPLUSRounded1c', textFonts);
    await loadFamily('Roboto', textFonts);
    // Materialアイコン(Flutter SDKのキャッシュから)
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      await loadFamily('MaterialIcons', [
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    }
  }

  /// GoogleFontsを使わない撮影用テーマ(実機と同じ見た目・フォントは読込済み)
  ThemeData shotTheme(CTPalette palette) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      fontFamily: 'MPLUSRounded1c',
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: palette.brightness,
        primary: palette.primary,
        surface: palette.surface,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: palette.bgBase,
      textTheme: base.textTheme.apply(
        bodyColor: palette.textMain,
        displayColor: palette.textMain,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: palette.textMain,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'MPLUSRounded1c',
            color: palette.textMain,
          ),
        ),
      ),
    );
  }

  Widget shell(
    AppDatabase db,
    Widget body,
    int tabIndex, {
    int studioSegment = 0,
  }) {
    final tempDir = Directory.systemTemp.createTempSync('shot');
    CTColors.current = CTThemes.candyPop;
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        documentsDirProvider.overrideWithValue(tempDir),
        studioSegmentProvider.overrideWith((ref) => studioSegment),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: shotTheme(CTThemes.candyPop),
        home: Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            height: 56,
            selectedIndex: tabIndex,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.menu_book_rounded),
                label: 'シール帳',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_fix_high_rounded),
                label: 'シール',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_rounded),
                label: '交換',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> capture(
    WidgetTester tester,
    Widget app, {
    required Size logical,
    required double ratio,
    required String outPath,
  }) async {
    tester.view.physicalSize = logical * ratio;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: app));
    // 非同期プロバイダの解決とアニメーションの静定を待つ
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: ratio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(outPath);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  final targets = <String, (Size, double)>{
    // App Store 6.9インチ: 1320x2868
    'ios': (const Size(440, 956), 3.0),
    // Google Play: 1080x2340
    'android': (const Size(360, 780), 3.0),
  };

  final screens = <String, Widget Function(AppDatabase db)>{
    '1_book': (db) => shell(db, const PagesPage(), 0),
    '2_sticker': (db) => shell(db, const StudioPage(), 1),
    '3_card': (db) => shell(db, const StudioPage(), 1, studioSegment: 1),
    '4_exchange': (db) => shell(db, const BeamPage(), 2),
  };

  for (final MapEntry(key: platform, value: (logical, ratio))
      in targets.entries) {
    for (final MapEntry(key: name, value: builder) in screens.entries) {
      testWidgets('screenshot $platform $name', (tester) async {
        if (!enabled) {
          markTestSkipped('SCREENSHOTS=1のときだけ実行');
          return;
        }
        SharedPreferences.setMockInitialValues({});
        await loadFonts();
        final db = AppDatabase(NativeDatabase.memory());
        await capture(
          tester,
          builder(db),
          logical: logical,
          ratio: ratio,
          outPath: 'release_assets/screenshots/$platform/$name.png',
        );
        // タイマー残留を防ぐため、ツリーを破棄して残タイマーを消化する
        await tester.pumpWidget(const SizedBox());
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        unawaited(db.close());
      });
    }
  }
}
