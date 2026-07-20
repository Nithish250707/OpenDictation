import Foundation

/// A single entry in the command palette: a navigation destination or action.
struct CommandItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let keywords: [String]
    let perform: () -> Void

    /// Fuzzy-ish substring match against title, subtitle, and keywords.
    func matches(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return true }
        if title.lowercased().contains(trimmed) { return true }
        if subtitle.lowercased().contains(trimmed) { return true }
        return keywords.contains { $0.lowercased().contains(trimmed) }
    }
}
