import Foundation
import Testing
@testable import OpenDictation

struct HotkeyShortcutTests {
    @Test func presetsAreUnique() {
        let ids = Set(HotkeyShortcut.presets.map(\.id))
        let combos = Set(HotkeyShortcut.presets.map { "\($0.keyCode)-\($0.carbonModifiers)" })

        #expect(ids.count == HotkeyShortcut.presets.count)
        #expect(combos.count == HotkeyShortcut.presets.count)
    }

    @Test func defaultPresetIsOptionSpace() {
        #expect(HotkeyShortcut.presets.first == .optionSpace)
        #expect(HotkeyShortcut.optionSpace.keyCode == 49)
        #expect(HotkeyShortcut.optionSpace.carbonModifiers == 0x0800)
    }

    @Test func codableRoundTrip() throws {
        for preset in HotkeyShortcut.presets {
            let data = try JSONEncoder().encode(preset)
            let decoded = try JSONDecoder().decode(HotkeyShortcut.self, from: data)
            #expect(decoded == preset)
        }
    }
}
