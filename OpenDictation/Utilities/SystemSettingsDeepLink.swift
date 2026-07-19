import AppKit

/// The System Settings panes Open Dictation links to. One source of truth so
/// UI code never re-types these URLs.
@MainActor
enum SystemSettingsDeepLink {
    // Force-unwraps are safe: both are compile-time string constants.
    static let microphone = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
    static let accessibility = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!

    static func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
