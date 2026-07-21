import SwiftUI

/// Shortcut, behavior toggles, and launch at login.
struct GeneralSettingsView: View {
    @Bindable var settings: SettingsStore
    let loginItems: any LoginItemManaging
    let updater: any UpdateManaging

    @State private var loginItemErrorMessage: String?

    var body: some View {
        Form {
            Section {
                Picker(selection: $settings.shortcut) {
                    ForEach(HotkeyShortcut.presets) { preset in
                        Text(preset.display).tag(preset)
                    }
                } label: {
                    Label("Dictation shortcut", systemImage: "keyboard")
                }
            } footer: {
                Text("Hold \(settings.shortcut.display) anywhere on your Mac to dictate, then release to insert. A quick tap is ignored.")
            }

            Section {
                Toggle(isOn: $settings.autoPaste) {
                    Label("Insert into the active app automatically", systemImage: "text.insert")
                }
                Toggle(isOn: $settings.autoCopy) {
                    Label("Copy transcript to the clipboard", systemImage: "doc.on.doc")
                }
            } header: {
                Text("After Transcription")
            } footer: {
                Text("Inserting text needs Accessibility access — see the Permissions tab. Without it, your transcript is copied so you can paste with ⌘V.")
            }

            Section {
                Toggle(isOn: launchAtLoginBinding) {
                    Label("Launch at login", systemImage: "power")
                }
                if let loginItemErrorMessage {
                    Text(loginItemErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } footer: {
                Text("Open Dictation is lightweight and lives only in your menu bar.")
            }

            Section {
                Toggle(isOn: automaticUpdatesBinding) {
                    Label("Check for updates automatically", systemImage: "arrow.triangle.2.circlepath")
                }
                HStack {
                    Label("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")", systemImage: "app.badge.checkmark")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Check Now") {
                        updater.checkForUpdates()
                    }
                }
            } header: {
                Text("Updates")
            } footer: {
                Text("Updates are delivered from GitHub Releases and verified with EdDSA signatures before installing.")
            }
        }
        .formStyle(.grouped)
        .animation(.default, value: loginItemErrorMessage)
    }

    private var automaticUpdatesBinding: Binding<Bool> {
        Binding {
            updater.automaticallyChecksForUpdates
        } set: { enabled in
            updater.automaticallyChecksForUpdates = enabled
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding {
            loginItems.isEnabled
        } set: { enabled in
            do {
                try loginItems.setEnabled(enabled)
                loginItemErrorMessage = nil
            } catch {
                loginItemErrorMessage = "macOS declined the change. Try again, or manage it in System Settings → General → Login Items."
                Log.app.error("Login item change failed: \(error.localizedDescription)")
            }
        }
    }
}
