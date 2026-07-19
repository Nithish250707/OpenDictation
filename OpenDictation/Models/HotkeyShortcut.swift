import Foundation

/// A global keyboard shortcut in Carbon terms (the hot key API's native
/// currency), plus its human-readable form.
struct HotkeyShortcut: Codable, Equatable, Hashable, Identifiable {
    /// Carbon virtual key code (kVK_*).
    var keyCode: UInt32
    /// Carbon modifier mask (cmdKey 0x0100, shiftKey 0x0200, optionKey 0x0800, controlKey 0x1000).
    var carbonModifiers: UInt32
    /// Display string using standard macOS modifier symbols, e.g. "⌥ Space".
    var display: String

    var id: String { display }

    static let optionSpace = HotkeyShortcut(keyCode: 49, carbonModifiers: 0x0800, display: "⌥ Space")

    /// Curated, conflict-aware combinations offered in Settings. A free-form
    /// shortcut recorder is a candidate for a future release.
    static let presets: [HotkeyShortcut] = [
        .optionSpace,
        HotkeyShortcut(keyCode: 49, carbonModifiers: 0x0800 | 0x1000, display: "⌃⌥ Space"),
        HotkeyShortcut(keyCode: 49, carbonModifiers: 0x0800 | 0x0200, display: "⇧⌥ Space"),
        HotkeyShortcut(keyCode: 49, carbonModifiers: 0x0100 | 0x0200, display: "⇧⌘ Space"),
        HotkeyShortcut(keyCode: 2, carbonModifiers: 0x0800 | 0x0100, display: "⌥⌘ D"),
        HotkeyShortcut(keyCode: 2, carbonModifiers: 0x0200 | 0x0100, display: "⇧⌘ D"),
    ]
}
