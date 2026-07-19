# Roadmap

## v0.1.0 — MVP (in progress)

| # | Milestone | Status |
|---|---|---|
| 1 | Project foundation — Xcode project, docs, blank app builds & launches | ✅ Done |
| 2 | Menu bar app — MenuBarExtra, no Dock icon, app menu | ✅ Done |
| 3 | Recording engine — global shortcut, floating popup, audio capture, timer, waveform | ✅ Done |
| 4 | OpenAI transcription — provider protocol, multipart upload, error handling | ⏳ Next |
| 5 | Transcript UI — transcript state, Copy / Paste / Retry / Done | Planned |
| 6 | Clipboard & paste — pasteboard service, ⌘V synthesis, Accessibility guidance | Planned |
| 7 | Settings — API key (Keychain), model picker, shortcut, launch at login | Planned |
| 8 | History — SwiftData store, history window, search, delete | Planned |
| 9 | Testing — mocks for all services, view model state machine tests | Planned |
| 10 | Open source polish — LICENSE audit, screenshots, CHANGELOG, refactor sweep | Planned |

Each milestone ends with: clean build, zero warnings, refactor pass, docs update, tests where appropriate, and a commit.

## Beyond v1 (ideas, not commitments)

- Additional transcription providers (Groq, Deepgram, …) via the existing `TranscriptionProvider` protocol
- Local/offline transcription (WhisperKit-class models)
- Streaming transcription
- AI post-processing (tone, formatting, custom vocabulary)
- Configurable output styles per app
- Localization

Ideas are discussed in issues before entering the roadmap. v1 ships first.
