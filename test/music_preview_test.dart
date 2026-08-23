import 'package:culture_tune/core/api/music_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MusicPreview.spotifyEmbedUrl', () {
    test('trackのURLを埋め込みURLに変換する', () {
      expect(
        MusicPreview.spotifyEmbedUrl(
          'https://open.spotify.com/track/3n3Ppam7vgaVa1iaRUc9Lp?si=xyz',
        ),
        'https://open.spotify.com/embed/track/3n3Ppam7vgaVa1iaRUc9Lp',
      );
    });
    test('地域プレフィックス付きも対応', () {
      expect(
        MusicPreview.spotifyEmbedUrl(
          'https://open.spotify.com/intl-ja/album/abc123',
        ),
        'https://open.spotify.com/embed/album/abc123',
      );
    });
    test('Spotify以外はnull', () {
      expect(
        MusicPreview.spotifyEmbedUrl('https://music.apple.com/jp/album/x/1'),
        isNull,
      );
    });
  });

  group('MusicPreview.appleMusicId', () {
    test('アルバム内の曲(?i=)を優先する', () {
      expect(
        MusicPreview.appleMusicId(
          'https://music.apple.com/jp/album/lemon/1361157020?i=1361157540',
        ),
        '1361157540',
      );
    });
    test('song形式のパス末尾ID', () {
      expect(
        MusicPreview.appleMusicId(
          'https://music.apple.com/jp/song/lemon/1361157540',
        ),
        '1361157540',
      );
    });
    test('Apple Music以外はnull', () {
      expect(
        MusicPreview.appleMusicId('https://open.spotify.com/track/abc'),
        isNull,
      );
    });
  });
}
