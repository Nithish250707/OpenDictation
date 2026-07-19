import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct RecordingViewModelTests {
    /// Everything a test needs: the view model plus every injected double.
    @MainActor
    private struct Harness {
        let audio = MockAudioRecording()
        let pasteboard = SpyPasteboard()
        let permission = MockAccessibilityPermission()
        let synthesizer = SpyKeyEventSynthesizer()
        let settings = SettingsStore(defaults: .ephemeral())
        let history = MockHistoryStore()
        let viewModel: RecordingViewModel

        init(
            provider: MockTranscriptionProvider = .returning("Hello"),
            apiKeys: [String: String] = ["mock": "sk-test"]
        ) {
            settings.providerID = provider.id
            let transcription = TranscriptionService(
                registry: ProviderRegistry(providers: [provider]),
                keyStore: InMemoryAPIKeyStore(keys: apiKeys),
                settings: settings,
                environment: [:]
            )
            viewModel = RecordingViewModel(
                audio: audio,
                transcription: transcription,
                pasteboard: pasteboard,
                paste: PasteService(pasteboard: pasteboard, permission: permission, synthesizer: synthesizer),
                accessibility: permission,
                settings: settings,
                history: history
            )
        }

        /// After `stopAndTranscribe()` the state advances asynchronously
        /// (.recording → .transcribing → terminal); poll until it settles.
        func waitForSettledState() async {
            for _ in 0..<100 {
                switch viewModel.state {
                case .recording, .transcribing:
                    try? await Task.sleep(for: .milliseconds(10))
                default:
                    return
                }
            }
        }

        func dictate() async {
            await viewModel.startRecording()
            viewModel.stopAndTranscribe()
            await waitForSettledState()
        }
    }

    // MARK: - Recording

    @Test func startTransitionsToRecording() async {
        let harness = Harness()

        await harness.viewModel.startRecording()

        #expect(harness.viewModel.state.isRecording)
    }

    @Test func deniedPermissionTransitionsToPermissionDenied() async {
        let harness = Harness()
        harness.audio.permissionGranted = false

        await harness.viewModel.startRecording()

        #expect(harness.viewModel.state == .permissionDenied)
    }

    @Test func rapidDoubleStartRecordsOnlyOnce() async {
        let harness = Harness()
        // Open the async permission gap so the second call can race the first.
        harness.audio.permissionDelayMilliseconds = 40

        async let first: Void = harness.viewModel.startRecording()
        async let second: Void = harness.viewModel.startRecording()
        _ = await (first, second)

        #expect(harness.audio.startCount == 1)
        #expect(harness.viewModel.state.isRecording)
    }

    @Test func recorderStartFailureSurfacesAnError() async {
        let harness = Harness()
        harness.audio.startError = AppError.audioRecordingFailed

        await harness.viewModel.startRecording()

        guard case .failed(let error, let audioFileURL, _) = harness.viewModel.state else {
            Issue.record("Expected .failed, got \(harness.viewModel.state)")
            return
        }
        #expect(error == .audioRecordingFailed)
        #expect(audioFileURL == nil)
    }

    // MARK: - Transcription

    @Test func stopProducesTranscriptAndDeletesAudio() async throws {
        let harness = Harness(provider: .returning("Hello, world."))

        await harness.dictate()

        guard case .transcript(let transcript) = harness.viewModel.state else {
            Issue.record("Expected .transcript, got \(harness.viewModel.state)")
            return
        }
        #expect(transcript.text == "Hello, world.")
        let audioURL = try #require(harness.audio.recordedFileURL)
        #expect(!FileManager.default.fileExists(atPath: audioURL.path))
    }

    @Test func failureKeepsAudioForRetry() async throws {
        let harness = Harness(provider: .failing(.networkUnavailable))

        await harness.dictate()

        guard case .failed(let error, let audioFileURL, _) = harness.viewModel.state else {
            Issue.record("Expected .failed, got \(harness.viewModel.state)")
            return
        }
        #expect(error == .networkUnavailable)
        let keptURL = try #require(audioFileURL)
        #expect(FileManager.default.fileExists(atPath: keptURL.path))
        #expect(keptURL == harness.audio.recordedFileURL)
    }

    @Test func resetAfterFailureDeletesKeptAudio() async throws {
        let harness = Harness(provider: .failing(.requestTimedOut))

        await harness.dictate()
        harness.viewModel.reset()

        #expect(harness.viewModel.state == .idle)
        let audioURL = try #require(harness.audio.recordedFileURL)
        #expect(!FileManager.default.fileExists(atPath: audioURL.path))
    }

    @Test func missingAPIKeySurfacesTypedError() async {
        let harness = Harness(apiKeys: [:])

        await harness.dictate()

        guard case .failed(let error, _, _) = harness.viewModel.state else {
            Issue.record("Expected .failed, got \(harness.viewModel.state)")
            return
        }
        #expect(error == .missingAPIKey)
    }

    @Test func dismissDuringTranscriptionDiscardsTheStaleResult() async throws {
        let slowProvider = MockTranscriptionProvider { _, _ in
            try await Task.sleep(for: .milliseconds(80))
            return Transcript(text: "too late", duration: 1, providerID: "mock", model: "mock-default", createdAt: .now)
        }
        let harness = Harness(provider: slowProvider)

        await harness.viewModel.startRecording()
        harness.viewModel.stopAndTranscribe()
        // Wait until the upload is in flight, then dismiss mid-request.
        for _ in 0..<100 {
            if case .transcribing = harness.viewModel.state { break }
            try await Task.sleep(for: .milliseconds(5))
        }
        harness.viewModel.reset()
        try await Task.sleep(for: .milliseconds(150))

        // The late result must not resurrect the UI.
        #expect(harness.viewModel.state == .idle)
        let audioURL = try #require(harness.audio.recordedFileURL)
        #expect(!FileManager.default.fileExists(atPath: audioURL.path))
    }

    // MARK: - History

    @Test func successfulTranscriptionIsSavedToHistory() async {
        let harness = Harness(provider: .returning("Saved for later"))

        await harness.dictate()

        #expect(harness.history.saved.map(\.text) == ["Saved for later"])
    }

    @Test func failedTranscriptionIsNotSavedToHistory() async {
        let harness = Harness(provider: .failing(.networkUnavailable))

        await harness.dictate()

        #expect(harness.history.saved.isEmpty)
    }

    @Test func historySaveFailureStillDeliversTranscript() async {
        let harness = Harness(provider: .returning("Still delivered"))
        harness.history.saveError = AppError.providerError(message: "disk full")

        await harness.dictate()

        guard case .transcript(let transcript) = harness.viewModel.state else {
            Issue.record("Expected .transcript, got \(harness.viewModel.state)")
            return
        }
        #expect(transcript.text == "Still delivered")
    }

    // MARK: - Clipboard & paste

    @Test func successfulTranscriptionAutoCopies() async {
        let harness = Harness(provider: .returning("Auto-copied"))

        await harness.dictate()

        #expect(harness.pasteboard.copiedStrings == ["Auto-copied"])
    }

    @Test func autoCopyReportsHonestlyWhenClipboardFails() async {
        let harness = Harness(provider: .returning("Never copied"))
        harness.pasteboard.succeeds = false

        await harness.dictate()

        #expect(!harness.viewModel.autoCopied)
        #expect(harness.viewModel.pasteErrorMessage != nil)
        // The transcript itself must still be delivered.
        if case .transcript = harness.viewModel.state {} else {
            Issue.record("Expected .transcript, got \(harness.viewModel.state)")
        }
    }

    @Test func successfulAutoCopySetsTheIndicator() async {
        let harness = Harness(provider: .returning("Copied fine"))

        await harness.dictate()

        #expect(harness.viewModel.autoCopied)
        #expect(harness.viewModel.pasteErrorMessage == nil)
    }

    @Test func autoCopyOffLeavesClipboardAlone() async {
        let harness = Harness(provider: .returning("Not copied"))
        harness.settings.autoCopy = false

        await harness.dictate()

        #expect(harness.pasteboard.copiedStrings.isEmpty)
        if case .transcript = harness.viewModel.state {} else {
            Issue.record("Expected .transcript, got \(harness.viewModel.state)")
        }
    }

    @Test func autoPasteOnPastesWithoutUserAction() async {
        let harness = Harness(provider: .returning("Auto-pasted"))
        harness.settings.autoPaste = true
        harness.permission.isGranted = true

        await harness.dictate()

        #expect(harness.synthesizer.postCount == 1)
        #expect(harness.viewModel.justPasted)
    }

    @Test func autoPasteWithoutPermissionShowsGuidanceInsteadOfFailing() async {
        let harness = Harness(provider: .returning("Auto-pasted"))
        harness.settings.autoPaste = true
        harness.permission.isGranted = false

        await harness.dictate()

        #expect(harness.synthesizer.postCount == 0)
        #expect(harness.viewModel.needsAccessibilityPermission)
        if case .transcript = harness.viewModel.state {} else {
            Issue.record("Expected to stay in .transcript, got \(harness.viewModel.state)")
        }
    }

    @Test func manualCopyCopiesAgain() async {
        let harness = Harness(provider: .returning("Copy me"))

        await harness.dictate()
        harness.viewModel.copyTranscript()

        #expect(harness.pasteboard.copiedStrings == ["Copy me", "Copy me"])
        #expect(harness.viewModel.justCopied)
    }

    @Test func pasteSynthesizesKeystrokeAndAcknowledges() async {
        let harness = Harness(provider: .returning("Paste me"))
        harness.permission.isGranted = true

        await harness.dictate()
        harness.viewModel.pasteTranscript()

        #expect(harness.synthesizer.postCount == 1)
        #expect(harness.pasteboard.copiedStrings.last == "Paste me")
        #expect(harness.viewModel.justPasted)
        #expect(!harness.viewModel.needsAccessibilityPermission)
    }

    @Test func pasteWithoutPermissionShowsAccessibilityHelp() async {
        let harness = Harness(provider: .returning("Paste me"))
        harness.permission.isGranted = false

        await harness.dictate()
        harness.viewModel.pasteTranscript()

        #expect(harness.viewModel.needsAccessibilityPermission)
        #expect(harness.synthesizer.postCount == 0)
        // Still in the transcript state — the user keeps their text.
        if case .transcript = harness.viewModel.state {} else {
            Issue.record("Expected to stay in .transcript, got \(harness.viewModel.state)")
        }
    }

    @Test func pasteSynthesisFailureShowsFriendlyMessageAndKeepsTranscript() async {
        let harness = Harness(provider: .returning("Paste me"))
        harness.synthesizer.error = AppError.pasteFailed

        await harness.dictate()
        harness.viewModel.pasteTranscript()

        #expect(harness.viewModel.pasteErrorMessage != nil)
        #expect(!harness.viewModel.justPasted)
        if case .transcript = harness.viewModel.state {} else {
            Issue.record("Expected to stay in .transcript, got \(harness.viewModel.state)")
        }
    }

    @Test func openAccessibilitySettingsDelegatesToPermissionService() async {
        let harness = Harness()

        harness.viewModel.openAccessibilitySettings()

        #expect(harness.permission.openSettingsCount == 1)
    }

    @Test func resetClearsPasteState() async {
        let harness = Harness(provider: .returning("text"))
        harness.permission.isGranted = false

        await harness.dictate()
        harness.viewModel.pasteTranscript()
        harness.viewModel.reset()

        #expect(!harness.viewModel.needsAccessibilityPermission)
        #expect(harness.viewModel.pasteErrorMessage == nil)
        #expect(harness.viewModel.state == .idle)
    }
}
