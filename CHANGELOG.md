# Changelog

All notable changes to Open Dictation are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org).

## [Unreleased]

### Added
- Milestone 5 — Transcription workflow: recording now flows straight into transcription — transcribing state with progress indicator, native transcript view with selectable text, Copy (with feedback) / Retry / Done, and a friendly error screen for every typed failure. Retry re-uses the kept recording so a network failure never loses a take. Keychain-backed API key storage with a development environment-variable override.
- Milestone 4 — Transcription layer: `TranscriptionProvider` protocol with a configurable-model OpenAI implementation (multipart upload to `/v1/audio/transcriptions`), clean `Transcript` model, and a fully typed error taxonomy (invalid key, timeout, offline, unsupported audio, rate limits with Retry-After, server errors). First unit-test target: 17 tests covering multipart encoding and every error path via URLProtocol stubs.
- Milestone 3 — Recording engine: global ⌥Space shortcut (Carbon, no Accessibility permission needed), floating non-activating recorder panel with fade animations, `AVAudioRecorder` capture to a temporary .m4a with live waveform and drift-free timer, microphone permission flow with System Settings deep link, clean idle → recording → stopped state machine. Recordings are deleted on dismissal until transcription exists.
- Milestone 2 — Menu bar app: `MenuBarExtra` with mic icon, `LSUIElement` (no Dock icon), menu with Start Dictation / Settings… / Quit, Settings window stub.
- Milestone 1 — Project foundation: native Xcode project (zero external tooling), blank SwiftUI app targeting macOS 14+ in Swift 6 mode, shared scheme for headless `xcodebuild`, asset catalog placeholders, full documentation set, MIT license.
