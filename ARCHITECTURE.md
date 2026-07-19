# Architecture

Open Dictation is a native SwiftUI menu bar app using **MVVM**, **protocol-oriented services**, **constructor dependency injection**, and **Swift Concurrency** (async/await, `@MainActor` view models). Swift 6 language mode.

## Layers

```
┌────────────────────────────────────────────────┐
│ Views (SwiftUI)                                │  dumb, declarative
├────────────────────────────────────────────────┤
│ ViewModels (@MainActor, ObservableObject)      │  state + user intent
├────────────────────────────────────────────────┤
│ Services / Managers (protocols + live impls)   │  audio, network, keychain,
│                                                │  pasteboard, history, hotkey
├────────────────────────────────────────────────┤
│ Providers (TranscriptionProvider impls)        │  OpenAI today, more later
├────────────────────────────────────────────────┤
│ System frameworks                              │  AVFoundation, SwiftData,
│                                                │  AppKit, Carbon, Security
└────────────────────────────────────────────────┘
```

**Rule:** dependencies point downward only. Views never touch services directly; services never import SwiftUI.

## Dependency injection

`AppDependencies` (in `App/`) is a plain struct built once at launch. It constructs every service behind its protocol and hands them to view models via initializers. Tests construct the same view models with mock services. No DI framework.

## Key components

| Component | Kind | Responsibility |
|---|---|---|
| `HotkeyManager` | Manager | Global shortcut via Carbon `RegisterEventHotKey` — the only zero-dependency API that needs no Accessibility permission |
| `PanelManager` | Manager | Owns the floating popup: a non-activating `NSPanel` + `NSHostingView`, so keyboard focus stays in the target app |
| `AudioRecordingService` | Service | `AVAudioRecorder` → `.m4a` (AAC), metering enabled for the waveform |
| `TranscriptionService` | Service | Orchestrates provider calls; owns retry and error mapping |
| `TranscriptionProvider` | Protocol | `transcribe(audioFileURL:) async throws -> Transcript`; OpenAI is one implementation (see [API_DESIGN.md](API_DESIGN.md)) |
| `KeychainService` | Service | API key storage via `SecItem*` — never UserDefaults, never logged |
| `PasteboardService` | Service | Copy to `NSPasteboard`; paste = synthesized ⌘V `CGEvent` (Accessibility permission, graceful copy-only fallback) |
| `HistoryService` | Service | SwiftData `TranscriptionRecord` store in Application Support |
| `LoginItemManager` | Manager | `SMAppService.mainApp` |

## Recording state machine

`RecordingViewModel` drives one linear flow:

```
idle ──shortcut──▶ recording ──shortcut──▶ transcribing ──▶ transcript
                                   │                            │
                                   └────────▶ error ◀───────────┘
                                          (Retry re-uploads kept audio)
```

Audio files are deleted after successful transcription (privacy). `Retry` reuses the recorded file, so a network failure never loses a take.

## Project format

A plain, hand-checked-in `OpenDictation.xcodeproj` — **no XcodeGen, no SPM manifest, no build scripts**. The project uses Xcode's folder-synchronized groups (`PBXFileSystemSynchronizedRootGroup`), so new source files added under `OpenDictation/` are picked up automatically and the project file rarely changes. A shared scheme is committed so `xcodebuild -scheme OpenDictation` works headlessly.

## Decisions & tradeoffs

- **Carbon hotkeys over CGEvent tap:** deprecated-adjacent but fully supported, dependency-free, and requires no permissions. A CGEvent tap would need Accessibility before the user has even recorded once.
- **Non-activating NSPanel over SwiftUI window:** SwiftUI cannot create a panel that floats without stealing focus; stealing focus would break "paste into the app you were using."
- **AVAudioRecorder over AVAudioEngine:** we don't need sample-level access in v1; the recorder gives AAC encoding and metering for free with a fraction of the code.
- **SwiftData over Core Data/files:** first-class Swift API, right-sized for a single-entity history store; sets the macOS 14 floor, which we accept.
- **Bring-your-own-key over hosted backend:** privacy promise and zero infrastructure. The tradeoff (users need an API key) is acceptable for the target audience.
