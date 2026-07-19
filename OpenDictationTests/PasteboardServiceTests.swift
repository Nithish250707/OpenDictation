import AppKit
import Testing
@testable import OpenDictation

/// Exercises the real general pasteboard (test host app context), restoring
/// whatever the user had on it afterwards.
@MainActor
struct PasteboardServiceTests {
    @Test func copyWritesStringToGeneralPasteboard() {
        let previous = NSPasteboard.general.string(forType: .string)
        defer {
            NSPasteboard.general.clearContents()
            if let previous {
                NSPasteboard.general.setString(previous, forType: .string)
            }
        }

        let marker = "opendictation-test-\(UUID().uuidString)"
        let succeeded = PasteboardService().copy(marker)

        #expect(succeeded)
        #expect(NSPasteboard.general.string(forType: .string) == marker)
    }
}
