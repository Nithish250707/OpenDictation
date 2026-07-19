import SwiftUI

/// Shell of the Settings window: native tabbed layout in the System
/// Settings idiom, one focused view per tab.
struct SettingsView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            GeneralSettingsView(
                settings: dependencies.settings,
                loginItems: dependencies.loginItems,
                updater: dependencies.updater
            )
            .tabItem { Label("General", systemImage: "slider.horizontal.3") }

            TranscriptionSettingsView(
                settings: dependencies.settings,
                registry: dependencies.registry,
                keyStore: dependencies.keyStore
            )
            .tabItem { Label("Transcription", systemImage: "waveform") }

            AppearanceSettingsView(settings: dependencies.settings)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }

            PermissionsSettingsView(status: dependencies.permissionStatus)
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
        }
        .frame(width: 560)
    }
}
