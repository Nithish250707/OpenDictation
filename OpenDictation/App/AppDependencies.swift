import Foundation

/// Composition root for services. Built once at launch; view models receive
/// the protocols they need through their initializers, and tests substitute
/// mocks the same way.
@MainActor
struct AppDependencies {
    let settings: SettingsStore
    let audio: any AudioRecording
    let pasteboard: any PasteboardServicing
    let paste: any PasteServicing
    let accessibility: any AccessibilityPermissionChecking
    let keyStore: any APIKeyStoring
    let registry: ProviderRegistry
    let transcription: TranscriptionService
    let loginItems: any LoginItemManaging
    let permissionStatus: any PermissionStatusChecking
    let history: any HistoryStoring
    let updater: any UpdateManaging

    static func live() -> AppDependencies {
        let settings = SettingsStore()
        let pasteboard = PasteboardService()
        let accessibility = AccessibilityPermission()
        // Cached so the protected Keychain read happens at most once per
        // provider per launch (see CachedAPIKeyStore for the why).
        let keyStore = CachedAPIKeyStore(wrapping: KeychainService())
        let registry = ProviderRegistry.live()
        return AppDependencies(
            settings: settings,
            audio: AVAudioRecordingService(),
            pasteboard: pasteboard,
            paste: PasteService(pasteboard: pasteboard, permission: accessibility, focusTracker: FrontmostAppTracker()),
            accessibility: accessibility,
            keyStore: keyStore,
            registry: registry,
            transcription: TranscriptionService(registry: registry, keyStore: keyStore, settings: settings),
            loginItems: LoginItemManager(),
            permissionStatus: SystemPermissionStatus(accessibility: accessibility),
            history: HistoryService.live(),
            updater: SparkleUpdaterManager()
        )
    }
}
