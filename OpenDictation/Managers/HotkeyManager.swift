import AppKit
import Carbon.HIToolbox

/// Registers a system-wide keyboard shortcut using the Carbon hot key API —
/// the only dependency-free mechanism that works without Accessibility
/// permission. Carbon dispatches hot key events on the main run loop.
///
/// Both edges are delivered: `onHotkeyPressed` when the key goes down and
/// `onHotkeyReleased` when it comes back up. That pair is what makes
/// hold-to-talk possible without Accessibility access.
@MainActor
final class HotkeyManager {
    /// Invoked on the main actor when the shortcut's key goes down.
    var onHotkeyPressed: (() -> Void)?
    /// Invoked on the main actor when the shortcut's key is released.
    var onHotkeyReleased: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private static let signature: OSType = 0x4F44_484B // "ODHK"

    /// Registers the user's chosen shortcut, replacing any previous one.
    func register(shortcut: HotkeyShortcut) {
        register(keyCode: shortcut.keyCode, carbonModifiers: shortcut.carbonModifiers)
    }

    // `HotkeyShortcut` is the single source of truth for defaults; the raw
    // variant exists only as the Carbon-facing implementation.
    private func register(keyCode: UInt32, carbonModifiers: UInt32) {
        unregister()
        installEventHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        if status != noErr {
            // Most likely another app owns the combination; Milestone 7 lets
            // the user pick a different one.
            Log.hotkey.error("Failed to register global shortcut (OSStatus \(status))")
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        // Hold-to-talk needs both edges: pressed starts recording, released
        // stops it. Carbon delivers the released event when the non-modifier
        // key comes up, which is exactly the "let go to stop" gesture.
        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]
        // C callbacks can't capture context, so `self` travels through userData.
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            let kind = event.map { GetEventKind($0) }
            MainActor.assumeIsolated {
                switch kind {
                case UInt32(kEventHotKeyPressed): manager.onHotkeyPressed?()
                case UInt32(kEventHotKeyReleased): manager.onHotkeyReleased?()
                default: break
                }
            }
            return noErr
        }, eventTypes.count, &eventTypes, selfPointer, &eventHandlerRef)
    }
}
