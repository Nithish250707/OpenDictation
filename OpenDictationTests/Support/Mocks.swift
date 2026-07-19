import Foundation
@testable import OpenDictation

/// Test doubles for every service protocol.

@MainActor
final class MockAudioRecording: AudioRecording {
    var permissionGranted = true
    var startError: Error?
    var recordedFileURL: URL?

    private(set) var isRecording = false

    func requestPermission() async -> Bool { permissionGranted }

    func startRecording() throws -> URL {
        if let startError { throw startError }
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
    let id = "mock"
    let displayName = "Mock"
    let handler: @Sendable (URL, TranscriptionConfiguration) throws -> Transcript

    func transcribe(audioFileURL: URL, configuration: TranscriptionConfiguration) async throws -> Transcript {
        try handler(audioFileURL, configuration)
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
    private(set) var copiedStrings: [String] = []

    func copy(_ text: String) { copiedStrings.append(text) }
}
