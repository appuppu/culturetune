# Culture Tune(かるちゅー)

**シール帳アプリ**。写真から被写体を自動で切り抜いて「本物みたいなシール」にして、
ページに自由にデコって、友達とシールを交換できる。
シールには音楽・動画・本・ご飯(カルチャー)を埋め込めて、タップで再生やマップ表示ができる。
SNS要素・サーバー・アルゴリズムなし、完全ローカル完結。

- 設計書: [docs/DESIGN.md](docs/DESIGN.md)
- 対応: iOS 15.5+(被写体切り抜きはiOS 17+) / Android (minSdk 24)

## 機能

| 機能 | 内容 |
|---|---|
| シール作成 | 写真から被写体を1タップ自動切り抜き(iOS: VisionKit / Android: ML Kit)。白フチ+ドロップシャドウ+光沢を自動付与。切り抜き不可時は角丸シールにフォールバック |
| 質感 | ノーマル / ぷくぷくジェル / 半透明クリア / ホログラム(傾きセンサー連動でキラキラ反射) |
| カルチャー埋め込み | シールにカード(音楽/動画/本/ご飯)を紐付け。タップで詳細が開き、YouTubeインライン再生やマップ表示 |
| デコキャンバス | シールをドラッグ配置、ピンチ拡縮、2本指回転、前面/背面入れ替え。貼る=ペタッ/剥がす=ペリッのハプティクス。1080px PNGで書き出し共有 |
| シール交換 | **非消費型**(あげても手元に残る)。PNGのtEXtチャンクにメタデータを埋め込み、LINE等で送信→受信側はパレットの「取り込む」で追加。作者クレジット(Created by 〇〇)と埋め込みカルチャーも復元。BLEレーダーで近くのユーザー検知+QR交換も継続 |
| カード | カルチャーの登録(ISBNスキャン/URLプレビュー/店舗検索)、ピン留め、推しMIX連続再生、ご飯マップ(写真丸ピン)、月間レポ |
| テーマ | キャンディポップ / モノモダン / ネオンナイト / ミントソーダを設定から選択 |

## セットアップ

```bash
flutter pub get
dart run build_runner build   # driftコード生成(スキーマ変更時のみ)
cd ios && pod install         # iOS初回のみ
```

### 利用API(すべてキー不要・無料・商用利用可)

| API | 用途 |
|---|---|
| openBD → Google Books | ISBN→書誌・書影 |
| YouTube oEmbed + 公式iframe埋め込み | 動画/音楽のメタデータと再生 |
| OGPパース | その他URLのリンクプレビュー |

**映画カテゴリを持たない理由**: TMDbの無料キーは個人利用限定で、広告収益化すると
商用ライセンス($149/mo)が必要。iTunes Search APIは映画の検索結果を返さなくなっており、
Wikipediaはポスター画像を持たない。「無料・商用可・ポスター付き」を満たす映画APIが
存在しないため、映画カテゴリは非搭載とした(将来TMDb商用契約すれば追加可能)。

## テスト・検証

```bash
flutter analyze
flutter test
dart run tool/api_smoke_test.dart   # 実APIの疎通確認
```

## アーキテクチャ

```
lib/
  app/            テーマ(Candy Pop)・Riverpodプロバイダ
  core/
    api/          openBD / Google Books / oEmbed / OGPクライアント
    beam/         BeamTransport抽象 + BLE近接検知実装
    data/         ItemRepository(保存・サムネ取り込み)
    db/           drift(SQLite): culture_items + beams
    models/       CultureCategory / CultureDetail / BeamCard
    theme/        デザイントークン
    widgets/      CandyButton / ThumbImage
  features/
    vault/ post/ detail/ mix/ beam/ map/ wrap/
```

### シール/カード交換の設計メモ

シールの交換は「メタデータ入りPNG」方式(サーバーレス・クロスOS):
PNGのtEXtチャンクに作者・質感・埋め込みカルチャーをJSONで保存し、
共有シートで画像として送る。受信側はパレットの取り込みで復元する。
※スクショや再圧縮されるとメタデータが消えるため「画像を保存」で受け取ること。

### カード交換(すれ違い)の設計メモ

iOSのMultipeerConnectivityとAndroidのNearby Connectionsは相互通信できないため、
v1は「BLEで存在検知 + QRでカード受け渡し」方式(クロスOSで確実に動く)。
`BeamTransport`インターフェースを差し替えることでv2のBLE GATT直接転送や
iOS同士のMultipeer高速転送に移行できる。

交換パケットには個人メモ・位置情報を含めない(プライバシー)。
