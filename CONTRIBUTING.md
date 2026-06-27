# Contributing / コントリビューション

Smart8 is a small macOS app for operating a user-owned EVS-70 device. Keep
changes narrow, testable, and clear.

## Development

```sh
swift test
./script/build_and_run.sh --verify
./script/build_and_run.sh
```

Before opening a pull request, run:

```sh
swift test
./script/build_and_run.sh --verify
```

## Rules

- Keep protocol changes covered by tests.
- Do not claim real-device Bluetooth success unless it was actually tested.
- Do not commit private device logs, personal data, or generated build output.
- When adding built-in recipes, update tests and `docs/brewing_recipe_spec_ja.md`.
- Keep UI changes consistent with the existing macOS SwiftUI style.

---

Smart8 は、ユーザー自身が所有する EVS-70 を操作するための小さな macOS
アプリです。変更は小さく、検証可能で、意図が分かる形にしてください。

## 開発

```sh
swift test
./script/build_and_run.sh --verify
./script/build_and_run.sh
```

Pull Request を出す前に、以下を実行してください。

```sh
swift test
./script/build_and_run.sh --verify
```

## ルール

- 通信プロトコルを変更する場合はテストを追加・更新してください。
- 実機で確認していない Bluetooth 通信成功を、成功済みとして書かないでください。
- 個人情報、私的なデバイスログ、ビルド生成物をコミットしないでください。
- 内蔵レシピを追加する場合は、テストと `docs/brewing_recipe_spec_ja.md` を更新してください。
- UI 変更は既存の macOS SwiftUI スタイルに合わせてください。
