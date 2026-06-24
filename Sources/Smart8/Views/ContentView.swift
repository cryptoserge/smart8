import SwiftUI

struct ContentView: View {
    @ObservedObject var store: Smart7SessionStore
    @State private var showingDiagnostics = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(store: store)
            Divider()
            HSplitView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ConnectionPanel(store: store)
                        RecipePanel(store: store)
                        BrewPanel(store: store)
                        DrainPanel(store: store)
                    }
                    .padding(18)
                }
                .frame(minWidth: 460)

                if showingDiagnostics {
                    LogPanel(logs: store.logs)
                        .frame(minWidth: 420)
                }
            }
            Divider()
            HStack {
                Spacer()
                Button {
                    showingDiagnostics.toggle()
                } label: {
                    Label(showingDiagnostics ? "診断ログを隠す" : "診断ログを表示", systemImage: showingDiagnostics ? "sidebar.right" : "list.bullet.rectangle")
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .onDisappear {
            store.prepareForExit()
        }
    }
}

private struct HeaderView: View {
    @ObservedObject var store: Smart7SessionStore

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Smart8")
                    .font(.headline)
                Text(store.connectionStatus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let error = store.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

private struct ConnectionPanel: View {
    @ObservedObject var store: Smart7SessionStore

    var body: some View {
        GroupBox("接続") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button {
                        store.startScanning()
                    } label: {
                        Label("EVS-70を検索", systemImage: "dot.radiowaves.left.and.right")
                    }

                    Button {
                        store.connectDiscoveredDevice()
                    } label: {
                        Label("発見したEVS-70に接続", systemImage: "link")
                    }
                    .disabled(!store.hasDiscoveredDevice || store.isReady)

                    Button {
                        store.disconnect()
                    } label: {
                        Label("切断", systemImage: "xmark.circle")
                    }
                }

                Button {
                    store.requestStatus()
                } label: {
                    Label("状態問い合わせ", systemImage: "arrow.clockwise")
                }
                .disabled(!store.isAuthenticated)
            }
            .padding(.vertical, 6)
        }
    }
}

private struct RecipePanel: View {
    @ObservedObject var store: Smart7SessionStore

    var body: some View {
        GroupBox("レシピ") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Picker("選択", selection: Binding(
                        get: { store.selectedRecipeID },
                        set: { store.selectRecipe($0) }
                    )) {
                        ForEach(store.savedRecipes) { recipe in
                            Text(recipe.name).tag(recipe.id)
                        }
                    }
                    .frame(maxWidth: 260)

                    Button {
                        store.saveRecipe()
                    } label: {
                        Label("保存", systemImage: "square.and.arrow.down")
                    }

                    Button {
                        store.duplicateRecipe()
                    } label: {
                        Label("追加", systemImage: "plus")
                    }

                    Button {
                        store.deleteCurrentRecipe()
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    .disabled(!store.canDeleteCurrentRecipe)

                    Button {
                        store.resetRecipeToDefault()
                    } label: {
                        Label("初期値", systemImage: "arrow.counterclockwise")
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                    GridRow {
                        Text("名前").foregroundStyle(.secondary)
                        TextField("レシピ名", text: $store.recipe.name)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                        Text("湯温").foregroundStyle(.secondary)
                        Stepper(value: $store.recipe.temperatureCelsius, in: 80...96) {
                            Text("\(store.recipe.temperatureCelsius) ℃")
                                .frame(width: 64, alignment: .leading)
                        }
                    }
                    GridRow {
                        Text("粉量").foregroundStyle(.secondary)
                        Stepper(value: $store.recipe.coffeeGrams, in: 1...60) {
                            Text("\(store.recipe.coffeeGrams) g")
                                .frame(width: 64, alignment: .leading)
                        }
                        Text("総湯量").foregroundStyle(.secondary)
                        Text("\(store.recipe.totalWaterML) ml")
                            .font(.headline)
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                    GridRow {
                        Text("工程").foregroundStyle(.secondary)
                        Text("湯量").foregroundStyle(.secondary)
                        Text("注湯").foregroundStyle(.secondary)
                        Text("待機").foregroundStyle(.secondary)
                        Text("")
                    }
                    ForEach(store.recipe.steps.indices, id: \.self) { index in
                        GridRow {
                            Text("\(index + 1)投目")
                            Stepper(value: $store.recipe.steps[index].volumeML, in: 10...500, step: 10) {
                                Text("\(store.recipe.steps[index].volumeML) ml")
                                    .frame(width: 70, alignment: .leading)
                            }
                            Stepper(value: $store.recipe.steps[index].pourSeconds, in: 0...255) {
                                Text("\(store.recipe.steps[index].pourSeconds)秒")
                                    .frame(width: 52, alignment: .leading)
                            }
                            Stepper(value: $store.recipe.steps[index].intervalSeconds, in: 0...255) {
                                Text("\(store.recipe.steps[index].intervalSeconds)秒")
                                    .frame(width: 52, alignment: .leading)
                            }
                            Button {
                                store.deleteStep(at: index)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                            .disabled(store.recipe.steps.count <= 1)
                        }
                    }
                }
                .font(.system(.body, design: .monospaced))

                Button {
                    store.addStep()
                } label: {
                    Label("工程を追加", systemImage: "plus.circle")
                }
                .disabled(store.recipe.steps.count >= 8)
            }
            .padding(.vertical, 6)
        }
    }
}

private struct BrewPanel: View {
    @ObservedObject var store: Smart7SessionStore

    var body: some View {
        GroupBox("抽出") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button {
                        store.startRecipe()
                    } label: {
                        Label("この内容で抽出開始", systemImage: "play.fill")
                    }
                    .disabled(!store.canStartRecipe)

                    Button {
                        store.stopBrewing()
                    } label: {
                        Label("抽出停止", systemImage: "stop.fill")
                    }
                    .disabled(!store.isAuthenticated || (!store.isBrewing && !store.isRecipeSending))
                }

                Button {
                    store.markBrewFinishedByUser()
                } label: {
                    Label("抽出が終わったので排水へ", systemImage: "checkmark.circle")
                }
                .disabled(!store.isBrewing)
            }
            .padding(.vertical, 6)
        }
    }
}

private struct DrainPanel: View {
    @ObservedObject var store: Smart7SessionStore

    var body: some View {
        GroupBox("残水排出") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button {
                        store.startDrain()
                    } label: {
                        Label("残水を排出する", systemImage: "drop.fill")
                    }
                    .disabled(!store.canStartDrain)

                    Button {
                        store.stopDrain()
                    } label: {
                        Label(store.drainCountdownSeconds == nil ? "排水を停止する" : "排水開始をキャンセル", systemImage: "stop.circle.fill")
                    }
                    .controlSize(.large)
                    .disabled(!store.isDraining && store.drainCountdownSeconds == nil)
                }

                if let seconds = store.drainCountdownSeconds {
                    Text("\(seconds)秒後に排水を開始します。移動してから本体を確認してください。")
                        .foregroundStyle(.orange)
                } else {
                    Text(store.isDraining ? "排水中です。停止するまで本体から目を離さないでください。" : "認証後はいつでも利用者の操作で排水を開始できます。")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

private struct LogPanel: View {
    let logs: [DiagnosticLogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("診断ログ")
                .font(.headline)
                .padding(.top, 18)
                .padding(.horizontal, 16)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(logs) { entry in
                            Text(entry.displayText)
                                .font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                }
                .onChange(of: logs.last?.id) { _, id in
                    guard let id else { return }
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }
        }
    }
}
