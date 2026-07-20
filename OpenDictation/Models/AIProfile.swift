import Foundation

/// A dictation "profile" that shapes tone and formatting for a context.
///
/// UI-preview model only in this release — profiles are illustrative sample
/// data and are not yet applied to transcription.
struct AIProfile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let summary: String
    let tone: String
    let isDefault: Bool

    static let samples: [AIProfile] = [
        AIProfile(
            name: "Default",
            icon: "sparkles",
            summary: "Balanced formatting and punctuation for everyday dictation.",
            tone: "Neutral",
            isDefault: true
        ),
        AIProfile(
            name: "Email",
            icon: "envelope",
            summary: "Polished, professional phrasing with greetings and sign-offs.",
            tone: "Professional",
            isDefault: false
        ),
        AIProfile(
            name: "Code",
            icon: "chevron.left.forwardslash.chevron.right",
            summary: "Preserves identifiers, snippets, and technical terms verbatim.",
            tone: "Technical",
            isDefault: false
        ),
        AIProfile(
            name: "Messages",
            icon: "bubble.left.and.bubble.right",
            summary: "Casual and concise, tuned for quick chats.",
            tone: "Casual",
            isDefault: false
        ),
        AIProfile(
            name: "Notes",
            icon: "note.text",
            summary: "Structured capture with bullets for fast thinking.",
            tone: "Structured",
            isDefault: false
        ),
    ]
}
