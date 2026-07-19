<div align="center">

# 🎙 Open Dictation

**Privacy-first AI dictation for macOS.**

Press a shortcut anywhere on your Mac, speak naturally, and get accurate text in seconds —
copied to your clipboard or pasted straight into the app you were typing in.

Free, open source, and fully native. No Electron, no web views, no telemetry, no middleman servers.

[![CI](https://github.com/Nithish250707/OpenDictation/actions/workflows/ci.yml/badge.svg)](https://github.com/Nithish250707/OpenDictation/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey)
![Swift](https://img.shields.io/badge/Swift-6-orange)

<!-- SCREENSHOT: recorder panel while dictating (docs/images/recording.png) -->
<!-- SCREENSHOT: transcript with Copy / Paste / Done (docs/images/transcript.png) -->
<!-- SCREENSHOT: Settings window (docs/images/settings.png) -->

</div>

---

## Why Open Dictation?

Dictation tools like Wispr Flow proved how transformative voice input can be — but the best ones are closed-source subscriptions. Open Dictation is an original, native implementation of that experience that respects your privacy: **your audio goes directly from your Mac to the transcription provider you configure, and nowhere else.**

## Features

- 🎙 **Dictate anywhere** — a global shortcut (⌥Space by default) opens a small floating recorder over any app, without stealing your keyboard focus
- 🌊 **Live waveform & timer** while you speak
- ⚡️ **Fast transcription** via OpenAI's speech-to-text API (bring your own key; more providers on the roadmap)
- 📋 **Auto-copy** the moment transcription finishes, plus one-click **paste into the app you were typing in**
- 🕘 **Local history** with live search — stored only on your Mac
- ⚙️ **Native Settings** — provider & model, 16 languages + auto-detect, shortcut, behavior toggles, panel appearance, live permission status
- 🔐 **Keychain-only API key storage** — never on disk, never in logs, never displayed once saved
- 🔄 **Auto-updates** via Sparkle, delivered from GitHub Releases with signature verification
- 🚀 Launch at login · menu-bar native · light & dark mode · exactly one dependency ([Sparkle](https://sparkle-project.org), for updates — everything else is pure Apple frameworks)

## Installation

**Requirements:** macOS 14 (Sonoma) or later, and an [OpenAI API key](https://platform.openai.com/api-keys).

Download the latest release from the [Releases page](https://github.com/Nithish250707/OpenDictation/releases), unzip, and drag **OpenDictation.app** to Applications.

> ⚠️ Releases are not yet notarized. On first launch, right-click the app and choose **Open**, or allow it under System Settings → Privacy & Security.

First-run setup takes under a minute:
1. Click the mic icon in your menu bar → **Settings… → Transcription** and add your API key.
2. Press **⌥Space**, grant microphone access, and speak.
3. (Optional) Grant Accessibility access when you first use **Paste**, so transcripts can land directly in the active app.

## Build from source

No package managers, no code generators, no extra tooling — the repository is self-contained:

```sh
git clone https://github.com/Nithish250707/OpenDictation.git
cd OpenDictation
open OpenDictation.xcodeproj   # then ⌘R in Xcode 16 or later
```

Headless build and test:

```sh
xcodebuild -project OpenDictation.xcodeproj -scheme OpenDictation build
xcodebuild -project OpenDictation.xcodeproj -scheme OpenDictation test
```

## Privacy by design

| Data | Where it lives |
|---|---|
| Your voice | Recorded to a temporary file, sent **directly** to your configured provider, then deleted the moment it's no longer needed |
| Transcripts | Local SwiftData store on your Mac (History window; delete any or all anytime) |
| API key | Apple Keychain only |
| Preferences | Local UserDefaults |
| Telemetry | **None. There is no analytics code in this repository.** |

Permissions: **Microphone** (required, requested on first recording) and **Accessibility** (optional — only needed for the Paste action, which synthesizes ⌘V).

## Troubleshooting

**"OpenDictation wants to use your confidential information stored in your keychain"** — you should see this at most once per launch, and on release builds at most once ever. The prompt appears when the app's code signature doesn't match the keychain item's access list. During *development* this is expected: ad-hoc (unsigned) builds get a new signature on every rebuild, so macOS re-asks and "Always Allow" cannot stick. Click Allow, or re-save the key in Settings → Transcription (which re-creates the item under the current build's signature). Properly signed release builds have a stable signature and don't churn. The app performs at most one protected keychain read per provider per launch; menu and Settings presence checks use attribute-only queries that never trigger the prompt.

## Architecture

Native SwiftUI/AppKit, MVVM, protocol-oriented services with constructor injection, Swift 6 strict concurrency. Every service lives behind a protocol with a mock in the test suite (88 tests).

```
Views → ViewModels → Services/Managers → Providers → system frameworks
```

Transcription backends implement one protocol (`TranscriptionProvider`) and register in one place (`ProviderRegistry`) — adding Groq, Deepgram, or a local Whisper is a single new file. See [ARCHITECTURE.md](ARCHITECTURE.md) and [API_DESIGN.md](API_DESIGN.md) for the full picture.

## Roadmap

v0.1.0 ships the complete core loop: record → transcribe → copy/paste → history. Next up: more providers (including fully local models), a free-form shortcut recorder, hotkey-conflict feedback, and history retention controls. Details in [ROADMAP.md](ROADMAP.md).

## Contributing

Contributions are very welcome — the codebase is deliberately small, documented, and fully tested. Start with [CONTRIBUTING.md](CONTRIBUTING.md), then check [TASKS.md](TASKS.md) and the [issues](https://github.com/Nithish250707/OpenDictation/issues). Every PR runs CI (build + 88 tests, zero-warnings policy).

## License

[MIT](LICENSE) © Open Dictation contributors
