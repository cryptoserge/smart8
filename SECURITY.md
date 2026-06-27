# Security Policy / セキュリティポリシー

## Reporting a Vulnerability

Please do not publish exploit details or device-safety issues in a public
issue. If GitHub private vulnerability reporting is available for this
repository, use it. Otherwise, open a minimal public issue that asks the
maintainer to coordinate privately, without including reproduction details.

Include only what is needed to understand the impact. Do not attach personal
data, private Bluetooth captures, or device identifiers unless they are
required and can be safely redacted.

## Scope

Security reports may cover:

- macOS app behavior
- Bluetooth command generation and parsing
- Handling of diagnostic logs and saved settings

This project cannot provide support for vulnerabilities in the EVS-70 firmware
or the original Smart7 app.

---

## 脆弱性の報告

攻撃手順や機器安全性に関わる詳細を、公開 Issue に直接書かないでください。
このリポジトリで GitHub の private vulnerability reporting が使える場合は、
それを使ってください。使えない場合は、再現手順を含めず、非公開での連絡調整を
依頼する最小限の公開 Issue を作成してください。

影響を理解するために必要な情報だけを含めてください。個人情報、私的な Bluetooth
キャプチャ、デバイス識別子は、必要で安全に伏せられる場合を除いて添付しないでください。

## 対象範囲

報告対象は以下です。

- macOS アプリの挙動
- Bluetooth コマンド生成と解析
- 診断ログと保存設定の扱い

EVS-70 本体ファームウェアや元の Smart7 アプリ自体の脆弱性には、このプロジェクトでは
対応できません。
