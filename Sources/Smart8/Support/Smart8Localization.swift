import SwiftUI

public enum Smart8Language: String, CaseIterable, Identifiable {
    case japanese = "ja"
    case english = "en"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .japanese: "日本語"
        case .english: "English"
        }
    }
}

public struct Smart8Copy {
    public let language: Smart8Language

    public init(language: Smart8Language) {
        self.language = language
    }

    public var authenticated: String { text("認証済み", "Authenticated") }
    public var unauthenticated: String { text("未認証", "Not authenticated") }
    public var showDiagnostics: String { text("診断", "Diagnostics") }
    public var hideDiagnostics: String { text("診断を隠す", "Hide diagnostics") }
    public var edit: String { text("編集", "Edit") }
    public var closeEdit: String { text("編集を閉じる", "Close edit") }
    public var recipeDescription: String { text("華やかな香りとクリアな味わいを狙うSmart7抽出レシピ", "Smart7 brew recipe for a bright aroma and clean cup") }
    public var recipe: String { text("レシピ", "Recipe") }
    public var defaultRecipe: String { text("既定", "Default") }
    public var temperature: String { text("湯温", "Temp") }
    public var coffeeAmount: String { text("粉量", "Coffee") }
    public var totalWater: String { text("総湯量", "Water") }
    public var pourCount: String { text("注湯回数", "Pours") }
    public var pourPlan: String { text("注湯プラン", "Pour plan") }
    public var startBrewing: String { text("抽出開始", "Start brew") }
    public var stopBrewing: String { text("抽出停止", "Stop brew") }
    public var recipeEditor: String { text("レシピ編集", "Recipe editor") }
    public var saveAndClose: String { text("保存して閉じる", "Save and close") }
    public var name: String { text("名前", "Name") }
    public var recipeNamePlaceholder: String { text("レシピ名", "Recipe name") }
    public var step: String { text("工程", "Step") }
    public var waterAmount: String { text("湯量", "Water") }
    public var pour: String { text("注湯", "Pour") }
    public var wait: String { text("待機", "Wait") }
    public var addStep: String { text("工程を追加", "Add step") }
    public var currentDefaultRecipe: String { text("既定レシピ", "Default recipe") }
    public var setDefaultRecipe: String { text("このレシピを既定にする", "Make default") }
    public var add: String { text("追加", "Add") }
    public var delete: String { text("削除", "Delete") }
    public var reset: String { text("初期値", "Reset") }
    public var device: String { text("デバイス", "Device") }
    public var foundEVS70: String { text("EVS-70を発見", "EVS-70 found") }
    public var notSearched: String { text("未検索", "Not searched") }
    public var notificationsEnabled: String { text("通知有効化済み", "Notifications enabled") }
    public var waiting: String { text("待機中", "Waiting") }
    public var searchEVS70: String { text("EVS-70を検索", "Search EVS-70") }
    public var connectFoundEVS70: String { text("発見したEVS-70に接続", "Connect found EVS-70") }
    public var requestStatus: String { text("状態問い合わせ", "Request status") }
    public var disconnect: String { text("切断", "Disconnect") }
    public var controls: String { text("コントロール", "Controls") }
    public var drainWater: String { text("残水排出", "Drain water") }
    public var startAfter: String { text("開始まで", "Start after") }
    public var drainingWarning: String { text("排水中です。停止するまで本体から目を離さないでください。", "Draining. Watch the device until you stop it.") }
    public var stopDrain: String { text("排水停止", "Stop drain") }
    public var cancelDrainStart: String { text("排水開始をキャンセル", "Cancel drain start") }
    public var drainStartsAfterSuffix: String { text("秒後に排水開始", "sec until drain starts") }
    public var moveBeforeDrain: String { text("移動してから本体を確認してください。", "Move first, then check the device.") }
    public var diagnostics: String { text("診断", "Diagnostics") }
    public var showDiagnosticLog: String { text("診断ログを表示", "Show diagnostic log") }
    public var hideDiagnosticLog: String { text("診断ログを隠す", "Hide diagnostic log") }
    public var allNormal: String { text("すべて正常", "All normal") }
    public var hasError: String { text("エラーがあります", "Error") }
    public var diagnosticLog: String { text("診断ログ", "Diagnostic log") }
    public var languageLabel: String { text("言語", "Language") }

    public func stepName(_ number: Int) -> String {
        text("\(number)投目", "Pour \(number)")
    }

    public func stepsCount(_ count: Int) -> String {
        text("(\(count)工程)", "(\(count) steps)")
    }

    public func seconds(_ value: Int) -> String {
        text("\(value)秒", "\(value) sec")
    }

    public func waitSeconds(_ value: Int) -> String {
        text("待機 \(value) 秒", "Wait \(value) sec")
    }

    public func drainIdleText(delaySeconds: Int) -> String {
        text("いつでも排出できます。開始は\(delaySeconds)秒後です。", "Drain anytime. Starts after \(delaySeconds) sec.")
    }

    public func connectionStatus(_ rawValue: String) -> String {
        guard language == .english else { return rawValue }
        if let exact = englishConnectionStatus[rawValue] {
            return exact
        }
        if rawValue.hasSuffix("秒後に排水開始") {
            return rawValue.replacingOccurrences(of: "秒後に排水開始", with: " sec until drain starts")
        }
        let prefixes = [
            ("Bluetooth未使用可: ", "Bluetooth unavailable: "),
            ("発見: ", "Found: "),
            ("接続中: ", "Connecting: "),
            ("接続済み: ", "Connected: ")
        ]
        for (japanesePrefix, englishPrefix) in prefixes where rawValue.hasPrefix(japanesePrefix) {
            return englishPrefix + rawValue.dropFirst(japanesePrefix.count)
        }
        return rawValue
    }

    private func text(_ japanese: String, _ english: String) -> String {
        language == .japanese ? japanese : english
    }

    private var englishConnectionStatus: [String: String] {
        [
            "未接続": "Not connected",
            "Bluetooth使用可能": "Bluetooth available",
            "検索中": "Searching",
            "通知有効化済み": "Notifications enabled",
            "6桁コード受信。自動認証中": "Code received. Authenticating",
            "認証済み": "Authenticated",
            "切断": "Disconnected",
            "エラー": "Error",
            "レシピ送信中": "Sending recipe",
            "加熱・抽出中": "Heating / brewing",
            "抽出停止命令を送信": "Stop brew command sent",
            "抽出完了（利用者確認）": "Brew complete",
            "排水中": "Draining",
            "排水開始をキャンセル": "Drain start canceled",
            "排水停止命令を送信": "Stop drain command sent"
        ]
    }
}

private struct Smart8CopyKey: EnvironmentKey {
    static let defaultValue = Smart8Copy(language: .japanese)
}

public extension EnvironmentValues {
    var smart8Copy: Smart8Copy {
        get { self[Smart8CopyKey.self] }
        set { self[Smart8CopyKey.self] = newValue }
    }
}
