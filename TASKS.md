# Tasks

Working checklist per milestone. Checked = done and committed.

## Milestone 12 — Distribution ✅

- [x] Sparkle 2 via SPM (`SparkleUpdaterManager` behind `UpdateManaging`; lazy init keeps tests/CI update-free)
- [x] GitHub Releases as the update feed: `appcast.xml` on main + EdDSA keys generated (private key in maintainer Keychain, public key in Info.plist)
- [x] "Check for Updates…" menu item; Updates section in Settings → General (auto-check toggle, version, Check Now)
- [x] `Scripts/release.sh`: Release build → sign (Developer ID or ad-hoc) → `hdiutil` DMG → optional notarize/staple → prints appcast signature; verified end-to-end unsigned
- [x] Hardened-runtime mic entitlement (`OpenDictation.entitlements`) so notarized builds can record
- [x] Custom Info.plist (feed URL + public key) merged with generated keys; membership exception so it isn't bundled as a resource
- [x] Versions → 0.2.0 / build 2; RELEASING.md; zero warnings; 88/88 tests

## Milestone 11 — Premium UX ✅

- [x] App icon: custom-drawn waveform on gradient squircle, all 10 sizes (no SF Symbols, per HIG)
- [x] Recorder capsule restyle: gradient hairline border, refined spacing/typography, tinted icon badges in status states
- [x] Blur-replace transitions between popup states; panel fade+slide entrance/exit
- [x] Waveform: peak-hold smoothing in the view model, gradient bars, smooth animation
- [x] Pulsing record indicator; larger rounded timer with numeric transitions
- [x] Onboarding: "Finish Setup — Add API Key…" menu item until a key exists; missing-key error opens Settings directly
- [x] Architecture unchanged; zero warnings; 88/88 tests green

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

## Milestone 7 — Settings ✅

- [x] `SettingsStore` — @Observable, UserDefaults-backed, injectable suite for tests
- [x] Four-tab native Settings window (General / Transcription / Appearance / Permissions), grouped forms, SF Symbols, subtle animations
- [x] API key add/replace/remove with validation via `APIKeyViewModel` (Keychain only; stored keys never displayed)
- [x] `ProviderRegistry` + provider protocol gains `defaultModel` / `supportedModels` — future providers are one file + one registry line
- [x] Per-provider model picker; stale model falls back to provider default
- [x] Language picker (16 languages + auto-detect) wired into requests
- [x] Shortcut picker (six curated presets), re-registered live via observation
- [x] Launch at login (`SMAppService` behind `LoginItemManaging`)
- [x] Auto-copy / auto-paste toggles honored by `RecordingViewModel`
- [x] Panel size / opacity / appearance applied by `FloatingPanelManager` + live preview
- [x] Live permission status (mic + Accessibility) with deep links, polled while visible
- [x] 25 new tests (67 total); build, zero warnings, docs, commit

## Milestone 8 — History ✅

- [x] SwiftData `TranscriptionRecord` + `HistoryService` behind `HistoryStoring` (injectable container, in-memory fallback if the store can't open)
- [x] Auto-save on successful transcription — never blocks the flow; failures log only
- [x] History window scene: newest-first list, live search, per-row copy (with feedback) and delete, Clear All with confirmation, empty states
- [x] History… menu item (window activation for a menu-bar-only app)
- [x] 13 new tests: service round-trips/search/sort, view model, auto-save behavior — 80 total
- [x] Build, zero warnings, tests green, commit

## Milestone 9 — Production Hardening ✅

(The test target, mocks, and state-machine tests originally planned here were
built incrementally in Milestones 4–8; this milestone became an audit.)

- [x] Fixed double-start race through the async mic-permission gap (`isStarting` guard + post-await state re-check + defensive recorder stop)
- [x] Fixed panel hide/show race (generation-guarded fade-out completion)
- [x] Recorder start failure surfaces a friendly error instead of vanishing
- [x] Cancel button in the Transcribing state (hung uploads can't trap the user)
- [x] "Copied to clipboard" indicator reflects the actual clipboard result
- [x] Copy/Paste feedback timers are cancellation-safe; permissions poller can't outlive its view model
- [x] Deep links consolidated (`SystemSettingsDeepLink`); duplicate default-shortcut source removed
- [x] Force-unwrap/force-cast audit: none remain except documented compile-time constants
- [x] 8 new regression tests (88 total, 14 suites); zero warnings

## Milestone 10 — Open Source Polish ✅

- [x] Refactor sweep (`PopupStatusView` extraction; naming/dead-code audit — all files under 300 lines)
- [x] Production README (hero, badges, screenshot placeholders, install, privacy table, architecture, roadmap)
- [x] Docs accuracy pass (ARCHITECTURE, API_DESIGN synced to shipped code)
- [x] GitHub Actions CI (build + tests on every push/PR), issue forms, PR template
- [x] LICENSE verified (MIT)
- [x] CHANGELOG 0.1.0 + tag + GitHub release
- [ ] App icon — deferred to v0.2 (needs design work)
- [ ] README screenshots — placeholders in; real captures deferred to v0.2
