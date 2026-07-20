import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct HomeViewModelTests {
    private func makeModel(
        keys: [String: String] = [:],
        microphone: PermissionState = .notDetermined,
        launchAtLogin: Bool = false,
        transcripts: [String] = [],
        configure: (SettingsStore) -> Void = { _ in }
    ) throws -> HomeViewModel {
        let history = HistoryService.inMemory()
        for (index, text) in transcripts.enumerated() {
            try history.save(Transcript(
                text: text,
                duration: 1,
                providerID: "openai",
                model: "whisper-1",
                createdAt: Date().addingTimeInterval(TimeInterval(index))
            ))
        }
        let settings = SettingsStore(defaults: .ephemeral())
        configure(settings)
        let permission = MockPermissionStatus()
        permission.microphone = microphone
        let login = MockLoginItemManager()
        login.isEnabled = launchAtLogin

        return HomeViewModel(
            history: history,
            keyStore: InMemoryAPIKeyStore(keys: keys),
            settings: settings,
            permissionStatus: permission,
            registry: .live(),
            loginItems: login
        )
    }

    @Test func recentRecordsAreLimitedAndNewestFirst() throws {
        let model = try makeModel(transcripts: ["1", "2", "3", "4", "5", "6", "7"])

        model.refresh()

        #expect(model.recentRecords.count == HomeViewModel.recentLimit)
        #expect(model.recentRecords.first?.text == "7")
        #expect(model.recentRecords.last?.text == "3")
    }

    @Test func emptyHistoryYieldsNoRecents() throws {
        let model = try makeModel()

        model.refresh()

        #expect(model.recentRecords.isEmpty)
    }

    @Test func notConfiguredWhenKeyOrMicMissing() throws {
        let noKey = try makeModel(microphone: .granted)
        #expect(!noKey.hasAPIKey)
        #expect(!noKey.isFullyConfigured)

        let noMic = try makeModel(keys: ["openai": "sk-test"], microphone: .denied)
        #expect(noMic.hasAPIKey)
        #expect(!noMic.microphoneGranted)
        #expect(!noMic.isFullyConfigured)
    }

    @Test func fullyConfiguredWhenKeyAndMicPresent() throws {
        let model = try makeModel(keys: ["openai": "sk-test"], microphone: .granted)

        #expect(model.isFullyConfigured)
    }

    @Test func providerAndLanguageNamesReflectSettings() throws {
        let model = try makeModel { settings in
            settings.languageCode = "fr"
        }

        #expect(model.providerName == "OpenAI")
        #expect(model.languageName == "French")
    }

    @Test func languageDefaultsToAutoDetect() throws {
        let model = try makeModel()

        #expect(model.languageName == "Auto-detect")
    }

    @Test func launchStatusReflectsLoginItems() throws {
        #expect(try makeModel(launchAtLogin: true).launchAtLogin)
        #expect(!(try makeModel(launchAtLogin: false).launchAtLogin))
    }
}
