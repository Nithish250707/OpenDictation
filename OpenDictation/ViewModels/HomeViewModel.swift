import Foundation
import Observation

/// Backing state for the Home dashboard: setup status and the most recent
/// dictations. Reads only the dependencies it needs so it stays testable
/// without constructing the whole app graph.
@MainActor
@Observable
final class HomeViewModel {
    static let recentLimit = 5

    private(set) var recentRecords: [TranscriptionRecord] = []

    private let history: any HistoryStoring
    private let keyStore: any APIKeyStoring
    private let settings: SettingsStore
    private let permissionStatus: any PermissionStatusChecking
    private let registry: ProviderRegistry
    private let loginItems: any LoginItemManaging

    init(
        history: any HistoryStoring,
        keyStore: any APIKeyStoring,
        settings: SettingsStore,
        permissionStatus: any PermissionStatusChecking,
        registry: ProviderRegistry,
        loginItems: any LoginItemManaging
    ) {
        self.history = history
        self.keyStore = keyStore
        self.settings = settings
        self.permissionStatus = permissionStatus
        self.registry = registry
        self.loginItems = loginItems
    }

    // MARK: - Setup status

    var hasAPIKey: Bool { keyStore.hasKey(for: settings.providerID) }
    var microphoneGranted: Bool { permissionStatus.microphone == .granted }
    var isFullyConfigured: Bool { hasAPIKey && microphoneGranted }

    // MARK: - Dashboard facts

    var providerName: String {
        registry.provider(id: settings.providerID)?.displayName ?? settings.providerID
    }

    var languageName: String {
        TranscriptionLanguage.all.first { $0.code == settings.languageCode }?.name
            ?? TranscriptionLanguage.auto.name
    }

    var launchAtLogin: Bool { loginItems.isEnabled }

    var shortcutDisplay: String { settings.shortcut.display }

    // MARK: - Recent dictations

    func refresh() {
        let all = (try? history.records(matching: nil)) ?? []
        recentRecords = Array(all.prefix(Self.recentLimit))
    }
}
