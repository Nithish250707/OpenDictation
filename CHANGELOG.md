# Changelog

All notable changes to Open Dictation are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org).

## [Unreleased]

_Nothing yet._

## [0.1.1] — 2026-07-19

App icon, premium UX polish, Sparkle auto-updates, and the Keychain prompt fix. This is the first release carrying the custom app icon (v0.1.0 shipped before the icon existed, which is why its bundle had no Assets.car) and the first with the auto-update framework — future releases install in one click.

### Fixed
- Keychain prompt audit: the app was performing a protected Keychain read on every menu open, every Settings visit, and every transcription — multiplying macOS "wants to use your confidential information" prompts, which recur across development rebuilds because ad-hoc signing changes the code signature the item's ACL was granted to. Now `CachedAPIKeyStore` caches the key in process memory after the first successful read (≤1 protected read per provider per launch; invalidated by save/delete, never persisted), and presence checks use attribute-only Keychain queries that never touch the protected secret, so they can't prompt at all. Root cause and guidance documented in the README's Troubleshooting section.

### Added
- Milestone 12 — Distribution: Sparkle 2 auto-updates fed from GitHub Releases (EdDSA-signed appcast served from the repo; updater initialized lazily so tests never trigger it), "Check for Updates…" in the menu bar and an Updates section in Settings → General; `Scripts/release.sh` builds a DMG via `hdiutil` with optional Developer ID signing and notarization (`CODESIGN_IDENTITY` / `NOTARY_PROFILE`); hardened-runtime microphone entitlement so notarized builds can record; versions bumped to 0.2.0 (build 2); RELEASING.md maintainer guide. Sparkle is the project's first and only dependency — there is no native framework for non-App-Store auto-updates.

### Changed
- Milestone 11 — Premium UX polish (no new features): app icon (custom-drawn waveform on a gradient squircle); recorder capsule restyled with a gradient hairline border, refined typography and spacing, and blur-replace transitions between states; panel now enters with a fade + upward slide and exits with a fade + drop; waveform bars gained peak-hold smoothing (instant attack, gentle decay) and a vertical gradient; pulsing record indicator; error/permission states get tinted icon badges; first-run onboarding — a "Finish Setup — Add API Key…" menu item until a key exists, and the missing-key error now opens Settings directly.

## [0.1.0] — 2026-07-19

First release: the complete core loop — global shortcut → floating recorder → OpenAI transcription → transcript with copy/paste → local history — as a fully native, dependency-free macOS menu bar app. 88 tests, zero-warnings policy, CI on every PR.

### Fixed
- Milestone 9 — Production hardening: a rapid double-press of the shortcut (or a press during the microphone permission prompt) can no longer start two recorders and leak a live mic capture; a new dictation started during the panel's fade-out can no longer have its panel hidden from under it; a recorder start failure now shows a friendly error instead of silently disappearing; the Transcribing state gained a Cancel button so a hung upload can't trap the user; the "Copied to clipboard" indicator now reflects whether the automatic copy actually succeeded; rapid Copy/Paste clicks no longer clear fresh feedback early; the Permissions polling task can no longer outlive its view model. System Settings deep links consolidated into one constant. 8 new regression tests (88 total).

### Added
- Milestone 8 — History: every successful dictation is saved automatically to a local SwiftData store in Application Support (never leaves the Mac; a store failure degrades to session-only history rather than blocking dictation). New History window from the menu bar: newest-first list with relative timestamps, duration, and model; live search; per-row copy with feedback and delete; Clear All with confirmation; native empty states. 13 new tests (80 total).
- Milestone 7 — Settings: native four-tab Settings window (General / Transcription / Appearance / Permissions) in the System Settings idiom. Keychain-backed API key add/replace/remove with validation (stored keys are never displayed); provider picker driven by a new `ProviderRegistry` so future providers are one file + one line; per-provider model picker; 16-language selection with auto-detect; six curated global-shortcut presets applied live without relaunch; launch at login via `SMAppService`; auto-copy and auto-paste toggles honored by the dictation flow; floating-panel size, opacity, and light/dark appearance with a live preview; live-updating microphone & Accessibility status with System Settings deep links. Preferences live in an injectable `SettingsStore`. 25 new tests (67 total).
- Milestone 6 — Clipboard & paste: transcripts are copied to the clipboard automatically the moment transcription succeeds; a Paste button places the text into the app you were dictating in by synthesizing ⌘V (never character-by-character typing). Accessibility permission is detected per attempt, with friendly inline guidance and a deep link to the exact System Settings pane when missing. Clipboard and keystroke synthesis live behind their own protocols; 13 new tests (42 total).
- Milestone 5 — Transcription workflow: recording now flows straight into transcription — transcribing state with progress indicator, native transcript view with selectable text, Copy (with feedback) / Retry / Done, and a friendly error screen for every typed failure. Retry re-uses the kept recording so a network failure never loses a take. Keychain-backed API key storage with a development environment-variable override.
- Milestone 4 — Transcription layer: `TranscriptionProvider` protocol with a configurable-model OpenAI implementation (multipart upload to `/v1/audio/transcriptions`), clean `Transcript` model, and a fully typed error taxonomy (invalid key, timeout, offline, unsupported audio, rate limits with Retry-After, server errors). First unit-test target: 17 tests covering multipart encoding and every error path via URLProtocol stubs.
- Milestone 3 — Recording engine: global ⌥Space shortcut (Carbon, no Accessibility permission needed), floating non-activating recorder panel with fade animations, `AVAudioRecorder` capture to a temporary .m4a with live waveform and drift-free timer, microphone permission flow with System Settings deep link, clean idle → recording → stopped state machine. Recordings are deleted on dismissal until transcription exists.
- Milestone 2 — Menu bar app: `MenuBarExtra` with mic icon, `LSUIElement` (no Dock icon), menu with Start Dictation / Settings… / Quit, Settings window stub.
- Milestone 1 — Project foundation: native Xcode project (zero external tooling), blank SwiftUI app targeting macOS 14+ in Swift 6 mode, shared scheme for headless `xcodebuild`, asset catalog placeholders, full documentation set, MIT license.
