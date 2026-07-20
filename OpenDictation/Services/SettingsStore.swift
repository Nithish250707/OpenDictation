import Foundation
import Observation

/// Single source of truth for user preferences, persisted in UserDefaults.
/// API keys never live here — they belong to the Keychain (`APIKeyStoring`).
/// `UserDefaults` is injectable so tests run against an isolated suite.
@MainActor
@Observable
final class SettingsStore {
    private enum Key {
        static let providerID = "settings.providerID"
        static let model = "settings.model"
        static let language = "settings.language"
        static let shortcut = "settings.shortcut"
        static let autoCopy = "settings.autoCopy"
        static let autoPaste = "settings.autoPaste"
        static let panelSize = "settings.panelSize"
        static let panelOpacity = "settings.panelOpacity"
        static let panelAppearance = "settings.panelAppearance"
        static let lastDesktopSection = "settings.lastDesktopSection"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var providerID: String {
        didSet { defaults.set(providerID, forKey: Key.providerID) }
    }

    var model: String {
        didSet { defaults.set(model, forKey: Key.model) }
    }

    /// ISO-639-1 code; nil = auto-detect.
    var languageCode: String? {
        didSet { defaults.set(languageCode, forKey: Key.language) }
    }

    var shortcut: HotkeyShortcut {
        didSet {
            if let data = try? JSONEncoder().encode(shortcut) {
                defaults.set(data, forKey: Key.shortcut)
            }
        }
    }

    var autoCopy: Bool {
        didSet { defaults.set(autoCopy, forKey: Key.autoCopy) }
    }

    var autoPaste: Bool {
        didSet { defaults.set(autoPaste, forKey: Key.autoPaste) }
    }

    var panelSize: PanelSize {
        didSet { defaults.set(panelSize.rawValue, forKey: Key.panelSize) }
    }

    /// 0.7…1.0 — the floating panel's settled opacity.
    var panelOpacity: Double {
        didSet { defaults.set(panelOpacity, forKey: Key.panelOpacity) }
    }

    var panelAppearance: PanelAppearanceMode {
        didSet { defaults.set(panelAppearance.rawValue, forKey: Key.panelAppearance) }
    }

    /// Last-viewed desktop sidebar section, restored on next launch.
    var lastDesktopSection: String {
        didSet { defaults.set(lastDesktopSection, forKey: Key.lastDesktopSection) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        providerID = defaults.string(forKey: Key.providerID) ?? "openai"
        model = defaults.string(forKey: Key.model) ?? OpenAITranscriptionProvider.defaultModel
        languageCode = defaults.string(forKey: Key.language)
        shortcut = defaults.data(forKey: Key.shortcut)
            .flatMap { try? JSONDecoder().decode(HotkeyShortcut.self, from: $0) }
            ?? .optionSpace
        autoCopy = defaults.object(forKey: Key.autoCopy) as? Bool ?? true
        autoPaste = defaults.object(forKey: Key.autoPaste) as? Bool ?? false
        panelSize = defaults.string(forKey: Key.panelSize).flatMap(PanelSize.init(rawValue:)) ?? .standard
        panelOpacity = defaults.object(forKey: Key.panelOpacity) as? Double ?? 1.0
        panelAppearance = defaults.string(forKey: Key.panelAppearance)
            .flatMap(PanelAppearanceMode.init(rawValue:)) ?? .system
        lastDesktopSection = defaults.string(forKey: Key.lastDesktopSection) ?? "home"
    }
}
