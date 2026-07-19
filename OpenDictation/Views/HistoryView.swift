import SwiftUI

/// The History window: every saved dictation, searchable, with per-row copy
/// and delete.
struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @State private var isConfirmingClearAll = false

    init(history: any HistoryStoring, pasteboard: any PasteboardServicing) {
        _viewModel = State(initialValue: HistoryViewModel(history: history, pasteboard: pasteboard))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("History")
                .searchable(text: $viewModel.searchText, prompt: "Search transcripts")
                .toolbar {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear All", role: .destructive) {
                            isConfirmingClearAll = true
                        }
                        .disabled(viewModel.records.isEmpty && viewModel.searchText.isEmpty)
                    }
                }
        }
        .frame(minWidth: 480, minHeight: 360)
        .onAppear { viewModel.refresh() }
        // New dictations may land while the window sits in the background;
        // refresh whenever it comes forward again.
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

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView(
                "Something Went Wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )
        } else if viewModel.records.isEmpty {
            if viewModel.searchText.isEmpty {
                ContentUnavailableView(
                    "No Dictations Yet",
                    systemImage: "mic",
                    description: Text("Transcripts are saved here automatically after each dictation.")
                )
            } else {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        } else {
            List(viewModel.records) { record in
                HistoryRow(
                    record: record,
                    justCopied: viewModel.justCopiedID == record.persistentModelID,
                    onCopy: { viewModel.copy(record) },
                    onDelete: { viewModel.delete(record) }
                )
            }
            .listStyle(.inset)
            .animation(.default, value: viewModel.records.count)
        }
    }
}

/// One saved dictation: text preview, metadata, and quick actions.
private struct HistoryRow: View {
    let record: TranscriptionRecord
    let justCopied: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.text)
                    .lineLimit(3)
                    .textSelection(.enabled)
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

            Spacer(minLength: 8)

            Button {
                onCopy()
            } label: {
                Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)
            .help("Copy transcript")

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete")
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button("Copy", action: onCopy)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
