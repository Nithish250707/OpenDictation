import AppKit
import Foundation
import Observation

/// Live permission readout for the Permissions tab. Polls while the tab is
/// visible so grants made in System Settings appear without relaunching.
@MainActor
@Observable
final class PermissionsViewModel {
    private(set) var microphone: PermissionState
    private(set) var accessibilityGranted: Bool

    private let status: any PermissionStatusChecking
    private var pollTask: Task<Void, Never>?

    init(status: any PermissionStatusChecking) {
        self.status = status
        microphone = status.microphone
        accessibilityGranted = status.accessibilityGranted
    }

    func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.refresh()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func refresh() {
        microphone = status.microphone
        accessibilityGranted = status.accessibilityGranted
    }

    func openMicrophoneSettings() {
        SystemSettingsDeepLink.open(SystemSettingsDeepLink.microphone)
    }

    func openAccessibilitySettings() {
        SystemSettingsDeepLink.open(SystemSettingsDeepLink.accessibility)
    }
}
