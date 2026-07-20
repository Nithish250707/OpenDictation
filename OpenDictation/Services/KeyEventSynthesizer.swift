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
        PasteDiagnostics.stage("synth: postCommandV begin")
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            PasteDiagnostics.stage("synth: CGEventSource(nil) FAILED")
            throw AppError.pasteFailed
        }
        PasteDiagnostics.stage("synth: CGEventSource created")
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true) else {
            PasteDiagnostics.stage("synth: keyDown event FAILED")
            throw AppError.pasteFailed
        }
        PasteDiagnostics.stage("synth: keyDown event created")
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
            PasteDiagnostics.stage("synth: keyUp event FAILED")
            throw AppError.pasteFailed
        }
        PasteDiagnostics.stage("synth: keyUp event created")
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        PasteDiagnostics.stage("synth: flags set; posting keyDown to cghidEventTap")
        keyDown.post(tap: .cghidEventTap)
        PasteDiagnostics.stage("synth: keyDown posted; posting keyUp")
        keyUp.post(tap: .cghidEventTap)
        PasteDiagnostics.stage("synth: keyUp posted; postCommandV DONE")
    }
}
