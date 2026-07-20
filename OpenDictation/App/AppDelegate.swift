import AppKit
import ApplicationServices

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
        // Diagnostic: which binary is running, and does TCC trust it? A grant
        // in System Settings applies to one specific executable identity; a
        // different build (Xcode DerivedData vs /Applications vs a re-signed
        // rebuild) is a different identity and will read as untrusted here.
        let executable = Bundle.main.executablePath ?? "?"
        let trusted = AXIsProcessTrusted()
        Log.paste.info("Launch — executable=\(executable, privacy: .public) AXIsProcessTrusted=\(trusted, privacy: .public)")
        #if DEBUG
        // Also to stderr in debug builds, so developers running the binary from
        // a terminal see the trust state directly. The grant is keyed to this
        // exact binary's code signature — a different build (Xcode DerivedData
        // vs /Applications vs a re-signed rebuild) is a different identity and
        // will read as untrusted even if "OpenDictation" looks enabled.
        FileHandle.standardError.write(Data("[OpenDictation] AXIsProcessTrusted=\(trusted) executable=\(executable)\n".utf8))
        #endif
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
