# Changelog

All notable changes to Open Dictation are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org).

## [Unreleased]

### Added
- Milestone 3 — Recording engine: global ⌥Space shortcut (Carbon, no Accessibility permission needed), floating non-activating recorder panel with fade animations, `AVAudioRecorder` capture to a temporary .m4a with live waveform and drift-free timer, microphone permission flow with System Settings deep link, clean idle → recording → stopped state machine. Recordings are deleted on dismissal until transcription exists.
- Milestone 2 — Menu bar app: `MenuBarExtra` with mic icon, `LSUIElement` (no Dock icon), menu with Start Dictation / Settings… / Quit, Settings window stub.
- Milestone 1 — Project foundation: native Xcode project (zero external tooling), blank SwiftUI app targeting macOS 14+ in Swift 6 mode, shared scheme for headless `xcodebuild`, asset catalog placeholders, full documentation set, MIT license.
