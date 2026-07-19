# Project Specification

## Mission

Create the best free and open-source AI dictation application for macOS. Users dictate naturally anywhere on macOS and receive beautifully formatted text within seconds, in software that feels like a native Apple application.

## Target users

Developers, students, founders, researchers, writers, knowledge workers — anyone who types frequently.

## Product principles

1. **Native.** SwiftUI/AppKit only. No Electron, React, Node, Python, Flutter, Tauri, or WebViews.
2. **Fast.** Instant launch, lightweight footprint, transcript in a few seconds.
3. **Private.** Audio goes directly to the user's configured provider. Keys live in the Keychain. Recordings are deleted after transcription. No telemetry.
4. **Simple.** When in doubt, choose simplicity over cleverness. Quality over feature count.

## Core user flow

1. User presses the global shortcut.
2. A small floating popup appears; recording starts immediately.
3. Waveform animates; timer counts up.
4. User presses the shortcut again; recording stops.
5. Audio uploads to the transcription provider.
6. The transcript appears in the popup with **Copy**, **Paste**, **Retry**, and **Done** actions.
7. The transcription is saved to history automatically.

Everything happens in a few seconds.

## MVP feature list (v1 — nothing else)

- Menu bar application (no Dock icon)
- Global keyboard shortcut
- Floating recording popup
- Audio recording with timer and simple waveform visualization
- Transcription via the OpenAI transcription API
- Transcript screen with copy / paste-into-focused-app / retry / done
- Settings (API key, model, shortcut, launch at login)
- Secure API key storage (Apple Keychain)
- Transcription history
- Launch at login
- Light mode and dark mode

## Explicit non-goals for v1

- Streaming/real-time transcription
- Local/offline models
- Voice commands, formatting commands, or AI post-processing
- Multiple simultaneous providers, teams, sync, accounts
- Windows/Linux/iOS

## Success criteria

- Cold launch to usable in under a second on Apple Silicon
- Shortcut-to-transcript round trip limited only by network + provider latency
- Zero compiler warnings; unit-tested services and view models
- A contributor can clone, open `OpenDictation.xcodeproj`, and build with no extra tools
