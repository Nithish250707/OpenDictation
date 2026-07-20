import SwiftUI

/// Application entry point.
///
/// Open Dictation launches as a menu-bar-only agent (`LSUIElement`), which
/// keeps the recorder and background behavior exactly as before. The desktop
/// management window is a separate `Window` scene, opened on demand from the
/// menu bar; while it's open the app promotes itself to a regular app (see
/// `DesktopView`). `AppComposition` owns the dependency graph shared by every
/// scene.
@main
struct OpenDictationApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var composition = AppComposition()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                controller: composition.controller,
                dependencies: composition.dependencies,
                navigator: composition.navigator
            )
        } label: {
            MenuBarLabel(
                isRecording: composition.controller.isRecording,
                coordinator: appDelegate.windowCoordinator
            )
        }

        Window("Open Dictation", id: WindowID.main) {
            DesktopView(
                composition: composition,
                windowCoordinator: appDelegate.windowCoordinator
            )
        }
        .defaultSize(width: 920, height: 640)
        .windowResizability(.contentMinSize)
        .commands {
            CommandMenu("Go") {
                Button("Command Palette") {
                    composition.navigator.toggleCommandPalette()
                }
                .keyboardShortcut("k", modifiers: .command)

                Divider()

                Button("Home") { composition.navigator.go(to: .home) }
                    .keyboardShortcut("1", modifiers: .command)
                Button("History") { composition.navigator.go(to: .history) }
                    .keyboardShortcut("2", modifiers: .command)
                Button("AI Profiles") { composition.navigator.go(to: .aiProfiles) }
                    .keyboardShortcut("3", modifiers: .command)
                Button("Dictionary") { composition.navigator.go(to: .dictionary) }
                    .keyboardShortcut("4", modifiers: .command)
                Button("Settings") { composition.navigator.go(to: .settings) }
                    .keyboardShortcut("5", modifiers: .command)
            }
        }

        Settings {
            SettingsView(dependencies: composition.dependencies)
        }
    }
}

/// Scene identifiers used with `openWindow`.
enum WindowID {
    static let main = "main"
}
