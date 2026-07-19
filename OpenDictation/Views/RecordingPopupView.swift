import SwiftUI

/// Content of the floating recorder panel. Renders whichever step of the
/// recording state machine is active; the panel window itself is managed by
/// `FloatingPanelManager`.
struct RecordingPopupView: View {
    let viewModel: RecordingViewModel
    let onDismiss: () -> Void

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                starting
            case .recording:
                recording
            case .stopped(_, let duration):
                stopped(duration: duration)
            case .permissionDenied:
                permissionDenied
            }
        }
        .padding(24)
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 1)
        }
        .animation(.spring(duration: 0.3), value: viewModel.state)
    }

    /// Shown for the instant between the shortcut press and the microphone
    /// permission resolving / the recorder spinning up.
    private var starting: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Starting…")
                .font(.headline)
        }
    }

    private var recording: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse)
                Text("Recording…")
                    .font(.headline)
            }
            RecordingTimerView(elapsed: viewModel.elapsed)
            WaveformView(levels: viewModel.levels)
            Text("Press ⌥ Space to stop")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func stopped(duration: TimeInterval) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.green)
            Text("Recording complete")
                .font(.headline)
            Text(RecordingTimerView.format(duration))
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private var permissionDenied: some View {
        VStack(spacing: 10) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text("Microphone Access Needed")
                .font(.headline)
            Text("Allow Open Dictation to use the microphone in System Settings, then try again.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                Button("Cancel", action: onDismiss)
                Button("Open System Settings") {
                    openMicrophonePrivacySettings()
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .controlSize(.small)
            .padding(.top, 4)
        }
    }

    private func openMicrophonePrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

#Preview("Recording") {
    RecordingPopupView(viewModel: RecordingViewModel(audio: AVAudioRecordingService()), onDismiss: {})
        .padding()
}
