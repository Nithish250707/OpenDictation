import Foundation

/// Capability: placing text into the currently focused application.
@MainActor
protocol PasteServicing: AnyObject {
    /// Copies `text` to the clipboard, then synthesizes ⌘V into the frontmost
    /// app. The clipboard keeps the text afterwards (never restored away).
    /// - Throws: `AppError.accessibilityPermissionDenied` when the permission
    ///   is missing, `AppError.pasteFailed` when event synthesis fails.
    func pasteToFocusedApp(_ text: String) throws
}

/// Permission gate → clipboard → keystroke, in that order. Because the
/// recorder panel never takes key or main status, the frontmost app — the one
/// the user was typing in — is the paste target. If that app quit meanwhile,
/// the keystroke lands harmlessly in whatever is frontmost now and the text
/// is still on the clipboard.
@MainActor
final class PasteService: PasteServicing {
    private let pasteboard: any PasteboardServicing
    private let permission: any AccessibilityPermissionChecking
    private let synthesizer: any KeyEventSynthesizing

    init(
        pasteboard: any PasteboardServicing,
        permission: any AccessibilityPermissionChecking,
        synthesizer: any KeyEventSynthesizing = CGKeyEventSynthesizer()
    ) {
        self.pasteboard = pasteboard
        self.permission = permission
        self.synthesizer = synthesizer
    }

    func pasteToFocusedApp(_ text: String) throws {
        guard permission.isGranted else {
            throw AppError.accessibilityPermissionDenied
        }
        guard pasteboard.copy(text) else {
            throw AppError.pasteFailed
        }
        try synthesizer.postCommandV()
    }
}
