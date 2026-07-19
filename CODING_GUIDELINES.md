# Coding Guidelines

## Language & concurrency

- Swift 6 language mode; resolve concurrency warnings properly, never with `@unchecked Sendable` shortcuts unless genuinely justified (document why).
- async/await everywhere; no completion handlers in new code.
- View models are `@MainActor`. Services are `Sendable` and actor-isolated where they hold mutable state.

## Structure

- One responsibility per file; one type per file; file name = type name.
- Prefer files under ~300 lines. Split before, not after, they get unwieldy.
- No duplicated code — extract a component, extension, or helper.
- Views stay small: if a `body` needs scrolling to read, extract subviews or components.
- Dependencies are injected via initializers against protocols. No singletons except thin wrappers over system singletons (and even then, behind a protocol).

## Naming

- Descriptive over clever: `startRecording()`, not `go()`.
- Protocols describe capability (`AudioRecording`, `APIKeyStoring`); implementations describe the mechanism (`AVAudioRecordingService`, `KeychainService`).
- Booleans read as assertions: `isRecording`, `hasAPIKey`.

## Comments

- Comment **why**, not what. A comment restating the code gets deleted in review.
- Public protocols and non-obvious behavior get doc comments (`///`).
- No commented-out code in commits.

## Errors & security

- Every error surfaced to the user is an `AppError` with a friendly, actionable message.
- Never log secrets, request headers, or transcript contents. `Logger` categories exist so this is auditable.
- API keys touch only the Keychain. Never UserDefaults, never files, never logs.
- Validate user input (API key shape, shortcut conflicts) at the edge, in view models.

## UI

- System colors, system fonts (SF), SF Symbols, semantic styles — light/dark support comes free and stays consistent.
- No hard-coded colors or magic numbers; shared constants live in `Utilities/Constants.swift`.
- Respect Reduce Motion for the waveform animation.

## Testing

- Every service protocol has a mock in the test target.
- View model state machines are unit-tested (happy path + each failure).
- Pure logic (multipart encoding, response parsing, error mapping) is tested exhaustively — it's cheap.
- No network calls in tests; providers are tested against canned responses via `URLProtocol` stubs.

## Warnings

- The build must stay at **zero warnings**. A PR that introduces a warning fixes it before merge.
