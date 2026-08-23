# カード配布ページの公開手順

アプリの「配布リンク」機能の着地先となる静的ページです。
サーバー・データベースは不要(カードのデータはURLの`#`以降に入っていて、
フラグメントはブラウザからサーバーへ送信されません)。

## 1. GitHub Pagesで公開(無料・5分)

1. GitHubで新しいリポジトリを作る(例: `card`)。Organization名を
   `culturetune-app` にすると、アプリ側のデフォルトURLと一致します
2. この`index.html`をリポジトリ直下に置いてpush
3. リポジトリの Settings → Pages → Branch: main で公開
4. 公開URL(例: `https://culturetune-app.github.io/card/`)を
   `lib/features/distribution/card_link.dart` の `distributionPageUrl` に設定

別のURLにした場合はアプリ側の定数を書き換えて再ビルドしてください。

## 2. 動作(この時点でインスタ配布が可能)

- リンクを踏む → ページがカードをプレビュー表示
- 「アプリで受け取る」→ `culturetune://` スキームでアプリが開き、受け取り確認が出る
- インスタのストーリー: アプリの「配布」→ストーリー画像を投稿し、
  リンクスタンプにコピーしたURLを設定

## 3. (任意)ユニバーサルリンク化 — リンクを踏んだら直接アプリを開く

ページを経由せず直接アプリを開きたい場合のみ。Apple Developer契約が必要です。

### iOS
1. リポジトリに `.well-known/apple-app-site-association` を追加(拡張子なし・JSON):
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<TeamID>.com.culturetune.cultureTune",
        "paths": ["/card/*", "/card"]
      }
    ]
  }
}
```
2. XcodeでRunnerターゲット → Signing & Capabilities → 「Associated Domains」を追加し
   `applinks:culturetune-app.github.io` を登録(要: あなたのTeamで署名)

### Android
1. リポジトリに `.well-known/assetlinks.json` を追加:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.culturetune.culture_tune",
    "sha256_cert_fingerprints": ["<署名証明書のSHA256>"]
  }
}]
```
   (指紋は `./gradlew signingReport` で確認)
2. `android/app/src/main/AndroidManifest.xml` のコメントアウトされた
   https用intent-filterを有効化してhostを合わせる
