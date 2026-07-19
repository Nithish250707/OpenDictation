# API Design

Core contracts the app is built around. All services are protocols so view models can be tested with mocks; all async work uses async/await.

## TranscriptionProvider

The central abstraction. OpenAI is *an* implementation, never *the* implementation.

```swift
/// A backend capable of turning recorded audio into text.
protocol TranscriptionProvider: Sendable {
    /// Stable identifier, e.g. "openai".
    var id: String { get }
    /// Human-readable name for Settings, e.g. "OpenAI".
    var displayName: String { get }
    /// Model used when the user hasn't chosen one (or their choice went stale).
    var defaultModel: String { get }
    /// Models Settings offers for this provider.
    var supportedModels: [String] { get }
    /// Transcribes the audio file at `url`.
    /// - Throws: `AppError` describing what went wrong in user-presentable terms.
    func transcribe(audioFileURL: URL, configuration: TranscriptionConfiguration) async throws -> Transcript
}
```

Providers are registered in `ProviderRegistry.live()`. Adding one = a new
conforming type + one line in the registry; the provider picker, model picker,
API-key storage, and pipeline pick it up automatically.

```swift

struct TranscriptionConfiguration: Sendable {
    var apiKey: String
    var model: String            // e.g. "gpt-4o-transcribe", "whisper-1"
    var language: String?        // BCP-47 hint, nil = auto-detect
}

struct Transcript: Sendable, Equatable {
    var text: String
    var duration: TimeInterval   // length of the source audio
    var providerID: String
    var model: String
    var createdAt: Date
}
```

Adding a future provider (Groq, Deepgram, local Whisper…) = implement the protocol in one new file under `Providers/` and register it in the provider registry. No view, view model, or service changes.

## Service protocols

UI-adjacent services are `@MainActor` (they wrap main-thread-only system
APIs); pure data services are `Sendable`.

```swift
@MainActor
protocol AudioRecording: AnyObject {
    var isRecording: Bool { get }
    func requestPermission() async -> Bool       // prompts on first use
    func startRecording() throws -> URL          // temp .m4a being written
    func stopRecording() -> URL?
    func currentPowerLevel() -> Float            // normalized 0…1 for the waveform
}

protocol APIKeyStoring: Sendable {
    func save(_ key: String, for providerID: String) throws
    func key(for providerID: String) throws -> String?
    func deleteKey(for providerID: String) throws
    // hasKey(for:) presence check provided via extension — UI never
    // handles key material.
}

@MainActor
protocol PasteboardServicing: AnyObject {
    @discardableResult
    func copy(_ text: String) -> Bool
}

@MainActor
protocol PasteServicing: AnyObject {
    /// Permission gate → clipboard → synthesized ⌘V into the frontmost app.
    /// Throws accessibilityPermissionDenied / pasteFailed.
    func pasteToFocusedApp(_ text: String) throws
}

@MainActor
protocol HistoryStoring: AnyObject {
    func save(_ transcript: Transcript) throws
    func records(matching query: String?) throws -> [TranscriptionRecord]
    func delete(_ record: TranscriptionRecord) throws
    func deleteAll() throws
}
```

Smaller capability protocols follow the same pattern:
`AccessibilityPermissionChecking`, `KeyEventSynthesizing`,
`PermissionStatusChecking`, and `LoginItemManaging` — each with a live
implementation and a test mock.

## Error taxonomy

One user-presentable error type; providers map raw failures into it.

```swift
enum AppError: LocalizedError, Equatable {
    // Recording
    case microphonePermissionDenied
    case audioRecordingFailed
    case audioFileUnreadable

    // Transcription
    case missingAPIKey
    case invalidAPIKey                     // 401/403 from provider
    case unsupportedAudio                  // 415, or 400 about the file/format
    case rateLimited(retryAfter: TimeInterval?)  // 429 + Retry-After header
    case networkUnavailable                // offline, DNS/connect failures
    case requestTimedOut
    case serverError(statusCode: Int)      // 5xx
    case providerError(message: String)    // anything else, with the API's message

    // accessibilityPermissionDenied joins in Milestone 6 (paste).
}
```

Rules: every thrown error reaching a view model is an `AppError`; `errorDescription` is friendly and actionable; raw response bodies are never shown to users and never logged with secrets.

## OpenAI implementation notes

- `POST https://api.openai.com/v1/audio/transcriptions`, multipart/form-data (`file`, `model`, optional `language`), `Authorization: Bearer <key>`.
- Multipart encoding lives in its own `MultipartFormEncoder` type — pure function of inputs, unit-tested without networking.
- `URLSession` only. Timeouts tuned for short clips; no streaming in v1.

## Dependency injection

```swift
@MainActor
struct AppDependencies {
    let settings: SettingsStore              // @Observable, UserDefaults-backed
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
}
```

`AppComposition` builds this graph exactly once at launch and shares it across
the menu bar, recorder, History, and Settings scenes. View models receive
exactly the dependencies they need through their initializers — never the
whole container.
