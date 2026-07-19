# Folder Structure

```
OpenDictation/
├── OpenDictation.xcodeproj/      # Native Xcode project (shared scheme committed)
├── OpenDictation/                # App target sources (folder-synchronized)
│   ├── App/                      # @main entry, AppDelegate, AppDependencies (DI)
│   ├── Views/                    # Screen-level SwiftUI views
│   ├── ViewModels/               # @MainActor state + intent, one per screen
│   ├── Models/                   # Value types & SwiftData models (Transcript, TranscriptionRecord, RecordingState, AppError)
│   ├── Services/                 # Protocol + live implementation pairs (audio, transcription, keychain, pasteboard, history)
│   ├── Managers/                 # System-integration wrappers (hotkey, floating panel, login item)
│   ├── Providers/                # TranscriptionProvider protocol + implementations (OpenAI)
│   ├── Components/               # Small reusable SwiftUI pieces (WaveformView, RecordingTimerView, ActionButton)
│   ├── Utilities/                # Logger, Constants
│   ├── Extensions/               # Small, focused extensions
│   └── Resources/                # Assets.xcassets
├── OpenDictationTests/           # Unit tests (target added in Milestone 9)
└── *.md                          # Documentation (see README)
```

## Responsibilities

- **App/** — composition root. The only place where concrete services are constructed and wired together.
- **Views/** — declarative UI only. No business logic, no service imports.
- **ViewModels/** — everything a view needs to render, plus methods for every user action. Talk to services through protocols.
- **Models/** — plain data. No behavior beyond validation/formatting.
- **Services/** — one capability each, defined by a protocol so it can be mocked.
- **Managers/** — like services, but wrapping stateful system APIs (Carbon, NSPanel, SMAppService).
- **Providers/** — transcription backends. Adding a provider = one new file + a registry entry, no other changes.
- **Components/** — reusable views under ~100 lines with no dependencies on view models.

## Conventions

- One type per file; file name = type name.
- Prefer files under ~300 lines; split before they grow past it.
- New source files under `OpenDictation/` are picked up automatically (folder-synchronized project) — no project file edits needed.
