import Carbon.HIToolbox
import CoreGraphics

/// Capability: synthesizing the ⌘V keystroke into the frontmost application.
/// Isolated behind a protocol so tests never post real keyboard events.
@MainActor
protocol KeyEventSynthesizing: AnyObject {
    func postCommandV() throws
}

final class CGKeyEventSynthesizer: KeyEventSynthesizing {
    func postCommandV() throws {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
            throw AppError.pasteFailed
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
