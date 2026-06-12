# ミーアキャットの見張り番

スマホを置いて集中時間を守るためのSwiftUIアプリです。外部APIやサーバーは使いません。

## 入っているもの

- ホーム画面
- 集中タイマー
- 成功・失敗判定
- バックグラウンド移動時の失敗判定
- 巣穴レベルアップ
- 毎日ログイン処理
- 月初めの仲間リセット
- 仲間一覧とメイン仲間選択
- UserDefaults保存
- Google Mobile Ads
- 起動直後のApp Tracking Transparency許可リクエスト

## App Review向けメモ

App Store Connectのプライバシー回答でDevice IDやAdvertising Dataを「トラッキングに使用」とする場合、このアプリはATT許可リクエストが必要です。

この実装では、初回起動直後に説明画面を出し、その後にATTのシステム許可ダイアログを表示します。Google Mobile Adsの開始とバナー読み込みは、ATTダイアログへの応答後に行います。

## 動作確認

1. Macで `MeerkatWatch.xcodeproj` を開く
2. シミュレーターか実機を選ぶ
3. Runする

Windows環境ではXcodeシミュレーター実行はできません。

## 画像差し替え

メイン画像は `MeerkatWatch/Assets.xcassets/MascotMeerkat.imageset` にあります。仲間画像は `FriendNormal` などのimagesetです。同じアセット名で画像を差し替えると、コード側の変更なしで反映できます。
