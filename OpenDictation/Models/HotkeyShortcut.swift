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
    /// True when the trigger is a lone modifier key (fn, Right ⌥, …) held as
    /// push-to-talk. These can't go through the Carbon hot key API — they're
    /// detected with a flags-change monitor instead (see `ModifierKeyMonitor`).
    var isModifierKey: Bool = false

    var id: String { display }

    static let optionSpace = HotkeyShortcut(keyCode: 49, carbonModifiers: 0x0800, display: "⌥ Space")

    /// Curated combinations offered as quick picks in Settings, alongside the
    /// free-form recorder.
    static let presets: [HotkeyShortcut] = [
        .optionSpace,
        HotkeyShortcut(keyCode: 49, carbonModifiers: 0x0800 | 0x1000, display: "⌃⌥ Space"),
        HotkeyShortcut(keyCode: 49, carbonModifiers: 0x0800 | 0x0200, display: "⌥⇧ Space"),
        HotkeyShortcut(keyCode: 49, carbonModifiers: 0x0100 | 0x0200, display: "⇧⌘ Space"),
        HotkeyShortcut(keyCode: 2, carbonModifiers: 0x0800 | 0x0100, display: "⌥⌘ D"),
        HotkeyShortcut(keyCode: 2, carbonModifiers: 0x0200 | 0x0100, display: "⇧⌘ D"),
    ]

    // MARK: - Carbon modifier masks

    static let commandMask: UInt32 = 0x0100
    static let shiftMask: UInt32 = 0x0200
    static let optionMask: UInt32 = 0x0800
    static let controlMask: UInt32 = 0x1000
    private static let allModifiers = commandMask | shiftMask | optionMask | controlMask

    // MARK: - Display composition (shared by the recorder)

    /// The modifier glyphs for a Carbon mask, in Apple's canonical order
    /// (⌃⌥⇧⌘). Empty when there are no modifiers.
    static func modifierSymbols(_ carbonModifiers: UInt32) -> String {
        var symbols = ""
        if carbonModifiers & controlMask != 0 { symbols += "⌃" }
        if carbonModifiers & optionMask != 0 { symbols += "⌥" }
        if carbonModifiers & shiftMask != 0 { symbols += "⇧" }
        if carbonModifiers & commandMask != 0 { symbols += "⌘" }
        return symbols
    }

    /// A readable label for a non-character key (Space, arrows, function keys,
    /// …); `nil` for ordinary character keys, whose label comes from the
    /// keyboard layout instead.
    static func specialKeyName(for keyCode: UInt32) -> String? {
        specialKeyNames[keyCode]
    }

    /// Assembles the persisted display string, e.g. "⌥ Space" or "F5".
    static func makeDisplay(carbonModifiers: UInt32, keyName: String) -> String {
        let symbols = modifierSymbols(carbonModifiers)
        return symbols.isEmpty ? keyName : "\(symbols) \(keyName)"
    }

    /// True when this is a lone character key with no modifiers — a footgun,
    /// since capturing it system-wide means it can't be typed normally.
    /// Function keys and lone modifier keys are exempt: they make perfectly
    /// good bare shortcuts.
    var capturesABareTypingKey: Bool {
        !isModifierKey
            && carbonModifiers & Self.allModifiers == 0
            && !Self.functionKeyCodes.contains(keyCode)
    }

    // MARK: - Modifier-key (push-to-talk) triggers

    /// Virtual key codes for the modifier keys usable as a lone push-to-talk
    /// trigger. They can't be registered as Carbon hot keys, so they run
    /// through `ModifierKeyMonitor` instead.
    static let modifierKeyCodes: Set<UInt32> = [54, 55, 56, 58, 59, 60, 61, 62, 63]

    /// The raw `NSEvent.modifierFlags` bit set while a given modifier key is
    /// held. Left/right variants use device-dependent bits; fn uses the
    /// device-independent function flag. `nil` for non-modifier key codes.
    static func modifierKeyMask(for keyCode: UInt32) -> UInt? {
        switch keyCode {
        case 55: 0x08          // Left Command
        case 54: 0x10          // Right Command
        case 56: 0x02          // Left Shift
        case 60: 0x04          // Right Shift
        case 59: 0x01          // Left Control
        case 62: 0x2000        // Right Control
        case 58: 0x20          // Left Option
        case 61: 0x40          // Right Option
        case 63: 0x80_0000     // fn / Globe (device-independent .function)
        default: nil
        }
    }

    /// A readable label for a lone modifier key, e.g. "Right ⌥" or "fn".
    static func modifierKeyName(for keyCode: UInt32) -> String? {
        switch keyCode {
        case 55: "Left ⌘"
        case 54: "Right ⌘"
        case 56: "Left ⇧"
        case 60: "Right ⇧"
        case 59: "Left ⌃"
        case 62: "Right ⌃"
        case 58: "Left ⌥"
        case 61: "Right ⌥"
        case 63: "fn"
        default: nil
        }
    }

    /// Builds a lone-modifier push-to-talk trigger, or `nil` if the key code
    /// isn't a supported modifier.
    static func modifierKey(keyCode: UInt32) -> HotkeyShortcut? {
        guard let name = modifierKeyName(for: keyCode) else { return nil }
        return HotkeyShortcut(keyCode: keyCode, carbonModifiers: 0, display: name, isModifierKey: true)
    }

    /// Virtual key codes for F1–F20.
    static let functionKeyCodes: Set<UInt32> = [
        122, 120, 99, 118, 96, 97, 98, 100, 101, 109,
        103, 111, 105, 107, 113, 106, 64, 79, 80, 90,
    ]

    private static let specialKeyNames: [UInt32: String] = [
        49: "Space", 36: "Return", 76: "Enter", 48: "Tab",
        51: "Delete", 117: "Forward Delete", 53: "Escape",
        115: "Home", 119: "End", 116: "Page Up", 121: "Page Down",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5",
        97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10",
        103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
        106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20",
    ]
}

extension HotkeyShortcut {
    private enum CodingKeys: String, CodingKey {
        case keyCode, carbonModifiers, display, isModifierKey
    }

    /// Custom decode so shortcuts persisted before `isModifierKey` existed
    /// still load (defaulting to a Carbon hot key) instead of being discarded.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyCode = try container.decode(UInt32.self, forKey: .keyCode)
        carbonModifiers = try container.decode(UInt32.self, forKey: .carbonModifiers)
        display = try container.decode(String.self, forKey: .display)
        isModifierKey = try container.decodeIfPresent(Bool.self, forKey: .isModifierKey) ?? false
    }
}
