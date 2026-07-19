import Foundation

/// The result of a completed transcription, independent of which provider
/// produced it.
struct Transcript: Sendable, Equatable {
    var text: String
    /// Length of the source audio in seconds.
    var duration: TimeInterval
    var providerID: String
    var model: String
    var createdAt: Date
}
