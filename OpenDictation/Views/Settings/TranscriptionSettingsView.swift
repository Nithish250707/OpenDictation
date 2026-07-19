import SwiftUI

/// Provider, API key, model, and language.
struct TranscriptionSettingsView: View {
    @Bindable var settings: SettingsStore
    let registry: ProviderRegistry

    @State private var apiKey: APIKeyViewModel

    init(settings: SettingsStore, registry: ProviderRegistry, keyStore: any APIKeyStoring) {
        self.settings = settings
        self.registry = registry
        _apiKey = State(initialValue: APIKeyViewModel(keyStore: keyStore, providerID: settings.providerID))
    }

    private var activeProvider: any TranscriptionProvider {
        registry.provider(id: settings.providerID) ?? registry.default
    }

    var body: some View {
        Form {
            Section {
                Picker(selection: $settings.providerID) {
                    ForEach(registry.all, id: \.id) { provider in
                        Text(provider.displayName).tag(provider.id)
                    }
                } label: {
                    Label("Provider", systemImage: "server.rack")
                }
                .onChange(of: settings.providerID) {
                    settings.model = activeProvider.defaultModel
                    apiKey.providerChanged(to: settings.providerID)
                }
            } footer: {
                Text("More providers — local models included — are on the roadmap. Contributions welcome.")
            }

            Section {
                apiKeySection
            } header: {
                Text("API Key")
            } footer: {
                Text("Stored only in your Mac's Keychain and sent only to \(activeProvider.displayName). Never written to disk or logs.")
            }

            Section {
                Picker(selection: $settings.model) {
                    ForEach(activeProvider.supportedModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                } label: {
                    Label("Model", systemImage: "cpu")
                }
            }

            Section {
                Picker(selection: languageBinding) {
                    ForEach(TranscriptionLanguage.all) { language in
                        Text(language.name).tag(language.id)
                    }
                } label: {
                    Label("Language", systemImage: "globe")
                }
            } footer: {
                Text("Auto-detect works well for most dictation. Picking a language can improve accuracy and speed.")
            }
        }
        .formStyle(.grouped)
        .animation(.default, value: apiKey.isEditing)
        .animation(.default, value: apiKey.hasKey)
    }

    @ViewBuilder
    private var apiKeySection: some View {
        if apiKey.isEditing {
            SecureField("Paste your \(activeProvider.displayName) API key", text: $apiKey.draft)
                .textFieldStyle(.roundedBorder)
                .onSubmit { apiKey.save() }
            HStack {
                Button("Save") { apiKey.save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.draft.isEmpty)
                Button("Cancel") { apiKey.cancelEditing() }
            }
            if let errorMessage = apiKey.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } else if apiKey.hasKey {
            HStack {
                Label {
                    Text("API key saved")
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                Spacer()
                Button("Replace…") { apiKey.beginEditing() }
                Button("Remove", role: .destructive) { apiKey.removeKey() }
            }
            if let errorMessage = apiKey.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } else {
            HStack {
                Label {
                    Text("No API key yet")
                } icon: {
                    Image(systemName: "key")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Add Key…") { apiKey.beginEditing() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var languageBinding: Binding<String> {
        Binding {
            settings.languageCode ?? TranscriptionLanguage.auto.id
        } set: { newID in
            settings.languageCode = newID == TranscriptionLanguage.auto.id ? nil : newID
        }
    }
}
