import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let iconURL = Bundle.main.url(forResource: "Smart8", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        .terminateNow
    }
}

@main
struct Smart8App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = Smart7SessionStore()
    @AppStorage("Smart8.language") private var languageRawValue = Smart8Language.japanese.rawValue

    private var copy: Smart8Copy {
        Smart8Copy(language: Smart8Language(rawValue: languageRawValue) ?? .japanese)
    }

    var body: some Scene {
        WindowGroup("Smart8") {
            ContentView(store: store)
                .frame(minWidth: 980, minHeight: 680)
        }
        .commands {
            CommandMenu("Smart8") {
                Button(copy.requestStatus) {
                    store.requestStatus()
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(!store.isAuthenticated)
            }
        }
    }
}
