import Foundation
import Observation

/// Orchestrates a dictation session: the global shortcut and the menu item
/// both funnel into `toggleDictation()`, which drives the recording view
/// model and shows/hides the floating panel around it.
@MainActor
@Observable
final class DictationController {
    private let recordingViewModel: RecordingViewModel
    private let settings: SettingsStore
    private let panelManager: FloatingPanelManager
    private let hotkeyManager = HotkeyManager()
    private let modifierMonitor = ModifierKeyMonitor()

    /// What to do with a recording when the shortcut is released.
    private enum ReleaseAction { case transcribe, discard }

    /// A hold shorter than this counts as an accidental tap and is discarded,
    /// so brushing the shortcut never fires a stray transcription.
    private static let minimumHold: TimeInterval = 0.1

    /// When the shortcut went down; nil when no hold is in progress.
    private var holdStartedAt: Date?
    /// Set when the key is released before the recorder finished spinning up
    /// (behind the mic-permission await), so the release is honored the moment
    /// recording actually begins.
    private var pendingRelease: ReleaseAction?
    /// Hides the HUD after a terminal outcome so the user never has to dismiss
    /// it — the essence of the invisible-recording experience.
    private var autoDismissTask: Task<Void, Never>?

    var isRecording: Bool { recordingViewModel.state.isRecording }

    init(dependencies: AppDependencies) {
        settings = dependencies.settings
        panelManager = FloatingPanelManager(settings: dependencies.settings)
        recordingViewModel = RecordingViewModel(
            audio: dependencies.audio,
            transcription: dependencies.transcription,
            pasteboard: dependencies.pasteboard,
            paste: dependencies.paste,
            accessibility: dependencies.accessibility,
            settings: dependencies.settings,
            history: dependencies.history
        )
        // Hold-to-talk: the key going down starts recording, releasing it stops.
        // Both mechanisms — the Carbon hot key and the modifier-key monitor —
        // funnel into the same press/release handlers.
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.handleHotkeyDown()
        }
        hotkeyManager.onHotkeyReleased = { [weak self] in
            self?.handleHotkeyUp()
        }
        modifierMonitor.onPressed = { [weak self] in
            self?.handleHotkeyDown()
        }
        modifierMonitor.onReleased = { [weak self] in
            self?.handleHotkeyUp()
        }
        applyShortcut(settings.shortcut)
        observeShortcutChanges()
        observeStateForHUD()
    }

    /// Routes the current shortcut to the right mechanism: a lone modifier is
    /// watched via the flags-change monitor (needs Accessibility); anything
    /// else registers as a Carbon hot key. Only one is ever active.
    private func applyShortcut(_ shortcut: HotkeyShortcut) {
        if shortcut.isModifierKey, let mask = HotkeyShortcut.modifierKeyMask(for: shortcut.keyCode) {
            hotkeyManager.unregister()
            modifierMonitor.start(keyCode: shortcut.keyCode, mask: mask)
        } else {
            modifierMonitor.stop()
            hotkeyManager.register(shortcut: shortcut)
        }
    }

    // MARK: - Hold-to-talk

    /// Shortcut pressed: begin recording immediately so the user's first word
    /// is never clipped.
    private func handleHotkeyDown() {
        switch recordingViewModel.state {
        case .recording, .transcribing:
            // Key auto-repeat or an overlapping press; a hold is already active.
            return
        case .transcript, .failed, .permissionDenied:
            // Clear a finished session's HUD before starting a fresh one.
            dismiss()
        case .idle:
            break
        }
        pendingRelease = nil
        holdStartedAt = .now
        beginDictation()
    }

    /// Shortcut released: transcribe what was captured, unless the hold was too
    /// brief to be intentional (then discard it).
    private func handleHotkeyUp() {
        guard let startedAt = holdStartedAt else { return }
        holdStartedAt = nil
        let held = Date.now.timeIntervalSince(startedAt)
        let action: ReleaseAction = held < Self.minimumHold ? .discard : .transcribe
        switch recordingViewModel.state {
        case .recording:
            apply(action)
        case .idle:
            // The recorder is still starting behind the permission await; run
            // the release once startRecording() returns.
            pendingRelease = action
        default:
            break
        }
    }

    private func apply(_ action: ReleaseAction) {
        switch action {
        case .transcribe: recordingViewModel.stopAndTranscribe()
        case .discard: cancelDictation()
        }
    }

    private func cancelDictation() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        recordingViewModel.cancelRecording()
        panelManager.hide()
    }

    // MARK: - HUD self-dismissal

    /// Watches the recording state so the HUD hides itself once a session
    /// reaches a terminal outcome — the whole flow needs no clicks. Active
    /// phases cancel any pending dismissal; terminal phases schedule one.
    private func observeStateForHUD() {
        withObservationTracking {
            _ = recordingViewModel.state
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.hudStateChanged()
                self.observeStateForHUD()
            }
        }
    }

    private func hudStateChanged() {
        switch recordingViewModel.state {
        case .idle, .recording, .transcribing:
            autoDismissTask?.cancel()
            autoDismissTask = nil
        case .transcript:
            // Inserted transcripts vanish quickly; a copy-only result lingers
            // long enough for the user to notice and press ⌘V.
            scheduleAutoDismiss(after: recordingViewModel.accessibilityGranted ? .milliseconds(700) : .seconds(3))
        case .failed, .permissionDenied:
            // Give the user time to read the reason before it disappears.
            scheduleAutoDismiss(after: .seconds(4))
        }
    }

    private func scheduleAutoDismiss(after delay: Duration) {
        autoDismissTask?.cancel()
        autoDismissTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard let self, !Task.isCancelled else { return }
            self.dismiss()
        }
    }

    /// Single entry point for the menu bar item (a click can't hold).
    func toggleDictation() {
        switch recordingViewModel.state {
        case .idle:
            beginDictation()
        case .recording:
            recordingViewModel.stopAndTranscribe()
        case .transcribing:
            // An upload is in flight; the popup resolves it momentarily.
            break
        case .transcript, .failed, .permissionDenied:
            dismiss()
        }
    }

    func dismiss() {
        holdStartedAt = nil
        pendingRelease = nil
        autoDismissTask?.cancel()
        autoDismissTask = nil
        panelManager.hide()
        recordingViewModel.reset()
    }

    private func beginDictation() {
        panelManager.show {
            RecordingHUDView(viewModel: recordingViewModel)
        }
        Task {
            await recordingViewModel.startRecording()
            guard recordingViewModel.state.isRecording else {
                // A failed start falls back to .idle; don't leave an empty
                // panel up. Permission/error states keep their own HUD.
                pendingRelease = nil
                if case .idle = recordingViewModel.state {
                    panelManager.hide()
                }
                return
            }
            // The key may have been released during the permission await —
            // honor that release now that recording is actually running.
            if let action = pendingRelease {
                pendingRelease = nil
                apply(action)
            }
        }
    }

    /// Re-registers the hot key whenever the user picks a new shortcut in
    /// Settings — no relaunch required.
    private func observeShortcutChanges() {
        withObservationTracking {
            _ = settings.shortcut
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                // Explicit self: older Swift 6 compilers (CI's Xcode 16.x)
                // require it through this nested escaping closure.
                guard let self else { return }
                self.applyShortcut(self.settings.shortcut)
                self.observeShortcutChanges()
            }
        }
    }
}
