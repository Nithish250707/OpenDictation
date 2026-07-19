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

## Milestone 2 — Menu Bar App

- [ ] Replace WindowGroup with `MenuBarExtra` (mic SF Symbol)
- [ ] `LSUIElement` so no Dock icon / app switcher entry
- [ ] Menu: Start Dictation, History…, Settings…, Quit
- [ ] Verify light/dark rendering of the menu bar icon
- [ ] Build, zero warnings, commit

## Milestone 3 — Recording Engine

- [ ] `HotkeyManager` (Carbon `RegisterEventHotKey`, default shortcut)
- [ ] `PanelManager` — non-activating floating `NSPanel` hosting SwiftUI
- [ ] `RecordingPopupView` + `RecordingViewModel` (state machine: idle → recording)
- [ ] `AudioRecordingService` (`AVAudioRecorder`, .m4a, metering)
- [ ] Microphone permission request + denied-state guidance
- [ ] `RecordingTimerView`, `WaveformView` components
- [ ] Build, zero warnings, commit

## Milestone 4 — OpenAI Transcription

- [ ] `TranscriptionProvider` protocol + `TranscriptionConfiguration` + `Transcript`
- [ ] `MultipartFormEncoder`
- [ ] `OpenAITranscriptionProvider` (URLSession)
- [ ] `AppError` taxonomy + friendly messages
- [ ] `TranscriptionService` orchestration (recording → upload → result)
- [ ] Build, zero warnings, commit

## Milestone 5 — Transcript UI

- [ ] Transcribing state (spinner) and transcript state in the popup
- [ ] Copy / Paste / Retry / Done actions wired to view model
- [ ] Error state with actionable message + Retry
- [ ] Build, zero warnings, commit

## Milestone 6 — Clipboard & Paste

- [ ] `PasteboardService` (copy + synthesized ⌘V)
- [ ] Accessibility permission detection + guidance flow
- [ ] Copy-only fallback when permission missing
- [ ] Build, zero warnings, commit

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
