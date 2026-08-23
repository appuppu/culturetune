# Culture Tune 設計書 v1

決定事項: Flutter / Beam v1 = BLE検知 + QR交換 / YouTubeはインライン再生 + 推しMIX

---

## 1. 使用技術

### コア
| 領域 | 採用技術 | 備考 |
|---|---|---|
| フレームワーク | Flutter 3.x / Dart 3 | iOS・Android 1コードベース |
| 状態管理 | Riverpod 3 | |
| ルーティング | go_router | |
| ローカルDB | drift (SQLite) | 型安全・マイグレーション対応。画像はDocumentsディレクトリに保存しDBには相対パスのみ |
| フォント | google_fonts: M PLUS Rounded 1c(本文)+ Baloo 2(ロゴ・英字) | 丸ゴでキュート感 |

### 機能別ライブラリ
| 機能 | ライブラリ |
|---|---|
| YouTube再生 | youtube_player_iframe(公式IFrame Player API・キー不要・規約準拠) |
| リンクプレビュー/OGP | metadata_fetch + YouTube oEmbed(キー不要) |
| バーコード(ISBN)/QR読取 | mobile_scanner |
| QR生成 | qr_flutter |
| BLE検知 | flutter_ble_peripheral(advertise)+ flutter_blue_plus(scan) |
| iOS限定マップ | apple_maps_flutter(Platform分岐) |
| 写真/カメラ | image_picker |
| 位置情報 | geolocator |
| 共有シート受信 | receive_sharing_intent(iOSはShare Extensionを薄くネイティブ実装) |
| アニメーション | flutter_animate + Lottie(紙吹雪・キャンディ演出)、HapticFeedback |
| 画像処理 | image(サムネ圧縮 WebP化) |

### 外部API(すべて無料)
- ※映画カテゴリは非搭載: TMDbは個人利用限定(広告収益化で商用$149/mo)、iTunes Search APIは映画結果を返さなくなり、Wikipediaはポスター無し。「無料・商用可・ポスター付き」の映画APIが存在しないため
- openBD API(キー不要)— ISBN→書誌。フォールバックに Google Books(キー不要)
- YouTube oEmbed `https://www.youtube.com/oembed?url=...`(キー不要)— タイトル/サムネ/チャンネル名
- OGPスクレイピング — その他URL(音楽サブスクの共有リンク等)

---

## 2. プロジェクト構成(feature-first)

```
lib/
  app/            # MaterialApp, router, theme
  core/
    db/           # drift schema, DAO
    api/          # tmdb_client, openbd_client, ogp_client, oembed_client
    models/       # CultureItem, BeamCard ほか
    theme/        # design tokens (色/角丸/影/タイポ)
  features/
    vault/        # 棚タブ (grid, filter, search)
    post/         # 登録フロー (カテゴリ別ウィザード)
    detail/       # カード詳細・インライン再生・カード画像書き出し
    beam/         # すれ違いタブ (BLE検知UI, QR交換)
    mix/          # 推しMIXミニプレイヤー
    map/          # iOS限定 Foodマップ
    wrap/         # 月間まとめ (Culture Wrap)
```

---

## 3. データ設計

### 3.1 CultureItem(単一テーブル + カテゴリ別詳細JSON)

```sql
CREATE TABLE culture_items (
  id            TEXT PRIMARY KEY,          -- UUID v4
  category      TEXT NOT NULL,             -- book | music | video | food
  title         TEXT NOT NULL,
  subtitle      TEXT,                      -- 著者 / チャンネル名 / 店名 など
  thumb_path    TEXT,                      -- ローカル保存画像(相対パス, WebP)
  thumb_url     TEXT,                      -- 元URL(交換時の再取得用)
  external_id   TEXT,                      -- tmdbId / ISBN / videoId / URL
  url           TEXT,
  memo          TEXT,                      -- 一言メモ 140字
  oshi_level    INTEGER NOT NULL DEFAULT 3,-- 推し度 1..5 (ハート)
  mood_tags     TEXT NOT NULL DEFAULT '[]',-- エモタグ JSON配列 (最大3)
  mood_color    TEXT,                      -- 気分カラー (カード縁色, hex)
  detail_json   TEXT NOT NULL DEFAULT '{}',-- カテゴリ固有フィールド
  lat           REAL, lng REAL,            -- food/iOSのみ
  place_name    TEXT,
  source        TEXT NOT NULL DEFAULT 'self', -- self | beam
  beam_from     TEXT,                      -- 交換相手の表示名
  is_favorite   INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL,
  consumed_at   INTEGER                    -- 観た日/読んだ日/食べた日
);
CREATE INDEX idx_items_category ON culture_items(category);
CREATE INDEX idx_items_created ON culture_items(created_at DESC);
```

### 3.2 detail_json の中身(カテゴリ別)
- book: `{ "isbn": "978...", "author": "...", "publisher": "..." }`
- music / video: `{ "videoId": "abc", "channel": "...", "siteName": "YouTube", "savedTimeOfDay": "night" }`
- food: `{ "storeName": "...", "menuName": "...", "priceYen": 480 }`

### 3.3 交換履歴

```sql
CREATE TABLE beams (
  id TEXT PRIMARY KEY,
  direction TEXT NOT NULL,   -- sent | received
  peer_name TEXT NOT NULL,
  peer_emoji TEXT,
  card_id TEXT NOT NULL,
  beamed_at INTEGER NOT NULL
);
```

---

## 4. 通信設計(Beam)

### 4.1 v1 方式: BLE検知 + QR交換
- **検知**: 固有Service UUIDでBLEアドバタイズ+スキャン。近くのCulture Tuneユーザーを検出したら、Beam画面にキャンディアバターがポヨンと出現(名前+絵文字はアドバタイズデータに載る範囲の短いプロフィールのみ)。
- **交換**: 送り手がカードをスワイプ→QRコード表示、受け手がスキャン。iOS↔Android完全互換・権限フリクション最小。
- **QRに画像は載らない**ため、book/music/videoは `thumb_url`(公開URL)を受信側が再取得。foodの自撮り写真は v1 では絵文字プレースホルダ+店名で受け渡し(v2の直接転送で解消)。

### 4.2 抽象インターフェース(v2で直接転送に差し替え可能)

```dart
abstract interface class BeamTransport {
  Future<void> startAdvertising(BeamProfile me);
  Stream<BeamPeer> discoverPeers();          // BLEスキャン結果
  Future<void> offer(BeamCard card);          // v1: QR表示
  Stream<BeamCard> incomingCards();           // v1: QRスキャン結果
  Future<void> stop();
}
// v1: BleQrTransport
// v2: BleGattTransport(クロスOS直接転送) / MultipeerTransport(iOS同士高速転送)
```

### 4.3 カードパケット(JSON, バージョン付き)

```json
{
  "v": 1,
  "kind": "culture_card",
  "sender": { "name": "たくみ", "emoji": "🍬" },
  "card": {
    "category": "music",
    "title": "...",
    "subtitle": "...",
    "thumbUrl": "https://i.ytimg.com/...",
    "externalId": "videoId or ISBN or tmdbId",
    "url": "...",
    "oshiLevel": 5,
    "moodTags": ["神", "リピ確"],
    "moodColor": "#FF6B9D"
  }
}
```
- **プライバシー**: 個人メモ・位置情報(lat/lng)は交換パケットからデフォルト除外。
- 受信カードは `source: "beam"`, `beam_from` 付きで保存し、Vaultで「〇〇からもらった」バッジ表示。

---

## 5. 投稿様式(登録フロー — 目標3タップ)

「＋」→ ボトムシートにキャンディ型カテゴリボタン5つ → カテゴリ別動線:

| カテゴリ | 動線 |
|---|---|
| 📚 Book | カメラ起動→ISBNバーコードスキャン→openBD(失敗時Google Books)で自動入力 |
| 🎵 Music / 📺 Video | URLペースト or 共有シート → oEmbed/OGPで即プレビュー表示 → 確定 |
| 🍦 Food | 写真撮影/選択 + 店名 + 推しメニュー名(iOSは現在地を自動付与、オフ可) |

**共通の仕上げ画面(1画面で完結)**:
- 推し度: ハート1〜5(タップでぷっくり膨らむ+ハプティクス)
- エモタグ: チップから最大3つ — `神 / 尊い / エモい / 泣ける / バイブス / リピ確 / 沼 / じわる / ととのう / 覇権`
- 一言メモ: 140字
- 気分カラー: 8色パレットから1つ(カードの縁色になる)

---

## 6. 表示デザイン

### Vault(棚タブ)
- ヘッダー: 「Culture Tune 🍬」ロゴ + カテゴリピル(All/📚/🍦/🎵/📺)+ ぷっくり「＋」
- 2列マソンリーグリッド。カードは**トレカ風**: 気分カラーの縁 + ホロ風グラデの角 + 推し度ハート + エモタグ1つ
- beamでもらったカードは「🎁 from 〇〇」リボン
- 並び替え: 新着 / 推し度 / カテゴリ

### 詳細画面
- タップでカードがフリップ(表=ビジュアル、裏=メモ・タグ)
- Music/Videoは**カード内でiframeインライン再生**
- **カード画像書き出し**: 1080×1920のストーリーサイズPNGを生成して共有シートへ(SNS機能は持たないが、スクショ共有文化に乗る)

### 推しMIX(若年層フック)
- 保存したMusic/Videoカードを連続再生するプレイリスト
- 画面下部にキャンディ型ミニプレイヤーが常駐(再生中はぷるぷる揺れる)
- 「今日の推しMIX」= 推し度とエモタグからシャッフル生成

### Beam(交換タブ)
- パステルグラデ背景にキャンディアバターがぷかぷか浮遊(BLE検知で出現)
- カードを相手にスワイプ→「ポーン」と飛ぶ→QR表示
- 交換成立でLottie紙吹雪 + 強めハプティクス

### そのほか
- 月間まとめ「**Culture Wrap(かるちゅーレポ)**」: 今月の登録数・推しジャンル・ベストカードをストーリー画像で書き出し
- iOSホーム画面ウィジェット: 「今日の推しカード」ランダム表示
- iOS限定: Foodカードのパステルピンマップ(MapKit)。Androidはタップで外部マップ起動

---

## 7. カラーデザイン(デザイントークン)

### ライトテーマ「Candy Pop」(デフォルト)
| トークン | 値 | 用途 |
|---|---|---|
| bg.base | #FFF7F9 | 画面背景(シュガーピンクホワイト) |
| bg.surface | #FFFFFF | カード背景 |
| primary | #FF6B9D | キャンディピンク(主ボタン・アクティブ) |
| primary.gradient | #FF8FB8 → #FF5C93 | ぷっくりボタンのグラデ |
| accent.mint | #4EECD2 | 成功・完了 |
| accent.lemon | #FFE853 | ハイライト・推し度ハート |
| accent.lavender | #C5B3FF | |
| accent.peach | #FFB48F | |
| accent.soda | #7ED6FF | |
| text.main | #33272A | 柔らかチャコール |
| text.sub | #9A8F94 | |
| shadow | rgba(255,107,157,0.16) blur24 y8 | ピンクがかったふんわり影 |

### カテゴリカラー(ピル・カード縁・ピンに一貫使用)
📚 Book = mint / 🎵 Music = candy pink / 📺 Video = soda / 🍦 Food = peach(lavenderは汎用アクセントとして温存)

### ダークテーマ「Neon Night」(若年層向けオプション)
- bg #1E1B26 / surface #2A2533、アクセントは同色相のネオン発光(グロー影)版
- 夜に保存したカードが多いユーザーに「夜モード解放」演出で提供すると刺さる

### 形状・質感
- 角丸: カード24px / ボタン28px(ほぼピル)/ シート上部32px
- ボタンは上部に白のインナーハイライトでキャンディの光沢
- タップ時 scale 0.96→1.03→1.0 のバウンス + light haptic


---

# v2 ピボット: シール帳(2026-08-24)

方針転換: 「カルチャーカード集め」から**シール帳**を主役に全振り。
カード機能はシールに埋め込む「カルチャーデータソース」として存続。

## タブ構成
シール帳(ページ一覧) / パレット(シール素材) / カード(旧Vault) / 交換

## データモデル(DB v3)
- `stickers`: 加工済み透過PNG + texture(normal/puffy/clear/holo) + 作者クレジット + linkedItemId(culture_items)
- `sticker_pages`: デコページ(背景色/タイトル)
- `page_stickers`: 配置(x,y=相対0..1中心 / scale / rotation / z)

## シール加工パイプライン
1. 被写体切り抜き: iOS=VisionKit VNGenerateForegroundInstanceMask(iOS17+, MethodChannel `culturetune/cutout`) / Android=ML Kit Subject Segmentation。不可なら角丸マスクにフォールバック
2. StickerFactory(dart:ui): シルエットを円周スタンプで膨張→白フチ、黒ぼかしで影、saveLayer+dstInで質感を形状マスク
3. ホロは表示時にShaderMask(srcATop)+加速度センサーで光の帯が動く

## 交換(サーバーレス・クロスOS)
- シールPNGのtEXtチャンク(keyword: culturetune)にJSON埋め込み(StickerShare)。CRC32自前実装
- 非消費型: 送信しても手元に残る。受信側はギャラリーから取り込み→作者クレジット+埋め込みカルチャー(BeamCard経由)を復元
- ページはフラットPNG書き出しで送る(再編集可能なページ転送はv2以降)
- MultipeerConnectivity/Nearby Connectionsは相互非互換のため、直接転送は同OS間限定機能として将来対応

## 削除した仕様
- 推し度(ハート): 「好きなものしか投稿しないので不要」(ユーザー判断)

## v2.1 (2026-08-24)
- キャンバスを9:16(ストーリーサイズ)化、書き出し1080x1920
- page_stickers → page_elements(sticker/card/text + payload JSON, DB v4)
- カード要素: ページ上に貼れてダブルタップで詳細/再生。テキスト要素: 色/サイズ選択、ダブルタップで再編集
- ページタイトル編集(AppBarタップ)
- タブ3つに再構成: シール帳 / シール(シール+カード統合、セグメント切替) / 交換
- 交換はシール送信・シール帳(ページ)送信・取り込みに刷新。カードQR交換は廃止(カードはシール/ページ経由で流通)
- 受信ページは背景画像付きページとして復元(その上から追いデコ可能)
- GIF素材(GIPHY/Tenor)は無料APIキーで追加可能だが未実装(書き出しが静止画になる制約あり)
