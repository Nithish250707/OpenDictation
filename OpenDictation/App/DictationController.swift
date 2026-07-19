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
            settings: dependencies.settings
        )
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.toggleDictation()
        }
        hotkeyManager.register(shortcut: settings.shortcut)
        observeShortcutChanges()
    }

    /// Single entry point for the shortcut and the menu bar item.
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
        panelManager.hide()
        recordingViewModel.reset()
    }

    private func beginDictation() {
        panelManager.show {
            RecordingPopupView(viewModel: recordingViewModel, settings: settings) { [weak self] in
                self?.dismiss()
            }
        }
        Task {
            await recordingViewModel.startRecording()
            // A failed start falls back to .idle; don't leave an empty panel up.
            if case .idle = recordingViewModel.state {
                panelManager.hide()
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
                guard let self else { return }
                hotkeyManager.register(shortcut: settings.shortcut)
                observeShortcutChanges()
            }
        }
    }
}
