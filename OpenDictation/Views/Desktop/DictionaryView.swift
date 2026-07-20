import SwiftUI

/// Preview of a custom vocabulary: names and terms to recognize, plus spoken
/// phrases to rewrite. UI-only in this release — entries are sample data.
struct DictionaryView: View {
    @State private var searchText = ""

    private var entries: [DictionaryEntry] {
        let all = DictionaryEntry.samples
        guard !searchText.isEmpty else { return all }
        let query = searchText.lowercased()
        return all.filter {
            $0.term.lowercased().contains(query)
                || ($0.replacement?.lowercased().contains(query) ?? false)
                || $0.category.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if entries.isEmpty {
                EmptyStateView(
                    icon: "character.book.closed",
                    title: "No matches",
                    message: "No dictionary entries match “\(searchText)”."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(entries) { entry in
                            EntryRow(entry: entry)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 820)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Dictionary")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text("Dictionary")
                    .font(.largeTitle.weight(.bold))
                PreviewBadge()
                Spacer()
                Button {
                    // Editing arrives in a future release.
                } label: {
                    Label("Add Word", systemImage: "plus")
                }
                .disabled(true)
            }
            Text("Teach Open Dictation your names, jargon, and preferred spellings.")
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search terms", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(.separator.opacity(0.4), lineWidth: 1)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 16)
        .frame(maxWidth: 820, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EntryRow: View {
    let entry: DictionaryEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isReplacement ? "arrow.left.arrow.right" : "text.badge.checkmark")
                .foregroundStyle(.tint)
                .frame(width: 26)

            HStack(spacing: 8) {
                Text(entry.term)
                    .font(.body.weight(.medium))
                if let replacement = entry.replacement {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(replacement)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text(entry.category)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.quaternary, in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.separator.opacity(0.4), lineWidth: 1)
        }
    }
}
