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
    /// The single source of truth. `AXIsProcessTrusted()` reports whether *this
    /// exact running binary* is trusted for Accessibility — the grant is keyed
    /// to the executable's code signature, not just its bundle identifier.
    var isGranted: Bool {
        let trusted = AXIsProcessTrusted()
        Log.paste.debug("AXIsProcessTrusted() -> \(trusted, privacy: .public)")
        return trusted
    }

    func openSystemSettings() {
        SystemSettingsDeepLink.open(SystemSettingsDeepLink.accessibility)
    }
}
