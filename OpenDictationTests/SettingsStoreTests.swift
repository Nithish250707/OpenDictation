import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct SettingsStoreTests {
    @Test func freshStoreHasSensibleDefaults() {
        let store = SettingsStore(defaults: .ephemeral())

        #expect(store.providerID == "openai")
        #expect(store.model == OpenAITranscriptionProvider.defaultModel)
        #expect(store.languageCode == nil)
        #expect(store.shortcut == .optionSpace)
        #expect(store.autoCopy)
        #expect(store.autoPaste)
        #expect(store.panelSize == .standard)
        #expect(store.panelOpacity == 1.0)
        #expect(store.panelAppearance == .system)
    }

    @Test func valuesPersistAcrossInstances() {
        let defaults = UserDefaults.ephemeral()

        let first = SettingsStore(defaults: defaults)
        first.providerID = "openai"
        first.model = "whisper-1"
        first.languageCode = "ta"
        first.shortcut = HotkeyShortcut.presets[2]
        first.autoCopy = false
        first.autoPaste = true
        first.panelSize = .large
        first.panelOpacity = 0.8
        first.panelAppearance = .dark

        let second = SettingsStore(defaults: defaults)
        #expect(second.model == "whisper-1")
        #expect(second.languageCode == "ta")
        #expect(second.shortcut == HotkeyShortcut.presets[2])
        #expect(!second.autoCopy)
        #expect(second.autoPaste)
        #expect(second.panelSize == .large)
        #expect(second.panelOpacity == 0.8)
        #expect(second.panelAppearance == .dark)
    }

    @Test func corruptShortcutDataFallsBackToDefault() {
        let defaults = UserDefaults.ephemeral()
        defaults.set(Data("not json at all".utf8), forKey: "settings.shortcut")

        let store = SettingsStore(defaults: defaults)

        #expect(store.shortcut == .optionSpace)
    }

    @Test func unknownEnumRawValuesFallBackToDefaults() {
        let defaults = UserDefaults.ephemeral()
        defaults.set("gigantic", forKey: "settings.panelSize")
        defaults.set("sepia", forKey: "settings.panelAppearance")

        let store = SettingsStore(defaults: defaults)

        #expect(store.panelSize == .standard)
        #expect(store.panelAppearance == .system)
    }

    @Test func clearingLanguageReturnsToAutoDetect() {
        let defaults = UserDefaults.ephemeral()

        let first = SettingsStore(defaults: defaults)
        first.languageCode = "fr"
        first.languageCode = nil

        let second = SettingsStore(defaults: defaults)
        #expect(second.languageCode == nil)
    }
}
