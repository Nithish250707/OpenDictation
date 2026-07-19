import Foundation

/// Capability: persisting finished transcripts locally and querying them.
@MainActor
protocol HistoryStoring: AnyObject {
    func save(_ transcript: Transcript) throws

    /// Newest first; `query` filters by transcript text (nil/empty = all).
    func records(matching query: String?) throws -> [TranscriptionRecord]

    func delete(_ record: TranscriptionRecord) throws
    func deleteAll() throws
}
