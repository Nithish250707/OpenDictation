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

    // MARK: - Free-form recorder helpers

    @Test func modifierSymbolsUseCanonicalOrder() {
        #expect(HotkeyShortcut.modifierSymbols(0) == "")
        #expect(HotkeyShortcut.modifierSymbols(HotkeyShortcut.optionMask) == "⌥")
        // Control, Option, Shift, Command — regardless of the mask's bit order.
        let all = HotkeyShortcut.commandMask | HotkeyShortcut.shiftMask
            | HotkeyShortcut.optionMask | HotkeyShortcut.controlMask
        #expect(HotkeyShortcut.modifierSymbols(all) == "⌃⌥⇧⌘")
        #expect(HotkeyShortcut.modifierSymbols(HotkeyShortcut.shiftMask | HotkeyShortcut.commandMask) == "⇧⌘")
    }

    @Test func specialKeyNamesCoverKeysAndFunctionRow() {
        #expect(HotkeyShortcut.specialKeyName(for: 49) == "Space")
        #expect(HotkeyShortcut.specialKeyName(for: 96) == "F5")
        #expect(HotkeyShortcut.specialKeyName(for: 126) == "↑")
        // An ordinary character key has no special name; its label comes from
        // the keyboard layout instead.
        #expect(HotkeyShortcut.specialKeyName(for: 2) == nil)
    }

    @Test func makeDisplayComposesModifiersAndKey() {
        #expect(HotkeyShortcut.makeDisplay(carbonModifiers: HotkeyShortcut.optionMask, keyName: "Space") == "⌥ Space")
        #expect(HotkeyShortcut.makeDisplay(carbonModifiers: 0, keyName: "F5") == "F5")
        // Composed presets match their hand-written display strings.
        for preset in HotkeyShortcut.presets {
            let keyName = HotkeyShortcut.specialKeyName(for: preset.keyCode) ?? ""
            if !keyName.isEmpty {
                #expect(HotkeyShortcut.makeDisplay(carbonModifiers: preset.carbonModifiers, keyName: keyName) == preset.display)
            }
        }
    }

    @Test func bareTypingKeyIsFlaggedButFunctionAndModifiedKeysAreNot() {
        let bareLetter = HotkeyShortcut(keyCode: 2, carbonModifiers: 0, display: "D")
        let bareFunction = HotkeyShortcut(keyCode: 96, carbonModifiers: 0, display: "F5")
        #expect(bareLetter.capturesABareTypingKey)
        #expect(!bareFunction.capturesABareTypingKey)
        #expect(!HotkeyShortcut.optionSpace.capturesABareTypingKey)
    }

    // MARK: - Modifier-key (push-to-talk) triggers

    @Test func modifierKeyMaskAndNameCoverTheSupportedKeys() {
        #expect(HotkeyShortcut.modifierKeyName(for: 61) == "Right ⌥")
        #expect(HotkeyShortcut.modifierKeyMask(for: 61) == 0x40)
        #expect(HotkeyShortcut.modifierKeyName(for: 63) == "fn")
        #expect(HotkeyShortcut.modifierKeyMask(for: 63) == 0x80_0000)
        // An ordinary key is not a modifier trigger.
        #expect(HotkeyShortcut.modifierKeyName(for: 2) == nil)
        #expect(HotkeyShortcut.modifierKeyMask(for: 2) == nil)
        #expect(!HotkeyShortcut.modifierKeyCodes.contains(2))
    }

    @Test func modifierKeyFactoryBuildsAPushToTalkTrigger() throws {
        let rightOption = try #require(HotkeyShortcut.modifierKey(keyCode: 61))
        #expect(rightOption.isModifierKey)
        #expect(rightOption.carbonModifiers == 0)
        #expect(rightOption.display == "Right ⌥")
        // A modifier trigger is never treated as a bare-typing-key footgun.
        #expect(!rightOption.capturesABareTypingKey)
        // A non-modifier key code yields nothing.
        #expect(HotkeyShortcut.modifierKey(keyCode: 2) == nil)
    }

    @Test func modifierKeyRoundTripsThroughCodable() throws {
        let trigger = try #require(HotkeyShortcut.modifierKey(keyCode: 63))
        let decoded = try JSONDecoder().decode(HotkeyShortcut.self, from: JSONEncoder().encode(trigger))
        #expect(decoded == trigger)
        #expect(decoded.isModifierKey)
    }

    @Test func legacyShortcutWithoutModifierFlagStillDecodes() throws {
        // Data persisted before isModifierKey existed must not be discarded.
        let legacy = Data(#"{"keyCode":49,"carbonModifiers":2048,"display":"⌥ Space"}"#.utf8)
        let decoded = try JSONDecoder().decode(HotkeyShortcut.self, from: legacy)
        #expect(decoded == .optionSpace)
        #expect(!decoded.isModifierKey)
    }
}
