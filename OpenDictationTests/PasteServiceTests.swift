import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct PasteServiceTests {
    private let pasteboard = SpyPasteboard()
    private let permission = MockAccessibilityPermission()
    private let focusTracker = MockFrontmostAppTracker()
    private let synthesizer = SpyKeyEventSynthesizer()

    private var service: PasteService {
        PasteService(pasteboard: pasteboard, permission: permission, focusTracker: focusTracker, synthesizer: synthesizer)
    }

    @Test func capturesTargetAndRestoresFocusBeforePaste() throws {
        permission.isGranted = true

        service.captureTarget()
        try service.pasteToFocusedApp("Hi")

        #expect(focusTracker.captureCount == 1)
        // The paste path always asks whether focus needs restoring.
        #expect(focusTracker.activateCount == 1)
        #expect(synthesizer.postCount == 1)
    }

    @Test func whenTargetNeedsActivationPasteIsDeferred() async throws {
        permission.isGranted = true
        focusTracker.needsActivation = true
        let svc = service // retain the instance across the deferred paste

        try svc.pasteToFocusedApp("Hi")

        // Deferred until focus settles, so not posted synchronously…
        #expect(synthesizer.postCount == 0)
        #expect(pasteboard.copiedStrings == ["Hi"]) // clipboard already set
        // …but delivered shortly after. Poll rather than sleep a fixed amount,
        // so a slow/contended CI runner can't flake the timing.
        for _ in 0..<250 where synthesizer.postCount == 0 {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(synthesizer.postCount == 1)
    }

    @Test func grantedPermissionCopiesThenPostsCommandV() throws {
        permission.isGranted = true

        try service.pasteToFocusedApp("Hello")

        #expect(pasteboard.copiedStrings == ["Hello"])
        #expect(synthesizer.postCount == 1)
    }

    @Test func missingPermissionThrowsTypedAndTouchesNothing() {
        permission.isGranted = false

        #expect(throws: AppError.accessibilityPermissionDenied) {
            try service.pasteToFocusedApp("Hello")
        }
        #expect(pasteboard.copiedStrings.isEmpty)
        #expect(synthesizer.postCount == 0)
    }

    @Test func permissionIsCheckedOnEveryCall() throws {
        permission.isGranted = false
        #expect(throws: AppError.accessibilityPermissionDenied) {
            try service.pasteToFocusedApp("first")
        }

        // The user grants permission in System Settings and tries again —
        // no restart required.
        permission.isGranted = true
        try service.pasteToFocusedApp("second")
        #expect(synthesizer.postCount == 1)
    }

    @Test func clipboardFailurePreventsKeystroke() {
        pasteboard.succeeds = false

        #expect(throws: AppError.pasteFailed) {
            try service.pasteToFocusedApp("Hello")
        }
        #expect(synthesizer.postCount == 0)
    }

    @Test func synthesisFailurePropagatesAfterCopy() {
        synthesizer.error = AppError.pasteFailed

        #expect(throws: AppError.pasteFailed) {
            try service.pasteToFocusedApp("Hello")
        }
        // The copy already happened, so the user can still ⌘V manually.
        #expect(pasteboard.copiedStrings == ["Hello"])
    }

    @Test func systemSettingsDeepLinksAreWellFormed() {
        #expect(SystemSettingsDeepLink.accessibility.absoluteString.contains("Privacy_Accessibility"))
        #expect(SystemSettingsDeepLink.microphone.absoluteString.contains("Privacy_Microphone"))
        #expect(SystemSettingsDeepLink.accessibility.scheme == "x-apple.systempreferences")
        #expect(SystemSettingsDeepLink.microphone.scheme == "x-apple.systempreferences")
    }
}
