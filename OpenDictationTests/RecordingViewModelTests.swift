import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct RecordingViewModelTests {
    private func makeViewModel(
        provider: MockTranscriptionProvider = .returning("Hello"),
        audio: MockAudioRecording = MockAudioRecording(),
        pasteboard: SpyPasteboard = SpyPasteboard()
    ) -> (RecordingViewModel, MockAudioRecording, SpyPasteboard) {
        let transcription = TranscriptionService(
            provider: provider,
            keyStore: InMemoryAPIKeyStore(keys: ["mock": "sk-test"]),
            environment: [:]
        )
        return (RecordingViewModel(audio: audio, transcription: transcription, pasteboard: pasteboard), audio, pasteboard)
    }

    /// After `stopAndTranscribe()` the state advances asynchronously
    /// (.recording → .transcribing → terminal); poll until it settles.
    private func waitForSettledState(of viewModel: RecordingViewModel) async {
        for _ in 0..<100 {
            switch viewModel.state {
            case .recording, .transcribing:
                try? await Task.sleep(for: .milliseconds(10))
            default:
                return
            }
        }
    }

    @Test func startTransitionsToRecording() async {
        let (viewModel, _, _) = makeViewModel()

        await viewModel.startRecording()

        #expect(viewModel.state.isRecording)
    }

    @Test func deniedPermissionTransitionsToPermissionDenied() async {
        let audio = MockAudioRecording()
        audio.permissionGranted = false
        let (viewModel, _, _) = makeViewModel(audio: audio)

        await viewModel.startRecording()

        #expect(viewModel.state == .permissionDenied)
    }

    @Test func stopProducesTranscriptAndDeletesAudio() async throws {
        let (viewModel, audio, _) = makeViewModel(provider: .returning("Hello, world."))

        await viewModel.startRecording()
        viewModel.stopAndTranscribe()
        await waitForSettledState(of: viewModel)

        guard case .transcript(let transcript) = viewModel.state else {
            Issue.record("Expected .transcript, got \(viewModel.state)")
            return
        }
        #expect(transcript.text == "Hello, world.")
        let audioURL = try #require(audio.recordedFileURL)
        #expect(!FileManager.default.fileExists(atPath: audioURL.path))
    }

    @Test func failureKeepsAudioForRetry() async throws {
        let (viewModel, audio, _) = makeViewModel(provider: .failing(.networkUnavailable))

        await viewModel.startRecording()
        viewModel.stopAndTranscribe()
        await waitForSettledState(of: viewModel)

        guard case .failed(let error, let audioFileURL, _) = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }
        #expect(error == .networkUnavailable)
        let keptURL = try #require(audioFileURL)
        #expect(FileManager.default.fileExists(atPath: keptURL.path))
        #expect(keptURL == audio.recordedFileURL)
    }

    @Test func resetAfterFailureDeletesKeptAudio() async throws {
        let (viewModel, audio, _) = makeViewModel(provider: .failing(.requestTimedOut))

        await viewModel.startRecording()
        viewModel.stopAndTranscribe()
        await waitForSettledState(of: viewModel)
        viewModel.reset()

        #expect(viewModel.state == .idle)
        let audioURL = try #require(audio.recordedFileURL)
        #expect(!FileManager.default.fileExists(atPath: audioURL.path))
    }

    @Test func missingAPIKeySurfacesTypedError() async {
        let transcription = TranscriptionService(
            provider: MockTranscriptionProvider.returning("unused"),
            keyStore: InMemoryAPIKeyStore(),
            environment: [:]
        )
        let viewModel = RecordingViewModel(
            audio: MockAudioRecording(),
            transcription: transcription,
            pasteboard: SpyPasteboard()
        )

        await viewModel.startRecording()
        viewModel.stopAndTranscribe()
        await waitForSettledState(of: viewModel)

        guard case .failed(let error, _, _) = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }
        #expect(error == .missingAPIKey)
    }

    @Test func copyPutsTranscriptTextOnPasteboard() async {
        let (viewModel, _, pasteboard) = makeViewModel(provider: .returning("Copy me"))

        await viewModel.startRecording()
        viewModel.stopAndTranscribe()
        await waitForSettledState(of: viewModel)
        viewModel.copyTranscript()

        #expect(pasteboard.copiedStrings == ["Copy me"])
        #expect(viewModel.justCopied)
    }
}
