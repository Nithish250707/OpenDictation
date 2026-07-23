import AppKit

/// Detects a lone modifier key (fn, Right ⌥, …) being held and released, so it
/// can drive hold-to-talk the same way `HotkeyManager` drives a Carbon hot key.
///
/// Carbon's `RegisterEventHotKey` can't register a modifier with no key, so a
/// modifier trigger is watched through `flagsChanged` events instead. That
/// requires Accessibility access (global keyboard monitoring is gated), whereas
/// ordinary Carbon combos do not — the caller is responsible for surfacing that.
///
/// A global monitor catches presses while another app is frontmost (the usual
/// case); a local monitor covers the moments Open Dictation itself is active.
@MainActor
final class ModifierKeyMonitor {
    /// Invoked on the main actor when the watched modifier goes down.
    var onPressed: (() -> Void)?
    /// Invoked on the main actor when the watched modifier is released.
    var onReleased: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var targetKeyCode: UInt16 = 0
    private var targetMask: UInt = 0
    private var isDown = false

    /// Starts watching `keyCode`, whose held-state is read from `mask` (the raw
    /// modifier-flags bit). Replaces any previous watch.
    func start(keyCode: UInt32, mask: UInt) {
        stop()
        targetKeyCode = UInt16(keyCode)
        targetMask = mask
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        isDown = false
    }

    private func handle(_ event: NSEvent) {
        // Every physical modifier reports its own key code on flagsChanged;
        // ignore the others so, e.g., Shift can't stop a Right-Option hold.
        guard event.keyCode == targetKeyCode else { return }
        let pressed = event.modifierFlags.rawValue & targetMask != 0
        if pressed, !isDown {
            isDown = true
            onPressed?()
        } else if !pressed, isDown {
            isDown = false
            onReleased?()
        }
    }
}
