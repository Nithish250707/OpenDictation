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
    var isGranted: Bool {
        AXIsProcessTrusted()
    }

    func openSystemSettings() {
        SystemSettingsDeepLink.open(SystemSettingsDeepLink.accessibility)
    }
}
