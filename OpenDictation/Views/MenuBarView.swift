import SwiftUI

/// Contents of the menu shown when the user clicks the menu bar icon.
struct MenuBarView: View {
    let controller: DictationController
    let dependencies: AppDependencies
    let navigator: DesktopNavigator

    @Environment(\.openWindow) private var openWindow

    private var needsAPIKey: Bool {
        !dependencies.keyStore.hasKey(for: dependencies.settings.providerID)
    }

    var body: some View {
        Button {
            openDesktop(.home)
        } label: {
            Label("Open Open Dictation", systemImage: "macwindow")
        }

        Divider()

        // Gentle first-run onboarding: surface the one missing step instead
        // of letting the first dictation end in an error.
        if needsAPIKey {
            Button {
                openDesktop(.settings)
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
            openDesktop(.history)
        } label: {
            Label("History…", systemImage: "clock.arrow.circlepath")
        }

        SettingsLink {
            Label("Settings…", systemImage: "gearshape")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button {
            dependencies.updater.checkForUpdates()
        } label: {
            Label("Check for Updates…", systemImage: "arrow.triangle.2.circlepath")
        }

        Divider()

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit Open Dictation", systemImage: "xmark.circle")
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    /// Deep-links into the desktop window at a specific section, bringing the
    /// app forward (it's a menu-bar agent, so it isn't active by default).
    private func openDesktop(_ section: DesktopSection) {
        navigator.go(to: section)
        openWindow(id: WindowID.main)
        NSApplication.shared.activate()
    }
}
