# Tasks

Working checklist per milestone. Checked = done and committed.

## Milestone 1 — Project Foundation ✅

- [x] Verify Xcode toolchain (`xcodebuild -version`)
- [x] Native `OpenDictation.xcodeproj` (folder-synchronized, shared scheme, zero external tooling)
- [x] Blank SwiftUI app target (macOS 14+, Swift 6 mode, ad-hoc signing)
- [x] Asset catalog (AppIcon placeholder, AccentColor)
- [x] Build succeeds with zero compiler warnings
- [x] App launches
- [x] Documentation set (README, PROJECT_SPEC, ARCHITECTURE, ROADMAP, CONTRIBUTING, TASKS, CODING_GUIDELINES, API_DESIGN, CHANGELOG, FOLDER_STRUCTURE)
- [x] MIT LICENSE, .gitignore
- [x] Initial commit

## Milestone 2 — Menu Bar App ✅

- [x] Replace WindowGroup with `MenuBarExtra` (mic SF Symbol)
- [x] `LSUIElement` so no Dock icon / app switcher entry
- [x] Menu: Start Dictation, Settings…, Quit (History menu item lands with Milestone 8)
- [x] Settings scene stub reachable via `SettingsLink`
- [x] Verified via LaunchServices: app registers as `UIElement`
- [x] Build, zero warnings, commit

## Milestone 3 — Recording Engine ✅

- [x] `HotkeyManager` (Carbon `RegisterEventHotKey`, default ⌥Space)
- [x] `FloatingPanelManager` — non-activating floating `NSPanel` hosting SwiftUI (never becomes key; stays above all windows; fade animations)
- [x] `RecordingPopupView` + `RecordingViewModel` (state machine: idle → recording → stopped, plus permission-denied)
- [x] `AVAudioRecordingService` (`AVAudioRecorder`, temp .m4a, metering)
- [x] Microphone permission request + denied-state guidance (deep link to System Settings)
- [x] `RecordingTimerView`, `WaveformView` components; recordings deleted on reset (no consumer until Milestone 4)
- [x] `AppDependencies` + `DictationController` composition root; menu item toggles Start/Stop
- [x] Build, zero warnings, commit

## Milestone 4 — OpenAI Transcription ✅

- [x] `TranscriptionProvider` protocol + `TranscriptionConfiguration` + `Transcript`
- [x] `MultipartFormEncoder` (pure, byte-for-byte testable)
- [x] `OpenAITranscriptionProvider` (URLSession, configurable model, injectable session)
- [x] `AppError` taxonomy: invalid key, timeout, offline, unsupported audio, rate limits (with Retry-After), server errors — all typed with friendly messages
- [x] `OpenDictationTests` target (pulled forward from Milestone 9): 17 tests — multipart encoding + provider success/error mapping via URLProtocol stubs
- [x] Build, zero warnings, tests green, commit
- [ ] `TranscriptionService` orchestration (recording → upload → result) — moved to Milestone 5, where the flow gets its UI

## Milestone 5 — Transcript UI ✅

- [x] `TranscriptionService` orchestration (key resolution → provider call), `KeychainService` + `APIKeyStoring` (storage only; Settings UI in Milestone 7)
- [x] State machine extended: recording → transcribing → transcript | failed (audio kept for Retry; deleted once it has no purpose)
- [x] Transcribing state (spinner) and transcript state in the popup
- [x] Copy (with "Copied" feedback) / Retry / Done actions wired to view model — Paste arrives in Milestone 6
- [x] Friendly error screen using the typed `AppError` messages, Retry re-uses the kept audio
- [x] 12 new tests (view model state machine with mocks, TranscriptionService key resolution, Keychain round-trip) — 29 total
- [x] Build, zero warnings, tests green, commit

## Milestone 6 — Clipboard & Paste ✅

- [x] Auto-copy transcript to clipboard on successful transcription (Copy button kept)
- [x] `PasteService` (permission gate → copy → synthesized ⌘V via `KeyEventSynthesizing`)
- [x] `AccessibilityPermission` detection (`AXIsProcessTrusted`, checked per attempt) + inline guidance with System Settings deep link
- [x] Copy-only fallback when permission missing; friendly message when synthesis fails
- [x] 13 new tests: paste service, clipboard service (real pasteboard, restored), permission flow, view model transitions — 42 total
- [x] Build, zero warnings, tests green, commit

## Milestone 7 — Settings

- [ ] `KeychainService` + masked API key field with validation
- [ ] Model picker (gpt-4o-transcribe / gpt-4o-mini-transcribe / whisper-1)
- [ ] Shortcut picker (curated presets)
- [ ] Launch at login toggle (`SMAppService`)
- [ ] Build, zero warnings, commit

## Milestone 8 — History

- [ ] SwiftData `TranscriptionRecord` + `HistoryService`
- [ ] Auto-save on successful transcription
- [ ] History window: list, search, copy, delete
- [ ] Build, zero warnings, commit

## Milestone 9 — Testing

- [ ] `OpenDictationTests` target
- [ ] Mocks for every service protocol
- [ ] Multipart encoder + OpenAI response/error parsing tests (URLProtocol stubs)
- [ ] `RecordingViewModel` state machine tests (happy path + failures)
- [ ] Keychain round-trip test (isolated service)
- [ ] Build, tests green, commit

## Milestone 10 — Open Source Polish

- [ ] Refactor sweep (duplication, file sizes, naming)
- [ ] App icon
- [ ] README screenshots
- [ ] CHANGELOG 0.1.0
- [ ] Docs accuracy pass
- [ ] Final commit / tag v0.1.0
