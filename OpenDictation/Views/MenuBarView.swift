import SwiftUI

/// Contents of the menu shown when the user clicks the menu bar icon.
struct MenuBarView: View {
    let controller: DictationController

    var body: some View {
        Button {
            controller.toggleDictation()
        } label: {
            Label(
                controller.isRecording ? "Stop Dictation" : "Start Dictation",
                systemImage: controller.isRecording ? "stop.circle" : "mic"
            )
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
