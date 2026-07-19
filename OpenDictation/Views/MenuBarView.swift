import SwiftUI

/// Contents of the menu shown when the user clicks the menu bar icon.
struct MenuBarView: View {
    let controller: DictationController
    let dependencies: AppDependencies

    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    private var needsAPIKey: Bool {
        !dependencies.keyStore.hasKey(for: dependencies.settings.providerID)
    }

    var body: some View {
        // Gentle first-run onboarding: surface the one missing step instead
        // of letting the first dictation end in an error.
        if needsAPIKey {
            Button {
                openSettings()
                NSApplication.shared.activate()
            } label: {
                Label("Finish Setup — Add API Key…", systemImage: "key.fill")
            }

            Divider()
        }

        Button {
            controller.toggleDictation()
        } label: {
            Label(
                controller.isRecording ? "Stop Dictation" : "Start Dictation",
                systemImage: controller.isRecording ? "stop.circle" : "mic"
            )
        }

        Divider()

        Button {
            openWindow(id: WindowID.history)
            // Menu-bar-only apps aren't active; activate so the window fronts.
            NSApplication.shared.activate()
        } label: {
            Label("History…", systemImage: "clock.arrow.circlepath")
        }

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
