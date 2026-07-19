import Foundation
import SwiftData

/// SwiftData-backed history store in Application Support. The container is
/// injectable so tests (and the fallback path) run fully in memory.
@MainActor
final class HistoryService: HistoryStoring {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    static func live() -> HistoryService {
        do {
            let directory = URL.applicationSupportDirectory
                .appending(path: "OpenDictation", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let configuration = ModelConfiguration(url: directory.appending(path: "History.store"))
            let container = try ModelContainer(for: TranscriptionRecord.self, configurations: configuration)
            return HistoryService(container: container)
        } catch {
            // Better a session-only history than a crashed app or no dictation.
            Log.app.error("History store unavailable, using in-memory fallback: \(error.localizedDescription)")
            return .inMemory()
        }
    }

    static func inMemory() -> HistoryService {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        // A schema-only in-memory container can't fail in practice.
        let container = try! ModelContainer(for: TranscriptionRecord.self, configurations: configuration)
        return HistoryService(container: container)
    }

    func save(_ transcript: Transcript) throws {
        context.insert(TranscriptionRecord(transcript: transcript))
        try context.save()
    }

    func records(matching query: String?) throws -> [TranscriptionRecord] {
        var descriptor = FetchDescriptor<TranscriptionRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let query, !query.isEmpty {
            descriptor.predicate = #Predicate { $0.text.localizedStandardContains(query) }
        }
        return try context.fetch(descriptor)
    }

    func delete(_ record: TranscriptionRecord) throws {
        context.delete(record)
        try context.save()
    }

    func deleteAll() throws {
        try context.delete(model: TranscriptionRecord.self)
        try context.save()
    }
}
