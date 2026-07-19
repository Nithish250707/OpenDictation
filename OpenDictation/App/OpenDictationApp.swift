import SwiftUI

/// Application entry point.
///
/// Open Dictation lives exclusively in the menu bar: `LSUIElement` (set in the
/// target's Info.plist keys) removes the Dock icon and app-switcher entry, and
/// `MenuBarExtra` provides the status item. `DictationController` wires the
/// global shortcut, the floating recorder panel, and the recording engine.
@main
struct OpenDictationApp: App {
    @State private var controller = DictationController(dependencies: .live())

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(controller: controller)
        } label: {
            // Template SF Symbols adapt to light/dark menu bars automatically.
            Image(systemName: controller.isRecording ? "waveform" : "mic.fill")
        }

        Settings {
            SettingsView()
        }
    }
}
