import SwiftUI

/// Content of the floating recorder panel. Renders whichever step of the
/// dictation state machine is active; the panel window itself is managed by
/// `FloatingPanelManager`.
struct RecordingPopupView: View {
    let viewModel: RecordingViewModel
    let settings: SettingsStore
    let onDismiss: () -> Void

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                starting
            case .recording:
                recording
            case .transcribing:
                transcribing
            case .transcript(let transcript):
                transcriptView(transcript)
            case .failed(let error, let audioFileURL, _):
                failure(error, canRetry: audioFileURL != nil)
            case .permissionDenied:
                permissionDenied
            }
        }
        .padding(24)
        .frame(width: settings.panelSize.width)
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
            Text("Press \(settings.shortcut.display) to stop")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var transcribing: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.regular)
            Text("Transcribing…")
                .font(.headline)
            Text("Usually just a few seconds")
                .font(.caption)
                .foregroundStyle(.secondary)
            // A hung upload must never trap the user in this state.
            Button("Cancel", action: onDismiss)
                .controlSize(.small)
                .padding(.top, 2)
        }
    }

    private func transcriptView(_ transcript: Transcript) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Transcript", systemImage: "text.quote")
                    .font(.headline)
                Spacer()
                Text(RecordingTimerView.format(transcript.duration))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                Text(transcript.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 150)
            .padding(10)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            if viewModel.autoCopied {
                Label("Copied to clipboard", systemImage: "checkmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button {
                    viewModel.copyTranscript()
                } label: {
                    Label(viewModel.justCopied ? "Copied" : "Copy", systemImage: viewModel.justCopied ? "checkmark" : "doc.on.doc")
                }

                Button {
                    viewModel.pasteTranscript()
                } label: {
                    Label(viewModel.justPasted ? "Pasted" : "Paste", systemImage: viewModel.justPasted ? "checkmark" : "arrow.down.doc")
                        .frame(minWidth: 60)
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button("Done", action: onDismiss)
            }

            if let pasteErrorMessage = viewModel.pasteErrorMessage {
                Text(pasteErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.needsAccessibilityPermission {
                accessibilityHelp
            }
        }
    }

    /// Inline guidance shown when Paste needs the Accessibility permission.
    private var accessibilityHelp: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Label("Accessibility Access Needed", systemImage: "hand.raised")
                .font(.subheadline.weight(.semibold))
            Text("To paste for you, Open Dictation needs Accessibility access. Your transcript is already on the clipboard, so you can also just press ⌘V.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button("Open Accessibility Settings") {
                    viewModel.openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)

                Button("Not Now") {
                    viewModel.dismissAccessibilityHelp()
                }
            }
            .controlSize(.small)
        }
    }

    private func failure(_ error: AppError, canRetry: Bool) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.orange)
            // Recording failures land here too, so keep the title generic.
            Text("Something Went Wrong")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Button("Cancel", action: onDismiss)
                if canRetry {
                    Button("Retry") {
                        viewModel.retry()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top, 4)
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
        SystemSettingsDeepLink.open(SystemSettingsDeepLink.microphone)
    }
}
