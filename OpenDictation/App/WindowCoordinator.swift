import AppKit

/// Bridges AppKit lifecycle events (launch, Dock reopen, relaunch) to
/// SwiftUI's `openWindow`, which is only reachable from inside the scene tree.
///
/// The menu bar label — the one view guaranteed to be alive from launch —
/// registers the open action; `AppDelegate` invokes it. The pending-open flag
/// makes the two safe in either order, since SwiftUI scene setup and
/// `applicationDidFinishLaunching` are not strictly ordered.
@MainActor
final class WindowCoordinator {
    private var openAction: (() -> Void)?
    private var launchHandled = false
    private var pendingLaunchOpen = false

    /// Set by the desktop window once it's live, so the Dock menu can trigger
    /// dictation. Nil until then.
    var startDictation: (() -> Void)?

    /// Supplied by a live SwiftUI view that owns an `openWindow` action.
    func register(open: @escaping () -> Void) {
        openAction = open
        if pendingLaunchOpen {
            pendingLaunchOpen = false
            open()
        }
    }

    /// Opens the desktop window exactly once, at app launch.
    func openOnLaunch() {
        guard !launchHandled else { return }
        launchHandled = true
        if let openAction {
            openAction()
        } else {
            // The scene tree isn't ready yet; open as soon as it registers.
            pendingLaunchOpen = true
        }
    }

    /// Reopens the single desktop window, e.g. on Dock click or relaunch.
    func reopen() {
        openAction?()
    }
}
