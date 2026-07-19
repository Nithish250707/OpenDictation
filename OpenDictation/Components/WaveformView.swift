import SwiftUI

/// Live input-level bars. Purely presentational: levels arrive normalized
/// (0…1) from the view model at metering cadence.
struct WaveformView: View {
    let levels: [Float]

    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 3
    private let minBarHeight: CGFloat = 3
    private let maxBarHeight: CGFloat = 34

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(levels.indices, id: \.self) { index in
                Capsule()
                    .fill(.tint)
                    .frame(width: barWidth, height: height(for: levels[index]))
            }
        }
        .frame(height: maxBarHeight)
        .animation(.linear(duration: 0.05), value: levels)
        .accessibilityHidden(true)
    }

    private func height(for level: Float) -> CGFloat {
        minBarHeight + (maxBarHeight - minBarHeight) * CGFloat(level)
    }
}

#Preview {
    WaveformView(levels: (0..<36).map { _ in Float.random(in: 0...1) })
        .padding()
}
