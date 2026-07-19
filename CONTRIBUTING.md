# Contributing

Thanks for helping build the best open-source dictation app for macOS! 🎙

## Getting started

1. Install Xcode 16 or later.
2. Clone the repo and open `OpenDictation.xcodeproj`.
3. Press ⌘R. That's it — there are intentionally **no** package managers, generators, or scripts to install.

Headless build & test:

```sh
xcodebuild -project OpenDictation.xcodeproj -scheme OpenDictation build
xcodebuild -project OpenDictation.xcodeproj -scheme OpenDictation test
```

## Before you code

- Read [ARCHITECTURE.md](ARCHITECTURE.md) and [CODING_GUIDELINES.md](CODING_GUIDELINES.md).
- Check [TASKS.md](TASKS.md) and open issues so work isn't duplicated.
- For anything non-trivial, open an issue first to discuss the approach.

## Workflow

1. Fork, then branch from `main`: `feature/short-description` or `fix/short-description`.
2. Keep PRs focused — one logical change per PR.
3. Make sure the project builds with **zero warnings** and all tests pass — CI runs both on every PR.
4. Add or update tests for behavior you change.
5. Update documentation if your change affects it.
6. Open a PR with a clear description of *what* and *why*.

## Commit messages

```
<type>: <imperative summary ≤ 72 chars>

Optional body explaining why, not what.
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`.

## Ground rules

- Native only — Sparkle (auto-updates) is the single sanctioned dependency; anything further needs prior discussion in an issue, and the bar is very high.
- Privacy is non-negotiable: nothing that logs, stores, or transmits user content beyond the configured provider call.
- v1 scope is frozen (see [PROJECT_SPEC.md](PROJECT_SPEC.md)); feature ideas go to [ROADMAP.md](ROADMAP.md) discussions, not PRs.

## Code of conduct

Be kind, be constructive, assume good intent.
