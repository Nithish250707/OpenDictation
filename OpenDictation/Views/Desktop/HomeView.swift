import SwiftData
import SwiftUI

/// Welcome dashboard: setup status, current configuration at a glance, quick
/// actions, and recent dictations.
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
            VStack(alignment: .leading, spacing: 22) {
                header

                if !model.isFullyConfigured {
                    onboardingCard
                }

                statusTiles
                quickActions
                recentSection
                tipsCard
            }
            .padding(28)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Home")
        .onAppear { model.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refresh()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.largeTitle.weight(.bold))
            Text("Press \(model.shortcutDisplay) anywhere to start dictating.")
                .font(.title3)
                .foregroundStyle(.secondary)
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

    // MARK: - Quick actions

    private var quickActions: some View {
        DashboardCard("Quick Actions") {
            HStack(spacing: 10) {
                Button {
                    composition.controller.toggleDictation()
                } label: {
                    Label("Start Dictation", systemImage: "mic.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    composition.navigator.go(to: .settings)
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }

                Button {
                    composition.dependencies.updater.checkForUpdates()
                } label: {
                    Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Recent dictations

    private var recentSection: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Dictations")
                        .font(.headline)
                    Spacer()
                    if !model.recentRecords.isEmpty {
                        Button("View All") {
                            composition.navigator.go(to: .history)
                        }
                        .buttonStyle(.link)
                    }
                }

                if model.recentRecords.isEmpty {
                    emptyRecent
                } else {
                    ForEach(Array(model.recentRecords.enumerated()), id: \.element.persistentModelID) { index, record in
                        recentRow(record)
                        if index < model.recentRecords.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var emptyRecent: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .foregroundStyle(.secondary)
            Text("Your dictations will appear here after your first transcription.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private func recentRow(_ record: TranscriptionRecord) -> some View {
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
        .padding(.vertical, 4)
    }

    // MARK: - Tips

    private var tipsCard: some View {
        DashboardCard("Tips") {
            VStack(alignment: .leading, spacing: 8) {
                tip("keyboard", "Press \(model.shortcutDisplay) from any app to dictate — the recorder floats above your work.")
                tip("lock.shield", "Everything stays on your Mac. Audio goes straight to your provider and is deleted after.")
                tip("arrow.triangle.2.circlepath", "Keep up to date from the menu bar or Settings → General.")
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
