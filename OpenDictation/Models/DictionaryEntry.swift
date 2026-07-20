import Foundation

/// A custom vocabulary entry: a term Open Dictation should recognize, or a
/// spoken phrase to rewrite.
///
/// UI-preview model only in this release — entries are illustrative sample
/// data and are not yet applied to transcription.
struct DictionaryEntry: Identifiable, Hashable {
    let id = UUID()
    let term: String
    /// When set, `term` is rewritten to this. When nil, `term` is simply a
    /// recognized spelling.
    let replacement: String?
    let category: String

    var isReplacement: Bool { replacement != nil }

    static let samples: [DictionaryEntry] = [
        DictionaryEntry(term: "OpenDictation", replacement: nil, category: "Names"),
        DictionaryEntry(term: "Anthropic", replacement: nil, category: "Names"),
        DictionaryEntry(term: "SwiftUI", replacement: nil, category: "Technical"),
        DictionaryEntry(term: "Keychain", replacement: nil, category: "Technical"),
        DictionaryEntry(term: "gonna", replacement: "going to", category: "Replacements"),
        DictionaryEntry(term: "wanna", replacement: "want to", category: "Replacements"),
        DictionaryEntry(term: "kinda", replacement: "kind of", category: "Replacements"),
        DictionaryEntry(term: "api", replacement: "API", category: "Capitalization"),
        DictionaryEntry(term: "macos", replacement: "macOS", category: "Capitalization"),
    ]
}
