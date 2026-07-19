import Testing
@testable import OpenDictation

@MainActor
struct PermissionsViewModelTests {
    @Test func reflectsInitialStatuses() {
        let status = MockPermissionStatus()
        status.microphone = .granted
        status.accessibilityGranted = true

        let viewModel = PermissionsViewModel(status: status)

        #expect(viewModel.microphone == .granted)
        #expect(viewModel.accessibilityGranted)
    }

    @Test func refreshPicksUpLiveChanges() {
        let status = MockPermissionStatus()
        let viewModel = PermissionsViewModel(status: status)
        #expect(viewModel.microphone == .notDetermined)

        // The user grants both permissions in System Settings…
        status.microphone = .granted
        status.accessibilityGranted = true
        viewModel.refresh()

        #expect(viewModel.microphone == .granted)
        #expect(viewModel.accessibilityGranted)
    }
}
