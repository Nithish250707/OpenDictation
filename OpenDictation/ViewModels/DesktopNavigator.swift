import Observation

/// Shared selection state for the desktop window's sidebar, so the menu bar
/// can deep-link into a specific section (e.g. "History…") and the window
/// follows. Optional to match SwiftUI's single-selection `List` binding.
@MainActor
@Observable
final class DesktopNavigator {
    var selection: DesktopSection? = .home
    /// Drives the ⌘K command palette sheet.
    var isCommandPalettePresented = false

    func go(to section: DesktopSection) {
        selection = section
    }

    func toggleCommandPalette() {
        isCommandPalettePresented.toggle()
    }
}
