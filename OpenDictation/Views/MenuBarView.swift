import SwiftUI

/// Contents of the menu shown when the user clicks the menu bar icon.
struct MenuBarView: View {
    var body: some View {
        Button {
            // Wired to the recording engine in Milestone 3.
        } label: {
            Label("Start Dictation", systemImage: "mic")
        }

        Divider()

        SettingsLink {
            Label("Settings…", systemImage: "gearshape")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit Open Dictation", systemImage: "xmark.circle")
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
