import Foundation
import Observation
import SwiftData

/// State and intent for the History window: querying, copying, and deleting
/// saved dictations.
@MainActor
@Observable
final class HistoryViewModel {
    private(set) var records: [TranscriptionRecord] = []
    private(set) var errorMessage: String?
    /// Row whose Copy button was just clicked, for transient feedback.
    private(set) var justCopiedID: PersistentIdentifier?

    var searchText = "" {
        didSet { refresh() }
    }

    private let history: any HistoryStoring
    private let pasteboard: any PasteboardServicing

    init(history: any HistoryStoring, pasteboard: any PasteboardServicing) {
        self.history = history
        self.pasteboard = pasteboard
    }

    func refresh() {
        do {
            records = try history.records(matching: searchText)
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
