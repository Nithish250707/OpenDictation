import AppKit
import SwiftUI

/// The desktop management window: a sidebar-driven shell around the existing
/// Home, History, Settings, and placeholder sections. The recorder and menu
/// bar agent are unaffected — this is purely the management surface.
///
/// While this window is open the app promotes itself to a regular (Dock-
/// visible) application; on close it returns to the menu-bar-only accessory
/// mode it launches in, preserving the background-agent behavior.
struct DesktopView: View {
    let composition: AppComposition

    var body: some View {
        @Bindable var navigator = composition.navigator

        NavigationSplitView {
            List(selection: $navigator.selection) {
                Section {
                    row(.home)
                    row(.history)
                }
                Section("Coming Soon") {
                    row(.aiProfiles)
                    row(.dictionary)
                }
                Section {
                    row(.settings)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 204, ideal: 224, max: 300)
            .navigationTitle("Open Dictation")
        } detail: {
            detail(for: navigator.selection ?? .home)
                .frame(minWidth: 480)
        }
        .frame(minWidth: 760, minHeight: 480)
        .onAppear(perform: promoteToRegularApp)
        .onDisappear(perform: returnToAccessoryApp)
    }

    private func row(_ section: DesktopSection) -> some View {
        Label(section.title, systemImage: section.symbol)
            .tag(section)
    }

    @ViewBuilder
    private func detail(for section: DesktopSection) -> some View {
        switch section {
        case .home:
            HomeView(composition: composition)
        case .history:
            HistoryView(
                history: composition.dependencies.history,
                pasteboard: composition.dependencies.pasteboard
            )
        case .aiProfiles:
            ComingSoonView(
                icon: "sparkles",
                title: "AI Profiles",
                message: "Tailor tone, formatting, and vocabulary for different apps and contexts. This is on the roadmap."
            )
        case .dictionary:
            ComingSoonView(
                icon: "character.book.closed",
                title: "Dictionary",
                message: "Teach Open Dictation your names, jargon, and spellings so transcripts come out just right."
            )
        case .settings:
            DesktopSettingsView(dependencies: composition.dependencies)
        }
    }

    // MARK: - Activation policy

    private func promoteToRegularApp() {
        NSApp.setActivationPolicy(.regular)
        NSApplication.shared.activate()
    }

    private func returnToAccessoryApp() {
        // Back to the menu-bar-only agent the app launches as.
        NSApp.setActivationPolicy(.accessory)
    }
}
