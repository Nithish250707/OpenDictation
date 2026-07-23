import SwiftUI

/// The invisible-recording HUD: a tiny, non-intrusive capsule that shows only
/// the current phase of dictation and then disappears on its own. There is no
/// transcript preview and no buttons — the text lands directly in whatever app
/// the user is focused on. The capsule is driven by `RecordingViewModel`'s
/// state machine; `DictationController` owns showing and auto-hiding it.
struct RecordingHUDView: View {
    let viewModel: RecordingViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(.regularMaterial, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            }
            .fixedSize()
            .animation(.smooth(duration: 0.25), value: phaseKey)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .recording:
            listening
        case .transcribing:
            transcribing
        case .transcript:
            delivered
        case .failed(let error, _, _):
            failure(error)
        case .permissionDenied:
            microphoneNeeded
        case .idle:
            EmptyView()
        }
    }

    /// One key per phase, so the capsule animates on phase changes rather than
    /// on every waveform tick.
    private var phaseKey: String {
        switch viewModel.state {
        case .idle: "idle"
        case .recording: "recording"
        case .transcribing: "transcribing"
        case .transcript: viewModel.accessibilityGranted ? "inserted" : "copied"
        case .failed: "failed"
        case .permissionDenied: "permission"
        }
    }

    // MARK: - Phases

    private var listening: some View {
        HStack(spacing: 9) {
            recordingDot
            Text("Listening")
                .foregroundStyle(.primary)
            HUDMeter(levels: viewModel.levels)
        }
    }

    @ViewBuilder
    private var recordingDot: some View {
        let dot = Circle().fill(.red).frame(width: 8, height: 8)
        if reduceMotion {
            dot
        } else {
            dot.phaseAnimator([1.0, 0.25]) { view, phase in
                view.opacity(phase)
            } animation: { _ in
                .easeInOut(duration: 0.7)
            }
        }
    }

    private var transcribing: some View {
        HStack(spacing: 9) {
            ProgressView()
                .controlSize(.small)
            Text("Transcribing")
                .foregroundStyle(.primary)
        }
    }

    /// The transcript has been delivered. When Accessibility is granted it was
    /// inserted into the focused app; otherwise it's on the clipboard and the
    /// user finishes with ⌘V.
    @ViewBuilder
    private var delivered: some View {
        if viewModel.accessibilityGranted {
            label("checkmark.circle.fill", "Inserted", tint: .green)
        } else {
            label("doc.on.clipboard.fill", "Copied · press ⌘V", tint: .secondary)
        }
    }

    private func failure(_ error: AppError) -> some View {
        label("exclamationmark.triangle.fill", error.hudSummary, tint: .orange)
    }

    private var microphoneNeeded: some View {
        label("mic.slash.fill", "Enable microphone access", tint: .secondary)
    }

    private func label(_ systemImage: String, _ text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(text)
                .foregroundStyle(.primary)
        }
    }
}

/// A compact five-bar level meter for the listening phase — just enough motion
/// to confirm the mic is hearing the user, without the full waveform's bulk.
private struct HUDMeter: View {
    let levels: [Float]

    private static let barCount = 5

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<Self.barCount, id: \.self) { index in
                Capsule()
                    .fill(.secondary)
                    .frame(width: 2.5, height: barHeight(index))
            }
        }
        .frame(height: 14, alignment: .center)
        .animation(.easeOut(duration: 0.12), value: levels)
    }

    /// Sample the tail of the level buffer so the bars ripple with recent audio.
    private func barHeight(_ index: Int) -> CGFloat {
        guard !levels.isEmpty else { return 3 }
        let stride = max(1, levels.count / Self.barCount)
        let sample = levels[min(levels.count - 1, levels.count - 1 - index * stride)]
        return 3 + CGFloat(max(0, min(1, sample))) * 11
    }
}
