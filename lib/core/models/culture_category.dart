import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum CultureCategory {
  // 並び順はカテゴリピル等の表示順(All, 音楽, 動画, ご飯, 本)
  music(icon: Icons.music_note_rounded, labelJa: '音楽'),
  video(icon: Icons.smart_display_rounded, labelJa: '動画'),
  food(icon: Icons.restaurant_rounded, labelJa: 'ご飯'),
  book(icon: Icons.menu_book_rounded, labelJa: '本');

  const CultureCategory({required this.icon, required this.labelJa});

  final IconData icon;
  final String labelJa;

  /// サムネイルの縦横比(幅/高さ)。コンテンツの形に合わせる
  double get thumbAspect => switch (this) {
    CultureCategory.video => 16 / 9, // 横長
    CultureCategory.book => 0.7, // 縦長(表紙)
    CultureCategory.music => 1, // 正方形(ジャケット)
    CultureCategory.food => 1, // 正方形(クロップ済み写真)
  };

  /// カテゴリカラー(現在のテーマから引く)
  Color get color => switch (this) {
    CultureCategory.book => CTColors.current.book,
    CultureCategory.music => CTColors.current.music,
    CultureCategory.video => CTColors.current.video,
    CultureCategory.food => CTColors.current.food,
  };
}

/// カードの出どころ
enum CardSource { self, beam }

/// Beam交換の方向
enum BeamDirection { sent, received }

/// エモタグ(投稿時に最大3つ選択)。カテゴリごとに刺さる語彙を変える
List<String> moodTagsFor(CultureCategory category) => switch (category) {
  CultureCategory.book => [
    '尊い',
    '泣ける',
    '一気読み',
    '神展開',
    '沼',
    '人生変わる',
    'じわる',
    '読み返す',
    '徹夜注意',
    'エモい',
  ],
  CultureCategory.music => [
    '神曲',
    'リピ確',
    'バイブス',
    '歌詞が刺さる',
    'エモい',
    '沼',
    '夜に聴く',
    '作業用',
    'ライブ行きたい',
    '泣ける',
  ],
  CultureCategory.video => [
    '神回',
    '爆笑',
    'リピ確',
    'ためになる',
    '沼',
    '覇権',
    'じわる',
    '作業用',
    '深夜に見がち',
    'エモい',
  ],
  CultureCategory.food => [
    '神うま',
    'リピ確',
    '映え',
    'コスパ神',
    'デカ盛り',
    'ととのう',
    'ご褒美',
    '深夜に思い出す',
    '沼',
    '幸せ',
  ],
};
