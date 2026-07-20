import Observation

/// Filtering and keyboard-navigation state for the command palette. Pure
/// logic, no SwiftUI — the actions themselves are opaque closures supplied by
/// the view, so this stays testable.
@MainActor
@Observable
final class CommandPaletteModel {
    let items: [CommandItem]
    var selectedIndex = 0

    var query = "" {
        didSet { clampSelection() }
    }

    init(items: [CommandItem]) {
        self.items = items
    }

    var filtered: [CommandItem] {
        items.filter { $0.matches(query) }
    }

    var selectedItem: CommandItem? {
        let results = filtered
        guard results.indices.contains(selectedIndex) else { return nil }
        return results[selectedIndex]
    }

    func moveDown() {
        let count = filtered.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + 1) % count
    }

    func moveUp() {
        let count = filtered.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex - 1 + count) % count
    }

    func executeSelected() {
        selectedItem?.perform()
    }

    private func clampSelection() {
        let count = filtered.count
        selectedIndex = count == 0 ? 0 : min(max(0, selectedIndex), count - 1)
    }
}
