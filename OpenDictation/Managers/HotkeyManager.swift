import AppKit
import Carbon.HIToolbox

/// Registers a system-wide keyboard shortcut using the Carbon hot key API —
/// the only dependency-free mechanism that works without Accessibility
/// permission. Carbon dispatches hot key events on the main run loop.
@MainActor
final class HotkeyManager {
    /// Invoked on the main actor every time the shortcut is pressed.
    var onHotkeyPressed: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private static let signature: OSType = 0x4F44_484B // "ODHK"

    /// Registers the shortcut. Defaults to ⌥Space; configurable in Milestone 7.
    func register(keyCode: UInt32 = UInt32(kVK_Space), carbonModifiers: UInt32 = UInt32(optionKey)) {
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

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        // C callbacks can't capture context, so `self` travels through userData.
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetEventDispatcherTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            MainActor.assumeIsolated {
                manager.onHotkeyPressed?()
            }
            return noErr
        }, 1, &eventType, selfPointer, &eventHandlerRef)
    }
}
