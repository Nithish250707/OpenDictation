# Roadmap

## v0.1.0 — MVP ✅ (released)

| # | Milestone | Status |
|---|---|---|
| 1 | Project foundation — Xcode project, docs, blank app builds & launches | ✅ Done |
| 2 | Menu bar app — MenuBarExtra, no Dock icon, app menu | ✅ Done |
| 3 | Recording engine — global shortcut, floating popup, audio capture, timer, waveform | ✅ Done |
| 4 | OpenAI transcription — provider protocol, multipart upload, error handling | ✅ Done |
| 5 | Transcript UI — transcript state, Copy / Retry / Done | ✅ Done |
| 6 | Clipboard & paste — auto-copy, paste-into-focused-app, ⌘V synthesis, Accessibility guidance | ✅ Done |
| 7 | Settings — provider/model/language, Keychain API key, shortcut, launch at login, behavior & panel preferences, live permission status | ✅ Done |
| 8 | History — SwiftData store, auto-save, history window with search/copy/delete | ✅ Done |
| 9 | Hardening — race/crash/edge-case audit, regression tests (88 total) | ✅ Done |
| 10 | Open source polish — refactor sweep, docs refresh, CI, community templates, v0.1.0 release | ✅ Done |

Each milestone ends with: clean build, zero warnings, refactor pass, docs update, tests where appropriate, and a commit.

## v0.2 candidates (from the v0.1 hardening audit)

- ~~App icon~~ ✅ shipped in Milestone 11
- README screenshots/GIF
- Hotkey-conflict feedback in Settings (registration failures are currently log-only)
- ~~Free-form shortcut recorder~~ ✅ shipped (record any key/combination; presets kept as quick picks)
- History retention limit and a "don't save history" toggle
- ~~Auto-updates + DMG pipeline~~ ✅ shipped in Milestone 12 (Sparkle, GitHub Releases feed)
- Notarized release builds — tooling ready (`Scripts/release.sh`); needs a Developer ID certificate

## Shipped since v0.1

- **Milestone 13 — Desktop app:** sidebar-driven management window (Home dashboard, History, Settings, placeholders for AI Profiles & Dictionary) alongside the menu-bar agent and floating recorder.
- **Milestone 14 — Desktop Experience 2.0:** command palette (⌘K), redesigned sidebar and Home dashboard, rich filterable History, designed AI Profiles & Dictionary screens (preview data), window state restoration, Dock menu.
- **Seamless dictation UX (pre-Local-AI):** hold-to-talk (press to start, release to stop; sub-100 ms taps discarded), an invisible recording HUD that replaces the transcript panel and auto-dismisses, auto-insert into the focused app on by default, and speech-tuned capture (16 kHz mono) with deterministic (temperature 0) transcription.

## Beyond that (ideas, not commitments)

- Additional transcription providers (Groq, Deepgram, …) via the existing `TranscriptionProvider` protocol
- Local/offline transcription (WhisperKit-class models)
- Streaming transcription
- AI post-processing (tone, formatting, custom vocabulary)
- Configurable output styles per app
- Localization

Ideas are discussed in issues before entering the roadmap. v1 ships first.
