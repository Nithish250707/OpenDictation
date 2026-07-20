import Foundation
import Observation
import SwiftData

/// State and intent for the History screen: querying, filtering, grouping,
/// copying, and deleting saved dictations.
@MainActor
@Observable
final class HistoryViewModel {
    /// Time-range filter applied on top of the text search.
    enum Filter: String, CaseIterable, Identifiable {
        case all, today, week

        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: "All"
            case .today: "Today"
            case .week: "This Week"
            }
        }

        func includes(_ date: Date, now: Date = .now) -> Bool {
            switch self {
            case .all:
                return true
            case .today:
                return Calendar.current.isDateInToday(date)
            case .week:
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
                return date >= weekAgo
            }
        }
    }

    /// A date-labeled group of records for sectioned display.
    struct Group: Identifiable {
        let id: String
        let title: String
        let records: [TranscriptionRecord]
    }

    private(set) var records: [TranscriptionRecord] = []
    private(set) var errorMessage: String?
    /// Row whose Copy button was just clicked, for transient feedback.
    private(set) var justCopiedID: PersistentIdentifier?

    var searchText = "" {
        didSet { refresh() }
    }

    var filter: Filter = .all {
        didSet { refresh() }
    }

    private let history: any HistoryStoring
    private let pasteboard: any PasteboardServicing

    init(history: any HistoryStoring, pasteboard: any PasteboardServicing) {
        self.history = history
        self.pasteboard = pasteboard
    }

    var isFiltering: Bool { !searchText.isEmpty || filter != .all }

    /// Records grouped by recency (Today / Yesterday / Previous 7 Days / Earlier),
    /// preserving the newest-first order within each group.
    var groups: [Group] {
        let calendar = Calendar.current
        var today: [TranscriptionRecord] = []
        var yesterday: [TranscriptionRecord] = []
        var week: [TranscriptionRecord] = []
        var earlier: [TranscriptionRecord] = []

        for record in records {
            if calendar.isDateInToday(record.createdAt) {
                today.append(record)
            } else if calendar.isDateInYesterday(record.createdAt) {
                yesterday.append(record)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now),
                      record.createdAt >= weekAgo {
                week.append(record)
            } else {
                earlier.append(record)
            }
        }

        return [
            Group(id: "today", title: "Today", records: today),
            Group(id: "yesterday", title: "Yesterday", records: yesterday),
            Group(id: "week", title: "Previous 7 Days", records: week),
            Group(id: "earlier", title: "Earlier", records: earlier),
        ].filter { !$0.records.isEmpty }
    }

    func refresh() {
        do {
            let matching = try history.records(matching: searchText)
            records = matching.filter { filter.includes($0.createdAt) }
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load history. Please try again."
            Log.app.error("History fetch failed: \(error.localizedDescription)")
        }
    }

    func copy(_ record: TranscriptionRecord) {
        pasteboard.copy(record.text)
        justCopiedID = record.persistentModelID
        Task {
            try? await Task.sleep(for: .milliseconds(1_200))
            justCopiedID = nil
        }
    }

    func delete(_ record: TranscriptionRecord) {
        do {
            try history.delete(record)
            refresh()
        } catch {
            errorMessage = "Couldn't delete that dictation. Please try again."
            Log.app.error("History delete failed: \(error.localizedDescription)")
        }
    }

    func clearAll() {
        do {
            try history.deleteAll()
            refresh()
        } catch {
            errorMessage = "Couldn't clear history. Please try again."
            Log.app.error("History clear failed: \(error.localizedDescription)")
        }
    }
}
