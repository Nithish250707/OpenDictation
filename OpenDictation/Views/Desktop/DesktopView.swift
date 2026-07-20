import AppKit
import SwiftUI

/// The desktop management window: a sidebar-driven shell around Home, History,
/// AI Profiles, Dictionary, and Settings. The recorder and menu bar agent are
/// unaffected — this is purely the management surface.
///
/// While this window is open the app promotes itself to a regular (Dock-
/// visible) application; on close it returns to the menu-bar-only accessory
/// mode it launches in, preserving the background-agent behavior.
struct DesktopView: View {
    let composition: AppComposition
    let windowCoordinator: WindowCoordinator

    var body: some View {
        @Bindable var navigator = composition.navigator

        NavigationSplitView {
            SidebarView(composition: composition)
                .navigationSplitViewColumnWidth(min: 214, ideal: 240, max: 320)
        } detail: {
            detail(for: navigator.selection ?? .home)
                .frame(minWidth: 480)
        }
        .frame(minWidth: 820, minHeight: 520)
        .background(WindowConfigurator(autosaveName: "OpenDictationMainWindow"))
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApplication.shared.activate()
            windowCoordinator.startDictation = { [weak composition] in
                composition?.controller.toggleDictation()
            }
        }
        .onDisappear {
            // Back to the menu-bar-only agent the app launches as.
            NSApp.setActivationPolicy(.accessory)
        }
        .onChange(of: navigator.selection) { _, newValue in
            composition.dependencies.settings.lastDesktopSection = newValue?.rawValue ?? "home"
        }
        .sheet(isPresented: $navigator.isCommandPalettePresented) {
            CommandPaletteView(composition: composition, isPresented: $navigator.isCommandPalettePresented)
        }
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
            AIProfilesView()
        case .dictionary:
            DictionaryView()
        case .settings:
            DesktopSettingsView(dependencies: composition.dependencies)
        }
    }
}
