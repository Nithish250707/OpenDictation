import Foundation
import SwiftData

/// A saved dictation. Stored locally (SwiftData) and nowhere else.
@Model
final class TranscriptionRecord {
    var text: String
    var createdAt: Date
    var duration: TimeInterval
    var providerID: String
    var modelName: String

    init(transcript: Transcript) {
        text = transcript.text
        createdAt = transcript.createdAt
        duration = transcript.duration
        providerID = transcript.providerID
        modelName = transcript.model
    }
}
