import SwiftData
import SwiftUI

/// Welcome dashboard: a hero with a primary action, setup status, current
/// configuration at a glance, recent dictations, and tips.
struct HomeView: View {
    let composition: AppComposition

    @State private var model: HomeViewModel
    @State private var copiedID: PersistentIdentifier?

    init(composition: AppComposition) {
        self.composition = composition
        let dependencies = composition.dependencies
        _model = State(initialValue: HomeViewModel(
            history: dependencies.history,
            keyStore: dependencies.keyStore,
            settings: dependencies.settings,
            permissionStatus: dependencies.permissionStatus,
            registry: dependencies.registry,
            loginItems: dependencies.loginItems
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                hero

                if !model.isFullyConfigured {
                    onboardingCard
                }

                section("Overview") { statusTiles }
                section("Recent Dictations", trailing: recentTrailing) { recentContent }
                section("Tips") { tipsContent }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Home")
        .onAppear { model.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refresh()
        }
    }

    // MARK: - Hero

    private var hero: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.largeTitle.weight(.bold))
                Text("Press \(model.shortcutDisplay) anywhere to dictate.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button {
                composition.controller.toggleDictation()
            } label: {
                Label("Start Dictation", systemImage: "mic.fill")
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
            }
            .controlSize(.extraLarge)
            .buttonStyle(.borderedProminent)
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default: "Welcome back"
        }
    }

    // MARK: - Section scaffold

    private func section<Content: View>(
        _ title: String,
        trailing: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .kerning(0.5)
                Spacer()
                trailing
            }
            content()
        }
    }

    // MARK: - Onboarding

    private var onboardingCard: some View {
        DashboardCard("Finish Setting Up") {
            VStack(alignment: .leading, spacing: 10) {
                onboardingStep(
                    done: model.hasAPIKey,
                    title: "Add your API key",
                    detail: "Required to transcribe. Stored only in your Keychain.",
                    actionTitle: "Open Settings"
                ) {
                    composition.navigator.go(to: .settings)
                }
                Divider()
                onboardingStep(
                    done: model.microphoneGranted,
                    title: "Grant microphone access",
                    detail: "Needed to capture your voice while dictating.",
                    actionTitle: "Open System Settings"
                ) {
                    SystemSettingsDeepLink.open(SystemSettingsDeepLink.microphone)
                }
            }
        }
    }

    private func onboardingStep(
        done: Bool,
        title: String,
        detail: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(done ? .green : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.medium))
                    .strikethrough(done, color: .secondary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !done {
                Button(actionTitle, action: action)
                    .controlSize(.small)
            }
        }
    }

    // MARK: - Status tiles

    private var statusTiles: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 12)], spacing: 12) {
            StatTile(icon: "server.rack", label: "Provider", value: model.providerName)
            StatTile(icon: "globe", label: "Language", value: model.languageName)
            StatTile(
                icon: model.launchAtLogin ? "power" : "power.dotted",
                label: "Launch at login",
                value: model.launchAtLogin ? "On" : "Off",
                tint: model.launchAtLogin ? .green : .secondary
            )
        }
    }

    // MARK: - Recent dictations

    private var recentTrailing: AnyView? {
        guard !model.recentRecords.isEmpty else { return nil }
        return AnyView(
            Button("View All") { composition.navigator.go(to: .history) }
                .buttonStyle(.link)
        )
    }

    @ViewBuilder
    private var recentContent: some View {
        if model.recentRecords.isEmpty {
            DashboardCard {
                HStack(spacing: 10) {
                    Image(systemName: "waveform").foregroundStyle(.secondary)
                    Text("Your dictations will appear here after your first transcription.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(model.recentRecords) { record in
                    recentCard(record)
                }
            }
        }
    }

    private func recentCard(_ record: TranscriptionRecord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(record.text)
                    .lineLimit(2)
                    .font(.callout)
                Text(record.createdAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button {
                composition.dependencies.pasteboard.copy(record.text)
                withAnimation { copiedID = record.persistentModelID }
                Task {
                    try? await Task.sleep(for: .milliseconds(1_200))
                    withAnimation { copiedID = nil }
                }
            } label: {
                Image(systemName: copiedID == record.persistentModelID ? "checkmark" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)
            .help("Copy transcript")
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(.separator.opacity(0.4), lineWidth: 1)
        }
    }

    // MARK: - Tips

    private var tipsContent: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 8) {
                tip("command", "Press ⌘K for the command palette — jump anywhere or run an action.")
                tip("keyboard", "Press \(model.shortcutDisplay) from any app to dictate; the recorder floats above your work.")
                tip("lock.shield", "Everything stays on your Mac. Audio goes straight to your provider and is deleted after.")
            }
        }
    }

    private func tip(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 20)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
