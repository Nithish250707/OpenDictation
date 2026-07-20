import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct HistoryFilterTests {
    private func makeViewModel(daysAgo: [Int]) throws -> HistoryViewModel {
        let history = HistoryService.inMemory()
        for days in daysAgo {
            let date = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
            try history.save(Transcript(
                text: "record-\(days)",
                duration: 1,
                providerID: "openai",
                model: "whisper-1",
                createdAt: date
            ))
        }
        let viewModel = HistoryViewModel(history: history, pasteboard: SpyPasteboard())
        viewModel.refresh()
        return viewModel
    }

    @Test func allFilterKeepsEverything() throws {
        let viewModel = try makeViewModel(daysAgo: [0, 1, 3, 10, 30])
        #expect(viewModel.filter == .all)
        #expect(viewModel.records.count == 5)
    }

    @Test func todayFilterKeepsOnlyToday() throws {
        let viewModel = try makeViewModel(daysAgo: [0, 1, 3, 10])
        viewModel.filter = .today
        #expect(viewModel.records.count == 1)
        #expect(viewModel.records.first?.text == "record-0")
    }

    @Test func weekFilterKeepsLastSevenDays() throws {
        let viewModel = try makeViewModel(daysAgo: [0, 1, 3, 10, 30])
        viewModel.filter = .week
        #expect(viewModel.records.count == 3)
    }

    @Test func isFilteringReflectsSearchOrRange() throws {
        let viewModel = try makeViewModel(daysAgo: [0])
        #expect(!viewModel.isFiltering)
        viewModel.filter = .today
        #expect(viewModel.isFiltering)
        viewModel.filter = .all
        viewModel.searchText = "record"
        #expect(viewModel.isFiltering)
    }

    @Test func groupsBucketByRecency() throws {
        let viewModel = try makeViewModel(daysAgo: [0, 1, 3, 30])
        let titles = viewModel.groups.map(\.title)
        #expect(titles == ["Today", "Yesterday", "Previous 7 Days", "Earlier"])
        // Every record is placed in exactly one group.
        #expect(viewModel.groups.reduce(0) { $0 + $1.records.count } == 4)
    }

    @Test func emptyGroupsAreOmitted() throws {
        let viewModel = try makeViewModel(daysAgo: [0])
        #expect(viewModel.groups.map(\.title) == ["Today"])
    }

    @Test func filterIncludesLogic() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        #expect(HistoryViewModel.Filter.today.includes(.now))
        #expect(!HistoryViewModel.Filter.today.includes(twoDaysAgo))
        #expect(HistoryViewModel.Filter.week.includes(twoDaysAgo))
        #expect(HistoryViewModel.Filter.all.includes(twoDaysAgo))
    }
}
