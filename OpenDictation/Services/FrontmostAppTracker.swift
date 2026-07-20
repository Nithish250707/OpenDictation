import AppKit

/// Remembers which application was frontmost when dictation began, so a
/// synthesized paste can be delivered to it even if Open Dictation (its
/// desktop window or recorder) is frontmost at paste time. Without this, the
/// ⌘V lands in whatever app happens to be frontmost — which may be Open
/// Dictation itself.
@MainActor
protocol FrontmostAppTracking: AnyObject {
    /// Records the current frontmost app as the paste target. Ignores Open
    /// Dictation itself, keeping the previously captured target instead.
    func captureTarget()

    /// Brings the captured target back to the front if it isn't already.
    /// - Returns: `true` if it had to activate it (the caller should let the
    ///   activation settle before synthesizing the keystroke).
    func activateTargetIfNeeded() -> Bool

    /// Name of the captured target, for logging.
    var targetName: String? { get }
}

final class FrontmostAppTracker: FrontmostAppTracking {
    private var target: NSRunningApplication?
    private let ownPID = ProcessInfo.processInfo.processIdentifier

    var targetName: String? { target?.localizedName }

    func captureTarget() {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return }
        guard frontmost.processIdentifier != ownPID else {
            // Dictation was started from within Open Dictation; keep whatever
            // real app we last captured rather than targeting ourselves.
            Log.paste.info("Capture skipped — Open Dictation is frontmost; target stays \(self.target?.localizedName ?? "none", privacy: .public)")
            return
        }
        target = frontmost
        Log.paste.info("Captured paste target: \(frontmost.localizedName ?? "?", privacy: .public)")
    }

    func activateTargetIfNeeded() -> Bool {
        guard let target, !target.isTerminated else {
            Log.paste.info("No paste target to restore; pasting into current frontmost app")
            return false
        }
        if target.processIdentifier == NSWorkspace.shared.frontmostApplication?.processIdentifier {
            return false // already frontmost — no focus change needed
        }
        Log.paste.info("Restoring focus to \(target.localizedName ?? "?", privacy: .public) before paste")
        target.activate(from: .current)
        return true
    }
}
