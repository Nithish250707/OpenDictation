import AppKit
import Foundation

/// Verbose, file-backed tracing for the paste pipeline. Every stage records
/// the timestamp, thread, current frontmost application, whether Open Dictation
/// is active, and whether the intended target is active — so the exact point of
/// failure is visible. Logs to os_log (`paste` category) always, and to
/// `~/Library/Logs/OpenDictation/paste.log` in debug builds.
@MainActor
enum PasteDiagnostics {
    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    #if DEBUG
    static let logURL: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Logs/OpenDictation", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "paste.log")
    }()
    #endif

    static func stage(_ name: String, target: NSRunningApplication? = nil) {
        let frontmost = NSWorkspace.shared.frontmostApplication
        let line = "\(formatter.string(from: Date())) | thread=\(Thread.isMainThread ? "main" : "bg") | \(name) | frontmost=\(frontmost?.localizedName ?? "?")(\(frontmost?.bundleIdentifier ?? "?")) | odActive=\(NSRunningApplication.current.isActive ? "YES" : "no") | targetActive=\(target.map { $0.isActive ? "YES" : "no" } ?? "-")"
        Log.paste.info("\(line, privacy: .public)")
        #if DEBUG
        append(line)
        #endif
    }

    #if DEBUG
    private static func append(_ line: String) {
        guard let data = (line + "\n").data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: logURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: logURL)
        }
    }

    /// Drives the real paste pipeline against a fresh TextEdit document so the
    /// full trace (and whether the paste actually lands) can be inspected
    /// without a live dictation. Triggered by the `--diagnose-paste` argument.
    static func runSelfTest() async {
        try? FileManager.default.removeItem(at: logURL)
        stage("selftest: BEGIN")

        // Give the app a moment to finish opening its own window first.
        try? await Task.sleep(for: .milliseconds(500))

        // Open a fresh, editable TextEdit document (empty file → cursor ready).
        let fileURL = URL(fileURLWithPath: "/tmp/opendictation-pastetest.txt")
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)
        stage("selftest: opening TextEdit with \(fileURL.path)")
        NSWorkspace.shared.open(fileURL)

        // Wait until TextEdit is frontmost.
        var target: NSRunningApplication?
        for step in 1...25 {
            try? await Task.sleep(for: .milliseconds(200))
            let frontmost = NSWorkspace.shared.frontmostApplication
            if frontmost?.bundleIdentifier == "com.apple.TextEdit" {
                target = frontmost
                stage("selftest: TextEdit frontmost after \(step * 200)ms", target: frontmost)
                break
            }
        }
        guard let target else {
            stage("selftest: TextEdit never became frontmost — ABORT")
            return
        }

        // Build the real pipeline and run it.
        stage("selftest: capturing target", target: target)
        let tracker = FrontmostAppTracker()
        tracker.captureTarget()
        stage("selftest: captured=\(tracker.targetName ?? "nil")", target: target)

        let paste = PasteService(
            pasteboard: PasteboardService(),
            permission: AccessibilityPermission(),
            focusTracker: tracker
        )
        // Scenario A — target is already frontmost (normal shortcut flow).
        let markerA = "ODPASTE-A-\(Int(Date().timeIntervalSince1970))"
        stage("selftest A: target frontmost; pasteToFocusedApp(\(markerA))", target: target)
        try? paste.pasteToFocusedApp(markerA)
        try? await Task.sleep(for: .milliseconds(500))
        stage("selftest A: END", target: target)

        // Scenario B — Open Dictation is frontmost at paste time (the real
        // failing case). Target was captured while TextEdit was frontmost;
        // now steal focus back to us and confirm the paste is still delivered.
        stage("selftest B: bringing Open Dictation frontmost to simulate focus steal", target: target)
        NSApplication.shared.activate()
        for step in 1...15 {
            try? await Task.sleep(for: .milliseconds(150))
            if NSRunningApplication.current.isActive {
                stage("selftest B: Open Dictation frontmost after \(step * 150)ms", target: target)
                break
            }
        }
        let markerB = "ODPASTE-B-\(Int(Date().timeIntervalSince1970))"
        stage("selftest B: pasteToFocusedApp(\(markerB)) with OD frontmost", target: target)
        try? paste.pasteToFocusedApp(markerB)
        try? await Task.sleep(for: .milliseconds(800))
        stage("selftest B: END (markers A=\(markerA) B=\(markerB))", target: target)
    }
    #endif
}
