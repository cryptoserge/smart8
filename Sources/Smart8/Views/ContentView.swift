import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    @ObservedObject var store: Smart7SessionStore
    @AppStorage("Smart8.language") private var languageRawValue = Smart8Language.japanese.rawValue
    @State private var showingDiagnostics = false
    @State private var isEditingRecipe = false

    private var copy: Smart8Copy {
        Smart8Copy(language: Smart8Language(rawValue: languageRawValue) ?? .japanese)
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(store: store, showingDiagnostics: $showingDiagnostics)
            Divider()
            HSplitView {
                ScrollView {
                    MainBrewDashboard(store: store, isEditingRecipe: $isEditingRecipe)
                        .padding(24)
                }
                .frame(minWidth: 580)
                .background(Smart8Palette.page)

                SidePanel(store: store, showingDiagnostics: $showingDiagnostics)
                    .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
                    .background(Smart8Palette.side)

                if showingDiagnostics {
                    LogPanel(logs: store.logs)
                        .frame(minWidth: 420, idealWidth: 480)
                        .background(Smart8Palette.side)
                }
            }
            FooterStatusView(store: store)
        }
        .background(Smart8Palette.page)
        .onDisappear {
            store.prepareForExit()
        }
        .environment(\.smart8Copy, copy)
    }
}

private enum Smart8Palette {
    static let page = adaptive(
        lightRed: 0.925, lightGreen: 0.915, lightBlue: 0.890,
        darkRed: 0.110, darkGreen: 0.105, darkBlue: 0.095
    )
    static let side = adaptive(
        lightRed: 0.900, lightGreen: 0.890, lightBlue: 0.865,
        darkRed: 0.145, darkGreen: 0.137, darkBlue: 0.122
    )
    static let surface = adaptive(
        lightRed: 0.955, lightGreen: 0.950, lightBlue: 0.935,
        darkRed: 0.190, darkGreen: 0.180, darkBlue: 0.160
    )
    static let line = Color.primary.opacity(0.13)
    static let accent = adaptive(
        lightRed: 0.50, lightGreen: 0.39, lightBlue: 0.25,
        darkRed: 0.70, darkGreen: 0.56, darkBlue: 0.36
    )
    static let accentSoft = adaptive(
        lightRed: 0.76, lightGreen: 0.68, lightBlue: 0.54,
        darkRed: 0.38, darkGreen: 0.32, darkBlue: 0.23
    )
    static let blue = adaptive(
        lightRed: 0.20, lightGreen: 0.36, lightBlue: 0.55,
        darkRed: 0.50, darkGreen: 0.68, darkBlue: 0.88
    )
    static let green = adaptive(
        lightRed: 0.22, lightGreen: 0.46, lightBlue: 0.32,
        darkRed: 0.48, darkGreen: 0.76, darkBlue: 0.56
    )
    static let danger = adaptive(
        lightRed: 0.66, lightGreen: 0.26, lightBlue: 0.22,
        darkRed: 0.94, darkGreen: 0.45, darkBlue: 0.38
    )

    private static func adaptive(
        lightRed: Double,
        lightGreen: Double,
        lightBlue: Double,
        darkRed: Double,
        darkGreen: Double,
        darkBlue: Double
    ) -> Color {
        #if canImport(AppKit)
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(
                calibratedRed: isDark ? darkRed : lightRed,
                green: isDark ? darkGreen : lightGreen,
                blue: isDark ? darkBlue : lightBlue,
                alpha: 1
            )
        })
        #else
        Color(red: lightRed, green: lightGreen, blue: lightBlue)
        #endif
    }
}

private struct HeaderView: View {
    @ObservedObject var store: Smart7SessionStore
    @Binding var showingDiagnostics: Bool
    @AppStorage("Smart8.language") private var languageRawValue = Smart8Language.japanese.rawValue
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title2)
                .foregroundStyle(Smart8Palette.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Smart8")
                    .font(.headline)
                Text(copy.connectionStatus(store.connectionStatus))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            StatusPill(
                title: store.isAuthenticated ? copy.authenticated : copy.unauthenticated,
                systemImage: store.isAuthenticated ? "checkmark.shield.fill" : "shield",
                color: store.isAuthenticated ? Smart8Palette.green : .secondary
            )

            Spacer()

            if let error = store.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Smart8Palette.danger)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Smart8Palette.danger.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            }

            Picker(copy.languageLabel, selection: $languageRawValue) {
                ForEach(Smart8Language.allCases) { language in
                    Text(language.displayName).tag(language.rawValue)
                }
            }
            .labelsHidden()
            .frame(width: 110)

            Button {
                showingDiagnostics.toggle()
            } label: {
                Label(showingDiagnostics ? copy.hideDiagnostics : copy.showDiagnostics, systemImage: "waveform.path.ecg")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }
}

private struct MainBrewDashboard: View {
    @ObservedObject var store: Smart7SessionStore
    @Binding var isEditingRecipe: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            RecipeHeroView(store: store, isEditingRecipe: $isEditingRecipe)
            MetricGrid(recipe: store.recipe)
            PourPlanView(recipe: store.recipe)

            if isEditingRecipe {
                RecipeEditorPanel(store: store, isEditingRecipe: $isEditingRecipe)
            }

            BrewActionPanel(store: store)
        }
        .frame(maxWidth: 980, alignment: .leading)
    }
}

private struct RecipeHeroView: View {
    @ObservedObject var store: Smart7SessionStore
    @Binding var isEditingRecipe: Bool
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 22) {
                HeroDripperArt()
                    .frame(width: 132, height: 118)
                    .frame(width: 144, height: 128)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(store.recipe.name)
                            .font(.system(size: 34, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                isEditingRecipe.toggle()
                            }
                        } label: {
                            Label(isEditingRecipe ? copy.closeEdit : copy.edit, systemImage: isEditingRecipe ? "xmark" : "pencil")
                        }
                    }

                    Text(copy.recipeDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        Picker(copy.recipe, selection: Binding(
                            get: { store.selectedRecipeID },
                            set: { store.selectRecipe($0) }
                        )) {
                            ForEach(store.savedRecipes) { recipe in
                                Text(recipe.name).tag(recipe.id)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 240)

                        if store.isCurrentRecipeDefault {
                            StatusPill(title: copy.defaultRecipe, systemImage: "star.fill", color: Smart8Palette.accent)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(22)
        .background(Smart8Palette.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Smart8Palette.line)
        )
    }
}

private struct HeroDripperArt: View {
    var body: some View {
        #if canImport(AppKit)
        if let url = Bundle.main.url(forResource: "HeroDripper", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "mug.fill")
                .font(.system(size: 54, weight: .regular))
                .foregroundStyle(Smart8Palette.accent)
        }
        #else
        Image(systemName: "mug.fill")
            .font(.system(size: 54, weight: .regular))
            .foregroundStyle(Smart8Palette.accent)
        #endif
    }
}

private struct MetricGrid: View {
    let recipe: Smart7Recipe
    @Environment(\.smart8Copy) private var copy

    private let columns = [
        GridItem(.adaptive(minimum: 220), spacing: 14)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            MetricCard(title: copy.temperature, value: "\(recipe.temperatureCelsius)", unit: "℃", assetName: "MetricTemperature", fallbackSystemImage: "thermometer", color: Smart8Palette.accent)
            MetricCard(title: copy.coffeeAmount, value: "\(recipe.coffeeGrams)", unit: "g", assetName: "MetricPowder", fallbackSystemImage: "scalemass.fill", color: Color(red: 0.46, green: 0.30, blue: 0.18))
            MetricCard(title: copy.totalWater, value: "\(recipe.totalWaterML)", unit: "ml", assetName: "MetricWater", fallbackSystemImage: "drop.fill", color: Smart8Palette.blue)
            MetricCard(title: copy.pourCount, value: "\(recipe.steps.count)", unit: copy.language == .japanese ? "回" : "", assetName: "MetricPours", fallbackSystemImage: "water.waves", color: .secondary)
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let assetName: String
    let fallbackSystemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            DashboardIcon(assetName: assetName, fallbackSystemImage: fallbackSystemImage, color: color)
                .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(unit)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(minHeight: 108)
        .background(Smart8Palette.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Smart8Palette.line)
        )
    }
}

private struct DashboardIcon: View {
    let assetName: String
    let fallbackSystemImage: String
    let color: Color

    var body: some View {
        #if canImport(AppKit)
        if let url = Bundle.main.url(forResource: assetName, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: fallbackSystemImage)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(color)
        }
        #else
        Image(systemName: fallbackSystemImage)
            .font(.system(size: 30, weight: .medium))
            .foregroundStyle(color)
        #endif
    }
}

private struct PourPlanView: View {
    let recipe: Smart7Recipe
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(copy.pourPlan)
                    .font(.headline)
                Text(copy.stepsCount(recipe.steps.count))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    PourRow(index: index, step: step)
                    if index < recipe.steps.count - 1 {
                        Divider()
                    }
                }
            }
            .background(Smart8Palette.surface, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Smart8Palette.line)
            )
        }
    }
}

private struct PourRow: View {
    let index: Int
    let step: Smart7RecipeStep
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        HStack(spacing: 18) {
            Text("\(index + 1)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Smart8Palette.accent.opacity(0.70), in: Circle())

            Text(copy.stepName(index + 1))
                .font(.headline)
                .frame(width: 86, alignment: .leading)

            PlanValue(systemImage: "drop", text: "\(step.volumeML) ml", color: Smart8Palette.blue)
            PlanValue(systemImage: "timer", text: copy.seconds(step.pourSeconds), color: Smart8Palette.blue)
            PlanValue(systemImage: "hourglass", text: copy.waitSeconds(step.intervalSeconds), color: Smart8Palette.accent)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

private struct PlanValue: View {
    let systemImage: String
    let text: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.body)
            .foregroundStyle(.primary)
            .labelStyle(CompactLabelStyle(color: color))
            .frame(minWidth: 122, alignment: .leading)
    }
}

private struct BrewActionPanel: View {
    @ObservedObject var store: Smart7SessionStore
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Button {
                    store.startRecipe()
                } label: {
                    Label(copy.startBrewing, systemImage: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(store.canStartRecipe ? Smart8Palette.accent : Color.secondary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                .disabled(!store.canStartRecipe)

                Button {
                    store.stopBrewing()
                } label: {
                    Label(copy.stopBrewing, systemImage: "stop.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 210)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.plain)
                .foregroundStyle(store.isAuthenticated && (store.isBrewing || store.isRecipeSending) ? .primary : .secondary)
                .background(Smart8Palette.surface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Smart8Palette.line)
                )
                .disabled(!store.isAuthenticated || (!store.isBrewing && !store.isRecipeSending))
            }
        }
    }
}

private struct RecipeEditorPanel: View {
    @ObservedObject var store: Smart7SessionStore
    @Binding var isEditingRecipe: Bool
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(copy.recipeEditor)
                    .font(.headline)
                Spacer()
                Button {
                    store.saveRecipe()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isEditingRecipe = false
                    }
                } label: {
                    Label(copy.saveAndClose, systemImage: "checkmark")
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text(copy.name).foregroundStyle(.secondary)
                    TextField(copy.recipeNamePlaceholder, text: $store.recipe.name)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 260)
                    Text(copy.temperature).foregroundStyle(.secondary)
                    Stepper(value: $store.recipe.temperatureCelsius, in: 80...96) {
                        Text("\(store.recipe.temperatureCelsius) ℃")
                            .frame(width: 72, alignment: .leading)
                    }
                }
                GridRow {
                    Text(copy.coffeeAmount).foregroundStyle(.secondary)
                    Stepper(value: $store.recipe.coffeeGrams, in: 1...60) {
                        Text("\(store.recipe.coffeeGrams) g")
                            .frame(width: 72, alignment: .leading)
                    }
                    Text(copy.totalWater).foregroundStyle(.secondary)
                    Text("\(store.recipe.totalWaterML) ml")
                        .font(.headline)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                GridRow {
                    Text(copy.step).foregroundStyle(.secondary)
                    Text(copy.waterAmount).foregroundStyle(.secondary)
                    Text(copy.pour).foregroundStyle(.secondary)
                    Text(copy.wait).foregroundStyle(.secondary)
                    Text("")
                }
                ForEach(store.recipe.steps.indices, id: \.self) { index in
                    GridRow {
                        Text(copy.stepName(index + 1))
                        Stepper(value: $store.recipe.steps[index].volumeML, in: 10...500, step: 10) {
                            Text("\(store.recipe.steps[index].volumeML) ml")
                                .frame(width: 70, alignment: .leading)
                        }
                        Stepper(value: $store.recipe.steps[index].pourSeconds, in: 0...255) {
                            Text(copy.seconds(store.recipe.steps[index].pourSeconds))
                                .frame(width: 56, alignment: .leading)
                        }
                        Stepper(value: $store.recipe.steps[index].intervalSeconds, in: 0...255) {
                            Text(copy.seconds(store.recipe.steps[index].intervalSeconds))
                                .frame(width: 56, alignment: .leading)
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

            HStack {
                Button {
                    store.addStep()
                } label: {
                    Label(copy.addStep, systemImage: "plus.circle")
                }
                .disabled(store.recipe.steps.count >= 8)

                Spacer()

                Button {
                    store.setCurrentRecipeAsDefault()
                } label: {
                    Label(store.isCurrentRecipeDefault ? copy.currentDefaultRecipe : copy.setDefaultRecipe, systemImage: "star.fill")
                }
                .disabled(store.isCurrentRecipeDefault)

                Button {
                    store.duplicateRecipe()
                } label: {
                    Label(copy.add, systemImage: "plus")
                }

                Button {
                    store.deleteCurrentRecipe()
                } label: {
                    Label(copy.delete, systemImage: "trash")
                }
                .disabled(!store.canDeleteCurrentRecipe)

                Button {
                    store.resetRecipeToDefault()
                } label: {
                    Label(copy.reset, systemImage: "arrow.counterclockwise")
                }
            }
        }
        .padding(18)
        .background(Smart8Palette.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Smart8Palette.line)
        )
    }
}

private struct SidePanel: View {
    @ObservedObject var store: Smart7SessionStore
    @Binding var showingDiagnostics: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                DeviceCard(store: store)
                DrainControlCard(store: store)
                DiagnosticsCard(showingDiagnostics: $showingDiagnostics)
            }
            .padding(24)
        }
    }
}

private struct DeviceCard: View {
    @ObservedObject var store: Smart7SessionStore
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(copy.device)
                .font(.headline)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: store.isAuthenticated ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(store.isAuthenticated ? Smart8Palette.green : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EVS-70")
                            .font(.title3.bold())
                        Text("HARIO Smart7 EVS-70")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "cellularbars")
                        .font(.title3)
                        .foregroundStyle(store.hasDiscoveredDevice ? .primary : .secondary)
                }

                StatusLine(systemImage: "dot.radiowaves.left.and.right", text: store.hasDiscoveredDevice ? copy.foundEVS70 : copy.notSearched, color: store.hasDiscoveredDevice ? Smart8Palette.blue : .secondary)
                StatusLine(systemImage: "bolt.horizontal.circle", text: store.isReady ? copy.notificationsEnabled : copy.waiting, color: store.isReady ? Smart8Palette.green : .secondary)
                StatusLine(systemImage: "checkmark.shield", text: store.isAuthenticated ? copy.authenticated : copy.unauthenticated, color: store.isAuthenticated ? Smart8Palette.green : .secondary)

                Divider()

                VStack(spacing: 8) {
                    Button {
                        store.startScanning()
                    } label: {
                        Label(copy.searchEVS70, systemImage: "dot.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }

                    Button {
                        store.connectDiscoveredDevice()
                    } label: {
                        Label(copy.connectFoundEVS70, systemImage: "link")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!store.hasDiscoveredDevice || store.isReady)

                    HStack {
                        Button {
                            store.requestStatus()
                        } label: {
                            Label(copy.requestStatus, systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(!store.isAuthenticated)

                        Button {
                            store.disconnect()
                        } label: {
                            Label(copy.disconnect, systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(18)
            .background(Smart8Palette.surface, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Smart8Palette.line)
            )
        }
    }
}

private struct DrainControlCard: View {
    @ObservedObject var store: Smart7SessionStore
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(copy.controls)
                .font(.headline)

            VStack(alignment: .leading, spacing: 14) {
                Button {
                    store.startDrain()
                } label: {
                    HStack {
                        Label(copy.drainWater, systemImage: "drop.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!store.canStartDrain)

                Stepper(
                    value: Binding(
                        get: { store.drainStartDelaySeconds },
                        set: { store.setDrainStartDelaySeconds($0) }
                    ),
                    in: 0...30
                ) {
                    HStack {
                        Text(copy.startAfter)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(copy.seconds(store.drainStartDelaySeconds))
                            .font(.headline)
                    }
                }
                .disabled(store.isDraining || store.drainCountdownSeconds != nil)

                if let seconds = store.drainCountdownSeconds {
                    CountdownBanner(seconds: seconds)
                } else {
                    Text(store.isDraining ? copy.drainingWarning : copy.drainIdleText(delaySeconds: store.drainStartDelaySeconds))
                        .font(.subheadline)
                        .foregroundStyle(store.isDraining ? Smart8Palette.danger : .secondary)
                }

                Divider()

                Button {
                    store.stopDrain()
                } label: {
                    Label(store.drainCountdownSeconds == nil ? copy.stopDrain : copy.cancelDrainStart, systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!store.isDraining && store.drainCountdownSeconds == nil)
            }
            .padding(18)
            .background(Smart8Palette.surface, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Smart8Palette.line)
            )
        }
    }
}

private struct CountdownBanner: View {
    let seconds: Int
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        HStack(spacing: 12) {
            Text("\(seconds)")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Smart8Palette.accent)
                .frame(width: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(copy.drainStartsAfterSuffix)
                    .font(.headline)
                Text(copy.moveBeforeDrain)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Smart8Palette.accentSoft.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DiagnosticsCard: View {
    @Binding var showingDiagnostics: Bool
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(copy.diagnostics)
                .font(.headline)

            Button {
                showingDiagnostics.toggle()
            } label: {
                Label(showingDiagnostics ? copy.hideDiagnosticLog : copy.showDiagnosticLog, systemImage: "waveform.path.ecg")
                    .frame(maxWidth: .infinity)
            }
            .padding(14)
            .background(Smart8Palette.surface, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Smart8Palette.line)
            )
        }
    }
}

private struct FooterStatusView: View {
    @ObservedObject var store: Smart7SessionStore
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        HStack {
            Spacer()
            Circle()
                .fill(store.errorMessage == nil ? Smart8Palette.green : Smart8Palette.danger)
                .frame(width: 8, height: 8)
            Text(store.errorMessage == nil ? copy.allNormal : copy.hasError)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}

private struct StatusPill: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }
}

private struct StatusLine: View {
    let systemImage: String
    let text: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.body)
            .foregroundStyle(.primary)
            .labelStyle(CompactLabelStyle(color: color))
    }
}

private struct CompactLabelStyle: LabelStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundStyle(color)
                .frame(width: 18)
            configuration.title
        }
    }
}

private struct LogPanel: View {
    let logs: [DiagnosticLogEntry]
    @Environment(\.smart8Copy) private var copy

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(copy.diagnosticLog)
                .font(.headline)
                .padding(.top, 22)
                .padding(.horizontal, 18)

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
                    .padding(.horizontal, 18)
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
