import SwiftUI

/// Live input-level bars. Purely presentational: levels arrive normalized
/// (0…1) from the view model at metering cadence, already peak-smoothed.
struct WaveformView: View {
    let levels: [Float]

    private let barWidth: CGFloat = 3.5
    private let barSpacing: CGFloat = 2.5
    private let minBarHeight: CGFloat = 4
    private let maxBarHeight: CGFloat = 34

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(levels.indices, id: \.self) { index in
                Capsule()
                    .fill(barGradient)
                    .frame(width: barWidth, height: height(for: levels[index]))
            }
        }
        .frame(height: maxBarHeight)
        .animation(.smooth(duration: 0.12), value: levels)
        .accessibilityHidden(true)
    }

    private var barGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor, Color.accentColor.opacity(0.45)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func height(for level: Float) -> CGFloat {
        minBarHeight + (maxBarHeight - minBarHeight) * CGFloat(level)
    }
}

#Preview {
    WaveformView(levels: (0..<36).map { _ in Float.random(in: 0...1) })
        .padding()
}
