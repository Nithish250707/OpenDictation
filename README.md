# Open Dictation

**Privacy-first AI dictation for macOS.**

Press a shortcut anywhere on your Mac, speak naturally, and get beautifully formatted text within seconds. Open Dictation is a free, open-source, fully native macOS utility — no Electron, no web views, no telemetry.

> 🚧 **Status: pre-release.** Version 0.1.0 is under active development. See [ROADMAP.md](ROADMAP.md) for progress.

## Features (v1)

- 🎙 Dictate anywhere — a global shortcut opens a small floating recording popup
- 🌊 Live waveform and recording timer while you speak
- ⚡️ Fast transcription via the OpenAI transcription API (bring your own key)
- 📋 Copy, or paste straight into the app you were typing in
- 🕘 Automatic transcription history
- 🔐 API key stored only in the Apple Keychain — never on disk, never logged
- 🚀 Launch at login, menu bar native, light & dark mode

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16 or later (to build from source)
- An OpenAI API key

## Building from source

No package managers, no code generators, no extra tooling:

```sh
git clone https://github.com/opendictation/OpenDictation.git
cd OpenDictation
open OpenDictation.xcodeproj   # then ⌘R in Xcode
```

Or headless:

```sh
xcodebuild -project OpenDictation.xcodeproj -scheme OpenDictation build
```

## Privacy

Your audio is sent directly from your Mac to the transcription provider you configure — there is no middleman server. Recordings are deleted after successful transcription. History is stored locally. Your API key lives in the Keychain. Nothing is ever collected by this project.

## Permissions

| Permission | When | Why |
|---|---|---|
| Microphone | First recording | Capturing your dictation |
| Accessibility | Only if you use **Paste** | Synthesizing ⌘V into the app you're dictating into (the transcript is always copied to the clipboard regardless, so this permission is optional) |

## Documentation

| Doc | Purpose |
|---|---|
| [PROJECT_SPEC.md](PROJECT_SPEC.md) | What we're building and for whom |
| [ARCHITECTURE.md](ARCHITECTURE.md) | How the app is structured |
| [FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md) | Where things live |
| [API_DESIGN.md](API_DESIGN.md) | Core protocols and service contracts |
| [CODING_GUIDELINES.md](CODING_GUIDELINES.md) | Code style and conventions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [ROADMAP.md](ROADMAP.md) | Milestones and future direction |
| [TASKS.md](TASKS.md) | Detailed milestone task tracking |
| [CHANGELOG.md](CHANGELOG.md) | Release history |

## License

[MIT](LICENSE)
