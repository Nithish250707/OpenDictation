import Foundation

/// A language option for transcription. `code == nil` lets the provider
/// auto-detect the spoken language.
struct TranscriptionLanguage: Equatable, Hashable, Identifiable {
    /// ISO-639-1 code sent to the provider; nil means auto-detect.
    let code: String?
    let name: String

    var id: String { code ?? "auto" }

    static let auto = TranscriptionLanguage(code: nil, name: "Auto-detect")

    static let all: [TranscriptionLanguage] = [
        .auto,
        TranscriptionLanguage(code: "en", name: "English"),
        TranscriptionLanguage(code: "es", name: "Spanish"),
        TranscriptionLanguage(code: "fr", name: "French"),
        TranscriptionLanguage(code: "de", name: "German"),
        TranscriptionLanguage(code: "it", name: "Italian"),
        TranscriptionLanguage(code: "pt", name: "Portuguese"),
        TranscriptionLanguage(code: "nl", name: "Dutch"),
        TranscriptionLanguage(code: "ja", name: "Japanese"),
        TranscriptionLanguage(code: "zh", name: "Chinese"),
        TranscriptionLanguage(code: "ko", name: "Korean"),
        TranscriptionLanguage(code: "hi", name: "Hindi"),
        TranscriptionLanguage(code: "ta", name: "Tamil"),
        TranscriptionLanguage(code: "ar", name: "Arabic"),
        TranscriptionLanguage(code: "ru", name: "Russian"),
        TranscriptionLanguage(code: "tr", name: "Turkish"),
    ]
}
