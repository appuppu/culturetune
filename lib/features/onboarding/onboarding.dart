import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/tokens.dart';

const _onboardKey = 'onboarded_v1';

/// 初回起動時だけ「このアプリで何ができるか」を1枚で見せる。
Future<void> maybeShowOnboarding(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_onboardKey) ?? false) return;
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: CTColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Culture Tuneへようこそ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: CTColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '音楽が鳴るシール帳',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: CTColors.textSub),
            ),
            const SizedBox(height: 20),
            const _Step(
              icon: Icons.auto_fix_high_rounded,
              title: '写真がシールになる',
              body: '写真を選ぶだけで自動で切り抜き。ホロやぷくぷくの質感も選べる',
            ),
            const _Step(
              icon: Icons.music_note_rounded,
              title: '貼ったシールが鳴る',
              body: '音楽・動画・ご飯を埋め込むと、シール帳の上でタップして再生できる',
            ),
            const _Step(
              icon: Icons.swap_horiz_rounded,
              title: '友達と交換できる',
              body: 'シールやページをLINEで送れる。あげても自分のは減らない',
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: CTColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_onboardKey, true);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              child: const Text(
                'はじめる',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CTColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: CTColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: CTColors.textSub,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
