import Foundation
import Observation

/// Orchestrates a dictation session: the global shortcut and the menu item
/// both funnel into `toggleDictation()`, which drives the recording view
/// model and shows/hides the floating panel around it.
@MainActor
@Observable
final class DictationController {
    private let recordingViewModel: RecordingViewModel
    private let panelManager = FloatingPanelManager()
    private let hotkeyManager = HotkeyManager()

    var isRecording: Bool { recordingViewModel.state.isRecording }

    init(dependencies: AppDependencies) {
        recordingViewModel = RecordingViewModel(audio: dependencies.audio)
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.toggleDictation()
        }
        hotkeyManager.register()
    }

    /// Single entry point for the shortcut and the menu bar item.
    func toggleDictation() {
        switch recordingViewModel.state {
        case .idle:
            beginDictation()
        case .recording:
            endDictation()
        case .stopped, .permissionDenied:
            dismiss()
        }
    }

    func dismiss() {
        panelManager.hide()
        recordingViewModel.reset()
    }

    private func beginDictation() {
        panelManager.show {
            RecordingPopupView(viewModel: recordingViewModel) { [weak self] in
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

    private func endDictation() {
        recordingViewModel.stopRecording()
        Task {
            // Let the confirmation register with the user before fading out.
            try? await Task.sleep(for: .milliseconds(900))
            if case .stopped = recordingViewModel.state {
                dismiss()
            }
        }
    }
}
