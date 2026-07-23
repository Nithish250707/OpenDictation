import Foundation
import ServiceManagement

/// Capability: registering the app to launch at login.
@MainActor
protocol LoginItemManaging: AnyObject {
    var isEnabled: Bool { get }
    /// Registers/unregisters the login item. Async because the underlying
    /// `SMAppService` call can block for seconds when it can't succeed.
    func setEnabled(_ enabled: Bool) async throws
}

/// `SMAppService`-backed implementation — the modern, helper-free API.
final class LoginItemManager: LoginItemManaging {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) async throws {
        // `SMAppService.register()/.unregister()` is synchronous and can stall
        // for several seconds when it can't complete (e.g. an app launched from
        // Xcode's DerivedData rather than /Applications). Run it OFF the main
        // thread so it can never freeze the UI (window + menu bar).
        try await Task.detached(priority: .userInitiated) {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        }.value
    }
}
