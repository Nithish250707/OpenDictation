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
| `HotkeyManager` | Manager | Global shortcut via Carbon `RegisterEventHotKey` — the only zero-dependency API that needs no Accessibility permission; re-registered live when Settings changes it |
| `FloatingPanelManager` | Manager | Owns the floating popup: a non-activating `NSPanel` + `NSHostingView`, so keyboard focus stays in the target app; applies panel opacity/appearance; generation-guarded hide animations |
| `AVAudioRecordingService` | Service | `AVAudioRecorder` → temp `.m4a` (AAC), metering enabled for the waveform |
| `TranscriptionService` | Service | Resolves provider + model + language from Settings and the API key from the Keychain, then hands off to the provider |
| `TranscriptionProvider` | Protocol | `transcribe(audioFileURL:configuration:) async throws -> Transcript`; OpenAI is one implementation (see [API_DESIGN.md](API_DESIGN.md)) |
| `KeychainService` | Service | API key storage via `SecItem*` — never UserDefaults, never logged |
| `PasteboardService` | Service | Clipboard writes (`NSPasteboard`), reporting success |
| `PasteService` | Service | Permission gate → clipboard → synthesized ⌘V (`CGKeyEventSynthesizer`); typed errors for every failure mode |
| `HistoryService` | Service | SwiftData `TranscriptionRecord` store in Application Support |
| `SettingsStore` | Service | Single source of truth for preferences (`@Observable`, UserDefaults-backed, injectable suite). API keys never live here |
| `ProviderRegistry` | Provider | Catalog of installed providers; Settings, the model picker, and the pipeline all read from it |
| `LoginItemManager` | Manager | `SMAppService.mainApp` behind `LoginItemManaging` |
| `SystemPermissionStatus` | Service | Non-prompting live permission readout (mic + Accessibility) for Settings |
| `SparkleUpdaterManager` | Manager | Auto-updates behind `UpdateManaging`; Sparkle initialized lazily so tests never trigger checks |
| `DesktopNavigator` | ViewModel | Sidebar selection state so the menu bar can deep-link into a desktop section |
| `AppComposition` | App | Builds `AppDependencies` + `DictationController` + `DesktopNavigator` once; shared by all scenes |

## Scenes & windowing

Three scenes, all fed by the single `AppComposition`:

- **`MenuBarExtra`** — the always-present agent; entry point for dictation and for opening the desktop window.
- **`Window` ("Open Dictation")** — the desktop management app: a `NavigationSplitView` (`DesktopView`) with Home / History / AI Profiles / Dictionary / Settings. History and the four Settings section views are reused verbatim from the standalone flows.
- **`Settings`** — the standard ⌘, preferences window (same section views), kept for muscle memory.

The app launches as a menu-bar-only agent (`LSUIElement` → `.accessory`). Opening the desktop window promotes the process to `.regular` (Dock icon, app menu); closing it returns to `.accessory`. This keeps the background-agent launch and the floating recorder unchanged while making the management window feel like a first-class app.

## Dependency policy

Exactly one third-party dependency: **Sparkle** (SPM), because macOS has no native framework for non-App-Store auto-updates. Everything else is Apple frameworks only, and the bar for adding anything further is very high (open an issue first).

## Recording state machine

`RecordingViewModel` drives one linear flow (see `RecordingState`):

```
idle ──shortcut──▶ recording ──shortcut──▶ transcribing ──▶ transcript ──Done──▶ idle
  │                                │            │               ▲
  │                                │         Cancel          Retry│
  └──▶ permissionDenied            └──────▶ failed ───────────────┘
```

Audio files are deleted the moment they have no further purpose (privacy). `Retry` reuses the recorded file, so a network failure never loses a take; a result arriving after the user dismissed the popup is discarded. Double-starts through the async permission gap are guarded at both the view-model and audio-service layers.

## Project format

A plain, hand-checked-in `OpenDictation.xcodeproj` — **no XcodeGen, no SPM manifest, no build scripts**. The project uses Xcode's folder-synchronized groups (`PBXFileSystemSynchronizedRootGroup`), so new source files added under `OpenDictation/` are picked up automatically and the project file rarely changes. A shared scheme is committed so `xcodebuild -scheme OpenDictation` works headlessly.

## Decisions & tradeoffs

- **Carbon hotkeys over CGEvent tap:** deprecated-adjacent but fully supported, dependency-free, and requires no permissions. A CGEvent tap would need Accessibility before the user has even recorded once.
- **Non-activating NSPanel over SwiftUI window:** SwiftUI cannot create a panel that floats without stealing focus; stealing focus would break "paste into the app you were using."
- **AVAudioRecorder over AVAudioEngine:** we don't need sample-level access in v1; the recorder gives AAC encoding and metering for free with a fraction of the code.
- **SwiftData over Core Data/files:** first-class Swift API, right-sized for a single-entity history store; sets the macOS 14 floor, which we accept.
- **Bring-your-own-key over hosted backend:** privacy promise and zero infrastructure. The tradeoff (users need an API key) is acceptable for the target audience.
