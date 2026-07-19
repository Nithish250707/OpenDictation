# Roadmap

## v0.1.0 — MVP (in progress)

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
| 10 | Open source polish — LICENSE audit, screenshots, CHANGELOG, refactor sweep | ⏳ Next |

Each milestone ends with: clean build, zero warnings, refactor pass, docs update, tests where appropriate, and a commit.

## Beyond v1 (ideas, not commitments)

- Additional transcription providers (Groq, Deepgram, …) via the existing `TranscriptionProvider` protocol
- Local/offline transcription (WhisperKit-class models)
- Streaming transcription
- AI post-processing (tone, formatting, custom vocabulary)
- Configurable output styles per app
- Localization

Ideas are discussed in issues before entering the roadmap. v1 ships first.
