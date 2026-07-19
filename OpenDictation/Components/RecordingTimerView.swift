import SwiftUI

/// Elapsed-time readout, formatted mm:ss with stable monospaced digits.
struct RecordingTimerView: View {
    let elapsed: TimeInterval

    var body: some View {
        Text(Self.format(elapsed))
            .font(.system(size: 30, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.smooth(duration: 0.2), value: Self.format(elapsed))
    }

    static func format(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    RecordingTimerView(elapsed: 3)
        .padding()
}
