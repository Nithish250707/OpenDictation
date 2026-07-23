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
                LabeledContent {
                    HStack(spacing: 8) {
                        ShortcutRecorder(shortcut: $settings.shortcut)
                        Menu {
                            ForEach(HotkeyShortcut.presets) { preset in
                                Button(preset.display) { settings.shortcut = preset }
                            }
                            Section("Hold a modifier (push-to-talk)") {
                                if let rightOption = HotkeyShortcut.modifierKey(keyCode: 61) {
                                    Button(rightOption.display) { settings.shortcut = rightOption }
                                }
                                if let globe = HotkeyShortcut.modifierKey(keyCode: 63) {
                                    Button(globe.display) { settings.shortcut = globe }
                                }
                            }
                            Divider()
                            Button("Restore Default (⌥ Space)") { settings.shortcut = .optionSpace }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .help("Quick picks and restore default")
                    }
                } label: {
                    Label("Dictation shortcut", systemImage: "keyboard")
                }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Click the shortcut, then press what you like — a single key, a function key, modifiers plus a key, or a lone modifier held on its own (fn, Right ⌥…). Hold it anywhere on your Mac to dictate, then release to insert; a quick tap is ignored.")
                    if settings.shortcut.capturesABareTypingKey {
                        Label("\(settings.shortcut.display) has no modifiers, so it's captured system-wide — you won't be able to type it normally. A function key, a lone modifier, or a combo is safer.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    if settings.shortcut.isModifierKey {
                        Label("A lone modifier trigger (\(settings.shortcut.display)) needs Accessibility access to be detected — grant it in the Permissions tab.", systemImage: "lock.shield")
                            .foregroundStyle(.secondary)
                    }
                }
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
