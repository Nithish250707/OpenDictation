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
        PasteDiagnostics.stage("paste: pasteToFocusedApp begin")
        // Query the permission immediately before pasting — never a cached value.
        let trusted = permission.isGranted
        PasteDiagnostics.stage("paste: accessibility trusted = \(trusted)")

        guard trusted else {
            PasteDiagnostics.stage("paste: EARLY RETURN — not trusted")
            throw AppError.accessibilityPermissionDenied
        }
        let copied = pasteboard.copy(text)
        PasteDiagnostics.stage("paste: clipboard write = \(copied)")
        guard copied else {
            PasteDiagnostics.stage("paste: EARLY RETURN — clipboard write failed")
            throw AppError.pasteFailed
        }

        // Ensure the app the user dictated from receives the keystroke.
        let reactivated = focusTracker.activateTargetIfNeeded()
        PasteDiagnostics.stage("paste: focus reactivation needed = \(reactivated)")
        if reactivated {
            // Activation is asynchronous; let the target become frontmost
            // before synthesizing ⌘V. The clipboard already holds the text, so
            // a failure here still leaves the user one manual ⌘V away.
            PasteDiagnostics.stage("paste: deferring ⌘V ~120ms for focus to settle")
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(120))
                guard let self else {
                    PasteDiagnostics.stage("paste: DEFERRED TASK EXITED EARLY — PasteService deallocated")
                    return
                }
                PasteDiagnostics.stage("paste: deferred — posting now")
                do {
                    try self.synthesizer.postCommandV()
                    PasteDiagnostics.stage("paste: deferred ⌘V complete")
                } catch {
                    PasteDiagnostics.stage("paste: deferred ⌘V threw \(error)")
                }
            }
            PasteDiagnostics.stage("paste: pasteToFocusedApp returning (deferred path)")
            return
        }

        do {
            try synthesizer.postCommandV()
            PasteDiagnostics.stage("paste: synchronous ⌘V complete")
        } catch {
            PasteDiagnostics.stage("paste: synchronous ⌘V threw \(error)")
            throw error
        }
    }
}
