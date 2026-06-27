# Smart8

Smart8 は、HARIO Smart7 EVS-70 を Mac から操作するための macOS SwiftUI アプリです。配信終了した Smart7 アプリの代替として、レシピ送信、抽出停止、残水排出を行う最小構成のアプリです。

> Smart8 は非公式の独立プロジェクトです。HARIO による承認、支援、提携を受けたものではありません。

## 機能

- EVS-70 の検索、接続、自動認証
- 抽出レシピの作成、編集、保存
- 既定レシピの設定と次回起動時の復元
- レシピ送信と抽出開始
- 抽出停止
- 残水排出と排出停止
- 残水排出開始までの待機秒数設定
- 日本語 / English のアプリ内切り替え
- 必要時だけ表示する診断ログ

## 必要環境

- macOS 14.0 以降
- Bluetooth が利用できる Mac
- HARIO Smart7 EVS-70 本体

## ビルドと起動

```sh
swift test
./script/build_and_run.sh --verify
./script/build_and_run.sh
```

`script/build_and_run.sh` は SwiftPM でビルドし、`dist/Smart8.app` を作成して起動します。

## DMGの作成

```sh
./script/package_dmg.sh
```

`dist/Smart8.dmg` を作成します。DMGには `Smart8.app` と `Applications` へのショートカットが入ります。

現時点のDMGは未署名・未notarizationです。別のMacで開く場合、macOSのGatekeeper警告が出る可能性があります。一般配布で警告を減らすには、Developer ID署名とnotarizationを別途行ってください。

## ドキュメント

- [抽出レシピ仕様書](docs/brewing_recipe_spec_ja.md)
- [コントリビューション](CONTRIBUTING.md)
- [セキュリティポリシー](SECURITY.md)
- [非公式プロジェクトとしての注意](NOTICE.md)

## 注意

このアプリは非公式の代替アプリです。実機操作では、本体の状態を確認しながら使用してください。残水排出は自動停止を前提にせず、必要に応じてアプリから停止してください。

## ライセンス

MIT License です。詳細は [LICENSE](LICENSE) を参照してください。

---

# Smart8

Smart8 is a macOS SwiftUI app for controlling the HARIO Smart7 EVS-70 from a Mac. It is a minimal replacement for the discontinued Smart7 app, focused on recipe transfer, brew stop, and water drain controls.

> Smart8 is an unofficial, independent project. It is not affiliated with, endorsed by, or supported by HARIO.

## Features

- Search, connect, and auto-authenticate with EVS-70
- Create, edit, and save brew recipes
- Set a default recipe and restore it on next launch
- Send recipes and start brewing
- Stop brewing
- Start and stop water drain
- Configure the delay before water drain starts
- Switch the app UI between Japanese and English
- Show diagnostic logs only when needed

## Requirements

- macOS 14.0 or later
- A Mac with Bluetooth
- HARIO Smart7 EVS-70

## Build and Run

```sh
swift test
./script/build_and_run.sh --verify
./script/build_and_run.sh
```

`script/build_and_run.sh` builds the SwiftPM package, creates `dist/Smart8.app`, and launches it.

## Create a DMG

```sh
./script/package_dmg.sh
```

This creates `dist/Smart8.dmg`. The DMG contains `Smart8.app` and an `Applications` shortcut.

The current DMG is unsigned and not notarized. macOS Gatekeeper may warn when opening it on another Mac. For broader distribution, sign the app with a Developer ID certificate and notarize it separately.

## Documentation

- [Brewing recipe specification](docs/brewing_recipe_spec_ja.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Unofficial project notice](NOTICE.md)

## Notes

This is an unofficial replacement app. When operating the device, keep the actual unit in view. Water drain should not be treated as automatically stopped; stop it from the app when needed.

## License

Smart8 is released under the MIT License. See [LICENSE](LICENSE).
