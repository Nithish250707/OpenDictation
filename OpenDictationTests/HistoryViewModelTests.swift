import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct HistoryViewModelTests {
    private func makeViewModel(
        texts: [String] = []
    ) throws -> (HistoryViewModel, HistoryService, SpyPasteboard) {
        let service = HistoryService.inMemory()
        for (index, text) in texts.enumerated() {
            try service.save(Transcript(
                text: text,
                duration: 1,
                providerID: "openai",
                model: "whisper-1",
                createdAt: .now.addingTimeInterval(TimeInterval(index))
            ))
        }
        let pasteboard = SpyPasteboard()
        return (HistoryViewModel(history: service, pasteboard: pasteboard), service, pasteboard)
    }

    @Test func refreshLoadsAllRecords() throws {
        let (viewModel, _, _) = try makeViewModel(texts: ["first", "second"])

        viewModel.refresh()

        #expect(viewModel.records.count == 2)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func typingInSearchFiltersLive() throws {
        let (viewModel, _, _) = try makeViewModel(texts: ["buy milk", "write tests"])
        viewModel.refresh()

        viewModel.searchText = "tests"

        #expect(viewModel.records.map(\.text) == ["write tests"])

        viewModel.searchText = ""
        #expect(viewModel.records.count == 2)
    }

    @Test func copyPutsRecordTextOnPasteboardWithFeedback() throws {
        let (viewModel, _, pasteboard) = try makeViewModel(texts: ["copy me"])
        viewModel.refresh()
        let record = try #require(viewModel.records.first)

        viewModel.copy(record)

        #expect(pasteboard.copiedStrings == ["copy me"])
        #expect(viewModel.justCopiedID == record.persistentModelID)
    }

    @Test func deleteRemovesRecordAndRefreshes() throws {
        let (viewModel, _, _) = try makeViewModel(texts: ["stays", "goes"])
        viewModel.refresh()
        let doomed = try #require(viewModel.records.first { $0.text == "goes" })

        viewModel.delete(doomed)

        #expect(viewModel.records.map(\.text) == ["stays"])
    }

    @Test func clearAllEmptiesTheList() throws {
        let (viewModel, _, _) = try makeViewModel(texts: ["one", "two", "three"])
        viewModel.refresh()

        viewModel.clearAll()

        #expect(viewModel.records.isEmpty)
    }
}
