import SwiftUI

/// Application entry point.
///
/// Milestone 1 shows a single placeholder window so the project has something
/// visible to launch. Milestone 2 replaces this with a `MenuBarExtra` scene and
/// removes the Dock presence (`LSUIElement`).
@main
struct OpenDictationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
