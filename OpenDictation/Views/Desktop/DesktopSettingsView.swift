import SwiftUI

/// Settings integrated into the desktop window. Reuses the exact same section
/// views as the standard `Settings` scene, organized under a segmented picker
/// instead of a tab bar so it reads cleanly next to the sidebar.
struct DesktopSettingsView: View {
    let dependencies: AppDependencies

    @State private var tab: Tab = .general

    enum Tab: String, CaseIterable, Identifiable {
        case general, transcription, appearance, permissions
        var id: String { rawValue }
        var title: String {
            switch self {
            case .general: "General"
            case .transcription: "Transcription"
            case .appearance: "Appearance"
            case .permissions: "Permissions"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Settings section", selection: $tab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(12)

            Divider()

            content
                .transition(.opacity)
        }
        .animation(.smooth(duration: 0.2), value: tab)
        .navigationTitle("Settings")
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .general:
            GeneralSettingsView(
                settings: dependencies.settings,
                loginItems: dependencies.loginItems,
                updater: dependencies.updater
            )
        case .transcription:
            TranscriptionSettingsView(
                settings: dependencies.settings,
                registry: dependencies.registry,
                keyStore: dependencies.keyStore
            )
        case .appearance:
            AppearanceSettingsView(settings: dependencies.settings)
        case .permissions:
            PermissionsSettingsView(status: dependencies.permissionStatus)
        }
    }
}
