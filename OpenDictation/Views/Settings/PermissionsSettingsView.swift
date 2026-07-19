import SwiftUI

/// Live permission status with deep links into System Settings.
struct PermissionsSettingsView: View {
    @State private var viewModel: PermissionsViewModel

    init(status: any PermissionStatusChecking) {
        _viewModel = State(initialValue: PermissionsViewModel(status: status))
    }

    var body: some View {
        Form {
            Section {
                permissionRow(
                    symbol: "mic.fill",
                    title: "Microphone",
                    caption: "Required — captures your dictation.",
                    state: viewModel.microphone,
                    openSettings: viewModel.openMicrophoneSettings
                )
                permissionRow(
                    symbol: "hand.raised.fill",
                    title: "Accessibility",
                    caption: "Optional — lets Open Dictation paste for you.",
                    state: viewModel.accessibilityGranted ? .granted : .denied,
                    openSettings: viewModel.openAccessibilitySettings
                )
            } header: {
                Text("System Permissions")
            } footer: {
                Text("Statuses update live — grant a permission in System Settings and it turns green here immediately.")
            }
        }
        .formStyle(.grouped)
        .animation(.default, value: viewModel.microphone)
        .animation(.default, value: viewModel.accessibilityGranted)
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
    }

    private func permissionRow(
        symbol: String,
        title: String,
        caption: String,
        state: PermissionState,
        openSettings: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge(for: state)

            if state != .granted {
                Button("Open Settings", action: openSettings)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }

    private func statusBadge(for state: PermissionState) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color(for: state))
                .frame(width: 8, height: 8)
            Text(label(for: state))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private func color(for state: PermissionState) -> Color {
        switch state {
        case .granted: .green
        case .denied: .red
        case .notDetermined: .orange
        }
    }

    private func label(for state: PermissionState) -> String {
        switch state {
        case .granted: "Granted"
        case .denied: "Not granted"
        case .notDetermined: "Not requested"
        }
    }
}
