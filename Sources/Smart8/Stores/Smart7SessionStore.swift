import Foundation
import SwiftUI

#if canImport(CoreBluetooth)
import CoreBluetooth
#endif
#if canImport(AppKit)
import AppKit
#endif

@MainActor
public final class Smart7SessionStore: ObservableObject {
    @Published public var recipe: Smart7Recipe {
        didSet {
            if !recipe.steps.isEmpty {
                selectedRecipeID = recipe.id
            }
        }
    }
    @Published public private(set) var savedRecipes: [Smart7Recipe]
    @Published public private(set) var selectedRecipeID: UUID
    @Published public var connectionStatus = "未接続"
    @Published public var codeInput = ""
    @Published public private(set) var isReady = false
    @Published public private(set) var hasDiscoveredDevice = false
    @Published public private(set) var receivedCode: String?
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var isRecipeSending = false
    @Published public private(set) var isBrewing = false
    @Published public private(set) var isDrainAvailable = false
    @Published public private(set) var isDraining = false
    @Published public private(set) var drainCountdownSeconds: Int?
    @Published public var errorMessage: String?
    @Published public private(set) var logs: [DiagnosticLogEntry] = []

    #if canImport(CoreBluetooth)
    private let client = Smart7BluetoothClient()
    #endif
    private var drainStartWorkItem: DispatchWorkItem?
    private var drainCountdownTimer: Timer?
    private let recipeStorageKey = "Smart8.savedRecipes.v1"

    public init() {
        let loadedRecipes = Self.loadRecipes()
        let initialRecipe = loadedRecipes.first ?? Smart7Recipe.kaoriSaku18g
        savedRecipes = loadedRecipes
        recipe = initialRecipe
        selectedRecipeID = initialRecipe.id

        #if canImport(CoreBluetooth)
        client.onEvent = { [weak self] event in
            Task { @MainActor in
                self?.handle(event)
            }
        }
        client.onLog = { [weak self] entry in
            Task { @MainActor in
                self?.append(entry)
            }
        }
        #endif
        #if canImport(AppKit)
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.prepareForExit()
            }
        }
        #endif
    }

    public var canStartRecipe: Bool {
        isAuthenticated && !isRecipeSending && !isBrewing && !isDraining
    }

    public var canStartDrain: Bool {
        isAuthenticated && !isDraining && drainCountdownSeconds == nil
    }

    public var canDeleteCurrentRecipe: Bool {
        savedRecipes.count > 1
    }

    public func selectRecipe(_ id: UUID) {
        guard let selected = savedRecipes.first(where: { $0.id == id }) else { return }
        recipe = selected
        selectedRecipeID = id
    }

    public func saveRecipe() {
        sanitizeCurrentRecipe()
        if let index = savedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            savedRecipes[index] = recipe
        } else {
            savedRecipes.append(recipe)
        }
        selectedRecipeID = recipe.id
        persistRecipes()
        append(.init(direction: .event, message: "レシピを保存: \(recipe.name)"))
    }

    public func duplicateRecipe() {
        sanitizeCurrentRecipe()
        var copied = recipe
        copied.id = UUID()
        copied.name = nextRecipeName(base: "\(recipe.name) コピー")
        recipe = copied
        savedRecipes.append(copied)
        selectedRecipeID = copied.id
        persistRecipes()
        append(.init(direction: .event, message: "レシピを追加: \(copied.name)"))
    }

    public func deleteCurrentRecipe() {
        guard canDeleteCurrentRecipe else { return }
        savedRecipes.removeAll { $0.id == recipe.id }
        let next = savedRecipes.first ?? Smart7Recipe.kaoriSaku18g
        recipe = next
        selectedRecipeID = next.id
        persistRecipes()
        append(.init(direction: .event, message: "レシピを削除"))
    }

    public func resetRecipeToDefault() {
        recipe = Smart7Recipe.kaoriSaku18g
        saveRecipe()
    }

    public func addStep() {
        guard recipe.steps.count < 8 else { return }
        recipe.steps.append(Smart7RecipeStep(volumeML: 40, pourSeconds: 15, intervalSeconds: 20))
    }

    public func deleteStep(at index: Int) {
        guard recipe.steps.count > 1, recipe.steps.indices.contains(index) else { return }
        recipe.steps.remove(at: index)
    }

    public func startScanning() {
        errorMessage = nil
        #if canImport(CoreBluetooth)
        do {
            try client.startScanning()
        } catch {
            fail(error)
        }
        #else
        failText("CoreBluetoothを利用できません")
        #endif
    }

    public func disconnect() {
        #if canImport(CoreBluetooth)
        if isDraining {
            client.stopDrain()
        }
        client.disconnect(sendCancel: true)
        #endif
        connectionStatus = "未接続"
        isReady = false
        hasDiscoveredDevice = false
        receivedCode = nil
        isAuthenticated = false
        isRecipeSending = false
        isBrewing = false
        isDraining = false
        cancelPendingDrainStart()
    }

    public func connectDiscoveredDevice() {
        errorMessage = nil
        #if canImport(CoreBluetooth)
        do {
            try client.connectDiscoveredPeripheral()
        } catch {
            fail(error)
        }
        #endif
    }

    public func submitCode() {
        errorMessage = nil
        #if canImport(CoreBluetooth)
        do {
            try client.submitPassword(codeInput)
            codeInput = ""
            isAuthenticated = true
            connectionStatus = "認証済み"
            append(.init(direction: .event, message: "6桁コード一致。接続許可を送信"))
        } catch {
            fail(error)
        }
        #endif
    }

    public func acceptReceivedCode() {
        errorMessage = nil
        #if canImport(CoreBluetooth)
        do {
            try client.acceptReceivedPassword()
            receivedCode = nil
            isAuthenticated = true
            connectionStatus = "認証済み"
            append(.init(direction: .event, message: "受信済み6桁コードで接続許可を送信"))
        } catch {
            fail(error)
        }
        #endif
    }

    public func requestStatus() {
        #if canImport(CoreBluetooth)
        client.requestStatus()
        #endif
    }

    public func startRecipe() {
        guard canStartRecipe else { return }
        errorMessage = nil
        sanitizeCurrentRecipe()
        isRecipeSending = true
        isDrainAvailable = false
        connectionStatus = "レシピ送信中"
        #if canImport(CoreBluetooth)
        client.sendRecipe(recipe) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isRecipeSending = false
                switch result {
                case .success:
                    self.isBrewing = true
                    self.connectionStatus = "加熱・抽出中"
                    self.append(.init(direction: .event, message: "全工程と温度を送信後、抽出開始を送信"))
                case let .failure(error):
                    self.fail(error)
                }
            }
        }
        #endif
    }

    public func stopBrewing() {
        guard isAuthenticated else { return }
        #if canImport(CoreBluetooth)
        client.stopBrewing { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success:
                    self.isRecipeSending = false
                    self.isBrewing = false
                    self.isDrainAvailable = true
                    self.connectionStatus = "抽出停止命令を送信"
                case let .failure(error):
                    self.fail(error)
                }
            }
        }
        #endif
    }

    public func markBrewFinishedByUser() {
        guard isBrewing else { return }
        isBrewing = false
        isDrainAvailable = true
        connectionStatus = "抽出完了（利用者確認）"
        append(.init(direction: .event, message: "利用者操作で抽出完了として排水操作を有効化"))
    }

    public func startDrain() {
        guard canStartDrain else { return }
        errorMessage = nil
        isRecipeSending = false
        isBrewing = false
        drainCountdownSeconds = 5
        connectionStatus = "5秒後に排水開始"
        append(.init(direction: .event, message: "排水開始を5秒後に予約"))
        startDrainCountdownTimer()

        #if canImport(CoreBluetooth)
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.drainCountdownTimer?.invalidate()
                self.drainCountdownTimer = nil
                self.drainCountdownSeconds = nil
                self.isDraining = true
                self.connectionStatus = "排水中"
                self.client.startDrain { [weak self] result in
                    Task { @MainActor in
                        if case let .failure(error) = result {
                            self?.isDraining = false
                            self?.fail(error)
                        }
                    }
                }
            }
        }
        drainStartWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: workItem)
        #endif
    }

    public func stopDrain() {
        if drainCountdownSeconds != nil {
            cancelPendingDrainStart()
            connectionStatus = "排水開始をキャンセル"
            append(.init(direction: .event, message: "5秒待機中の排水開始をキャンセル"))
            return
        }
        guard isAuthenticated, isDraining else { return }
        #if canImport(CoreBluetooth)
        client.stopDrain { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success:
                    self.isDraining = false
                    self.isDrainAvailable = false
                    self.connectionStatus = "排水停止命令を送信"
                    self.append(.init(direction: .event, message: "本体停止の断定ではなく、停止命令送信として記録"))
                case let .failure(error):
                    self.fail(error)
                }
            }
        }
        #endif
    }

    public func prepareForExit() {
        guard isDraining || drainCountdownSeconds != nil else { return }
        append(.init(direction: .event, message: "終了前に排水停止の送信を試行"))
        stopDrain()
    }

    private func handle(_ event: Smart7ClientEvent) {
        switch event {
        case let .bluetoothState(state):
            connectionStatus = state == .poweredOn ? "Bluetooth使用可能" : "Bluetooth未使用可: \(state.rawValue)"
        case .scanning:
            connectionStatus = "検索中"
        case let .discovered(name, _, _):
            hasDiscoveredDevice = true
            connectionStatus = "発見: \(name)"
        case let .connecting(name):
            connectionStatus = "接続中: \(name)"
        case let .connected(name):
            connectionStatus = "接続済み: \(name)"
        case .ready:
            isReady = true
            connectionStatus = "通知有効化済み"
        case .passwordReceived:
            receivedCode = "受信済み"
            connectionStatus = "6桁コード受信。自動認証中"
        case .authenticated:
            receivedCode = nil
            isAuthenticated = true
            connectionStatus = "認証済み"
        case .frame:
            break
        case let .disconnected(error):
            isReady = false
            receivedCode = nil
            isAuthenticated = false
            isRecipeSending = false
            isBrewing = false
            isDraining = false
            connectionStatus = "切断"
            if let error {
                errorMessage = error.localizedDescription
            }
        case let .error(error):
            fail(error)
        }
    }

    private func fail(_ error: Error) {
        failText(String(describing: error))
    }

    private func failText(_ text: String) {
        errorMessage = text
        connectionStatus = "エラー"
        append(.init(direction: .error, message: text))
    }

    private func append(_ entry: DiagnosticLogEntry) {
        logs.append(entry)
        if logs.count > 500 {
            logs.removeFirst(logs.count - 500)
        }
    }

    private func sanitizeCurrentRecipe() {
        recipe.name = recipe.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if recipe.name.isEmpty {
            recipe.name = "マイレシピ"
        }
        recipe.temperatureCelsius = min(max(recipe.temperatureCelsius, 80), 96)
        recipe.coffeeGrams = min(max(recipe.coffeeGrams, 1), 60)
        if recipe.steps.isEmpty {
            recipe.steps = [Smart7RecipeStep(volumeML: 40, pourSeconds: 15, intervalSeconds: 20)]
        }
        recipe.steps = recipe.steps.map {
            Smart7RecipeStep(
                volumeML: min(max($0.volumeML / 10 * 10, 10), 500),
                pourSeconds: min(max($0.pourSeconds, 0), 255),
                intervalSeconds: min(max($0.intervalSeconds, 0), 255)
            )
        }
    }

    private func persistRecipes() {
        if let data = try? JSONEncoder().encode(savedRecipes) {
            UserDefaults.standard.set(data, forKey: recipeStorageKey)
        }
    }

    private static func loadRecipes() -> [Smart7Recipe] {
        let key = "Smart8.savedRecipes.v1"
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Smart7Recipe].self, from: data),
              !decoded.isEmpty else {
            return [Smart7Recipe.kaoriSaku18g]
        }
        return decoded
    }

    private func nextRecipeName(base: String) -> String {
        var candidate = base
        var suffix = 2
        let names = Set(savedRecipes.map(\.name))
        while names.contains(candidate) {
            candidate = "\(base) \(suffix)"
            suffix += 1
        }
        return candidate
    }

    private func startDrainCountdownTimer() {
        drainCountdownTimer?.invalidate()
        drainCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let current = self.drainCountdownSeconds else { return }
                if current > 1 {
                    self.drainCountdownSeconds = current - 1
                    self.connectionStatus = "\(current - 1)秒後に排水開始"
                }
            }
        }
    }

    private func cancelPendingDrainStart() {
        drainStartWorkItem?.cancel()
        drainStartWorkItem = nil
        drainCountdownTimer?.invalidate()
        drainCountdownTimer = nil
        drainCountdownSeconds = nil
    }
}
