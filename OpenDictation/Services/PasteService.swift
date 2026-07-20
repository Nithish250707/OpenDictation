import AppKit

/// Capability: placing text into the currently focused application.
@MainActor
protocol PasteServicing: AnyObject {
    /// Records the app to paste back into. Call when dictation begins, while
    /// the target app is still frontmost.
    func captureTarget()

    /// Copies `text` to the clipboard, restores the captured target app to the
    /// front if needed, then synthesizes ⌘V into it. The clipboard keeps the
    /// text afterwards (never restored away).
    /// - Throws: `AppError.accessibilityPermissionDenied` when the permission
    ///   is missing, `AppError.pasteFailed` when event synthesis fails.
    func pasteToFocusedApp(_ text: String) throws
}

/// Permission gate → clipboard → restore focus → keystroke. The recorder panel
/// never takes key/main status, so in the normal shortcut flow the target app
/// is still frontmost and no focus change is needed. But if Open Dictation is
/// frontmost at paste time (dictation started from the desktop window, etc.),
/// the captured target is reactivated first so the ⌘V lands in the right app.
@MainActor
final class PasteService: PasteServicing {
    private let pasteboard: any PasteboardServicing
    private let permission: any AccessibilityPermissionChecking
    private let focusTracker: any FrontmostAppTracking
    private let synthesizer: any KeyEventSynthesizing

    init(
        pasteboard: any PasteboardServicing,
        permission: any AccessibilityPermissionChecking,
        focusTracker: any FrontmostAppTracking,
        synthesizer: any KeyEventSynthesizing = CGKeyEventSynthesizer()
    ) {
        self.pasteboard = pasteboard
        self.permission = permission
        self.focusTracker = focusTracker
        self.synthesizer = synthesizer
    }

    func captureTarget() {
        focusTracker.captureTarget()
    }

    func pasteToFocusedApp(_ text: String) throws {
        // Query the permission immediately before pasting — never a cached value.
        let trusted = permission.isGranted
        Log.paste.info("Paste requested (Accessibility trusted = \(trusted, privacy: .public))")

        guard trusted else {
            Log.paste.error("Paste blocked: Accessibility not trusted for this process")
            throw AppError.accessibilityPermissionDenied
        }
        guard pasteboard.copy(text) else {
            Log.paste.error("Paste blocked: clipboard write failed")
            throw AppError.pasteFailed
        }

        // Ensure the app the user dictated from receives the keystroke.
        let reactivated = focusTracker.activateTargetIfNeeded()
        if reactivated {
            // Activation is asynchronous; let the target become frontmost
            // before synthesizing ⌘V. The clipboard already holds the text, so
            // a failure here still leaves the user one manual ⌘V away.
            Log.paste.info("Deferring ⌘V ~120ms for focus to settle")
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(120))
                guard let self else { return }
                do {
                    try self.synthesizer.postCommandV()
                    Log.paste.info("Paste succeeded: synthesized ⌘V (after focus restore)")
                } catch {
                    Log.paste.error("Paste failed: keystroke synthesis error (after focus restore)")
                }
            }
            return
        }

        do {
            try synthesizer.postCommandV()
            Log.paste.info("Paste succeeded: synthesized ⌘V")
        } catch {
            Log.paste.error("Paste failed: keystroke synthesis error")
            throw error
        }
    }
}
