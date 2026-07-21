import AppKit
import SwiftUI

/// A macOS-style shortcut recorder. Click to arm it, then press what you want:
///
/// - modifiers plus a key (e.g. ⌃⌥ D) or a single key/function key — captured
///   from the key-down and registered as a Carbon hot key, or
/// - a **lone modifier** (fn, Right ⌥, …) tapped on its own — captured from the
///   flags change and run as a push-to-talk trigger.
///
/// Escape cancels. Capture uses a local monitor (no permission needed) inside
/// the settings window; the runtime detection of a modifier trigger is what
/// needs Accessibility, not this recorder.
struct ShortcutRecorder: View {
    @Binding var shortcut: HotkeyShortcut

    @State private var coordinator = ShortcutRecorderCoordinator()
    @State private var isRecording = false

    var body: some View {
        Button(action: toggle) {
            Text(isRecording ? "Press shortcut…" : shortcut.display)
                .font(.body.weight(.medium))
                .frame(minWidth: 130)
                .padding(.vertical, 2)
        }
        .buttonStyle(.bordered)
        .tint(isRecording ? .accentColor : nil)
        .help(isRecording ? "Press any key, combination, or a lone modifier — Escape cancels" : "Click, then press your shortcut")
        .onDisappear(perform: stop)
    }

    private func toggle() {
        isRecording ? stop() : start()
    }

    private func start() {
        coordinator.onRecorded = { recorded in
            shortcut = recorded
            isRecording = false
        }
        coordinator.onCancelled = { isRecording = false }
        coordinator.start()
        isRecording = true
    }

    private func stop() {
        coordinator.stop()
        isRecording = false
    }
}

/// Owns the key monitor and the transient state needed to tell a lone-modifier
/// tap apart from a modifier+key combo while recording.
@MainActor
final class ShortcutRecorderCoordinator {
    var onRecorded: ((HotkeyShortcut) -> Void)?
    var onCancelled: (() -> Void)?

    private var monitor: Any?
    /// A modifier held on its own; recorded as push-to-talk if released before
    /// any other key or modifier joins it.
    private var armedModifierKeyCode: UInt16?

    func start() {
        stop()
        // Return nil from the handler to swallow the event so nothing types or
        // beeps into the settings window while we capture it.
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handle(event)
            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        armedModifierKeyCode = nil
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .keyDown: handleKeyDown(event)
        case .flagsChanged: handleFlagsChanged(event)
        default: break
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        // A real key press means this isn't a lone modifier — it's a combo.
        armedModifierKeyCode = nil
        let carbon = Self.carbonModifiers(from: event.modifierFlags)
        // Escape on its own cancels; ⌘Escape (etc.) is a legitimate shortcut.
        if event.keyCode == 53, carbon == 0 {
            onCancelled?()
            stop()
            return
        }
        guard let keyName = Self.keyName(for: event) else { return }
        record(HotkeyShortcut(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: carbon,
            display: HotkeyShortcut.makeDisplay(carbonModifiers: carbon, keyName: keyName)
        ))
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let keyCode = UInt32(event.keyCode)
        guard HotkeyShortcut.modifierKeyCodes.contains(keyCode),
              let mask = HotkeyShortcut.modifierKeyMask(for: keyCode) else {
            return // e.g. Caps Lock, or a key we don't offer as a trigger
        }
        let isDown = event.modifierFlags.rawValue & mask != 0
        if isDown {
            // Arm on the first lone modifier; a second one means a combo is
            // being built, so disarm and wait for the key-down instead.
            armedModifierKeyCode = armedModifierKeyCode == nil ? UInt16(keyCode) : nil
        } else if armedModifierKeyCode == UInt16(keyCode) {
            // Tapped and released on its own → a push-to-talk modifier trigger.
            if let recorded = HotkeyShortcut.modifierKey(keyCode: keyCode) {
                record(recorded)
            }
        } else {
            armedModifierKeyCode = nil
        }
    }

    private func record(_ shortcut: HotkeyShortcut) {
        onRecorded?(shortcut)
        stop()
    }

    // MARK: - Event parsing

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
