import SwiftUI

/// Settings window placeholder.
/// Real preferences (API key, model, shortcut, launch at login) arrive in Milestone 7.
struct SettingsView: View {
    var body: some View {
        Form {
            LabeledContent("Settings") {
                Text("Available in an upcoming milestone.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 140)
    }
}

#Preview {
    SettingsView()
}
