import AppKit
import SwiftUI

/// A macOS-style shortcut recorder. Click to arm it, then press any key
/// combination — a single key, a function key, or modifiers plus a key — and it
/// becomes the dictation shortcut. Escape cancels an in-progress recording.
///
/// Recording uses a local key-down monitor while armed, so it needs no special
/// permission and captures whatever the user presses inside the app's own
/// window. The captured key code and modifiers map straight onto Carbon's hot
/// key API (the virtual key codes are identical), so anything recorded here is
/// exactly what gets registered globally.
struct ShortcutRecorder: View {
    @Binding var shortcut: HotkeyShortcut

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggle) {
            Text(isRecording ? "Press shortcut…" : shortcut.display)
                .font(.body.weight(.medium))
                .frame(minWidth: 130)
                .padding(.vertical, 2)
        }
        .buttonStyle(.bordered)
        .tint(isRecording ? .accentColor : nil)
        .help(isRecording ? "Press any key or combination — Escape cancels" : "Click, then press your shortcut")
        .onDisappear(perform: stop)
    }

    private func toggle() {
        isRecording ? stop() : start()
    }

    private func start() {
        isRecording = true
        // Return nil from the handler to swallow the key press so it doesn't
        // beep or type into the settings window while we're capturing it.
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            handle(event)
            return nil
        }
    }

    private func handle(_ event: NSEvent) {
        let carbon = Self.carbonModifiers(from: event.modifierFlags)
        // Escape on its own cancels; ⌘Escape (etc.) is a legitimate shortcut.
        if event.keyCode == 53, carbon == 0 {
            stop()
            return
        }
        guard let keyName = Self.keyName(for: event) else { return }
        shortcut = HotkeyShortcut(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: carbon,
            display: HotkeyShortcut.makeDisplay(carbonModifiers: carbon, keyName: keyName)
        )
        stop()
    }

    private func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isRecording = false
    }

    // MARK: - Event → shortcut

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= HotkeyShortcut.commandMask }
        if flags.contains(.shift) { carbon |= HotkeyShortcut.shiftMask }
        if flags.contains(.option) { carbon |= HotkeyShortcut.optionMask }
        if flags.contains(.control) { carbon |= HotkeyShortcut.controlMask }
        return carbon
    }

    /// A special-key label (Space, F5, arrows) when the key code has one;
    /// otherwise the layout's base character, uppercased. `nil` for keys with
    /// no printable representation (e.g. a dead key), which we simply ignore.
    private static func keyName(for event: NSEvent) -> String? {
        if let special = HotkeyShortcut.specialKeyName(for: UInt32(event.keyCode)) {
            return special
        }
        guard let characters = event.charactersIgnoringModifiers else { return nil }
        let trimmed = characters.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let scalar = trimmed.unicodeScalars.first, scalar.value >= 0x20 else { return nil }
        return trimmed.uppercased()
    }
}
