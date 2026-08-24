import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/providers.dart';
import 'app/theme.dart';
import 'features/beam/beam_page.dart';
import 'features/distribution/link_receiver.dart';
import 'features/onboarding/onboarding.dart';
import 'features/book/pages_page.dart';
import 'features/studio/studio_page.dart';
import 'features/settings/theme_provider.dart';
import 'features/mix/mini_player.dart';

/// 配布リンク受信時にどこからでも画面を出すためのキー
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedPalette();
  final docsDir = await getApplicationDocumentsDirectory();
  runApp(
    ProviderScope(
      overrides: [documentsDirProvider.overrideWithValue(docsDir)],
      child: const CultureTuneApp(),
    ),
  );
}

class CultureTuneApp extends ConsumerWidget {
  const CultureTuneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'しーるちょー',
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(palette),
      home: const HomeShell(),
      // 画面のどこをタップしてもキーボードを閉じられるようにする
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  late final LinkReceiver _linkReceiver = LinkReceiver(navigatorKey);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowOnboarding(context);
    });
    _linkReceiver.start(ref);
  }

  @override
  void dispose() {
    _linkReceiver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // プレイヤーはコンテンツを縮めず、上に浮かせて表示する
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _index,
              children: const [PagesPage(), StudioPage(), BeamPage()],
            ),
          ),
          const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 56, // コンテンツを主役にするため低めに
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
    );
  }
}
