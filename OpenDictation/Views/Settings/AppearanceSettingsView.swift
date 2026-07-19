import SwiftUI

/// Floating panel preferences with a live preview.
struct AppearanceSettingsView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Form {
            Section("Recorder Panel") {
                Picker(selection: $settings.panelSize) {
                    ForEach(PanelSize.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                } label: {
                    Label("Size", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .pickerStyle(.segmented)

                Picker(selection: $settings.panelAppearance) {
                    ForEach(PanelAppearanceMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.symbolName).tag(mode)
                    }
                } label: {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                }

                LabeledContent {
                    HStack(spacing: 8) {
                        Slider(value: $settings.panelOpacity, in: 0.7...1.0)
                        Text(settings.panelOpacity, format: .percent.precision(.fractionLength(0)))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                } label: {
                    Label("Opacity", systemImage: "circle.dotted")
                }
            }

            Section("Preview") {
                panelPreview
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .formStyle(.grouped)
        .animation(.spring(duration: 0.3), value: settings.panelSize)
        .animation(.default, value: settings.panelAppearance)
    }

    /// A miniature of the real recorder panel, honoring the chosen size,
    /// opacity, and appearance.
    private var panelPreview: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
                Text("Recording…")
                    .font(.subheadline.weight(.semibold))
            }
            Text("00:03")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .monospacedDigit()
            HStack(spacing: 2.5) {
                ForEach(0..<24, id: \.self) { index in
                    Capsule()
                        .fill(.tint)
                        .frame(width: 2.5, height: previewBarHeight(index))
                }
            }
        }
        .padding(16)
        .frame(width: settings.panelSize.width * 0.62)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 1)
        }
        .opacity(settings.panelOpacity)
        .environment(\.colorScheme, previewColorScheme)
    }

    private var previewColorScheme: ColorScheme {
        switch settings.panelAppearance {
        case .system:
            NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua]) == .darkAqua ? .dark : .light
        case .light: .light
        case .dark: .dark
        }
    }

    /// Deterministic pseudo-waveform so the preview looks alive but stable.
    private func previewBarHeight(_ index: Int) -> CGFloat {
        let pattern: [CGFloat] = [6, 10, 16, 22, 14, 18, 24, 12, 8, 15, 20, 10]
        return pattern[index % pattern.count]
    }
}
