import SwiftUI

/// Application entry point.
///
/// Open Dictation lives exclusively in the menu bar: `LSUIElement` (set in the
/// target's Info.plist keys) removes the Dock icon and app-switcher entry, and
/// `MenuBarExtra` provides the status item. `AppComposition` owns the
/// dependency graph shared by the menu, the recorder, and Settings.
@main
struct OpenDictationApp: App {
    @State private var composition = AppComposition()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(controller: composition.controller, dependencies: composition.dependencies)
        } label: {
            // Template SF Symbols adapt to light/dark menu bars automatically.
            Image(systemName: composition.controller.isRecording ? "waveform" : "mic.fill")
        }

        Settings {
            SettingsView(dependencies: composition.dependencies)
        }

        Window("History", id: WindowID.history) {
            HistoryView(
                history: composition.dependencies.history,
                pasteboard: composition.dependencies.pasteboard
            )
        }
        .defaultSize(width: 560, height: 460)
    }
}

/// Scene identifiers used with `openWindow`.
enum WindowID {
    static let history = "history"
}
