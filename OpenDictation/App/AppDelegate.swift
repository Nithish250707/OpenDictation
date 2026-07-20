import AppKit

/// First-class launch behavior while remaining a menu bar agent:
/// - Launching (from Finder, Spotlight, Dock, Launchpad) opens the desktop
///   management window.
/// - Relaunching or clicking the Dock icon reopens the existing window rather
///   than doing nothing or spawning a duplicate.
/// - Closing the window leaves the app running in the menu bar; it never quits
///   from a window close.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let windowCoordinator = WindowCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowCoordinator.openOnLaunch()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // No visible window (the app is running quietly in the menu bar):
        // bring the desktop window back. The window is single-instance, so
        // this reopens the existing one.
        if !flag {
            windowCoordinator.reopen()
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Closing the desktop window hides it; the menu bar recorder stays.
        false
    }

    /// Right-click Dock menu: quick access to the window and the recorder.
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()

        let open = NSMenuItem(title: "Open Open Dictation", action: #selector(dockOpen), keyEquivalent: "")
        open.target = self
        menu.addItem(open)

        if windowCoordinator.startDictation != nil {
            let dictate = NSMenuItem(title: "Start Dictation", action: #selector(dockStartDictation), keyEquivalent: "")
            dictate.target = self
            menu.addItem(dictate)
        }
        return menu
    }

    @objc private func dockOpen() {
        windowCoordinator.reopen()
    }

    @objc private func dockStartDictation() {
        windowCoordinator.startDictation?()
    }
}
