import Foundation

/// Composition root for services. Built once at launch; view models receive
/// the protocols they need through their initializers, and tests substitute
/// mocks the same way.
@MainActor
struct AppDependencies {
    let audio: any AudioRecording
    let pasteboard: any PasteboardServicing
    let paste: any PasteServicing
    let accessibility: any AccessibilityPermissionChecking
    let transcription: TranscriptionService

    static func live() -> AppDependencies {
        let pasteboard = PasteboardService()
        let accessibility = AccessibilityPermission()
        return AppDependencies(
            audio: AVAudioRecordingService(),
            pasteboard: pasteboard,
            paste: PasteService(pasteboard: pasteboard, permission: accessibility),
            accessibility: accessibility,
            transcription: TranscriptionService(
                provider: OpenAITranscriptionProvider(),
                keyStore: KeychainService()
            )
        )
    }
}
