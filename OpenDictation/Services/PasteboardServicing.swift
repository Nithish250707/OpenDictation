import AppKit

/// Capability: putting transcript text on the system clipboard.
@MainActor
protocol PasteboardServicing: AnyObject {
    /// Returns `false` if the pasteboard refused the write (vanishingly rare,
    /// but callers that depend on the clipboard — like paste — must know).
    @discardableResult
    func copy(_ text: String) -> Bool
}

final class PasteboardService: PasteboardServicing {
    @discardableResult
    func copy(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}
