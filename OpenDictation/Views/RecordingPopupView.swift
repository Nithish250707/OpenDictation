import SwiftUI

/// Content of the floating recorder capsule. Renders whichever step of the
/// dictation state machine is active; the panel window itself is managed by
/// `FloatingPanelManager`.
struct RecordingPopupView: View {
    let viewModel: RecordingViewModel
    let settings: SettingsStore
    let onDismiss: () -> Void

    @Environment(\.openSettings) private var openSettings

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
        .id(stateKey)
        .transition(.blurReplace)
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(width: settings.panelSize.width)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.28), .white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .animation(.smooth(duration: 0.3), value: stateKey)
        .animation(.smooth(duration: 0.25), value: viewModel.shouldShowAccessibilityHelp)
        .animation(.smooth(duration: 0.2), value: viewModel.accessibilityGranted)
        // Re-read AXIsProcessTrusted() when the popup appears and whenever the
        // app becomes active (e.g. returning from System Settings), so the
        // banner and Paste button reflect the live permission.
        .onAppear { viewModel.refreshAccessibilityPermission() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.refreshAccessibilityPermission()
        }
    }

    /// One key per state case so transitions fire on state *changes*, not on
    /// every associated-value tick.
    private var stateKey: String {
        switch viewModel.state {
        case .idle: "idle"
        case .recording: "recording"
        case .transcribing: "transcribing"
        case .transcript: "transcript"
        case .failed: "failed"
        case .permissionDenied: "permissionDenied"
        }
    }

    /// Shown for the instant between the shortcut press and the microphone
    /// permission resolving / the recorder spinning up.
    private var starting: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Starting…")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var recording: some View {
        VStack(spacing: 14) {
            HStack(spacing: 7) {
                Circle()
                    .fill(.red)
                    .frame(width: 7, height: 7)
                    .phaseAnimator([1.0, 0.25]) { dot, phase in
                        dot.opacity(phase)
                    } animation: { _ in
                        .easeInOut(duration: 0.7)
                    }
                Text("Recording")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            RecordingTimerView(elapsed: viewModel.elapsed)
            WaveformView(levels: viewModel.levels)
            Text("\(settings.shortcut.display) to stop")
                .font(.caption2)
                .foregroundStyle(.tertiary)
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
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

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
                        .contentTransition(.symbolEffect(.replace))
                }

                Button {
                    viewModel.pasteTranscript()
                } label: {
                    Label(viewModel.justPasted ? "Pasted" : "Paste", systemImage: viewModel.justPasted ? "checkmark" : "arrow.down.doc")
                        .contentTransition(.symbolEffect(.replace))
                        .frame(minWidth: 60)
                }
                .buttonStyle(.borderedProminent)
                // Enabled only when AXIsProcessTrusted() is true.
                .disabled(!viewModel.accessibilityGranted)
                .help(viewModel.accessibilityGranted
                      ? "Paste into the app you were using"
                      : "Grant Accessibility access to enable pasting")

                Spacer()

                Button("Done", action: onDismiss)
            }

            if let pasteErrorMessage = viewModel.pasteErrorMessage {
                Text(pasteErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.shouldShowAccessibilityHelp {
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
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    @ViewBuilder
    private func failure(_ error: AppError, canRetry: Bool) -> some View {
        if error == .missingAPIKey {
            // First-run onboarding: route straight to the fix.
            PopupStatusView(
                systemImage: "key.fill",
                iconColor: .accentColor,
                title: "Add Your API Key",
                message: "Open Dictation needs your OpenAI API key to transcribe. It's stored only in your Mac's Keychain."
            ) {
                Button("Cancel", action: onDismiss)
                Button("Open Settings…") {
                    openSettings()
                    NSApplication.shared.activate()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            PopupStatusView(
                systemImage: "exclamationmark.triangle.fill",
                iconColor: .orange,
                // Recording failures land here too, so keep the title generic.
                title: "Something Went Wrong",
                message: error.localizedDescription
            ) {
                Button("Cancel", action: onDismiss)
                if canRetry {
                    Button("Retry") {
                        viewModel.retry()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var permissionDenied: some View {
        PopupStatusView(
            systemImage: "mic.slash.fill",
            iconColor: .secondary,
            title: "Microphone Access Needed",
            message: "Allow Open Dictation to use the microphone in System Settings, then try again."
        ) {
            Button("Cancel", action: onDismiss)
            Button("Open System Settings") {
                SystemSettingsDeepLink.open(SystemSettingsDeepLink.microphone)
                onDismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
    }
}
