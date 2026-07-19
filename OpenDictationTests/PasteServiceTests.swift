import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct PasteServiceTests {
    private let pasteboard = SpyPasteboard()
    private let permission = MockAccessibilityPermission()
    private let synthesizer = SpyKeyEventSynthesizer()

    private var service: PasteService {
        PasteService(pasteboard: pasteboard, permission: permission, synthesizer: synthesizer)
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

    @Test func accessibilitySettingsDeepLinkIsWellFormed() {
        let url = URL(string: AccessibilityPermission.settingsURLString)
        #expect(url != nil)
        #expect(AccessibilityPermission.settingsURLString.contains("Privacy_Accessibility"))
    }
}
