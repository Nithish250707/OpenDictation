import SwiftUI

/// Application entry point.
///
/// Open Dictation lives exclusively in the menu bar: `LSUIElement` (set in the
/// target's Info.plist keys) removes the Dock icon and app-switcher entry, and
/// `MenuBarExtra` provides the status item. The Settings scene is opened from
/// the menu via `SettingsLink`.
@main
struct OpenDictationApp: App {
    var body: some Scene {
        MenuBarExtra("Open Dictation", systemImage: "mic.fill") {
            MenuBarView()
        }

        Settings {
            SettingsView()
        }
    }
}
