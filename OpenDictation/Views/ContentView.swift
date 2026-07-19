import SwiftUI

/// Placeholder root view for the Milestone 1 blank application.
/// Replaced by the menu bar UI in Milestone 2.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Open Dictation")
                .font(.title2.weight(.semibold))
            Text("Privacy-first AI dictation for macOS")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(48)
        .frame(minWidth: 360, minHeight: 240)
    }
}

#Preview {
    ContentView()
}
