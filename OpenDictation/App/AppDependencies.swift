import Foundation

/// Composition root for services. Built once at launch; view models receive
/// the protocols they need through their initializers, and tests substitute
/// mocks the same way.
@MainActor
struct AppDependencies {
    let audio: any AudioRecording
    let pasteboard: any PasteboardServicing
    let transcription: TranscriptionService

    static func live() -> AppDependencies {
        AppDependencies(
            audio: AVAudioRecordingService(),
            pasteboard: PasteboardService(),
            transcription: TranscriptionService(
                provider: OpenAITranscriptionProvider(),
                keyStore: KeychainService()
            )
        )
    }
}
