import SwiftUI

/// The menu bar status item's icon. It doubles as the app's launch hook:
/// being alive from launch, it registers the desktop-window open action with
/// the `WindowCoordinator` (the only point where `openWindow` is reachable
/// early enough to auto-open on launch).
struct MenuBarLabel: View {
    let isRecording: Bool
    let coordinator: WindowCoordinator

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        // Template SF Symbols adapt to light/dark menu bars automatically.
        Image(systemName: isRecording ? "waveform" : "mic.fill")
            .onAppear {
                coordinator.register {
                    openWindow(id: WindowID.main)
                    NSApplication.shared.activate()
                }
            }
    }
}
