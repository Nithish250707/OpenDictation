import AppKit
import ApplicationServices

/// Capability: knowing whether the app may synthesize keyboard events
/// (macOS Accessibility permission), and sending the user to the right
/// System Settings pane when it may not.
@MainActor
protocol AccessibilityPermissionChecking: AnyObject {
    var isGranted: Bool { get }
    func openSystemSettings()
}

final class AccessibilityPermission: AccessibilityPermissionChecking {
    /// Deep link straight to Privacy & Security → Accessibility.
    static let settingsURLString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

    var isGranted: Bool {
        AXIsProcessTrusted()
    }

    func openSystemSettings() {
        guard let url = URL(string: Self.settingsURLString) else { return }
        NSWorkspace.shared.open(url)
    }
}
