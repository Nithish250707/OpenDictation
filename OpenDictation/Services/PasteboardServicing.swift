import AppKit

/// Capability: putting transcript text on the system clipboard.
/// Paste-into-focused-app joins in Milestone 6.
@MainActor
protocol PasteboardServicing: AnyObject {
    func copy(_ text: String)
}

final class PasteboardService: PasteboardServicing {
    func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
