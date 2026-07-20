import SwiftData
import SwiftUI

/// The History screen: every saved dictation, searchable and filterable, in
/// date-grouped cards with per-item copy and delete.
struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @State private var isConfirmingClearAll = false
    @State private var hoveredID: PersistentIdentifier?

    init(history: any HistoryStoring, pasteboard: any PasteboardServicing) {
        _viewModel = State(initialValue: HistoryViewModel(history: history, pasteboard: pasteboard))
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            Divider()
            content
        }
        .navigationTitle("History")
        .searchable(text: $viewModel.searchText, placement: .toolbar, prompt: "Search transcripts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear All", role: .destructive) {
                    isConfirmingClearAll = true
                }
                .disabled(viewModel.records.isEmpty && !viewModel.isFiltering)
            }
        }
        .onAppear { viewModel.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.refresh()
        }
        .confirmationDialog(
            "Clear all dictation history?",
            isPresented: $isConfirmingClearAll
        ) {
            Button("Clear All", role: .destructive) { viewModel.clearAll() }
        } message: {
            Text("This removes every saved transcript from this Mac. This can't be undone.")
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        HStack {
            Picker("Range", selection: $viewModel.filter) {
                ForEach(HistoryViewModel.Filter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()

            Spacer()

            if !viewModel.records.isEmpty {
                Text("^[\(viewModel.records.count) dictation](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .animation(.default, value: viewModel.filter)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            EmptyStateView(icon: "exclamationmark.triangle", title: "Something Went Wrong", message: errorMessage)
        } else if viewModel.records.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.groups) { group in
                        Section {
                            ForEach(group.records) { record in
                                HistoryCard(
                                    record: record,
                                    justCopied: viewModel.justCopiedID == record.persistentModelID,
                                    isHovered: hoveredID == record.persistentModelID,
                                    onCopy: { viewModel.copy(record) },
                                    onDelete: { viewModel.delete(record) }
                                )
                                .onHover { hovering in
                                    hoveredID = hovering ? record.persistentModelID : nil
                                }
                            }
                        } header: {
                            Text(group.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.bar)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
            }
            .animation(.default, value: viewModel.records.map(\.persistentModelID))
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.isFiltering {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No Results",
                message: "No dictations match your search or filter."
            )
        } else {
            EmptyStateView(
                icon: "mic",
                title: "No Dictations Yet",
                message: "Transcripts are saved here automatically after each dictation. Press your shortcut to try it."
            )
        }
    }
}

/// One saved dictation as a card.
private struct HistoryCard: View {
    let record: TranscriptionRecord
    let justCopied: Bool
    let isHovered: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(record.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text(record.createdAt, format: .relative(presentation: .named))
                    Text("·")
                    Text(RecordingTimerView.format(record.duration))
                        .monospacedDigit()
                    Text("·")
                    Text(record.modelName)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Button(action: onCopy) {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                        .contentTransition(.symbolEffect(.replace))
                }
                .help("Copy transcript")
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .help("Delete")
            }
            .buttonStyle(.borderless)
            .opacity(isHovered ? 1 : 0.55)
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.separator.opacity(isHovered ? 0.8 : 0.4), lineWidth: 1)
        }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .contextMenu {
            Button("Copy", action: onCopy)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
