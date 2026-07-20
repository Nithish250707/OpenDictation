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

<!-- SCREENSHOT: desktop Home dashboard with sidebar (docs/images/desktop-home.png) -->
<!-- SCREENSHOT: command palette ⌘K (docs/images/command-palette.png) -->
<!-- SCREENSHOT: History with filters and grouped cards (docs/images/history.png) -->
<!-- SCREENSHOT: floating recorder capsule while dictating (docs/images/recording.png) -->
<!-- SCREENSHOT: Settings (docs/images/settings.png) -->

</div>

---

## Why Open Dictation?

Dictation tools like Wispr Flow proved how transformative voice input can be — but the best ones are closed-source subscriptions. Open Dictation is an original, native implementation of that experience that respects your privacy: **your audio goes directly from your Mac to the transcription provider you configure, and nowhere else.**

## Features

- 🖥 **Native desktop app** — a sidebar-driven management window (Home dashboard, History, AI Profiles, Dictionary, Settings) that lives alongside the menu-bar agent; the floating recorder stays a lightweight overlay
- ⌘K **command palette** — jump to any section or run an action with type-ahead search, the way you'd expect from Raycast or Linear
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

> ⚠️ **Releases are not yet notarized** (that requires an Apple Developer ID; it's on the roadmap). Gatekeeper will block the first launch of a downloaded copy. To open it:
> 1. Double-click the app once (it will be blocked), then go to **System Settings → Privacy & Security**, scroll down, and click **"Open Anyway"**. *(On modern macOS the old right-click → Open trick no longer works for unnotarized apps.)*
> 2. Or, from Terminal: `xattr -d com.apple.quarantine /Applications/OpenDictation.app`
>
> Building from source avoids this entirely — locally built apps are never quarantined.

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

**"OpenDictation can't be opened" / Gatekeeper blocks the app** — expected for now: releases are ad-hoc signed, and `spctl` rejects any app without a Developer ID + notarization, no matter how correct its packaging. `codesign --verify` passing while `spctl` rejects is the ad-hoc signature working exactly as designed — internally valid, but carrying no trust chain. Use the "Open Anyway" steps from the Installation section. This disappears permanently once releases are notarized.

**"Accessibility Access Needed" persists even though OpenDictation is enabled in System Settings** — this is the same development-signing issue as the Keychain one. The app uses `AXIsProcessTrusted()` as the single source of truth, checked immediately before every paste; if the banner shows, that call is returning `false` for the running binary. macOS keys the Accessibility grant to the app's **code signature** (for ad-hoc/unsigned dev builds, the exact CDHash of the binary). A grant applies to *one specific binary*: the copy in `/Applications`, the copy in Xcode's DerivedData (⌘R), and a re-signed rebuild are three different identities with three different CDHashes, so a grant to one doesn't cover the others — even though the single "OpenDictation" row in System Settings looks enabled. To fix in development: remove the OpenDictation entry in System Settings → Privacy & Security → Accessibility, run the *exact* binary you intend to use, then grant it — and don't rebuild with a different signer in between. The permanent fix is a stable signing identity (Developer ID for releases), where the grant is keyed to the stable designated requirement and persists across rebuilds. Launch logging (`log stream --predicate 'process == "OpenDictation"' --info`, category `paste`) prints `AXIsProcessTrusted` and the executable path so you can confirm which binary is (un)trusted.

**"OpenDictation wants to use your confidential information stored in your keychain"** — this can only ever appear on the **first transcription of a session**, and on release builds at most once ever. The prompt is a *read* (decrypt) prompt, and the app issues exactly one protected read per launch — the key is then cached in memory for the rest of the process. Opening the window, navigating, checking onboarding, saving/replacing the key, and every other UI action use metadata-only queries (or the in-memory cache) and never prompt.

The prompt appears when the app's code signature doesn't match the keychain item's access list. During *development* this is expected: ad-hoc (unsigned) builds get a new signature on every rebuild, so a key saved by an earlier build no longer matches, and "Always Allow" can't stick because the signature it authorized ceases to exist at the next build. Two ways to clear it: click Allow once per session, or **re-save the key** in Settings → Transcription — saving now deletes and re-adds the item so it's owned by the current build's signature, after which that session won't prompt again. Properly signed release builds have a stable signature, so they prompt at most once ever.

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
