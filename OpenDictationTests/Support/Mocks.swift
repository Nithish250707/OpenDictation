import Foundation
@testable import OpenDictation

/// Test doubles for every service protocol.

@MainActor
final class MockAudioRecording: AudioRecording {
    var permissionGranted = true
    /// Simulates the async gap while macOS shows the permission prompt.
    var permissionDelayMilliseconds = 0
    var startError: Error?
    var recordedFileURL: URL?
    private(set) var startCount = 0

    private(set) var isRecording = false

    func requestPermission() async -> Bool {
        if permissionDelayMilliseconds > 0 {
            try? await Task.sleep(for: .milliseconds(permissionDelayMilliseconds))
        }
        return permissionGranted
    }

    func startRecording() throws -> URL {
        if let startError { throw startError }
        startCount += 1
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mock-recording-\(UUID().uuidString).m4a")
        try Data("mock-audio".utf8).write(to: url)
        recordedFileURL = url
        isRecording = true
        return url
    }

    func stopRecording() -> URL? {
        isRecording = false
        return recordedFileURL
    }

    func currentPowerLevel() -> Float { 0.5 }
}

struct MockTranscriptionProvider: TranscriptionProvider {
    var id = "mock"
    var displayName = "Mock"
    var defaultModel = "mock-default"
    var supportedModels = ["mock-default", "mock-advanced"]
    let handler: @Sendable (URL, TranscriptionConfiguration) async throws -> Transcript

    func transcribe(audioFileURL: URL, configuration: TranscriptionConfiguration) async throws -> Transcript {
        try await handler(audioFileURL, configuration)
    }

    static func returning(_ text: String) -> MockTranscriptionProvider {
        MockTranscriptionProvider { _, configuration in
            Transcript(text: text, duration: 2, providerID: "mock", model: configuration.model, createdAt: .now)
        }
    }

    static func failing(_ error: AppError) -> MockTranscriptionProvider {
        MockTranscriptionProvider { _, _ in throw error }
    }
}

/// Serialized test access only; the lock-free mutable state is fine there.
final class InMemoryAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    var keys: [String: String]

    init(keys: [String: String] = [:]) {
        self.keys = keys
    }

    func save(_ key: String, for providerID: String) throws { keys[providerID] = key }
    func key(for providerID: String) throws -> String? { keys[providerID] }
    func deleteKey(for providerID: String) throws { keys[providerID] = nil }
}

@MainActor
final class SpyPasteboard: PasteboardServicing {
    var succeeds = true
    private(set) var copiedStrings: [String] = []

    @discardableResult
    func copy(_ text: String) -> Bool {
        guard succeeds else { return false }
        copiedStrings.append(text)
        return true
    }
}

@MainActor
final class MockAccessibilityPermission: AccessibilityPermissionChecking {
    var isGranted = true
    private(set) var openSettingsCount = 0

    func openSystemSettings() { openSettingsCount += 1 }
}

@MainActor
final class SpyKeyEventSynthesizer: KeyEventSynthesizing {
    var error: Error?
    private(set) var postCount = 0

    func postCommandV() throws {
        if let error { throw error }
        postCount += 1
    }
}

@MainActor
final class MockLoginItemManager: LoginItemManaging {
    var isEnabled = false
    var nextError: Error?

    func setEnabled(_ enabled: Bool) throws {
        if let nextError { throw nextError }
        isEnabled = enabled
    }
}

@MainActor
final class MockPermissionStatus: PermissionStatusChecking {
    var microphone: PermissionState = .notDetermined
    var accessibilityGranted = false
}

@MainActor
final class MockHistoryStore: HistoryStoring {
    private(set) var saved: [Transcript] = []
    var saveError: Error?

    func save(_ transcript: Transcript) throws {
        if let saveError { throw saveError }
        saved.append(transcript)
    }

    func records(matching query: String?) throws -> [TranscriptionRecord] {
        saved
            .filter { query.map($0.text.localizedStandardContains) ?? true }
            .map(TranscriptionRecord.init)
    }

    func delete(_ record: TranscriptionRecord) throws {
        saved.removeAll { $0.text == record.text }
    }

    func deleteAll() throws {
        saved.removeAll()
    }
}

extension UserDefaults {
    /// A unique, empty defaults suite per call so settings tests never touch
    /// the user's real preferences or each other.
    static func ephemeral() -> UserDefaults {
        let suiteName = "opendictation-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
